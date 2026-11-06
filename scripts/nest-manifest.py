#!/usr/bin/env python3
"""nest-manifest.py: one page per parent folder ("nest") that says which repositories live in it and how each one stands.

    python3 -I scripts/nest-manifest.py ~/dappu                  # writes ~/dappu/MANIFEST.md
    python3 -I scripts/nest-manifest.py ~/dappu --print          # prints the generated part, writes nothing
    python3 -I scripts/nest-manifest.py ~/dappu --check          # exit 1 when the workspace or .gitignore has fallen behind
    python3 -I scripts/nest-manifest.py ~/intent/workspaces --workspace ~/intent/intent.code-workspace --out ~/intent/MANIFEST.md
    sh scripts/nest-manifest.selftest.sh                         # proves it on fake folders in a temporary directory

A nest is a folder of repositories: a parent repository that gitignores its children (~/code, ~/dappu), or a plain folder
that only holds them (an organisation folder). For every child repository the table gives its folder, its origin
(owner/name), its visibility when `gh` can say, its branch, how far it is ahead of and behind its upstream (as of its
last fetch: nothing is fetched here), its last commit date, whether the nest's .code-workspace lists it, and, in a parent
repository, whether the parent's .gitignore ignores it. Repositories one level deeper are listed indented under their
folder. A plain folder that holds repositories (Intent's workspace folders do) counts its repositories as children.

Read-only on every child: only `git -C <child>` reads (rev-parse, remote, rev-list, log, check-ignore), with optional
locks off, so not even an index refresh is written. It writes MANIFEST.md (or --out) and its visibility cache, nothing else.

MANIFEST.md has two parts. The table between the markers is rewritten on every run. Everything else is written once,
when the file is first made, and is then the reader's to edit. One line there is read back: a line starting
"Outside the workspace on purpose:" names, in backticks, children (or a plain folder, for all the repositories in it)
that --check should not expect in the workspace.

Children whose path holds a word listed in ~/.claude/projects/MANIFEST-PRIVATE.txt (or --private-file, or given with
--private) are counted, never opened and never named.

Visibility comes from `gh repo list <owner>` (one call per owner), cached for a week in
~/.cache/nest-manifest/visibility.json. Offline, or with --no-gh, the cache answers and the rest shows "?".
Exit: 0 fine, 1 --check found something, 2 usage or a manifest whose markers are missing.
"""
import argparse, datetime, json, os, re, shutil, subprocess, sys

HOME = os.path.expanduser('~')
BEGIN = '<!-- nest-manifest:begin (nest-manifest.py rewrites this part) -->'
END = '<!-- nest-manifest:end -->'
ON_PURPOSE = 'Outside the workspace on purpose:'
CACHE = os.path.join(HOME, '.cache', 'nest-manifest', 'visibility.json')
PRIVATE_FILE = os.path.join(HOME, '.claude', 'projects', 'MANIFEST-PRIVATE.txt')
TTL = datetime.timedelta(days=7)
ENV = dict(os.environ, GIT_OPTIONAL_LOCKS='0', GIT_TERMINAL_PROMPT='0')


def tilde(p):
    return '~' + p[len(HOME):] if p == HOME or p.startswith(HOME + os.sep) else p


def git(repo, *args):
    try:
        r = subprocess.run(['git', '-C', repo, *args], capture_output=True, text=True, env=ENV, timeout=20)
    except (OSError, subprocess.TimeoutExpired):
        return None
    return r.stdout.strip() if r.returncode == 0 else None


def is_repo(p):
    return os.path.exists(os.path.join(p, '.git'))


def subdirs(p):
    try:
        names = sorted(os.listdir(p), key=str.lower)
    except OSError:
        return []
    return [n for n in names if n != '.git' and os.path.isdir(os.path.join(p, n)) and not os.path.islink(os.path.join(p, n))]


def origin_slug(url):
    if not url:
        return None
    m = re.match(r'^(?:https?://(?:[^@/]+@)?github\.com/|git@github\.com:|ssh://git@github\.com/)([^/]+)/(.+?)(?:\.git)?/?$', url)
    if m:
        return f'{m.group(1)}/{m.group(2)}'
    return re.sub(r'^[a-z+]+://([^@/]+@)?', '', url)  # not GitHub: host/path, credentials stripped


def load_jsonc(path):
    with open(path, encoding='utf-8') as fh:
        text = fh.read()
    try:
        return json.loads(text)
    except ValueError:
        pass
    # VS Code allows comments and trailing commas; strip them outside strings
    out, i, n, s = [], 0, len(text), None
    while i < n:
        c = text[i]
        if s:
            out.append(c)
            if c == '\\' and i + 1 < n:
                out.append(text[i + 1]); i += 1
            elif c == s:
                s = None
        elif c == '"':
            s = c; out.append(c)
        elif text.startswith('//', i):
            while i < n and text[i] != '\n':
                i += 1
            continue
        elif text.startswith('/*', i):
            j = text.find('*/', i + 2); i = n if j < 0 else j + 2
            continue
        else:
            out.append(c)
        i += 1
    return json.loads(re.sub(r',(\s*[}\]])', r'\1', ''.join(out)))


class Vis:
    """owner/name -> visibility, from a week-old-at-most cache and `gh repo list <owner>`."""

    def __init__(self, path, use_gh):
        self.path, self.dirty = path, False
        self.online = use_gh and shutil.which('gh') is not None
        try:
            with open(path, encoding='utf-8') as fh:
                self.data = json.load(fh)
        except (OSError, ValueError):
            self.data = {}
        self.data.setdefault('owners', {}); self.data.setdefault('repos', {})

    def _fresh(self, owner):
        t = self.data['owners'].get(owner)
        try:
            return t and datetime.datetime.now(datetime.timezone.utc) - datetime.datetime.fromisoformat(t) < TTL
        except ValueError:
            return False

    def _gh(self, *args):
        if not self.online:
            return None
        try:
            r = subprocess.run(['gh', *args], capture_output=True, text=True, timeout=30)
        except (OSError, subprocess.TimeoutExpired):
            self.online = False
            return None
        if r.returncode != 0:
            if re.search(r'(?i)could not resolve|connect|timeout|network|auth', r.stderr):
                self.online = False
            return None
        return r.stdout

    def get(self, slug):
        if not slug or '/' not in slug or slug.count('/') != 1:
            return '?'
        key = slug.lower(); owner = key.split('/')[0]
        if not self._fresh(owner) and self.online:
            out = self._gh('repo', 'list', owner, '--limit', '1000', '--json', 'nameWithOwner,visibility')
            if out is not None:
                for r in json.loads(out or '[]'):
                    self.data['repos'][r['nameWithOwner'].lower()] = r['visibility'].lower()
                self.data['owners'][owner] = datetime.datetime.now(datetime.timezone.utc).isoformat(timespec='seconds')
                self.dirty = True
        if key not in self.data['repos'] and self.online:
            out = self._gh('repo', 'view', slug, '--json', 'visibility', '-q', '.visibility')
            if out:
                self.data['repos'][key] = out.strip().lower(); self.dirty = True
        return self.data['repos'].get(key, '?')

    def save(self):
        if not self.dirty:
            return
        try:
            os.makedirs(os.path.dirname(self.path), exist_ok=True)
            tmp = self.path + '.tmp'
            with open(tmp, 'w', encoding='utf-8') as fh:
                json.dump(self.data, fh, indent=1, sort_keys=True)
            os.replace(tmp, self.path)
        except OSError:
            pass


def repo_info(path, vis):
    branch = git(path, 'symbolic-ref', '--short', '-q', 'HEAD')
    if branch is None:
        sha = git(path, 'rev-parse', '--short', 'HEAD')
        branch = f'detached @ {sha}' if sha else '?'
    slug = origin_slug(git(path, 'remote', 'get-url', 'origin'))
    counts = git(path, 'rev-list', '--left-right', '--count', 'HEAD...@{upstream}')
    if counts and len(counts.split()) == 2:
        a, b = counts.split(); ab = f'{a} / {b}'
    else:
        ab = 'no upstream'
    return {'origin': slug or 'no origin', 'vis': vis.get(slug) if slug else '—', 'branch': branch, 'ab': ab,
            'last': git(path, 'log', '-1', '--format=%cs') or 'no commits'}


def ignored(repo, rel):
    """True when repo's ignore rules cover rel (a folder inside it)."""
    return subprocess.run(['git', '-C', repo, 'check-ignore', '-q', '--no-index', rel.rstrip('/') + '/'],
                          capture_output=True, env=ENV).returncode == 0


def workspace_entries(ws):
    d = load_jsonc(ws)
    base = os.path.dirname(os.path.abspath(ws))
    return [os.path.normpath(os.path.join(base, os.path.expanduser(f.get('path', '')))) for f in d.get('folders', [])
            if isinstance(f, dict) and f.get('path') is not None]


def on_purpose(text):
    names = set()
    for line in text.splitlines():
        if line.strip().startswith(ON_PURPOSE):
            names.update(re.findall(r'`([^`]+)`', line))
    return names


def survey(nest, ws, private_words, purpose, vis):
    nest = os.path.abspath(nest)
    parent_repo = is_repo(nest)
    ws_paths = set()
    problems, members, others, privates = [], [], [], []
    if ws and os.path.exists(ws):
        try:
            entries = workspace_entries(ws)
        except (OSError, ValueError) as e:
            problems.append(f'{tilde(ws)} does not parse as JSON ({e})'); entries = []
        for p in entries:
            ws_paths.add(os.path.realpath(p))
            if not os.path.isdir(p):
                problems.append(f'the workspace names a folder that is missing: `{tilde(p)}`')
    else:
        problems.append(f'no workspace file ({tilde(ws) if ws else "none given"})')

    root = os.path.realpath(nest)

    def private(rel):
        low = rel.lower()
        return any(w and w in low for w in private_words)

    def member(rel):
        full = os.path.join(nest, rel)
        if private(rel):
            ign = parent_repo and ignored(nest, rel)
            privates.append(ign)
            if parent_repo and not ign:
                problems.append('a private child is not ignored by the parent (see the private count below)')
            return
        row = {'rel': rel, 'nested': [], **repo_info(full, vis)}
        real = os.path.realpath(full)
        via = [w for w in ws_paths if real.startswith(w + os.sep) and w.startswith(root + os.sep)]  # a folder above it, below the nest
        row['ws'] = ('yes' if real in ws_paths else f'yes (via `{os.path.relpath(via[0], root)}`)' if via
                     else 'on purpose, no' if rel in purpose or rel.split('/')[0] in purpose else 'no')
        row['ign'] = ('yes' if ignored(nest, rel) else 'no') if parent_repo else '—'
        if row['ws'] == 'no' and ws and os.path.exists(ws):
            problems.append(f'`{rel}` is not in the workspace')
        if row['ign'] == 'no':
            problems.append(f'`{rel}` is not ignored by the parent repository')
        for g in subdirs(full):
            grel = f'{rel}/{g}'
            if private(grel):  # checked before anything is looked at inside it
                privates.append(None); continue
            if not is_repo(os.path.join(full, g)):
                continue
            sub = {'rel': grel, **repo_info(os.path.join(full, g), vis), 'ws': '—'}
            sub['ign'] = f"{'yes' if ignored(full, g) else 'no'} (by `{rel}`)"
            row['nested'].append(sub)
        members.append(row)

    for c in subdirs(nest):
        full = os.path.join(nest, c)
        if private(c):
            member(c); continue  # counted (and its ignore line checked), never opened
        if is_repo(full):
            member(c)
            continue
        inner = [g for g in subdirs(full) if private(f'{c}/{g}') or is_repo(os.path.join(full, g))]
        for g in inner:
            member(f'{c}/{g}')
        if not inner and not c.startswith('.'):
            others.append(c)
    return parent_repo, members, others, privates, problems


def render(nest, ws, parent_repo, members, others, privates, problems):
    today = datetime.date.today().isoformat()
    L = [f'_Generated {today} by `python3 -I ~/code/my-template/scripts/nest-manifest.py {tilde(nest)}`. '
         f'Ahead / behind is against each upstream as of its last fetch. Workspace: '
         f'{"`" + tilde(ws) + "`" if ws and os.path.exists(ws) else "none"}._', '',
         '| Folder | Repository | Visibility | Branch | Ahead / behind | Last commit | In workspace | Ignored by parent |',
         '|---|---|---|---|---|---|---|---|']
    cell = lambda s: str(s).replace('|', '\\|')
    for r in members:
        for x, lead in [(r, '')] + [(n, '↳ ') for n in r['nested']]:
            L.append(f"| {lead}`{cell(x['rel'])}` | {cell(x['origin'])} | {x['vis']} | {cell(x['branch'])} | {x['ab']} | "
                     f"{x['last']} | {x['ws']} | {x['ign']} |")
    L.append('')
    n = sum(1 + len(r['nested']) for r in members)
    L.append(f'**{len(members)} children** ({n} repositories with the nested ones).')
    if privates:
        tops = [p for p in privates if p is not None]
        note = f' (ignored by the parent: {sum(1 for p in tops if p)} of {len(tops)})' if parent_repo and tops else ''
        L.append(f'**Private:** {len(privates)} more, counted, never opened and not named here{note}.')
    if others:
        L.append('**Other folders (not repositories):** ' + ', '.join(f'`{o}`' for o in others) + '.')
    L.append('')
    if problems:
        L.append('**For `--check`:**')
        L += [f'- {p}' for p in problems]
    else:
        L.append('**For `--check`:** nothing found.')
    return '\n'.join(L)


SEED = """# {name}: what lives in this folder

{kind} Each child folder is its own git repository with its own remote; the table says how each one stands.
Rewrite the table with `python3 -I ~/code/my-template/scripts/nest-manifest.py {where}`; add `--check` to have it
say whether the workspace file and the .gitignore have kept up. Everything outside the markers is yours to edit.

{on_purpose} (none yet: name children here in backticks to tell `--check` they are left out of the workspace on purpose)

{BEGIN}
{gen}
{END}
"""


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('nest')
    ap.add_argument('--workspace', help='the .code-workspace file (default: <nest>/<nest name>.code-workspace)')
    ap.add_argument('--out', help='where MANIFEST.md goes (default: <nest>/MANIFEST.md)')
    ap.add_argument('--check', action='store_true')
    ap.add_argument('--print', dest='show', action='store_true')
    ap.add_argument('--private', action='append', default=[], help='a word; a child whose path holds it is not opened')
    ap.add_argument('--private-file', default=PRIVATE_FILE)
    ap.add_argument('--cache', default=CACHE)
    ap.add_argument('--no-gh', action='store_true', help='visibility from the cache only')
    a = ap.parse_args()
    nest = os.path.abspath(os.path.expanduser(a.nest.rstrip('/')) or '/')
    if not os.path.isdir(nest):
        print(f'refused: {a.nest} is not a folder'); return 2
    name = os.path.basename(nest)
    ws = os.path.abspath(os.path.expanduser(a.workspace)) if a.workspace else os.path.join(nest, f'{name}.code-workspace')
    out = os.path.abspath(os.path.expanduser(a.out)) if a.out else os.path.join(nest, 'MANIFEST.md')
    words = [w.lower() for w in a.private]
    try:
        with open(a.private_file, encoding='utf-8') as fh:
            words += [l.strip().lower() for l in fh if l.strip() and not l.lstrip().startswith('#')]
    except OSError:
        pass
    text = None
    if os.path.exists(out):
        with open(out, encoding='utf-8') as fh:
            text = fh.read()
        if BEGIN not in text or END not in text or text.index(BEGIN) > text.index(END):
            print(f'refused: {tilde(out)} has lost its markers; put them back rather than have it rewritten'); return 2
    purpose = on_purpose(text[:text.index(BEGIN)] + text[text.index(END):]) if text else set()
    vis = Vis(a.cache, not a.no_gh)
    parent_repo, members, others, privates, problems = survey(nest, ws, words, purpose, vis)
    vis.save()
    gen = render(nest, ws, parent_repo, members, others, privates, problems)
    if a.check:
        for p in problems:
            print(f'{tilde(nest)}: {p}')
        print(f'{tilde(nest)}: {"nothing found" if not problems else str(len(problems)) + " found"}')
        return 1 if problems else 0
    if a.show:
        print(gen); return 0
    if text is not None:
        i, j = text.index(BEGIN) + len(BEGIN), text.index(END)
        text = text[:i] + '\n' + gen + '\n' + text[j:]
    else:
        kind = ('This folder is a parent repository: it tracks its own few files and gitignores every child.' if parent_repo
                else 'This folder is a plain folder (not a repository) that holds repositories.')
        where = tilde(nest) + (f' --workspace {tilde(ws)} --out {tilde(out)}' if a.workspace or a.out else '')
        text = SEED.format(name=name, kind=kind, where=where, on_purpose=ON_PURPOSE, BEGIN=BEGIN, END=END, gen=gen)
    tmp = out + '.tmp'
    with open(tmp, 'w', encoding='utf-8') as fh:
        fh.write(text)
    os.replace(tmp, out)
    print(f'wrote {tilde(out)}: {len(members)} children, {len(problems)} for --check')
    return 0


if __name__ == '__main__':
    sys.exit(main())
