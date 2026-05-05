# AGENTS.md
> AI Agent Configuration — [Project Name]
> Read by: Claude Code, Cursor, GitHub Copilot, and other AI coding assistants.
> See `CLAUDE.md` for Claude Code–specific rules.

---

## Project Overview

[One paragraph describing what this project does, who it's for, and its current status.]

**Visibility:** [PUBLIC / PRIVATE]
**Primary builder:** [Auggie / Alfred / Fortuna / Human]

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Language | [e.g. TypeScript, Python, Solidity] |
| Framework | [e.g. React, Hardhat, FastMCP] |
| Runtime | [e.g. Node.js 20, Python 3.11] |
| Package manager | [e.g. npm, pip, uv] |
| Hosting | [e.g. GitHub Pages, local, Vercel] |

---

## Common Commands

```bash
# Install dependencies
[install command]

# Run dev / local server
[run command]

# Run tests
[test command]

# Build / compile
[build command]

# Lint / format
[lint command]
```

---

## Coding Standards

- [e.g. 2-space indent, single quotes, no trailing commas]
- [e.g. Solidity: follow OpenZeppelin patterns, NatSpec on all public functions]
- [e.g. Python: ruff for linting, type hints on all public functions]
- Keep functions small and single-purpose
- Prefer explicit over implicit

---

## Agent Boundaries

**Do:**
- Follow the task as scoped — don't expand scope unilaterally
- Ask before creating new directories or files outside the expected structure
- Commit after every meaningful change

**Don't:**
- Modify `.env`, secrets, or credential files
- Add dependencies without flagging them first
- Expand the feature scope beyond what was requested
- Auto-push to remote without confirmation

---

## Security Rules

These apply in every repo, always:

- Never read, display, or commit `.env` files, private keys, seed phrases, or credential files
- Never expose API keys, wallet addresses, or access tokens in committed files
- If a staged file contains sensitive data, warn before committing — stop and ask
- When creating example env files, use placeholder values only (e.g. `API_KEY=your_key_here`)
- Before installing any external dependency: audit `preinstall`/`postinstall` hooks, verify provenance, check for typosquatting

---

## Canonical References

- `CLAUDE.md` — Claude Code–specific configuration and session rules
- `README.md` — Human-readable project overview
- `PENDING-TASKS.md` or `tasks.md` — Active task tracking (if present)
- `specs/` — Detailed specs and workflow documents (if present)
