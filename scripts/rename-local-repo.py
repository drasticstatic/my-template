#!/usr/bin/env python3
"""rename-local-repo.py: rename or move a local folder of repositories without orphaning what is filed under its path.

    python3 -I scripts/rename-local-repo.py OLD NEW            # a dry run: says what would move, changes nothing
    python3 -I scripts/rename-local-repo.py OLD NEW --apply    # does it

Claude Code files each project's sessions and saved memory under ~/.claude/projects/<the folder's path, flattened>. Rename a
folder and Claude treats it as a new project: /resume stops listing the old sessions and the memory stops loading. A parent's
rename changes the path of everything inside it. See SOP-IT-006.

The flattening turns every character but a letter or a digit into "-", so ~/code/pir/foo and ~/code/pir-foo flatten alike. A name
match alone would move the wrong history, so each candidate is confirmed against the "cwd" recorded inside its own session files.
A candidate that cannot be confirmed is left where it is and named. Transcripts are moved whole and never edited.

It refuses to run while a process is working inside OLD. It repairs linked git worktrees and reports every file it knows of that
still names the old path (launchd agents, Claude settings, fleet scripts), which a person or a session then updates.
Nothing is deleted. Exit: 0 fine, 1 refused, 2 usage.
"""
import argparse, json, os, re, shutil, subprocess, sys

HOME = os.path.expanduser('~')


def flatten(path):
    return re.sub(r'[^A-Za-z0-9]', '-', path)


def session_cwd(project_dir):
    """The working folder recorded in this project's newest session file that names one, or None."""
    try:
        files = [f for f in os.listdir(project_dir) if f.endswith('.jsonl')]
    except OSError:
        return None
    files.sort(key=lambda f: os.path.getmtime(os.path.join(project_dir, f)), reverse=True)
    for f in files[:20]:
        try:
            with open(os.path.join(project_dir, f), encoding='utf-8', errors='replace') as fh:
                for i, line in enumerate(fh):
                    if i > 200:
                        break
                    if '"cwd"' not in line:
                        continue
                    try:
                        cwd = json.loads(line).get('cwd')
                    except ValueError:
                        continue
                    if cwd:
                        return cwd
        except OSError:
            continue
    return None


def project_moves(old, new, projects, adopt=()):
    """[(from dir, to dir)] confirmed, and [(dir, why)] left alone. adopt names folders a person has looked at and vouches for."""
    moves, unsure = [], []
    if not os.path.isdir(projects):
        return moves, unsure
    base = flatten(old)
    for name in sorted(os.listdir(projects)):
        if name != base and not name.startswith(base + '-'):
            continue
        d = os.path.join(projects, name)
        if not os.path.isdir(d):
            continue
        cwd = session_cwd(d)
        if name in adopt:
            moves.append((d, os.path.join(projects, flatten(new) + name[len(base):])))
        elif cwd is None:
            unsure.append((d, 'no session file names a folder, so it cannot be confirmed'))
        elif cwd == old or cwd.startswith(old + os.sep):
            # the directory's own path, not the session's, decides the suffix: sessions may sit in a subfolder
            suffix = name[len(base):]
            moves.append((d, os.path.join(projects, flatten(new) + suffix)))
        else:
            unsure.append((d, f'its sessions ran in {cwd}, which is not inside this folder: a name collision'))
    return moves, unsure


def busy(old):
    """Processes with a working directory inside old, by pid and command."""
    try:
        out = subprocess.run(['lsof', '-a', '-d', 'cwd', '-Fpcn'], capture_output=True, text=True, timeout=60).stdout
    except (OSError, subprocess.TimeoutExpired):
        return ['(lsof did not answer, so this could not be checked)']
    found, pid, cmd = [], '', ''
    for line in out.splitlines():
        if line.startswith('p'):
            pid = line[1:]
        elif line.startswith('c'):
            cmd = line[1:]
        elif line.startswith('n') and (line[1:] == old or line[1:].startswith(old + os.sep)):
            found.append(f'{pid} {cmd} in {line[1:]}')
    return found


def references(old, extra):
    """Known places that hard-code a path, which a rename leaves stale."""
    roots = [os.path.join(HOME, 'Library/LaunchAgents'), os.path.join(HOME, '.claude/settings.json'),
             os.path.join(HOME, '.config/git-safety-backup')] + list(extra)
    hits = []
    pat = re.compile(re.escape(old) + r'(?![A-Za-z0-9_-])')
    short = re.compile(re.escape('~' + old[len(HOME):]) + r'(?![A-Za-z0-9_-])') if old.startswith(HOME) else None
    for r in roots:
        paths = [r] if os.path.isfile(r) else [os.path.join(dp, f) for dp, dn, fs in os.walk(r) for f in fs
                                                 if not {'.git', 'node_modules', '__pycache__'} & set(dp.split(os.sep)) and os.path.basename(f) != 'rename-local-repo.py']
        for p in paths:
            try:
                if os.path.getsize(p) > 2_000_000:
                    continue
                s = open(p, encoding='utf-8', errors='ignore').read()
            except OSError:
                continue
            if pat.search(s) or (short and short.search(s)):
                hits.append(p)
    return hits


def linked_worktrees(new):
    """Repair every repository inside new whose linked worktrees recorded the old path."""
    repaired = []
    for dp, dn, fs in os.walk(new):
        dn[:] = [d for d in dn if d != 'node_modules']
        if '.git' in dn or '.git' in fs:
            r = subprocess.run(['git', '-C', dp, 'worktree', 'repair'], capture_output=True, text=True)
            if r.stdout.strip():
                repaired.append(dp)
            if '.git' in dn:
                dn.remove('.git')
    return repaired


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('old')
    ap.add_argument('new')
    ap.add_argument('--apply', action='store_true')
    ap.add_argument('--projects', default=os.path.join(HOME, '.claude/projects'))
    ap.add_argument('--allow-idle-shells', action='store_true', help='do not count a shell sitting idle in the folder: macOS keeps it working through the move, and it still shows the old path')
    ap.add_argument('--adopt', action='append', default=[], help='a project folder name to move though its sessions name another path, because you checked it (an earlier move left it so)')
    ap.add_argument('--ref', action='append', default=[], help='another file or folder to look for the old path in')
    a = ap.parse_args()
    old, new = os.path.abspath(os.path.expanduser(a.old)), os.path.abspath(os.path.expanduser(a.new))
    if not os.path.isdir(old):
        print(f'refused: {old} is not a folder'); return 1
    if os.path.exists(new):
        print(f'refused: {new} already exists'); return 1
    moves, unsure = project_moves(old, new, a.projects, a.adopt)
    who = busy(old)
    if a.allow_idle_shells:
        who = [w for w in who if w.split()[1].lstrip('-') not in ('zsh', 'bash', 'sh')]
    refs = references(old, a.ref)
    print(f"{'APPLY' if a.apply else 'DRY RUN'}: {old} -> {new}")
    print(f'  Claude project folders to move with it: {len(moves)}')
    for f, t in moves:
        print(f'    {os.path.basename(f)} -> {os.path.basename(t)}')
    for d, why in unsure:
        print(f'  LEFT ALONE {os.path.basename(d)}: {why}')
    for t in [t for _, t in moves if os.path.exists(t)]:
        print(f'  refused: {t} already exists'); return 1
    if who:
        print('  working inside it right now:')
        for w in who:
            print(f'    {w}')
    print(f'  files still naming the old path: {len(refs)}')
    for p in refs:
        print(f'    {p}')
    if not a.apply:
        print('  nothing changed; add --apply when nothing is working inside it')
        return 0
    if who:
        print('refused: close those first'); return 1
    os.makedirs(os.path.dirname(new), exist_ok=True)
    shutil.move(old, new)
    for f, t in moves:
        shutil.move(f, t)
    repaired = linked_worktrees(new)
    print(f'  moved. Worktrees repaired in {len(repaired)} repositories. Update the files named above, then open one moved project and run /resume.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
