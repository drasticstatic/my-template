# AGENTS.md
> AI Agent Configuration — [Project Name]
> Read by: Claude Code, Cursor, GitHub Copilot, Codex, Windsurf, Devin, OpenCode, and other AI coding assistants.
> See `CLAUDE.md` for Claude Code–specific rules.

---

## About This Standard

`AGENTS.md` is an open, markdown-based standard that acts as a **README for AI agents** — providing build steps, conventions, and constraints that differ from human-centric docs. It reduces hallucination and inconsistent behavior by giving every AI tool a single source of truth.

### Supported Environments

| Tool | Behavior |
|------|----------|
| **Claude Code** | Layers with `CLAUDE.md` — AGENTS.md provides shared cross-runtime rules |
| **Cursor** | Recognizes AGENTS.md for project context and constraints |
| **VS Code (Copilot)** | Auto-detects root AGENTS.md, applies to all chat requests |
| **Codex** | Reads AGENTS.md (and AGENTS.override.md) to build an instruction chain |
| **Windsurf / Devin** | Compatible with the standard |
| **OpenCode** | Terminal agent that reads AGENTS.md for tooling instructions |

### Precedence Model

Agents search from the **working file up to the project root**, using the nearest file found:

```
1. Direct user prompt            ← always highest priority
2. AGENTS.override.md (local)    ← subdirectory-level temporary overrides
3. AGENTS.md (local)             ← subdirectory-level project rules
4. AGENTS.md (root)              ← this file — project-wide baseline
5. ~/.config/coding-agents/      ← machine-wide global defaults
```

**Monorepos:** Each package can have its own AGENTS.md. The nearest file to the edited file wins — prevents frontend rules bleeding into backend packages (and vice versa).

### Override System

Create `AGENTS.override.md` to apply **temporary, task-specific rules** without editing this file. When the task is done, delete the override — project rules restore automatically. No cleanup of this file needed.

See `AGENTS.override.md` in this repo for the template. Use cases:
- Lock a folder during sensitive maintenance (`"Do not touch /payments"`)
- Force a specific package manager only in certain services (`pnpm` vs `npm`)
- Add verbose debug logging during an incident
- Restrict risky actions (API key rotation, file deletion) during a focused task

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
| Package manager | [e.g. npm / pip / uv / pnpm] |
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

- `AGENTS.md` (this file) — universal AI agent config and project baseline
- `AGENTS.override.md` — temporary task-specific overrides (delete when done)
- `CLAUDE.md` — Claude Code–specific configuration and session rules
- `README.md` — Human-readable project overview
- `PENDING-TASKS.md` or `tasks.md` — Active task tracking (if present)
- `specs/` — Detailed specs and workflow documents (if present)
