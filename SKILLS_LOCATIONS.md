# Where custom skills/prompts actually live, per tool

This fleet runs sessions across multiple AI coding CLIs (Claude Code, Augment/Auggie/Cosmos, and
occasionally OpenAI's Codex CLI). Each one looks for custom skill/prompt files in a different
place, with different format requirements. Written 2026-09-14 after a real fleet-wide mismatch was
found: `trading-assistant` and several other repos have skills as flat `.claude/skills/<name>.md`
files, which **Claude Code does not actually discover** — verified against
[Claude Code's own skills docs](https://code.claude.com/docs/en/skills.md), not assumed.

## Claude Code CLI

- **Location:** `.claude/skills/<skill-name>/SKILL.md` — a subdirectory per skill, fixed filename
  inside it. Also checks `~/.claude/skills/` for user-global skills.
- **Flat files are not discovered at all** — `.claude/skills/<name>.md` (no subdirectory) is
  silently invisible, no error. This is the exact mismatch this doc exists to prevent repeating.
- **Frontmatter:** YAML, `name` must match the directory name (lowercase-hyphenated), plus
  `description`.
- **Verify what's actually discovered** in a live session: run `/skill-doctor` (lists every skill
  Claude Code found, with usage/cost) rather than assuming from the file layout alone.

## Augment CLI / Auggie / Cosmos

- **Location:** the **same** path as Claude Code — `.claude/skills/<name>/SKILL.md` and
  `~/.claude/skills/` — confirmed via `docs.augmentcode.com/cli/skills`. This is a genuine
  convergence, not a coincidence to route around: one correctly-formatted skill directory serves
  both ecosystems with zero duplication.
- Same subdirectory-per-skill requirement as Claude Code. A flat file fails silently here too.

## Codex CLI (OpenAI)

Two different mechanisms exist — know which one applies before writing a new file:

- **Legacy custom prompts** (deprecated by OpenAI, still functional as of this writing):
  `~/.codex/prompts/*.md`, **flat files only** — Codex scans the top level of that directory, not
  subdirectories. YAML frontmatter (`description`, `argument-hint`, positional placeholders like
  `$1`/`$ARGUMENTS`). Don't build new skills this way; OpenAI's own docs point migrators toward
  Skills instead.
- **Skills (current, recommended):** `.agents/skills/<skill-name>/SKILL.md` — part of the emerging
  cross-tool **"Agent Skills Open Standard"**. Same shape as Claude Code's format: a subdirectory
  per skill, `SKILL.md` inside, YAML frontmatter requiring `name` + `description`, with optional
  `scripts/`, `references/`, `assets/` alongside it.
- **`AGENTS.md`** is a separate, complementary concept — always-on project context (like this
  fleet's own `AGENTS.md`/`CLAUDE.md` convention), not a skill/prompt mechanism. Global version:
  `~/.codex/AGENTS.md`.

## The portability takeaway

Claude Code, Augment/Cosmos, and Codex's current Skills format have converged on the same shape:
a subdirectory per skill, a `SKILL.md` file inside it, YAML frontmatter with exactly `name` +
`description` as the fields that travel across tools. **Stick to just those two frontmatter
fields** for anything meant to be portable — tool-specific extras (Codex's `argument-hint`,
whatever Claude Code or Cosmos might add later) don't carry over and will be ignored or may error
depending on the reading tool's strictness.

Practical fleet convention going forward: author a skill once at `.claude/skills/<name>/SKILL.md`
(covers Claude Code + Augment/Cosmos with zero extra work), and only add a
`.agents/skills/<name>/SKILL.md` copy if that specific repo is actually used from Codex CLI too —
don't pre-emptively duplicate into a directory tree nothing reads yet.

## Restructuring an existing flat-file skill

Don't do this blind if the skill backs a live slash command someone depends on (e.g. Fortuna's
`/import-trades`, `/trade-review` in `trading-assistant`) — the flat file might currently be
working through a completely different path (a `CLAUDE.md` instruction telling the agent to read
it directly, rather than native skill discovery), and moving it could either fix a real bug or
break something that was quietly working via that other path. Verify with `/skill-doctor` in a
live session first, in the actual repo, before moving anything.
