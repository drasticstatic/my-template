# CLAUDE.md — [Project Name]
### Claude Code CLI | [Agent Name and Role]

> **Instructions:** Fill in each section for your repo. Delete sections that don't apply.
> This file is loaded automatically by Claude Code CLI at session start.
> Keep it in the repo root. Add to `.gitignore` if you don't want it in public previews.

---

## Scope

[Describe what this repo is and what Claude's primary role is here.]

Agent roles (if using multiple agents):
- **[Agent 1]:** [Role and domain]
- **[Agent 2]:** [Role and domain]

---

## Security Rules (Non-Negotiable)

- **Never read, display, or reference `.env` files**
- **Never read private keys, seed phrases, wallet files, or mnemonic files**
- **Never read or expose API key files** regardless of filename
- **Never commit secrets** — warn and stop if staged
- If an example env file is needed, use placeholder values only (e.g. `API_KEY=your_key_here`)

---

## Context Rules

- [List any files Claude should read at session start]
- [List where memory or handoff files live]
- [Note any cross-repo privacy boundaries]

---

## File & Directory Rules

- [Naming conventions for files Claude creates]
- [Which dirs are private vs public-preview]
- [Commit frequency expectations]

---

## Workspace Notes

- Primary repo path: `~/[path/to/repo]`
- **Private dirs** (excluded from public preview): [list them]
- **Public preview repo:** [name] — synced via `.github/workflows/sync-public.yml`

---

## Skills Library

Skills live in `.claude/skills/`. Triggers are natural-language phrases.

| Skill | Trigger | Purpose |
|-------|---------|---------|
| `/[skill-name]` | "[trigger phrase]" | [what it does] |

---

## Canonical Reference Files

When these exist in this repo, they are the **source of truth** — do not duplicate their content in CLAUDE.md or memory files. Reference by path instead.

| File pattern | Purpose |
|---|---|
| `AGENTS.md` | Root-level config for all AI agents (Claude Code, Cursor, Copilot) — read this first |
| `AGENTS.override.md` | Temporary task-specific overrides — delete when done; fill-in template in this repo |
| `PENDING-TASKS.md` / `tasks.md` / `task-list.md` | Open and completed tasks — check before creating new tasks; update when tasks complete |
| `.claude/skills/` | Skill definitions for repeatable workflows — use skill triggers instead of re-explaining procedures |
| `specs/` | Detailed workflow specs — reference section numbers rather than copying content here |
| `AGENT-SYNC/AGENT_SYNC.md` | Current agent handoff state — read at session start (if using multi-agent pattern) |

**Pattern:** When skills and specs exist, follow them as canonical. CLAUDE.md and memory files hold identity, pointers, and short rules — not full procedure text.

---

## Agent-Specific Notes

**Before this repo is considered "shipped"**, run the checklist in this repo's
own `README.md` ("New Repo Checklist") — most importantly a real `LICENSE`
file in the public repo (not covered by the `drasticstatic/.github` fallback,
unlike `SECURITY.md`/`CONTRIBUTING.md`) and an accurate README License
section. See [`how-to-establish-cross_repo_CONTRIBUTORS_SECURITY_LICENSING.md`](https://github.com/drasticstatic/drasticstatic/blob/main/how-to-establish-cross_repo_CONTRIBUTORS_SECURITY_LICENSING.md)
for the full walkthrough. If you're an agent scaffolding a new repo from this
template, don't let this get silently skipped.

[Any other persistent instructions for Claude in this repo.]
