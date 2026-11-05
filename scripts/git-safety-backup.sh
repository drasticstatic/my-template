#!/bin/sh
""":"
# The two quote marks above are a no-op to sh and the start of a string to python3, so this one file runs under both.
command -v python3 >/dev/null 2>&1 || { echo "git-safety-backup: python3 is required (xcode-select --install)" >&2; exit 127; }
exec python3 -I "$0" "$@"
"""
# git-safety-backup.sh: put what GitHub does not yet have into iCloud Drive as finished, verified git bundles.
#
#     sh scripts/git-safety-backup.sh --init          once per machine: write the skip list, the exclude list and the
#                                                     passphrase (shown once), then read the first two
#     sh scripts/git-safety-backup.sh --dry-run       report what would be written, write nothing
#     sh scripts/git-safety-backup.sh                 write
#     sh scripts/git-safety-backup.sh --encrypt       write, each bundle sealed with the passphrase (.bundle.enc)
#     sh scripts/git-safety-backup.sh --decrypt FILE  open a sealed bundle, into the current folder
#     sh scripts/git-safety-backup.selftest.sh        prove it, in a throwaway folder
#     scripts/launchd/git-safety-backup.plist.template  run it every two hours, once you have read a dry run
#
# The principle: GitHub keeps what is committed and pushed. iCloud only receives finished files holding what GitHub
# does not yet have. Repositories never live in iCloud. Walkthrough: walkthroughs/ICLOUD-AND-GITHUB-TOGETHER.md
#
# For each repository found under the roots, up to eight folders deep:
#   - a repository is backed up once, from its main worktree, however many linked worktrees (`git worktree add`) of it
#     are found: they share one object store, one stash list and one set of branches. Uncommitted work in each linked
#     worktree travels too, under refs/safety/worktrees/<folder name>/wip, so nothing is lost by counting it once;
#   - a repository with a lock, or a rebase, merge, cherry-pick, revert or bisect under way is left alone until next run.
#     A linked worktree in that state is left out of this run, with a note, and the rest of the repository still goes;
#   - uncommitted work (staged, unstaged, untracked) is captured through a temporary copy of the index, into a temporary
#     object folder. The repository's own index, stash list and refs are only read, and no object is added or changed.
#     (When captured work matches an object it already has, git refreshes that file's modified time, as any `git add` does);
#   - paths named like secrets are left out and counted, never listed. An untracked one is not opened at all; a tracked
#     one git may hash to learn whether it changed, and that hash goes nowhere (see SECRET_NAMES);
#   - noise (NOISE_NAMES: node_modules, .venv, venv, __pycache__, .DS_Store) and the globs in exclude.txt stay out of the
#     captured work, and out of stash entries too: a stash holding such paths travels as a copy rebuilt without them,
#     in the temporary object folder. The real stash is never touched. When the stash's base commit is one no branch
#     holds any more (a deploy commit since replaced, say), that base travels as a copy rebuilt the same way;
#   - the bundle holds that work, the stash entries, and the branches and tags GitHub lacks. The rest of the history
#     stays out (--not the remote branches), so the bundle is small. A repository with no remote gets its whole history;
#   - if what was found matches the last backup, or there is nothing GitHub lacks, nothing is written;
#   - the bundle is built in a temporary folder, checked with `git bundle verify`, with --encrypt sealed and checked
#     again by opening it, and only then moved into <dest>/<repo-path-slug>/<UTC timestamp>.bundle (or .bundle.enc),
#     keeping the newest seven per repository.
#
# Options:
#   --init               write the skip list, the exclude list and the passphrase file, whichever are missing, and stop.
#                        Nothing runs until the skip list exists, so a new machine cannot send a private repository
#                        to iCloud before someone has thought of it. The passphrase is printed once, for the
#                        password manager, and never again
#   --dry-run            everything except the write; sizes are estimates
#   --encrypt            seal each bundle: openssl enc -aes-256-cbc -pbkdf2 -salt, passphrase from the config folder.
#                        The passphrase file must be mode 600. Bundles are then named .bundle.enc
#   --decrypt FILE       open a sealed bundle into the current folder (or --out PATH), never into iCloud Drive, and stop
#   --out PATH           with --decrypt: where the opened bundle goes
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
#   exclude.txt          one glob per line, matched against paths inside every repository (see EXCLUDE_TEMPLATE). Such
#                        paths stay out of the captured work and out of stash copies; git itself is not told anything
#   passphrase           one line, mode 600, written by --init. Used by --encrypt and --decrypt; never read otherwise
#   history-ok.txt       one repository path per line: you looked, and its secret-named history may go (see HELD below)
#   roots.txt            one root per line, replacing the default roots
#   state/               a fingerprint per repository, so an unchanged repository writes nothing
#
# Log words: WROTE, WOULD WRITE, DEFER (left for next run), HELD (commits GitHub lacks contain a secret-named path,
# and a commit cannot be filtered, so the repository is not backed up until you decide), TOO BIG, WARN, FAIL.
# Exit: 0 fine (a DEFER or HELD is not a failure) · 1 a repository failed · 2 usage · 3 no skip list · 4 iCloud Drive absent
import argparse
import base64
import datetime
import errno
import fcntl
import fnmatch
import hashlib
import os
import re
import secrets
import shutil
import stat
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
PROBE_TIMEOUT = 60  # for the one question asked of every folder found: which repository is this
# How a bundle is sealed. The passphrase travels as a file path, never on the command line or in the environment.
OPENSSL = ["openssl", "enc", "-aes-256-cbc", "-pbkdf2", "-salt"]
BUNDLE_MAGIC = (b"# v2 git bundle", b"# v3 git bundle")

# Matched against every part of a path, in lower case, so keystore/UTC--x.json and WALLET.DAT both count.
SECRET_NAMES = [
    ".env*", "*.pem", "*.pem.*", "*.key", "*.key.*", "*.p12", "keystore*", "wallet*", "*mnemonic*", "*.secret*", "id_rsa*",
    "secrets*", "id_ed25519*", "id_ecdsa*", "id_dsa*", "*.pfx", "*.keystore", "*.jks", "*.ppk", "*.kdbx",
    "*seed*phrase*", "service-account*", "credentials*", "*credentials", ".npmrc", ".netrc", ".pgpass",
    ".git-credentials", ".pypirc", ".dockercfg", "*.gpg", "*.asc", "*.age", "utc--*", "token.json", "token.pickle",
    ".ssh", ".aws", ".gnupg",
]
# These words name source code too (useWallet.ts, resetPassword.tsx), so they only count on a file that holds data.
SECRET_WORDS = ["wallet", "secret", "credential", "password", "passwd", "private*key", "privatekey", "api*key", "apikey",
                "access*token", "auth*token", "api*token", "service*account", "serviceaccount"]
DATA_ENDINGS = ["json", "yaml", "yml", "toml", "ini", "txt", "csv", "dat", "cfg", "conf", "xml", "plist", "bak", "pickle"]
SECRET_NAMES += ["*%s*.%s" % (word, ending) for word in SECRET_WORDS for ending in DATA_ENDINGS]
# Templates by name; these may sit in history, and only in history. Uncommitted, they are left out with the rest.
SAFE_IN_HISTORY = {".env.example", ".env.sample", ".env.template", ".env.dist"}
NOISE_NAMES = {"node_modules", ".venv", "venv", "__pycache__", ".DS_Store"}
WALK_PRUNE = {"node_modules", ".venv", "venv", "__pycache__", ".cache", ".next", ".Trash"}

BUNDLE_NAME = re.compile(r"^(\d{8}T\d{6}Z(?:-\d+)?)\.bundle(?:\.enc)?$")
# An iCloud file evicted from this Mac can appear as a hidden placeholder named .<name>.icloud.
PLACEHOLDER_NAME = re.compile(r"^\.(\d{8}T\d{6}Z(?:-\d+)?)\.bundle(?:\.enc)?\.icloud$")

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


class Excludes:
    """Globs from exclude.txt, matched against paths inside a repository. A glob with a slash is matched against the
    whole path from the repository's root; one without is matched against each folder and file name along it.
    `*` matches anything, `/` included, so logs/edge/*.jsonl also covers logs/edge/2026/x.jsonl."""

    def __init__(self, path):
        self.whole, self.names = [], []
        for line in read_lines(path):
            line = line.strip("/")
            if line:
                (self.whole if "/" in line else self.names).append(line)

    def matches(self, path):
        path = os.fsdecode(path)
        if any(fnmatch.fnmatchcase(path, pat) for pat in self.whole):
            return True
        return any(fnmatch.fnmatchcase(part, pat) for part in path.split("/") for pat in self.names)


def find_repos(roots, skip):
    """Every repository under the roots, once each, named by its main worktree. A folder holds a .git folder (a clone)
    or a .git file (a linked worktree or a submodule). Linked worktrees of one repository share its common git dir,
    so they are folded into it, and the repository is backed up from its main worktree even when that main worktree
    sits outside the roots. Nested repositories count."""
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
                pointer = os.path.join(folder, ".git")
                if os.path.isfile(pointer) and skip.matches_path(worktree_home(pointer, folder)):
                    skipped += 1
                    continue  # a linked worktree, or a submodule, of a skipped repository
                main, common = main_worktree(folder)
                if common not in seen:
                    seen.add(common)
                    if skip.matches_path(main):
                        skipped += 1
                    else:
                        repos.append(main)
            stack.extend(subfolders)
    return sorted(repos), skipped


def worktree_home(pointer, folder):
    """Where a .git file points: under the main worktree's .git for a linked worktree, under the parent's for a submodule."""
    try:
        with open(pointer, encoding="utf-8", errors="replace") as handle:
            line = handle.readline().strip()
    except OSError:
        return pointer
    if not line.startswith("gitdir:"):
        return pointer
    return os.path.normpath(os.path.join(folder, line[len("gitdir:"):].strip()))


def main_worktree(folder):
    """(main worktree, common git dir) of the repository this folder belongs to. For a clone that is the folder itself
    and its .git; for a linked worktree, the folder holding the shared .git; for a submodule, the folder again, since
    a submodule is a repository of its own (its git dir lives under the parent's .git/modules)."""
    real = os.path.realpath(folder)
    try:
        raw = git(["rev-parse", "--path-format=absolute", "--git-common-dir"], folder, check=False, timeout=PROBE_TIMEOUT)
    except Failed:
        raw = None
    if not raw:
        return real, os.path.join(real, ".git")
    common = os.path.realpath(text(raw))
    if os.path.basename(common) == ".git" and os.path.isdir(os.path.dirname(common)):
        return os.path.dirname(common), common
    return real, common


def linked_worktrees(repo, env, skip):
    """(path, ref-safe name) for each linked worktree of this repository that is present and not skipped."""
    raw = git(["worktree", "list", "--porcelain"], repo, env, check=False)
    found, taken = [], set()
    main = os.path.realpath(repo)
    for block in (raw or b"").decode("utf-8", "surrogateescape").split("\n\n"):
        lines = block.strip().splitlines()
        if not lines or not lines[0].startswith("worktree "):
            continue
        path = lines[0][len("worktree "):]
        flags = {line.split(" ", 1)[0] for line in lines[1:]}
        if flags & {"bare", "prunable"} or not os.path.isdir(path) or os.path.realpath(path) == main:
            continue
        if skip.matches_path(path):
            continue
        name = re.sub(r"[^A-Za-z0-9_-]+", "_", os.path.basename(path.rstrip("/"))).strip("_") or "worktree"
        base, n = name, 1
        while name in taken:
            n += 1
            name = "%s-%d" % (base, n)
        taken.add(name)
        found.append((path, name))
    return found


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


def place(temp_bundle, folder, suffix=".bundle"):
    """Move the verified bundle into place, whole. The name is unique: a backup is never overwritten."""
    os.makedirs(folder, mode=0o700, exist_ok=True)
    stamp = datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    final, n = os.path.join(folder, stamp + suffix), 0
    while os.path.exists(final):
        n += 1
        final = os.path.join(folder, "%s-%d%s" % (stamp, n, suffix))
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
        self.left_excluded = 0
        self.unreadable = False
        self.wip = None
        self.staged = None


def capture_work(repo, env, opts, empty_tree, excludes):
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
        elif excludes.matches(path):
            work.left_excluded, leave = work.left_excluded + 1, True
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


def commit_work(repo, env, work, branch, worktree=None):
    """Up to two commits, in the shape of a stash: HEAD <- staged <- everything. A restore recovers which was which."""
    commit_env = dict(env, **IDENTITY)
    lines = ["Branch: %s" % (branch or "(detached)"), "Base: %s" % (work.head or "(none)")]
    if worktree:
        lines.append("Worktree: %s" % worktree)
    lines.append("Left-out-by-name: %d" % work.left_secret)
    lines.append("Left-out-by-size: %d" % work.left_big)
    lines.append("Left-out-by-exclude: %d" % work.left_excluded)
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


def stash_refs(repo, env, excludes):
    """Stash entries are uncommitted work too. One holding a secret-named path stays behind, and is counted. So does one
    built on a commit GitHub lacks that touches one: amend that commit away and the stash still carries it.
    One holding noise or excluded paths travels as a copy rebuilt without them (see rebuild_stash)."""
    if git(["rev-parse", "-q", "--verify", "refs/stash"], repo, env, check=False) is None:
        return {}, 0, 0
    out, left, dropped = {}, 0, 0
    entries = text(git(["log", "-g", "--format=%H", "refs/stash"], repo, env)).split()
    for n, sha in enumerate(entries):
        parents = text(git(["rev-list", "--parents", "-1", sha], repo, env)).split()[1:]
        names = nul_list(git(["diff-tree", "-r", "-z", "--name-only", parents[0], sha], repo, env))
        names += nul_list(git(["diff-tree", "-r", "-z", "--name-only", parents[0], parents[1]], repo, env))
        if len(parents) > 2:
            names += nul_list(git(["ls-tree", "-r", "-z", "--name-only", parents[2]], repo, env))
        if any(is_secret(p) for p in names) or secret_names_in_history(repo, env, [parents[0]]):
            left += 1
        else:
            out["refs/safety/stash/%d" % n], gone = rebuild_stash(repo, env, sha, parents, excludes)
            dropped += gone
    return out, left, dropped


def tree_entries(repo, env, tree):
    """{path: b"<mode> <id>"} for every blob and gitlink in a tree."""
    out = {}
    for entry in nul_list(git(["ls-tree", "-r", "-z", tree], repo, env)):
        meta, path = entry.split(b"\t", 1)  # "<mode> <type> <id>\t<path>"
        mode, _, obj = meta.split(b" ")
        out[path] = mode + b" " + obj
    return out


def filtered_tree(repo, env, tree, drop, reference=None):
    """The same tree with the paths `drop` names taken out, written into the temporary object folder; or the tree
    itself when nothing changes. With `reference` (the entries of the commit this tree will be compared against), a
    dropped path that the reference holds is set back to the reference's version instead of removed, so a tracked
    file nobody touched does not come back as a deletion."""
    reference = reference or {}
    keep, changed = [], 0
    for path, entry in tree_entries(repo, env, tree).items():
        if drop(path):
            if path in reference:
                changed += reference[path] != entry
                entry = reference[path]
            else:
                changed += 1
                continue
        keep.append(entry + b"\t" + path + b"\0")
    if not changed:
        return tree, 0
    if os.path.exists(env["GIT_INDEX_FILE"]):
        os.remove(env["GIT_INDEX_FILE"])
    if keep:
        git(["update-index", "-z", "--index-info"], repo, env, data=b"".join(keep))
    return text(git(["write-tree"], repo, env)), changed


def rebuild_stash(repo, env, sha, parents, excludes):
    """A stash is up to four commits: base <- index, base <- (untracked), and the stash itself on top of them. Each tree
    is rewritten without noise and excluded paths, into the temporary object folder, and the commits are made again
    over the new trees with their original messages and authors. The base is only rebuilt when no branch, tag or
    remote holds it any more, since then the bundle would carry it, node_modules and all; a base a branch still holds
    travels with that branch and stays as it is. Returns (the stash to bundle, how many paths were dropped)."""
    def drop(path):
        return is_noise(path) or excludes.matches(path)

    side = dict(env, GIT_INDEX_FILE=env["GIT_INDEX_FILE"] + ".stash")
    base, index_commit = parents[0], parents[1]
    untracked_commit = parents[2] if len(parents) > 2 else None
    orphaned_base = bool(text(git(["rev-list", "-1", base, "--not", "--branches", "--tags", "--remotes"], repo, env)))
    trees, dropped = {}, 0

    def tree_of(commit):
        return text(git(["rev-parse", commit + "^{tree}"], repo, env))

    trees[base] = tree_of(base)
    if orphaned_base:
        trees[base], gone = filtered_tree(repo, side, trees[base], drop)
        dropped += gone
    # What the stash will be compared against: the base as it travels. A dropped path it still holds goes back to it.
    reference = {path: entry for path, entry in tree_entries(repo, env, trees[base]).items() if drop(path)}
    for commit in [sha, index_commit]:
        trees[commit], gone = filtered_tree(repo, side, tree_of(commit), drop, reference)
        dropped += gone
    if untracked_commit:
        trees[untracked_commit], gone = filtered_tree(repo, side, tree_of(untracked_commit), drop)
        dropped += gone
    if not dropped:
        return sha, 0

    note = "\n\ngit-safety-backup: a copy, rebuilt without %d noise or excluded path(s). The original is untouched.\n"

    def again(commit, new_parents):
        who = text(git(["log", "-1", "--format=%an%x00%ae%x00%aI", commit], repo, env)).split("\0")
        message = git(["log", "-1", "--format=%B", commit], repo, env).rstrip(b"\n") + (note % dropped).encode()
        made = dict(env, **IDENTITY)
        made.update(GIT_AUTHOR_NAME=who[0], GIT_AUTHOR_EMAIL=who[1], GIT_AUTHOR_DATE=who[2])
        args = ["commit-tree", trees[commit], "-F", "-"]
        for parent in new_parents:
            args += ["-p", parent]
        return text(git(args, repo, made, data=message))

    new_base = base
    if trees[base] != tree_of(base):
        new_base = again(base, text(git(["rev-list", "--parents", "-1", base], repo, env)).split()[1:])
    new_index = index_commit
    if new_base != base or trees[index_commit] != tree_of(index_commit):
        new_index = again(index_commit, [new_base])
    new_parents = [new_base, new_index]
    if untracked_commit:
        new_untracked = untracked_commit
        if trees[untracked_commit] != tree_of(untracked_commit):
            new_untracked = again(untracked_commit, [])
        new_parents.append(new_untracked)
    return again(sha, new_parents), dropped


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


GIT_PATHS = ["index", "index.lock", "objects", "shallow", "rebase-merge", "rebase-apply", "MERGE_HEAD",
             "CHERRY_PICK_HEAD", "REVERT_HEAD", "BISECT_LOG"]


def git_paths(worktree):
    """Where this worktree keeps its index and its in-progress markers. Objects and shallow are shared with the main."""
    args = ["rev-parse", "--path-format=absolute"]
    for name in GIT_PATHS:
        args += ["--git-path", name]
    return dict(zip(GIT_PATHS, os.fsdecode(git(args, worktree)).splitlines()))


def busy(paths):
    """Why this worktree should be left alone for now, or None."""
    if os.path.exists(paths["index.lock"]):
        age = (datetime.datetime.now().timestamp() - os.path.getmtime(paths["index.lock"])) / 3600
        stale = " (it is %.0f hours old: if no git is running, it is stale and yours to remove)" % age if age >= 2 else ""
        return "index.lock" + stale
    for name in GIT_PATHS[4:]:
        if os.path.exists(paths[name]):
            return name + " in progress"
    return None


def back_up(repo, opts, skip, history_ok, excludes, state_dir):
    slug = slug_for(repo)
    urls = git(["config", "--get-regexp", r"^remote\..*\.url$"], repo, check=False) or b""
    if any(skip.matches_url(text(line).split(" ", 1)[-1]) for line in urls.splitlines()):
        return Result(repo, "skipped", slug)

    paths = git_paths(repo)
    why = busy(paths)
    if why:
        return Result(repo, "deferred", slug, note=why)

    temp = tempfile.mkdtemp(prefix="git-safety-backup.")
    try:
        return back_up_in(repo, slug, temp, paths, opts, skip, history_ok, excludes, state_dir)
    except Deferred as why:
        return Result(repo, "deferred", slug, note=str(why))
    except TooMuch as why:
        return Result(repo, "toobig", slug, note=str(why))
    finally:
        shutil.rmtree(temp, ignore_errors=True)


def capture_worktree(worktree, name, env, temp, opts, empty_tree, excludes):
    """Uncommitted work in one worktree, committed into the temporary object folder. Returns the Capture."""
    env = dict(env, GIT_INDEX_FILE=os.path.join(temp, "index-" + name))
    paths = git_paths(worktree)
    if os.path.exists(paths["index"]):
        shutil.copyfile(paths["index"], env["GIT_INDEX_FILE"])
    work = capture_work(worktree, env, opts, empty_tree, excludes)
    branch_raw = git(["symbolic-ref", "-q", "--short", "HEAD"], worktree, env, check=False)
    work.wip, work.staged = commit_work(worktree, env, work, text(branch_raw) if branch_raw else None,
                                        worktree=None if name == "main" else name)
    return work


def back_up_in(repo, slug, temp, paths, opts, skip, history_ok, excludes, state_dir):
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
    empty_tree = text(git(["hash-object", "-t", "tree", "/dev/null"], repo, env))

    # The main worktree first, then each linked worktree of the same repository, each with its own index and HEAD.
    notes = []
    works = {"main": capture_worktree(repo, "main", env, temp, opts, empty_tree, excludes)}
    for path, name in linked_worktrees(repo, env, skip):
        why = busy(git_paths(path))
        if not why:
            try:
                works[name] = capture_worktree(path, name, env, temp, opts, empty_tree, excludes)
                continue
            except (Deferred, TooMuch) as reason:
                why = str(reason)
        notes.append("worktree %s left for next run (%s)" % (name, why))
    work = works["main"]
    linked = [name for name in works if name != "main"]
    if linked:
        notes.append("with %d linked worktree(s): %s" % (len(linked), ", ".join(linked)))

    refs, remote_tips = unpushed_refs(repo, env)
    tips = list(refs.values())
    stashes, stash_left, stash_dropped = stash_refs(repo, env, excludes)
    left_secret = sum(w.left_secret for w in works.values())
    left_excluded = sum(w.left_excluded + w.left_noise for w in works.values())
    left_big = sum(w.left_big for w in works.values())
    if left_secret or stash_left:
        notes.append("left out by name: %d path(s), %d stash entr(ies)" % (left_secret, stash_left))
    if left_excluded or stash_dropped:
        notes.append("left out by the exclude list or as noise: %d path(s), %d in stash copies" % (left_excluded, stash_dropped))
    if left_big:
        notes.append("left out over %d MB: %d file(s)" % (opts.max_file_mb, left_big))
        log("WARN", "%s: %d changed file(s) over %d MB left out; commit them, ignore them, or raise --max-file-mb"
            % (slug, left_big, opts.max_file_mb))
    if any(w.unreadable for w in works.values()):
        notes.append("some files could not be read")
        log("WARN", "%s: some changed files could not be read and were left out" % slug)

    any_wip = any(w.wip for w in works.values())
    if not any_wip and not refs and not stashes:
        return Result(repo, "clean", slug, note="; ".join(notes))

    held = secret_names_in_history(repo, env, tips)
    if held and repo not in history_ok:
        return Result(repo, "held", slug, note="commits GitHub lacks touch %d secret-named path(s). Look, then "
                      "add this repository's path to history-ok.txt, or fix the history" % held)

    fingerprint_lines = sorted("%s %s" % pair for pair in list(refs.items()) + list(stashes.items()))
    fingerprint_lines += ["wip %s %s %s" % (work.head, work.tree, work.staged_tree)] if work.wip else []
    for name in linked:
        w = works[name]
        fingerprint_lines += ["wip@%s %s %s %s" % (name, w.head, w.tree, w.staged_tree)] if w.wip else []
    fingerprint_lines += ["encrypted"] if opts.encrypt else []
    fingerprint = hashlib.sha256("\n".join(fingerprint_lines).encode()).hexdigest()
    folder = os.path.join(opts.dest, slug)
    state_file = os.path.join(state_dir, slug + ".sha256")
    previous = open(state_file, encoding="utf-8").read().strip() if os.path.exists(state_file) else ""
    if previous == fingerprint and existing_bundles(folder):
        return Result(repo, "unchanged", slug)

    # Name everything the bundle should carry, in the shadow repository.
    updates = ["create refs/seen/%d %s" % (n, sha) for n, sha in enumerate(remote_tips)]
    wanted = dict(refs, **stashes)
    for name, w in works.items():
        where = "refs/safety/" if name == "main" else "refs/safety/worktrees/%s/" % name
        if w.wip:
            wanted[where + "wip"] = w.wip
        if w.staged:
            wanted[where + "wip-staged"] = w.staged
    updates += ["create %s %s" % (ref, sha) for ref, sha in wanted.items()]
    git(["--git-dir", shadow, "update-ref", "--stdin"], temp, data=("\n".join(updates) + "\n").encode())
    selection = ["--branches", "--tags", "--glob=refs/safety/*", "--not", "--glob=refs/seen/*"]

    # The last gate: nothing secret-named in the commits this tool itself made, whatever the code above believes.
    for w in works.values():
        if w.wip:
            made = ["diff-tree", "-r", "-z", "--name-only", w.head, w.wip] if w.head \
                else ["ls-tree", "-r", "-z", "--name-only", w.wip]
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
    suffix = ".bundle"
    if opts.encrypt:
        bundle, suffix = seal(bundle, opts.passphrase_file), ".bundle.enc"
        size = os.path.getsize(bundle)
    os.chmod(bundle, 0o600)
    try:
        place(bundle, folder, suffix)
        prune(folder, opts.keep)
    except PermissionError as err:
        raise Failed("cannot write to %s (%s). A background job may need Full Disk Access in System Settings"
                     % (folder, err.strerror))
    write_atomically(state_file, fingerprint + "\n")
    return Result(repo, "wrote", slug, size, "; ".join(notes))


def openssl(args, timeout=GIT_TIMEOUT):
    try:
        done = subprocess.run(OPENSSL + args, env=BASE_ENV, timeout=timeout, stdin=subprocess.DEVNULL,
                              stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
    except subprocess.TimeoutExpired:
        raise Failed("openssl took over %d seconds" % timeout)
    except OSError as err:
        raise Failed("openssl: %s" % err.strerror)
    if done.returncode != 0:
        last = done.stderr.decode("utf-8", "replace").strip().splitlines()
        raise Failed("openssl: %s" % (last[-1][:200] if last else "exit %d" % done.returncode))


def sha256_of(path):
    digest = hashlib.sha256()
    with open(path, "rb") as handle:
        for chunk in iter(lambda: handle.read(1 << 20), b""):
            digest.update(chunk)
    return digest.hexdigest()


def seal(bundle, passphrase_file):
    """The bundle, encrypted beside itself; opened again at once and compared, so a sealed file is known to open."""
    sealed, check = bundle + ".enc", bundle + ".check"
    openssl(["-in", bundle, "-out", sealed, "-pass", "file:" + passphrase_file])
    openssl(["-d", "-in", sealed, "-out", check, "-pass", "file:" + passphrase_file])
    if sha256_of(check) != sha256_of(bundle):
        raise Failed("the sealed bundle did not open to the same bytes; nothing written")
    os.remove(check)
    return sealed


def unseal(opts):
    """--decrypt: open a sealed bundle into the current folder, or --out. Never into iCloud Drive."""
    source = os.path.abspath(os.path.expanduser(opts.decrypt))
    if not os.path.isfile(source):
        print("git-safety-backup: %s is not a file" % source, file=sys.stderr)
        return 2
    name = os.path.basename(source)
    name = name[:-len(".enc")] if name.endswith(".enc") else name + ".bundle"
    target = os.path.abspath(os.path.expanduser(opts.out)) if opts.out else os.path.join(os.getcwd(), name)
    icloud = os.path.realpath(os.path.expanduser(ICLOUD_DRIVE))
    if os.path.realpath(os.path.dirname(target)).startswith(icloud):
        print("git-safety-backup: %s is inside iCloud Drive. Open the bundle somewhere else, so no plain copy syncs"
              % target, file=sys.stderr)
        return 2
    if os.path.exists(target):
        print("git-safety-backup: %s already exists; not overwriting it" % target, file=sys.stderr)
        return 2
    partial = target + ".partial"
    try:
        openssl(["-d", "-in", source, "-out", partial, "-pass", "file:" + opts.passphrase_file])
        with open(partial, "rb") as handle:
            head = handle.read(16)
        if not head.startswith(BUNDLE_MAGIC):
            raise Failed("that opened, but not to a git bundle: wrong passphrase, or not a sealed bundle")
    except Failed as why:
        if os.path.exists(partial):
            os.remove(partial)
        print("git-safety-backup: %s" % why, file=sys.stderr)
        return 1
    os.chmod(partial, 0o600)
    os.rename(partial, target)
    print("Opened %s\nNext, inside a fresh clone: git bundle verify %s" % (target, target))
    return 0


def passphrase_ready(path):
    """Why the passphrase file cannot be used, or None. It must exist, be a regular file, be readable by its owner
    only, and hold something."""
    try:
        st = os.lstat(path)
    except OSError:
        return "no passphrase file at %s. Run --init to make one" % path
    if not stat.S_ISREG(st.st_mode):
        return "%s is not a regular file" % path
    if st.st_mode & 0o077:
        return "%s is readable by others; chmod 600 it" % path
    if st.st_size == 0:
        return "%s is empty" % path
    return None


def write_atomically(path, content):
    partial = path + ".tmp"
    with open(partial, "w", encoding="utf-8") as handle:
        handle.write(content)
    os.replace(partial, path)


SKIP_TEMPLATE = """# git-safety-backup skip list. A repository named here is never opened and never reaches iCloud.
# One per line: a folder name (any part of the path, any case), or a ~/full/path.
# Read your clones and think: which ones should never leave this machine, or never reach this iCloud account?
"""
EXCLUDE_TEMPLATE = """# git-safety-backup exclude list: paths that stay out of the backup, inside every repository.
# One glob per line. A glob with a slash is matched against the whole path from the repository's root; one without
# is matched against each folder and file name along the path. `*` matches anything, `/` included. Case matters.
# node_modules, .venv, venv, __pycache__ and .DS_Store already stay out. Nothing here is told to git: these paths
# are not ignored, not deleted, only left out of the bundles and counted. Examples (remove the # to use one):
#logs/edge/*.jsonl      a desk's ever-growing logs, committed nightly anyway
#server.*.log           a server that writes a dated log beside its code
"""


def init(config_dir, skip_path, exclude_path, passphrase_path):
    os.makedirs(config_dir, mode=0o700, exist_ok=True)
    if os.path.exists(skip_path):
        print("%s already exists; left as it is." % skip_path)
    else:
        write_atomically(skip_path, SKIP_TEMPLATE)
        print("Wrote %s. Read it, add what should never reach iCloud, then run --dry-run." % skip_path)
    if os.path.exists(exclude_path):
        print("%s already exists; left as it is." % exclude_path)
    else:
        write_atomically(exclude_path, EXCLUDE_TEMPLATE)
        print("Wrote %s. Add globs for paths that should stay out of every bundle, such as big logs." % exclude_path)
    if os.path.exists(passphrase_path):
        print("%s already exists; left as it is, and never shown." % passphrase_path)
    else:
        passphrase = base64.b64encode(secrets.token_bytes(32)).decode("ascii")
        handle = os.open(passphrase_path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
        with os.fdopen(handle, "w", encoding="utf-8") as out:
            out.write(passphrase + "\n")
        os.chmod(passphrase_path, 0o600)
        print("Wrote %s (mode 600). This is its passphrase, shown once and never logged:\n\n    %s\n\n"
              "Put it in your password manager now. --encrypt seals every bundle with it, and a bundle that leaves "
              "iCloud, or a Mac that is lost, can only be opened with this line." % (passphrase_path, passphrase))
    return 0


def main():
    parser = argparse.ArgumentParser(add_help=True, description="See the head of this file.")
    parser.add_argument("--init", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--encrypt", action="store_true")
    parser.add_argument("--decrypt", metavar="FILE", default=None)
    parser.add_argument("--out", metavar="PATH", default=None)
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
    opts.passphrase_file = os.path.join(config_dir, "passphrase")
    if opts.init:
        return init(config_dir, skip_path, os.path.join(config_dir, "exclude.txt"), opts.passphrase_file)
    if opts.encrypt or opts.decrypt:
        why = passphrase_ready(opts.passphrase_file)
        if why is None and shutil.which("openssl") is None:
            why = "openssl is not on PATH"
        if why:
            print("git-safety-backup: %s" % why, file=sys.stderr)
            return 2
    if opts.decrypt:
        return unseal(opts)
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
    excludes = Excludes(os.path.join(config_dir, "exclude.txt"))
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
            result = back_up(repo, opts, skip, history_ok, excludes, state_dir)
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
