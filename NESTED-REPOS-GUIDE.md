# Nested-repos guide: lightweight parent + git-ignored children

A working pattern for grouping several independent git repos under one shared local directory,
without any of them tracking each other's content.

## <img src="assets/icons-phosphor/compass.svg" width="24" height="24" alt=""> TL;DR

1. <img src="assets/icons-phosphor/layers.svg" width="16" height="16" alt=""> **A parent folder can be a lightweight repository** that holds several full repositories side by side, each git-ignored by the parent. No submodules.
2. <img src="assets/icons-phosphor/building-2.svg" width="16" height="16" alt=""> **An organisation's clone lives at `~/<org>/<repository>` and that clone is canonical.** Labs explore under `~/code/<lab>/`.
3. <img src="assets/icons-phosphor/files.svg" width="16" height="16" alt=""> **A second clone under a lab is a spare.** It stays where it is, with a `WHERE-EVERYTHING-WENT.md` beside it. Nothing is deleted by a helper.
4. <img src="assets/icons-phosphor/map.svg" width="16" height="16" alt=""> **See the whole map:** `sh scripts/clone-map.sh` lists every repository on the machine and marks the duplicates and spares, without changing anything.

## The pattern

1. Pick a **parent directory** that will hold several related-but-independent repos side by side.
2. The parent directory is **itself a git repo** — but a *lightweight* one. It tracks only its own
   README and a pointer to this guide, nothing belonging to its children.
3. Each **child** is its own full repo — `git init`, own remote, own history, own privacy
   settings — that happens to live in a subdirectory of the parent's working tree.
4. The parent's `.gitignore` lists every child directory by name, so `git status`/`git add` in the
   parent never sees the children's files. A `.git` boundary already stops git's outer-repo
   tracking at each child's root; the `.gitignore` entry is belt-and-suspenders, and specifically
   prevents an accidental "gitlink" commit if someone runs `git add -A` carelessly at the parent
   level before a child has its own `.gitignore` entry in place.

## Why this instead of one combined repo, or submodules

- **Independent lifecycles.** Children get created, archived, made public/private, or handed to a
  different GitHub org on completely different timelines. One combined repo forces them to share a
  single history and a single privacy setting.
- **Independent audiences.** A coordination lane and a tooling lane have different reviewers,
  different sensitivity, different commit cadence. Splitting them means each repo's history stays
  legible for its own purpose instead of interleaving unrelated changes.
- **No submodule overhead.** Git submodules solve a related problem (pinning a child repo to a
  specific commit, versioned from the parent) but add real friction — `git submodule update --init`,
  detached-HEAD children, a `.gitmodules` file to keep in sync. This pattern doesn't need that:
  nothing here needs the parent to pin or version its children, so plain sibling directories plus
  `.gitignore` is simpler and sufficient.
- **No GitHub-side effect either way.** Nesting is purely a local, working-directory convenience.
  GitHub has no visibility into local directory structure — a repo nested three directories deep
  looks identical, from GitHub's side, to one cloned at the top level. This pattern buys
  organizational ergonomics on disk, nothing more, nothing less.

## Setting this up for a new parent

1. `git init` the parent directory (or reuse an existing repo, correcting it to this pattern if it
   was previously tracking child content directly).
2. Write a parent `README.md` that tables out each child, its GitHub repo, and its purpose.
3. Add each child directory name to the parent's `.gitignore`.
4. `git init` each child directly, `gh repo create <name> --private --source=. --remote=origin
   --push`.
5. Link back to this guide from the parent README.

## If a child directory is moving from somewhere it already lived (Claude Code session continuity)

Moving an existing repo's directory (e.g. `~/code/foo` → `~/some-parent/foo`) via plain `mv`
preserves its git history fine — `.git/` moves with it. What it *doesn't* preserve automatically is
Claude Code CLI's own session continuity: sessions are stored at
`~/.claude/projects/<encoded-cwd-path>/`, where the encoding replaces every non-alphanumeric
character with `-`. `claude --continue` and the session picker look up sessions by encoding the
*current* working directory — after a move, that's a different encoded name than the one holding
the repo's actual history, so old sessions become invisible from the new path (though
`claude --resume <session-id>` still finds them anywhere, since that looks up by ID across the
whole machine, not by directory).

**Fix:** `cp -R` (not `mv`, so nothing is destroyed if this turns out unnecessary) the old
`~/.claude/projects/<old-encoded-path>/` directory to a new one matching the new path's encoding.
This is a manual workaround, not an officially documented migration path — the documented one is
running `/cd <new-path>` *inside* a still-open session for that project, which isn't available for
sessions that already ended before the move. Skip this if the encoded path would exceed roughly 200
characters — Claude Code truncates and hashes long paths, and the hash won't match after a move.

## Where a clone lives: labs under `~/code`, organisation clones at `~/<org>/`

The pattern above is for a person's own work. A repository an organisation owns does not nest inside it.

| What it is | Where it lives | Example |
|---|---|---|
| A lab: a person's own working copy, on a personal account, drafts and all | `~/code/<lab>/` | `~/code/pir` |
| A clone of a repository an organisation owns | `~/<org>/<repository>`, the folder named exactly as the GitHub organisation | `~/psychedelicsinrecovery/reading-room` |

A lab never holds an organisation's clone, not even git-ignored. Why:

- **`grep` tells the truth.** `grep -r` over `~/<org>/` searches everything that organisation holds and nothing else.
  Searching a lab searches the drafts, without the organisation's published pages mixed in under the same names
  (a lab and its organisation each have a `proposals`).
- **One place to look.** "Where is that organisation's reading room?" has one answer, for a person and for a helper,
  and it is the same answer for every organisation.
- **The tools know the roots.** `scripts/sync-local.sh`, `scripts/agent-sync-health.py` and `scripts/clone-map.sh` walk `~/code`, `~/dappu` and
  every `~/<org>/` by default. A new organisation's folder gets added to each default the day it is created.

**Moving a clone home.** Check first that its remote is the organisation's and that it has nothing uncommitted, unpushed or
stashed; skip it if the destination exists. Plain `mv` is enough, since `.git/` travels with it. Keep the name in the lab's
`.gitignore` with a comment saying where the clone went, so a stray clone there can never be tracked. The session-continuity
note above applies if anyone ran Claude Code from inside the old path.

## <img src="assets/icons-phosphor/building-2.svg" width="24" height="24" alt=""> The organisation clone is canonical

When the same repository is cloned twice on one machine, one of the two is the one to work in, and it is always the
organisation's. The rule in one table:

| | Where | What it is for |
|---|---|---|
| <img src="assets/icons-phosphor/landmark.svg" width="16" height="16" alt=""> **Organisation clone** | `~/<org>/<repository>` | The canonical copy. Edit here, commit here, push from here. |
| <img src="assets/icons-phosphor/flask-conical.svg" width="16" height="16" alt=""> **Lab** | `~/code/<lab>/` | A person's own exploring: drafts, experiments, a lightweight parent with its own children. |
| <img src="assets/icons-phosphor/files.svg" width="16" height="16" alt=""> **Spare** | A second clone of an organisation repository found under a lab | Left in place, accounted for, not worked in. |

The organisation folders on this machine, each named exactly as the GitHub organisation: `~/theholyearthfoundation`,
`~/psychedelicsinrecovery`, `~/Octagon-Religious-Research-Group-ORG`, `~/psanctuary`, `~/psanctuarychurch`, `~/taylordwraps-org`
and `~/WILSONSLAWNMAINTENANCE`. Everything else a person clones for themselves goes under a lab in `~/code/<lab>/`
(coursework and the like have their own homes, such as `~/dappu`, and Intent keeps its workspaces under `~/intent`).

**What a spare is, and what happens to it.** A spare is a second clone of a repository an organisation owns, sitting
under a lab because that is where it was cloned before the organisation had a folder of its own. It is not wrong, and
it is not removed. The lab gets a `WHERE-EVERYTHING-WENT.md` beside the spare that says, in a short table, what moved
where and what stayed, and that the copy here is the spare and the organisation's is the one to use. The spare was
checked against the canonical clone the day the note was written (same remote, same HEAD, nothing unpushed), and the
note says so. Three such notes exist today, in `~/code/psanctuarychurch` (two spares: `proposals` and the
`psanctuarychurch.github.io` site, the second on its own branch), `~/code/pir` (one: `changelog-astro`) and
`~/code/the-holy-earth-foundation` (one: `changelog-astro`). Each ends the same way: *a person can remove these once
sure of them; no helper will.*

**Nothing is deleted by a helper.** This is the rule under the rule. A helper (a Claude Code session, Littlebird, any
agent) may move a clone home, write the note, add the git-ignore line and report what it found. It never runs `rm`,
`git rm` or anything that empties a folder, however clean the spare looks: a clean tree says nothing about a stash, a
reflog, a branch that was never pushed, or a session someone means to resume from that path. The person who owns the
machine decides, with the note in front of them, and the spare costs nothing while they wait.

**Seeing the map.** `sh scripts/clone-map.sh` walks every root (`~/code`, `~/dappu`, `~/code-forked`, `~/intent`,
`~/littlebirds-git-home` and each `~/<org>/`) and prints one line per repository: its path, origin URL, branch, how
many files are changed locally and how many commits it is ahead of its upstream. Two clones of the same origin are
both marked `DUPLICATE`; the one under a lab, when the organisation has its own, is also `SPARE`, and `NOTED` when the
note sits beside it. `--duplicates` shows only those rows and `--json` gives the same rows to a script. It reads and
never writes: no fetch, no pull, no lock file, nothing removed. The sweep that *does* change clones, `sync-local.sh`,
pulls each one that is behind and still never deletes or pushes ([`scripts/README.md`](./scripts/README.md)).

## Worked examples (private, real-world detail lives there, not here)

This guide stays generic and public-safe on purpose — real founder names, org details, and
repo-specific reasoning belong in each parent repo's own README, not duplicated here where they'd
drift. If you have access to see them, these repos are real, in-production instances of this
pattern, each with its own README explaining the specific reasoning that led to it:

- `pir` — a coordination repo, WordPress tooling, and backups as separate children, plus a
  pre-existing legacy client repo that predated the pattern.
- `Psanctuary` — same shape, deliberately not over-built beyond the parent itself yet.
- `littlebirds-home` — two related-but-distinct repos (a private continuity store and a
  public-facing sibling) kept together under one parent name without either living inside the
  other's git history.

If you're building your own fleet and want to see this pattern (or the fleet's other conventions —
commit attribution, `AGENT-SYNC-<name>` coordination repos, skill-file locations) actually working
end to end, ask whoever granted you access to this template for a pointer into one of the private
instances above — the pattern is the same regardless of which one you look at.
