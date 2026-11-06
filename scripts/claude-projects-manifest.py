#!/usr/bin/env python3
"""claude-projects-manifest.py: one page that says what every folder in ~/.claude/projects is, and what moved.

    python3 -I scripts/claude-projects-manifest.py            # writes ~/.claude/projects/MANIFEST-LOG.md
    python3 -I scripts/claude-projects-manifest.py --print    # prints the table, writes nothing
    python3 -I scripts/claude-projects-manifest.py --check    # exit 1 on an orphan, or an old-path folder Moves does not list
    sh scripts/claude-projects-manifest.selftest.sh           # proves it, the session-start hook and the zsh guard

Claude Code files each session under ~/.claude/projects/<the folder the session started in, every character but a letter
or a digit turned into "-">, and auto memory under the same kind of name for the git repository's root. Rename a folder
and the old name stays behind. This script reads, for each project folder, only the "cwd" field and the timestamps in the
first lines of each session file: it never prints message content and never edits, moves or deletes a session file.

MANIFEST-LOG.md has three parts. The table between the "generated" markers is rewritten on every run. The Moves section is
kept as it is: people, and rename-local-repo.py --apply, add one line there per move. The explainer and the house rules
are written once, when the file is first made, and are then the reader's to edit.

Project folders whose name holds a word listed in <projects>/MANIFEST-PRIVATE.txt (one per line; a local file, never
committed) or given with --private are counted, never opened.
Exit: 0 fine, 1 --check found something, 2 usage or a manifest whose markers are missing.
"""
import argparse, datetime, json, os, re, sys

HOME = os.path.expanduser('~')
CONFIG = os.environ.get('CLAUDE_CONFIG_DIR') or os.path.join(HOME, '.claude')
GEN_BEGIN, GEN_END = '<!-- generated:begin (claude-projects-manifest.py rewrites this part) -->', '<!-- generated:end -->'
MOVES_END = '<!-- moves:end (new lines go above this one) -->'
ARCHIVE = '_archived-pre-move-sessions'
# Folders macOS guards with a privacy prompt: never listed, never looked inside.
GUARDED = ('Desktop', 'Documents', 'Downloads', 'Library', 'Pictures', 'Movies', 'Music')
PARENTS = ('', 'code', 'dappu', 'drasticstaticLabs', 'intent/workspaces')


def flatten(path):
    return re.sub(r'[^A-Za-z0-9]', '-', path)


def tilde(path):
    if path == HOME:
        return '~'
    return '~' + path[len(HOME):] if path.startswith(HOME + os.sep) else path


def guarded(path):
    return any(path == os.path.join(HOME, g) or path.startswith(os.path.join(HOME, g) + os.sep) for g in GUARDED) \
        or path.startswith('/Volumes')


def resolve(slug):
    """Real folders whose flattened path is slug, found by walking down from / along matching names only."""
    found = []

    def walk(path, depth):
        try:
            names = sorted(os.listdir(path))
        except OSError:
            return
        for n in names:
            p = os.path.join(path, n)
            f = flatten(p)
            if f == slug:
                if guarded(p) or os.path.isdir(p):
                    found.append(p)
            elif slug.startswith(f + '-') and depth < 16 and not guarded(p) and os.path.isdir(p):
                walk(p, depth + 1)
    walk('/', 0)
    return found


def first_fields(path, lines=200):
    """(cwd, first timestamp) from the first lines of one session file. Only those two fields are kept."""
    cwd = ts = None
    try:
        with open(path, encoding='utf-8', errors='replace') as fh:
            for i, line in enumerate(fh):
                if i >= lines or (cwd and ts):
                    break
                if '"cwd"' not in line and '"timestamp"' not in line:
                    continue
                try:
                    o = json.loads(line)
                except ValueError:
                    continue
                if not isinstance(o, dict):
                    continue
                if not cwd and isinstance(o.get('cwd'), str):
                    cwd = o['cwd']
                if not ts and isinstance(o.get('timestamp'), str):
                    ts = o['timestamp']
    except OSError:
        pass
    return cwd, ts


def is_parent(path):
    """A folder that holds repositories rather than being one: the fixed list, or a folder in ~ with repos inside."""
    if path in [os.path.join(HOME, p) if p else HOME for p in PARENTS]:
        return True
    if os.path.dirname(path) != HOME or guarded(path) or os.path.exists(os.path.join(path, '.git')):
        return False
    try:
        return any(os.path.exists(os.path.join(path, n, '.git')) for n in os.listdir(path))
    except OSError:
        return False


def cleanup_days(override):
    if override is not None:
        return override
    try:
        with open(os.path.join(CONFIG, 'settings.json'), encoding='utf-8') as fh:
            v = json.load(fh).get('cleanupPeriodDays')
        return int(v) if v else 30
    except (OSError, ValueError, TypeError, AttributeError):
        return 30


def survey(projects, private, days):
    rows = []
    dirs = []
    for name in sorted(os.listdir(projects)):
        d = os.path.join(projects, name)
        if not os.path.isdir(d) or name.startswith('.'):
            continue
        if name == ARCHIVE:
            for sub in sorted(os.listdir(d)):
                if os.path.isdir(os.path.join(d, sub)):
                    dirs.append((sub, os.path.join(d, sub), True))
        else:
            dirs.append((name, d, False))
    now = datetime.datetime.now()
    for slug, d, archived in dirs:
        sessions = sorted(f for f in os.listdir(d) if f.endswith('.jsonl'))
        mem = os.path.join(d, 'memory')
        memory = len([f for f in os.listdir(mem) if not f.startswith('.')]) if os.path.isdir(mem) else 0
        secret = any(p and p in slug for p in private)
        cwds, starts, mtimes = [], [], []
        for f in sessions:
            p = os.path.join(d, f)
            mtimes.append(os.path.getmtime(p))
            if not secret:
                cwd, ts = first_fields(p)
                cwds.append(cwd)
                if ts:
                    starts.append(ts[:10])
        here = [c for c in cwds if c and flatten(c) == slug]
        older = sorted({c for c in cwds if c and flatten(c) != slug})
        if here:
            folder = here[0]
        else:
            hits = resolve(slug)
            folder = hits[0] if len(hits) == 1 else (' or '.join(hits) if hits else None)
        if not folder:
            exists = 'no'
        elif guarded(folder):
            exists = 'not checked'
        elif ' or ' in folder:
            exists = 'several'
        else:
            exists = 'yes' if os.path.isdir(folder) else 'no'
        if archived:
            status = 'archived'
        elif exists == 'no':
            status = 'orphan'
        elif not sessions:
            status = 'memory-only'
        elif secret or here:
            status = 'live'
        else:
            status = 'moved-here'
        notes = []
        if secret:
            notes.append('private: transcripts not opened')
        if older:
            notes.append('recorded cwd ' + ', '.join(tilde(c) for c in older))
        if sum(1 for c in cwds if c is None) and not secret:
            notes.append(f'{sum(1 for c in cwds if c is None)} session(s) name no cwd')
        if folder and exists == 'yes' and is_parent(folder):
            notes.append('a parent folder')
        ages_out = None
        if mtimes and not archived:
            ages_out = datetime.datetime.fromtimestamp(min(mtimes)) + datetime.timedelta(days=days)
        prints = memory_print(mem) if memory else None
        rows.append(dict(slug=slug, prints=prints, folder=folder, exists=exists, sessions=len(sessions), newest=max(starts) if starts else '',
                         last=datetime.datetime.fromtimestamp(max(mtimes)).strftime('%Y-%m-%d') if mtimes else '',
                         memory=memory, status=status, notes=notes, older=older, ages_out=ages_out,
                         soon=bool(ages_out and ages_out - now < datetime.timedelta(days=7))))
    for r in rows:
        twins = [o['slug'] for o in rows if o is not r and r['prints'] and o['prints'] == r['prints']]
        if twins:
            r['notes'].append('memory identical to ' + ', '.join('`' + t + '`' for t in twins))
    return rows


def memory_print(mem):
    """A fingerprint of a memory folder (names and contents), to spot a stale copy. Nothing is printed from it."""
    import hashlib
    h = hashlib.sha256()
    for f in sorted(os.listdir(mem)):
        p = os.path.join(mem, f)
        if f.startswith('.') or not os.path.isfile(p):
            continue
        h.update(f.encode() + b'\0')
        try:
            with open(p, 'rb') as fh:
                h.update(hashlib.sha256(fh.read()).digest())
        except OSError:
            h.update(b'?')
    return h.hexdigest()


def recent_parent_starts(projects, n=10):
    p = os.path.join(projects, 'SESSIONS-LOG.tsv')
    try:
        with open(p, encoding='utf-8', errors='replace') as fh:
            lines = [l.rstrip('\n').split('\t') for l in fh if l.strip() and not l.startswith('date\t')]
    except OSError:
        return None, []
    hits = [l for l in lines if len(l) >= 4 and is_parent(l[3])]
    return len(lines), hits[-n:]


def table(rows, days, projects):
    out = [f'*Generated {datetime.datetime.now():%Y-%m-%d %H:%M} by `my-template/scripts/claude-projects-manifest.py`. '
           f'Retention: `cleanupPeriodDays` = {days}.*', '',
           '| Project folder (slug) | Real folder | Exists | Sessions | Newest start | Last write | Memory files | Status | Notes |',
           '|---|---|---|---|---|---|---|---|---|']
    for r in rows:
        folder = tilde(r['folder']) if r['folder'] and ' or ' not in r['folder'] else (r['folder'] or 'not found')
        slug = ('`' + ARCHIVE + '/`<br>' if r['status'] == 'archived' else '') + '`' + r['slug'] + '`'
        out.append(f"| {slug} | `{folder}` | {r['exists']} | {r['sessions']} | {r['newest']} | {r['last']} | {r['memory']} | "
                   f"**{r['status']}** | {'; '.join(r['notes'])} |")
    counts = {}
    for r in rows:
        counts[r['status']] = counts.get(r['status'], 0) + 1
    out += ['', 'Totals: ' + ', '.join(f'{k} {v}' for k, v in sorted(counts.items())) + '.']
    soon = [r for r in rows if r['soon']]
    if soon:
        out += ['', f'**Ages out within a week** (Claude Code deletes a session file {days} days after its last write; memory is kept):']
        out += [f"- `{r['slug']}`: its oldest session file goes on or after {r['ages_out']:%Y-%m-%d}" for r in soon]
    total, hits = recent_parent_starts(projects)
    if total is not None:
        out += ['', f'**SESSIONS-LOG.tsv:** {total} starts logged; {len(hits)} of the latest started in a parent folder.']
        out += [f'- {h[0]} `{h[1][:8]}` in `{tilde(h[3])}`' for h in hits]
    return '\n'.join(out)


SEED = """# Claude projects: the manifest

What every folder in `~/.claude/projects/` is, where its real folder lives today, and what moved. The table is
generated; the Moves section is kept by hand and by `rename-local-repo.py`. Orphaned logs and their archive:
[ARCHIVE-LOG.md](ARCHIVE-LOG.md).

## Projects today

{GEN_BEGIN}
{GEN_END}

**Status:** *live*, its sessions ran in the folder the name says · *moved-here*, its sessions name an earlier path
(an earlier move carried them) · *memory-only*, memory and no sessions · *orphan*, the folder is gone · *archived*,
set aside in `_archived-pre-move-sessions/`, out of `/resume`'s way.

## Moves

Newest last. One line per move; `rename-local-repo.py --apply` adds its own.

- **2026-08-31**: the `~/ClaudeCodeCLI/` layout ended (`~/ClaudeCodeCLI/trading-assistant` and its sibling became
  `~/code/...`). Archived; see ARCHIVE-LOG.md.
- **2026-09-22 to 09-29**: `~/pir`, `~/O-R-G`, `~/the-holy-earth-foundation` and siblings moved under `~/code/`;
  sessions still running at the move kept writing to their old names until a crash on 09-27. Orphaned logs archived in
  `_archived-pre-move-sessions/`: the full table, and the dead-end `littlebird-ambassador` names, are in
  [ARCHIVE-LOG.md](ARCHIVE-LOG.md).
- **2026-11-05 to 11-06, copies**: seven archived sessions were **copied, not moved**, into live project folders so
  `/resume` lists them; the archive keeps its own copies. `a50cbbbe` into
  `-Users-christopherwilson-littlebirds-git-home-littlebird-ambassador`; `2a994432` and `b4c8994d` into the THEF lab's
  david-amaringo project (today `-Users-christopherwilson-drasticstaticLabs-the-holy-earth-foundation-lab-david-amaringo`);
  `131c9ac9`, `5fbaab04`, `20a10a7b` and `d2dbb76b` into its iamoneself project (today
  `-Users-christopherwilson-drasticstaticLabs-the-holy-earth-foundation-lab-iamoneself`). Their recorded `cwd` names
  the path of their day, so the table shows those folders as moved-here.
- **2026-11-06, before 01:50**: seven of eight renames (SOP-IT-006, worked example one), each with its Claude project
  folders: `~/taylordwraps-org` to `~/taylordwraps` (an organisation folder; no project folder) · `~/code/psanctuary` to
  `~/code/psanctuary-lab` · `~/code/psanctuarychurch` to `~/code/psanctuarychurch-lab` ·
  `~/code/the-holy-earth-foundation` to `~/code/the-holy-earth-foundation-lab` (vouched:
  `-Users-christopherwilson-code-the-holy-earth-foundation-iamoneself`) · `~/code/O-R-G` to `~/code/O-R-G-lab`
  (vouched: `-Users-christopherwilson-code-O-R-G`) · `~/code/pir` to `~/code/pir-lab` · `~/code/findyourfeathers` to
  `~/code/findyourfeathers-lab`. `~/code/taylordwraps` waited on an open VS Code window.
- **2026-11-06 07:00**: the ten labs left `~/code` for `~/drasticstaticLabs` (SOP-IT-006, worked example two); project
  folders `-Users-christopherwilson-code-<old>` became `-Users-christopherwilson-drasticstaticLabs-<new>`:
  `findyourfeathers-lab` (no project folder) · `O-R-G-lab` to `-Users-christopherwilson-drasticstaticLabs-O-R-G-lab` ·
  `pir-lab` to `-Users-christopherwilson-drasticstaticLabs-pir-lab` · `psanctuary-lab` (none) ·
  `psanctuarychurch-lab`, a plain folder (none) · `the-holy-earth-foundation-lab` to
  `-Users-christopherwilson-drasticstaticLabs-the-holy-earth-foundation-lab`, with its `-david-amaringo` and
  `-iamoneself` children · `~/code/taylordwraps` to `taylordwraps-lab`
  (`-Users-christopherwilson-drasticstaticLabs-taylordwraps-lab`) · `wilson-lawn-ai-assist` to
  `wilson-lawn-ai-assist-lab` (none) · `RhebekahStar` to `RhebekahStar-lab` (none) · `dpnelson` to `dpnelson-lab`
  (`-Users-christopherwilson-drasticstaticLabs-dpnelson-lab`).
{MOVES_END}

## How sessions get filed

- **Transcripts** go to `~/.claude/projects/<start folder>/<session id>.jsonl`, where `<start folder>` is the full path
  of the folder `claude` started in, every character but a letter or a digit turned into `-` (a name longer than 200
  characters is cut and given a hash). So `~/code/pir/foo` and `~/code/pir-foo` flatten alike, and a session started in
  `~` or `~/code` is filed under `-Users-christopherwilson` or `-Users-christopherwilson-code`.
- **Auto memory** goes to `~/.claude/projects/<the git repository's root, flattened>/memory/`: every subfolder and
  worktree of one repository shares it, and outside a repository the start folder is used. `~/code`, `~/dappu` and
  `~/drasticstaticLabs` are repositories themselves, so a session in a plain folder inside one of them (such as
  `psanctuarychurch-lab`) reads and writes the parent's memory.
- **`MEMORY.md` loads at every start:** its first 200 lines or 25KB.
- **`/cd <folder>`** moves a running session to another folder, and Claude Code relocates it to that folder's project
  storage. That is the repair for a session started in the wrong place.
- **Retention.** Claude Code deletes a session file `cleanupPeriodDays` after its last write (30 by default); memory is
  kept. The table's Generated line says what this machine uses.
- Source: code.claude.com/docs/en/sessions, /memory and /claude-directory, read Nov 6, 2026. Claude Code may change
  how it files projects; re-read those pages if this ever seems wrong.

## Rules of the house

1. **Start a session inside the repository** (`cd ~/drasticstaticLabs/pir-lab && claude`), never in `~`, `~/code`,
   `~/dappu`, `~/drasticstaticLabs` or an organisation folder. Started in the wrong place? `/cd` to the repository.
2. **Move or rename a folder only with `my-template/scripts/rename-local-repo.py`**: the dry run first, then
   `--apply`. It carries the project folders along and adds its line to Moves above.
3. **Never edit or delete a transcript.** An orphan goes whole into `_archived-pre-move-sessions/`, with a row in
   ARCHIVE-LOG.md. To bring one back, copy it and write the copy here.
4. **After any move, run the manifest**, and `--check` before calling the work done.
5. **Mind the retention.** Claude Code deletes a session file once it is older than `cleanupPeriodDays` (30 unless
   `~/.claude/settings.json` says otherwise). Setting it longer is Christopher's call; until then, the table's
   "Ages out within a week" list is the warning.
"""


def write(projects, rows, days):
    path = os.path.join(projects, 'MANIFEST-LOG.md')
    gen = table(rows, days, projects)
    if os.path.exists(path):
        with open(path, encoding='utf-8') as fh:
            text = fh.read()
        if GEN_BEGIN not in text or GEN_END not in text or text.index(GEN_BEGIN) > text.index(GEN_END):
            print(f'refused: {path} has lost its generated markers; put them back rather than have it rewritten')
            return 2
        a, b = text.index(GEN_BEGIN) + len(GEN_BEGIN), text.index(GEN_END)
        text = text[:a] + '\n' + gen + '\n' + text[b:]
    else:
        text = SEED.replace('{GEN_BEGIN}', GEN_BEGIN).replace('{GEN_END}', GEN_END).replace('{MOVES_END}', MOVES_END)
        a = text.index(GEN_BEGIN) + len(GEN_BEGIN)
        text = text[:a] + '\n' + gen + '\n' + text[a + 1:]
    tmp = path + '.tmp'
    with open(tmp, 'w', encoding='utf-8') as fh:
        fh.write(text)
    os.replace(tmp, path)
    print(f'wrote {tilde(path)}: {len(rows)} project folders')
    return 0


def moves_text(projects):
    try:
        with open(os.path.join(projects, 'MANIFEST-LOG.md'), encoding='utf-8') as fh:
            text = fh.read()
    except OSError:
        return ''
    a = text.find('## Moves')
    b = text.find(MOVES_END)
    return text[a:b] if a >= 0 and b > a else ''


def check(projects, rows):
    moves = moves_text(projects)
    bad = []
    for r in rows:
        if r['status'] == 'orphan':
            bad.append(f"orphan: {r['slug']} (its folder is gone; {r['sessions']} sessions, {r['memory']} memory files)")
        elif r['status'] in ('moved-here', 'live') and r['older'] and r['slug'] not in moves:
            bad.append(f"not in Moves: {r['slug']} holds sessions from {', '.join(tilde(c) for c in r['older'])}")
    for r in rows:
        if r['soon']:
            print(f"warning: {r['slug']} has a session file that ages out on or after {r['ages_out']:%Y-%m-%d}")
    for b in bad:
        print(b)
    print(f'check: {len(bad)} problem(s)')
    return 1 if bad else 0


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--projects', default=os.path.join(CONFIG, 'projects'))
    ap.add_argument('--check', action='store_true')
    ap.add_argument('--print', dest='show', action='store_true')
    ap.add_argument('--private', action='append', default=[], help='a word; a project folder whose name holds it is not opened')
    ap.add_argument('--cleanup-days', type=int, default=None)
    a = ap.parse_args()
    if not os.path.isdir(a.projects):
        print(f'refused: {a.projects} is not a folder')
        return 2
    days = cleanup_days(a.cleanup_days)
    try:
        with open(os.path.join(a.projects, 'MANIFEST-PRIVATE.txt'), encoding='utf-8') as fh:
            a.private += [l.strip() for l in fh if l.strip() and not l.startswith('#')]
    except OSError:
        pass
    rows = survey(a.projects, a.private, days)
    if a.check:
        return check(a.projects, rows)
    if a.show:
        print(table(rows, days, a.projects))
        return 0
    return write(a.projects, rows, days)


if __name__ == '__main__':
    sys.exit(main())
