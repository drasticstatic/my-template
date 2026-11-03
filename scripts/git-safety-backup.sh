#!/bin/sh
""":"
# The two quote marks above are a no-op to sh and the start of a string to python3, so this one file runs under both.
command -v python3 >/dev/null 2>&1 || { echo "git-safety-backup: python3 is required (xcode-select --install)" >&2; exit 127; }
exec python3 -I "$0" "$@"
"""
# git-safety-backup.sh: put what GitHub does not yet have into iCloud Drive as finished, verified git bundles.
#
#     sh scripts/git-safety-backup.sh --init          once per machine: write the skip list, then read it
#     sh scripts/git-safety-backup.sh --dry-run       report what would be written, write nothing
#     sh scripts/git-safety-backup.sh                 write
#     sh scripts/git-safety-backup.selftest.sh        prove it, in a throwaway folder
#     scripts/launchd/git-safety-backup.plist.template  run it every two hours, once you have read a dry run
#
# The principle: GitHub keeps what is committed and pushed. iCloud only receives finished files holding what GitHub
# does not yet have. Repositories never live in iCloud. Walkthrough: walkthroughs/ICLOUD-AND-GITHUB-TOGETHER.md
#
# For each repository found under the roots, up to eight folders deep:
#   - a repository with a lock, or a rebase, merge, cherry-pick, revert or bisect under way is left alone until next run;
#   - uncommitted work (staged, unstaged, untracked) is captured through a temporary copy of the index, into a temporary
#     object folder. The repository's own index, stash list, refs and object store are only read, never written;
#   - paths named like secrets are left out and counted, never listed. An untracked one is not opened at all; a tracked
#     one git may hash to learn whether it changed, and that hash goes nowhere (see SECRET_NAMES);
#   - the bundle holds that work, the stash entries, and the branches and tags GitHub lacks. The rest of the history
#     stays out (--not the remote branches), so the bundle is small. A repository with no remote gets its whole history;
#   - if what was found matches the last backup, or there is nothing GitHub lacks, nothing is written;
#   - the bundle is built in a temporary folder, checked with `git bundle verify`, and only then moved into
#     <dest>/<repo-path-slug>/<UTC timestamp>.bundle, keeping the newest seven per repository.
#
# Options:
#   --init               write an empty skip list if there is none, and stop. Nothing runs until that file exists,
#                        so a new machine cannot send a private repository to iCloud before someone has thought of it
#   --dry-run            everything except the write; sizes are estimates
#   --root DIR           where to look; repeat for more (default: roots.txt in the config folder if it exists, else
#                        DEFAULT_ROOTS below, whichever exist)
#   --dest DIR           where bundles go (default: iCloud Drive, GitBackups)
#   --keep N             bundles kept per repository (default 7)
#   --max-file-mb N      a changed file above this is left out, counted and warned about (default 100)
#   --max-bundle-mb N    a bundle above this is not written, and is warned about (default 1024)
#   --config-dir DIR     default ~/.config/git-safety-backup
#   --verbose            also name repositories that were clean or unchanged
#
# Files in the config folder:
#   skip.txt             one per line: a folder name (any part of the path, any case) or a ~/full/path. A skipped
#                        repository is never opened, and neither is a linked worktree or clone of one
#   history-ok.txt       one repository path per line: you looked, and its secret-named history may go (see HELD below)
#   roots.txt            one root per line, replacing the default roots
#   state/               a fingerprint per repository, so an unchanged repository writes nothing
#
# Log words: WROTE, WOULD WRITE, DEFER (left for next run), HELD (commits GitHub lacks contain a secret-named path,
# and a commit cannot be filtered, so the repository is not backed up until you decide), TOO BIG, WARN, FAIL.
# Exit: 0 fine (a DEFER or HELD is not a failure) · 1 a repository failed · 2 usage · 3 no skip list · 4 iCloud Drive absent
import argparse
import datetime
import errno
import fcntl
import fnmatch
import hashlib
import os
import re
import shutil
import subprocess
import sys
import tempfile

# Edit these for your own machine, or write roots.txt and leave this file alone.
DEFAULT_ROOTS = [
    "~/code", "~/dappu", "~/theholyearthfoundation", "~/psychedelicsinrecovery",
    "~/Octagon-Religious-Research-Group-ORG", "~/psanctuary", "~/psanctuarychurch", "~/taylordwraps-org",
    "~/intent", "~/code-forked", "~/littlebirds-git-home",
]
ICLOUD_DRIVE = "~/Library/Mobile Documents/com~apple~CloudDocs"
DEFAULT_DEST = ICLOUD_DRIVE + "/GitBackups"
MAX_DEPTH = 8
MAX_SLUG = 200  # a file name may hold 255 bytes, and a timestamp and a short hash still have to fit
READ_LIMIT = 4  # changed files adding up to this many bundle caps are not read at all: logs squeeze about fourfold
GIT_TIMEOUT = 900

# Matched against every part of a path, in lower case, so keystore/UTC--x.json and WALLET.DAT both count.
SECRET_NAMES = [
    ".env*", "*.pem", "*.key", "*.p12", "keystore*", "wallet*", "*mnemonic*", "*.secret*", "id_rsa*",
    "secrets*", "id_ed25519*", "id_ecdsa*", "id_dsa*", "*.pfx", "*.keystore", "*.jks", "*.ppk", "*.kdbx",
    "*seed*phrase*", "service-account*", "credentials*", ".npmrc", ".netrc", ".pgpass",
]
# Templates by name; these may sit in history, and only in history. Uncommitted, they are left out with the rest.
SAFE_IN_HISTORY = {".env.example", ".env.sample", ".env.template", ".env.dist"}
NOISE_NAMES = {"node_modules", ".venv", "venv", "__pycache__", ".DS_Store"}
WALK_PRUNE = {"node_modules", ".venv", "venv", "__pycache__", ".cache", ".next", ".Trash"}

BUNDLE_NAME = re.compile(r"^(\d{8}T\d{6}Z(?:-\d+)?)\.bundle$")
# An iCloud file evicted from this Mac can appear as a hidden placeholder named .<name>.icloud.
PLACEHOLDER_NAME = re.compile(r"^\.(\d{8}T\d{6}Z(?:-\d+)?)\.bundle\.icloud$")

# Only the variables that would point git somewhere else are removed; everything else passes through unread.
SCRUBBED = ("GIT_DIR", "GIT_WORK_TREE", "GIT_INDEX_FILE", "GIT_OBJECT_DIRECTORY", "GIT_ALTERNATE_OBJECT_DIRECTORIES",
            "GIT_COMMON_DIR", "GIT_PREFIX", "GIT_LITERAL_PATHSPECS")
BASE_ENV = {k: v for k, v in os.environ.items() if k not in SCRUBBED}
BASE_ENV.update(GIT_OPTIONAL_LOCKS="0", GIT_TERMINAL_PROMPT="0", GIT_NO_LAZY_FETCH="1", LC_ALL="C")
# fsmonitor and hooks can run a repository's own programs; nothing here should. gc and threads: stay out of the way.
# The LFS filter is off too: it would write into .git/lfs, and it stops `git add` where git-lfs is required but missing.
GIT = ["git", "-c", "core.fsmonitor=false", "-c", "core.hooksPath=/dev/null", "-c", "core.splitIndex=false",
       "-c", "core.untrackedCache=false", "-c", "gc.auto=0", "-c", "maintenance.auto=false", "-c", "pack.threads=1",
       "-c", "advice.addEmbeddedRepo=false", "-c", "filter.lfs.required=false", "-c", "filter.lfs.clean=",
       "-c", "filter.lfs.smudge=", "-c", "filter.lfs.process="]
IDENTITY = {
    "GIT_AUTHOR_NAME": "git-safety-backup", "GIT_AUTHOR_EMAIL": "git-safety-backup@localhost",
    "GIT_COMMITTER_NAME": "git-safety-backup", "GIT_COMMITTER_EMAIL": "git-safety-backup@localhost",
}


class Failed(Exception):
    pass


class Deferred(Exception):
    pass


class TooMuch(Exception):
    pass


def log(word, message=""):
    stamp = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    print(("%s %s %s" % (stamp, word, message)).rstrip(), flush=True)


def human(size):
    size = float(size)
    for unit in ("B", "KB", "MB", "GB"):
        if size < 1024 or unit == "GB":
            return "%d %s" % (size, unit) if unit == "B" else "%.1f %s" % (size, unit)
        size /= 1024


def git(args, cwd, env=None, data=None, check=True, timeout=GIT_TIMEOUT):
    """Run git; return stdout as bytes, or None when check is False and it failed."""
    try:
        done = subprocess.run(GIT + args, cwd=cwd, env=env or BASE_ENV, input=data, timeout=timeout,
                              stdin=None if data is not None else subprocess.DEVNULL,
                              stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    except subprocess.TimeoutExpired:
        raise Failed("git %s took over %d seconds" % (args[0], timeout))
    if done.returncode == 0:
        return done.stdout
    if not check:
        return None
    last = done.stderr.decode("utf-8", "replace").strip().splitlines()
    raise Failed("git %s: %s" % (args[0], last[-1][:200] if last else "exit %d" % done.returncode))


def text(raw):
    return raw.decode("utf-8", "surrogateescape").strip()


def nul_list(raw):
    return [p for p in raw.split(b"\0") if p]


def is_secret(path, in_history=False):
    parts = os.fsdecode(path).lower().split("/")
    if in_history and parts[-1] in SAFE_IN_HISTORY:
        return False
    return any(fnmatch.fnmatchcase(part, pat) for part in parts for pat in SECRET_NAMES)


def is_noise(path):
    return any(part in NOISE_NAMES for part in os.fsdecode(path).split("/"))


class SkipList:
    def __init__(self, path):
        self.names, self.paths = set(), []
        with open(path, encoding="utf-8") as handle:
            for line in handle:
                line = line.split("#", 1)[0].strip().rstrip("/")
                if not line:
                    continue
                if "/" in line:
                    self.paths.append(os.path.abspath(os.path.expanduser(line)))
                else:
                    self.names.add(line.lower())

    def matches_path(self, path):
        path = os.path.abspath(path)
        if any(path == p or path.startswith(p + "/") for p in self.paths):
            return True
        return any(part.lower() in self.names for part in path.split("/"))

    def matches_url(self, url):
        name = url.rstrip("/").rsplit("/", 1)[-1].rsplit(":", 1)[-1].lower()
        return name[:-4] in self.names if name.endswith(".git") else name in self.names


def read_lines(path):
    if not os.path.exists(path):
        return []
    with open(path, encoding="utf-8") as handle:
        return [ln.strip() for ln in (raw.split("#", 1)[0] for raw in handle) if ln.strip()]


def find_repos(roots, skip):
    """Every folder holding a .git (a folder for a clone, a file for a worktree or submodule). Nested ones count."""
    repos, skipped, seen = [], 0, set()
    for root in roots:
        stack = [(root, 0)]
        while stack:
            folder, depth = stack.pop()
            if skip.matches_path(folder):
                skipped += 1
                continue
            try:
                entries = list(os.scandir(folder))
            except OSError:
                continue
            subfolders = []
            has_git = False
            for entry in entries:
                if entry.name == ".git":
                    has_git = True
                elif depth < MAX_DEPTH and entry.name not in WALK_PRUNE and entry.is_dir(follow_symlinks=False):
                    subfolders.append((entry.path, depth + 1))
            if has_git:
                real = os.path.realpath(folder)
                if real not in seen:
                    seen.add(real)
                    pointer = os.path.join(folder, ".git")
                    if os.path.isfile(pointer) and skip.matches_path(worktree_home(pointer)):
                        skipped += 1
                        continue  # a linked worktree of a skipped repository
                    repos.append(real)
            stack.extend(subfolders)
    return sorted(repos), skipped


def worktree_home(pointer):
    try:
        with open(pointer, encoding="utf-8", errors="replace") as handle:
            line = handle.readline().strip()
    except OSError:
        return pointer
    return line[len("gitdir:"):].strip() if line.startswith("gitdir:") else pointer


def slug_for(repo):
    home = os.path.expanduser("~")
    rel = repo[len(home) + 1:] if repo.startswith(home + "/") else repo.lstrip("/")
    slug = rel.replace("/", "--")
    clean = re.sub(r"[^A-Za-z0-9._-]+", "_", slug)
    if clean != slug or "--" in rel or len(clean) > MAX_SLUG:  # two different paths must not share a folder
        clean = clean[:MAX_SLUG] + "-" + hashlib.sha256(rel.encode("utf-8", "surrogateescape")).hexdigest()[:6]
    return clean


def existing_bundles(folder):
    """(sort key, file name) for each backup here, oldest first, including ones evicted to a placeholder."""
    found = []
    try:
        names = os.listdir(folder)
    except OSError:
        return found
    for name in names:
        match = BUNDLE_NAME.match(name) or PLACEHOLDER_NAME.match(name)
        if match:
            found.append((match.group(1), name))
    return sorted(found)


def prune(folder, keep):
    bundles = existing_bundles(folder)
    gone = 0
    for _, name in bundles[:max(0, len(bundles) - max(1, keep))]:
        os.remove(os.path.join(folder, name))
        gone += 1
    return gone


def place(temp_bundle, folder):
    """Move the verified bundle into place, whole. The name is unique: a backup is never overwritten."""
    os.makedirs(folder, mode=0o700, exist_ok=True)
    stamp = datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    final, n = os.path.join(folder, stamp + ".bundle"), 0
    while os.path.exists(final):
        n += 1
        final = os.path.join(folder, "%s-%d.bundle" % (stamp, n))
    try:
        os.rename(temp_bundle, final)
    except OSError as err:
        if err.errno != errno.EXDEV:
            raise
        partial = final + ".partial"
        shutil.copyfile(temp_bundle, partial)
        with open(partial, "rb") as handle:
            os.fsync(handle.fileno())
        os.rename(partial, final)
    return final


class Result:
    def __init__(self, repo, kind, slug, size=0, note=""):
        self.repo, self.kind, self.slug, self.size, self.note = repo, kind, slug, size, note


class Capture:
    """The uncommitted work, as trees in a temporary object folder. Nothing in the repository changes."""

    def __init__(self):
        self.head = None
        self.head_tree = None
        self.staged_tree = None
        self.tree = None
        self.left_secret = 0
        self.left_big = 0
        self.left_noise = 0
        self.unreadable = False


def capture_work(repo, env, opts, empty_tree):
    work = Capture()
    head = git(["rev-parse", "-q", "--verify", "HEAD^{commit}"], repo, env, check=False)
    work.head = text(head) if head else None
    work.head_tree = text(git(["rev-parse", work.head + "^{tree}"], repo, env)) if work.head else empty_tree

    git(["update-index", "-q", "--refresh"], repo, env, check=False)  # exits 1 whenever anything has changed
    changed = nul_list(git(["diff-files", "--name-only", "-z"], repo, env))
    untracked = [p for p in nul_list(git(["ls-files", "-o", "--exclude-standard", "-z"], repo, env))
                 if not p.endswith(b"/")]  # a trailing slash is a nested repository, which gets its own bundle
    if work.head:
        staged = nul_list(git(["diff-index", "--cached", "--name-only", "-z", work.head], repo, env))
    else:
        staged = nul_list(git(["ls-files", "-z"], repo, env))

    base = os.fsencode(repo)
    cap = opts.max_file_mb * 1024 * 1024
    staged_set = set(staged)
    in_worktree = set(changed) | set(untracked)
    to_add, to_undo = [], []
    pending = 0
    for path in dict.fromkeys(changed + untracked + staged):
        leave = False
        if is_secret(path):
            work.left_secret, leave = work.left_secret + 1, True
        elif is_noise(path):
            work.left_noise, leave = work.left_noise + 1, True
        else:
            try:
                size = os.lstat(os.path.join(base, path)).st_size
                if size > cap:
                    work.left_big, leave = work.left_big + 1, True
                else:
                    pending += size
            except OSError:
                pass  # deleted: a deletion is work too, and takes no room
        if leave:
            if path in staged_set:
                to_undo.append(path)
        elif path in in_worktree:
            to_add.append(path)

    if pending > opts.max_bundle_mb * 1024 * 1024 * READ_LIMIT:
        raise TooMuch("changed files add up to %s, so they were not read. Ignore or commit them" % human(pending))

    if to_undo:  # staged but left out: this temporary index goes back to HEAD's version, or to no entry at all
        literal = dict(env, GIT_LITERAL_PATHSPECS="1")
        lines = []
        for path in to_undo:
            found = git(["ls-tree", work.head, "--", os.fsdecode(path)], repo, literal) if work.head else b""
            if found:  # "<mode> <type> <id><tab><path>"
                mode, _, blob = found.split(b"\t", 1)[0].split(b" ")
                lines.append(mode + b" " + blob + b"\t" + path + b"\0")
            else:
                lines.append(b"0 " + b"0" * len(work.head_tree) + b"\t" + path + b"\0")
        git(["update-index", "-z", "--index-info"], repo, env, data=b"".join(lines))

    wtree = git(["write-tree"], repo, env, check=False)
    if wtree is None:
        raise Deferred("unmerged paths")
    work.staged_tree = text(wtree)

    if to_add:  # `add -A`, minus what was left out, so `add` never opens a left-out file
        adding = dict(env, GIT_LITERAL_PATHSPECS="1")
        try:
            done = subprocess.run(GIT + ["add", "-A", "--ignore-errors", "--pathspec-from-file=-", "--pathspec-file-nul"],
                                  cwd=repo, env=adding, input=b"\0".join(to_add), timeout=GIT_TIMEOUT,
                                  stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
        except subprocess.TimeoutExpired:
            raise Failed("git add took over %d seconds" % GIT_TIMEOUT)
        if done.returncode != 0:
            if b"did not match" in done.stderr:
                raise Deferred("files changed while they were being read")
            work.unreadable = True  # --ignore-errors added the rest
    wtree = git(["write-tree"], repo, env, check=False)
    if wtree is None:
        raise Deferred("unmerged paths")
    work.tree = text(wtree)
    return work


def commit_work(repo, env, work, branch):
    """Up to two commits, in the shape of a stash: HEAD <- staged <- everything. A restore recovers which was which."""
    commit_env = dict(env, **IDENTITY)
    lines = ["Branch: %s" % (branch or "(detached)"), "Base: %s" % (work.head or "(none)")]
    lines.append("Left-out-by-name: %d" % work.left_secret)
    lines.append("Left-out-by-size: %d" % work.left_big)
    trailer = "\n".join(lines)
    parent = work.head
    parent_tree = work.head_tree
    wip = staged = None
    if work.staged_tree != parent_tree:
        args = ["commit-tree", work.staged_tree, "-m", "git-safety-backup: staged work", "-m", trailer]
        staged = text(git(args + (["-p", parent] if parent else []), repo, commit_env))
        parent, parent_tree, wip = staged, work.staged_tree, staged
    if work.tree != parent_tree:
        args = ["commit-tree", work.tree, "-m", "git-safety-backup: all work in progress", "-m", trailer]
        wip = text(git(args + (["-p", parent] if parent else []), repo, commit_env))
    return wip, staged


def unpushed_refs(repo, env):
    """The branches and tags GitHub lacks, plus a detached HEAD, and whether this repository has a remote at all."""
    listing = text(git(["for-each-ref", "--format=%(objectname) %(refname)", "refs/heads", "refs/tags"], repo, env))
    local = dict(reversed(line.split(" ", 1)) for line in listing.splitlines())
    remote_tips = sorted(set(text(git(["for-each-ref", "--format=%(objectname)", "refs/remotes"], repo, env)).split()))
    out = {}
    if not remote_tips:
        out.update(local)
    elif text(git(["rev-list", "-1", "--branches", "--tags", "--not", "--remotes"], repo, env)):
        for ref, sha in local.items():
            if text(git(["rev-list", "-1", sha, "--not", "--remotes"], repo, env)):
                out[ref] = sha
    if git(["symbolic-ref", "-q", "HEAD"], repo, env, check=False) is None:
        head = git(["rev-parse", "-q", "--verify", "HEAD^{commit}"], repo, env, check=False)
        if head and text(git(["rev-list", "-1", text(head), "--not", "--branches", "--remotes"], repo, env)):
            out["refs/safety/head"] = text(head)
    return out, remote_tips


def stash_refs(repo, env):
    """Stash entries are uncommitted work too. One holding a secret-named path stays behind, and is counted."""
    if git(["rev-parse", "-q", "--verify", "refs/stash"], repo, env, check=False) is None:
        return {}, 0
    out, left = {}, 0
    entries = text(git(["log", "-g", "--format=%H", "refs/stash"], repo, env)).split()
    for n, sha in enumerate(entries):
        parents = text(git(["rev-list", "--parents", "-1", sha], repo, env)).split()[1:]
        names = nul_list(git(["diff-tree", "-r", "-z", "--name-only", parents[0], sha], repo, env))
        names += nul_list(git(["diff-tree", "-r", "-z", "--name-only", parents[0], parents[1]], repo, env))
        if len(parents) > 2:
            names += nul_list(git(["ls-tree", "-r", "-z", "--name-only", parents[2]], repo, env))
        if any(is_secret(p) for p in names):
            left += 1
        else:
            out["refs/safety/stash/%d" % n] = sha
    return out, left


def secret_names_in_history(repo, env, tips):
    """How many secret-named paths the commits GitHub lacks touch. A commit cannot be filtered, only held back."""
    if not tips:
        return 0
    commits = git(["rev-list", "--stdin", "--not", "--remotes"], repo, env, data=("\n".join(tips) + "\n").encode())
    if not commits.strip():
        return 0
    names = git(["diff-tree", "--stdin", "--root", "-r", "-m", "--no-commit-id", "--name-only", "-z"], repo, env,
                data=commits)
    return len({p for p in nul_list(names) if is_secret(p, in_history=True)})


def back_up(repo, opts, skip, history_ok, state_dir):
    slug = slug_for(repo)
    urls = git(["config", "--get-regexp", r"^remote\..*\.url$"], repo, check=False) or b""
    if any(skip.matches_url(text(line).split(" ", 1)[-1]) for line in urls.splitlines()):
        return Result(repo, "skipped", slug)

    names = ["index", "index.lock", "objects", "shallow", "rebase-merge", "rebase-apply", "MERGE_HEAD",
             "CHERRY_PICK_HEAD", "REVERT_HEAD", "BISECT_LOG"]
    args = ["rev-parse", "--path-format=absolute"]
    for name in names:
        args += ["--git-path", name]
    paths = dict(zip(names, os.fsdecode(git(args, repo)).splitlines()))
    if os.path.exists(paths["index.lock"]):
        age = (datetime.datetime.now().timestamp() - os.path.getmtime(paths["index.lock"])) / 3600
        stale = " (it is %.0f hours old: if no git is running, it is stale and yours to remove)" % age if age >= 2 else ""
        return Result(repo, "deferred", slug, note="index.lock" + stale)
    for name in names[4:]:
        if os.path.exists(paths[name]):
            return Result(repo, "deferred", slug, note=name + " in progress")

    temp = tempfile.mkdtemp(prefix="git-safety-backup.")
    try:
        return back_up_in(repo, slug, temp, paths, opts, history_ok, state_dir)
    except Deferred as why:
        return Result(repo, "deferred", slug, note=str(why))
    except TooMuch as why:
        return Result(repo, "toobig", slug, note=str(why))
    finally:
        shutil.rmtree(temp, ignore_errors=True)


def back_up_in(repo, slug, temp, paths, opts, history_ok, state_dir):
    # A shadow repository: temporary refs and objects, reading the real objects through an alternate.
    shadow = os.path.join(temp, "shadow.git")
    git(["init", "-q", "--bare", "--template=", shadow], temp)
    os.makedirs(os.path.join(shadow, "objects", "info"), exist_ok=True)
    with open(os.path.join(shadow, "objects", "info", "alternates"), "w", encoding="utf-8") as handle:
        handle.write(paths["objects"] + "\n")
    if os.path.exists(paths["shallow"]):
        shutil.copyfile(paths["shallow"], os.path.join(shadow, "shallow"))
    env = dict(BASE_ENV, GIT_INDEX_FILE=os.path.join(temp, "index"),
               GIT_OBJECT_DIRECTORY=os.path.join(shadow, "objects"))
    if os.path.exists(paths["index"]):
        shutil.copyfile(paths["index"], env["GIT_INDEX_FILE"])

    empty_tree = text(git(["hash-object", "-t", "tree", "/dev/null"], repo, env))
    work = capture_work(repo, env, opts, empty_tree)
    branch_raw = git(["symbolic-ref", "-q", "--short", "HEAD"], repo, env, check=False)
    wip, staged = commit_work(repo, env, work, text(branch_raw) if branch_raw else None)

    refs, remote_tips = unpushed_refs(repo, env)
    tips = list(refs.values())
    stashes, stash_left = stash_refs(repo, env)
    notes = []
    if work.left_secret or stash_left:
        notes.append("left out by name: %d path(s), %d stash entr(ies)" % (work.left_secret, stash_left))
    if work.left_big:
        notes.append("left out over %d MB: %d file(s)" % (opts.max_file_mb, work.left_big))
        log("WARN", "%s: %d changed file(s) over %d MB left out; commit them, ignore them, or raise --max-file-mb"
            % (slug, work.left_big, opts.max_file_mb))
    if work.unreadable:
        notes.append("some files could not be read")
        log("WARN", "%s: some changed files could not be read and were left out" % slug)

    if not wip and not refs and not stashes:
        return Result(repo, "clean", slug, note="; ".join(notes))

    held = secret_names_in_history(repo, env, tips)
    if held and repo not in history_ok:
        return Result(repo, "held", slug, note="commits GitHub lacks touch %d secret-named path(s). Look, then "
                      "add this repository's path to history-ok.txt, or fix the history" % held)

    fingerprint_lines = sorted("%s %s" % pair for pair in list(refs.items()) + list(stashes.items()))
    fingerprint_lines += ["wip %s %s %s" % (work.head, work.tree, work.staged_tree)] if wip else []
    fingerprint = hashlib.sha256("\n".join(fingerprint_lines).encode()).hexdigest()
    folder = os.path.join(opts.dest, slug)
    state_file = os.path.join(state_dir, slug + ".sha256")
    previous = open(state_file, encoding="utf-8").read().strip() if os.path.exists(state_file) else ""
    if previous == fingerprint and existing_bundles(folder):
        return Result(repo, "unchanged", slug)

    # Name everything the bundle should carry, in the shadow repository.
    updates = ["create refs/seen/%d %s" % (n, sha) for n, sha in enumerate(remote_tips)]
    wanted = dict(refs, **stashes)
    if wip:
        wanted["refs/safety/wip"] = wip
    if staged:
        wanted["refs/safety/wip-staged"] = staged
    updates += ["create %s %s" % (ref, sha) for ref, sha in wanted.items()]
    git(["--git-dir", shadow, "update-ref", "--stdin"], temp, data=("\n".join(updates) + "\n").encode())
    selection = ["--branches", "--tags", "--glob=refs/safety/*", "--not", "--glob=refs/seen/*"]

    # The last gate: nothing secret-named in the commits this tool itself made, whatever the code above believes.
    if wip:
        made = ["diff-tree", "-r", "-z", "--name-only", work.head, wip] if work.head \
            else ["ls-tree", "-r", "-z", "--name-only", wip]
        if any(is_secret(p) for p in nul_list(git(made, repo, env))):
            raise Failed("a secret-named path reached the backup commit; nothing written")

    if opts.dry_run:
        usage = git(["--git-dir", shadow, "rev-list", "--disk-usage", "--objects"] + selection, temp, check=False)
        size = int(text(usage)) if usage else 0
        if size > opts.max_bundle_mb * 1024 * 1024:
            return Result(repo, "toobig", slug, size, "estimated over %d MB, would not be written" % opts.max_bundle_mb)
        return Result(repo, "would", slug, size, "; ".join(notes))

    if previous == "too-big " + fingerprint:
        return Result(repo, "toobig", slug, note="unchanged since it was last too big")
    bundle = os.path.join(temp, "out.bundle")
    git(["--git-dir", shadow, "bundle", "create", "-q", bundle] + selection, temp)
    size = os.path.getsize(bundle)
    if size > opts.max_bundle_mb * 1024 * 1024:
        write_atomically(state_file, "too-big " + fingerprint + "\n")
        return Result(repo, "toobig", slug, size, "over %d MB, not written" % opts.max_bundle_mb)
    git(["--git-dir", shadow, "bundle", "verify", "-q", bundle], temp)
    os.chmod(bundle, 0o600)
    try:
        place(bundle, folder)
        prune(folder, opts.keep)
    except PermissionError as err:
        raise Failed("cannot write to %s (%s). A background job may need Full Disk Access in System Settings"
                     % (folder, err.strerror))
    write_atomically(state_file, fingerprint + "\n")
    return Result(repo, "wrote", slug, size, "; ".join(notes))


def write_atomically(path, content):
    partial = path + ".tmp"
    with open(partial, "w", encoding="utf-8") as handle:
        handle.write(content)
    os.replace(partial, path)


SKIP_TEMPLATE = """# git-safety-backup skip list. A repository named here is never opened and never reaches iCloud.
# One per line: a folder name (any part of the path, any case), or a ~/full/path.
# Read your clones and think: which ones should never leave this machine, or never reach this iCloud account?
"""


def main():
    parser = argparse.ArgumentParser(add_help=True, description="See the head of this file.")
    parser.add_argument("--init", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--root", action="append", default=[])
    parser.add_argument("--dest", default=None)
    parser.add_argument("--keep", type=int, default=7)
    parser.add_argument("--max-file-mb", type=int, default=100)
    parser.add_argument("--max-bundle-mb", type=int, default=1024)
    parser.add_argument("--config-dir", default="~/.config/git-safety-backup")
    parser.add_argument("--verbose", action="store_true")
    opts = parser.parse_args()

    config_dir = os.path.abspath(os.path.expanduser(opts.config_dir))
    skip_path = os.path.join(config_dir, "skip.txt")
    if opts.init:
        os.makedirs(config_dir, mode=0o700, exist_ok=True)
        if os.path.exists(skip_path):
            print("%s already exists; left as it is." % skip_path)
        else:
            write_atomically(skip_path, SKIP_TEMPLATE)
            print("Wrote %s. Read it, add what should never reach iCloud, then run --dry-run." % skip_path)
        return 0
    if not os.path.exists(skip_path):
        print("git-safety-backup: no skip list at %s. Run --init, read it, and decide first." % skip_path, file=sys.stderr)
        return 3

    default_dest = opts.dest is None
    opts.dest = os.path.abspath(os.path.expanduser(opts.dest or DEFAULT_DEST))
    if default_dest and not os.path.isdir(os.path.expanduser(ICLOUD_DRIVE)):
        print("git-safety-backup: iCloud Drive is not at %s. Sign in and turn it on, or pass --dest." % ICLOUD_DRIVE,
              file=sys.stderr)
        return 4

    skip = SkipList(skip_path)
    history_ok = {os.path.realpath(os.path.expanduser(p)) for p in read_lines(os.path.join(config_dir, "history-ok.txt"))}
    roots_file = read_lines(os.path.join(config_dir, "roots.txt"))
    roots = [os.path.abspath(os.path.expanduser(r)) for r in (opts.root or roots_file or DEFAULT_ROOTS)]
    roots = [r for r in roots if os.path.isdir(r)]

    state_dir = os.path.join(config_dir, "state")
    os.makedirs(state_dir, mode=0o700, exist_ok=True)
    lock = open(os.path.join(config_dir, "lock"), "w")
    try:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except OSError:
        log("DEFER", "another run is under way")
        return 0
    try:
        os.nice(10)
    except OSError:
        pass

    repos, skipped = find_repos(roots, skip)
    tally = {k: 0 for k in ("wrote", "would", "unchanged", "clean", "deferred", "held", "toobig", "failed", "skipped")}
    tally["skipped"] = skipped
    total = 0
    words = {"wrote": "WROTE", "would": "WOULD WRITE", "deferred": "DEFER", "held": "HELD", "toobig": "TOO BIG"}
    for repo in repos:
        try:
            result = back_up(repo, opts, skip, history_ok, state_dir)
        except Failed as why:
            result = Result(repo, "failed", slug_for(repo), note=str(why))
        except OSError as why:
            result = Result(repo, "failed", slug_for(repo), note="%s: %s" % (type(why).__name__, why.strerror))
        tally[result.kind] += 1
        if result.kind in ("wrote", "would"):
            total += result.size
        if result.kind in words:
            bits = [human(result.size)] if result.size else []
            bits += [result.note] if result.note else []
            log(words[result.kind], "%s %s" % (result.slug, "(%s)" % "; ".join(bits) if bits else ""))
        elif result.kind == "failed":
            log("FAIL", "%s: %s" % (result.slug, result.note))
        elif opts.verbose:
            log(result.kind.upper(), result.slug)
    action = "would write %d (estimated %s)" % (tally["would"], human(total)) if opts.dry_run \
        else "wrote %d (%s)" % (tally["wrote"], human(total))
    log("SUMMARY", "%d repositories: %s; unchanged %d; clean %d; deferred %d; held %d; too big %d; failed %d; skipped %d"
        % (len(repos) + skipped, action, tally["unchanged"], tally["clean"], tally["deferred"], tally["held"],
           tally["toobig"], tally["failed"], tally["skipped"]))
    return 1 if tally["failed"] else 0


if __name__ == "__main__":
    sys.exit(main())
