# Nested-repos guide: lightweight parent + git-ignored children

A working pattern for grouping several independent git repos under one shared local directory,
without any of them tracking each other's content.

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
