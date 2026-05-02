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

## Agent-Specific Notes

[Any other persistent instructions for Claude in this repo.]
