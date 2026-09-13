# CLAUDE.md — [Project Name]
### Claude Code CLI | [Agent Name and Role]

> **Instructions:** Fill in each section for your repo. Delete sections that don't apply.
> This file is loaded automatically by Claude Code CLI at session start.
> Keep it in the repo root. Add to `.gitignore` if you don't want it in public previews.

---

---

## ⚠ FIRST: sync this clone before you touch anything

```sh
git pull --rebase --autostash
```

Run this at the **start of every session**, before reading deeply or editing. Several agents and
Christopher push to these repos — including Cosmos agents that run unattended while nobody is at the
machine — so a clone can be behind by the time you open it.

**`--autostash` is what makes this safe on a dirty tree.** It stashes uncommitted changes, rebases
onto the remote, then reapplies them. Your in-progress work survives. Without it, `git pull --rebase`
refuses to run and you are tempted into something worse.

Why it matters more than it sounds:

- A stale clone **does not fail early.** It fails at push time, after the work is done, as a
  non-fast-forward rejection — the most expensive moment to discover it.
- The tempting fix at that point is `git push --force`, which discards whatever someone else pushed
  in the meantime. Syncing first removes the temptation.
- If a rebase does conflict, stop and resolve it deliberately. A conflict is information: someone
  else changed the same lines, and you want to know that *before* building on top of them.

**Fresh clone?** Also run `sh scripts/install-hooks.sh` — git hooks are not version-controlled, so
the commit-attribution hook stays inert until this clone is pointed at `.githooks/`. Details:
[`scripts/README.md`](./scripts/README.md).

## ⚠ FIRST: is this repo private or public?

Get this wrong and session logs leak to a public mirror. The rule:

| | **Private repo** | **Public repo** |
|---|---|---|
| Coordination lane | `AGENT-SYNC/` | `AGENT-SYNC_PUBLIC/` |
| `logs/` | ✅ yes | ❌ **never** |

There is **no `logs_PUBLIC/`** and one must never be created. `AGENT-SYNC/` has a public
counterpart; `logs/` deliberately does not. Session logs name infrastructure, in-progress work, and
client or financial context that nobody writes for an outside reader.

Don't decide by hand — the script decides and builds it:

```sh
sh scripts/scaffold-agent-sync.sh          # detect visibility, create the right layout
sh scripts/scaffold-agent-sync.sh --check  # verify an existing repo, change nothing
```

**If this repo syncs to a public mirror,** any NEW root directory must be classified in
`.github/workflows/sync-public.yml` **in the same commit** — or the next sync fails (allowlist
model) or silently publishes it (exclude model). This has bitten the fleet before.

`gitexporter` is **deprecated** — never run `npx gitexporter`. The Actions pipeline replaced it.
`gitexporter.config.json` is kept as documentation only. Canonical spec:
`workflow-templates/GITEXPORTER-TO-ACTIONS-SYNC.md`.

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

---

## Commit Convention

Full fleet convention, shown here regardless of whether this specific repo currently has an Augment
Intent workspace pairing or NIM in active use — so a new repo (and its memory) doesn't need the
whole multi-agent suite re-explained from scratch. Which *application* launched a session decides
the agent name and engine, not which path — see
`anthropas-argus-alfred/sandbox/AGENT_IDENTITY_REFERENCE.md` and `INTENT_WORKTREE_LEGEND.md` for
the full rule.

- Alfred-Anthropic: `Co-Authored-By: Alfred · ClaudeCodeCLI · Anthropic [Sonnet-5/Opus-#/Haiku-#]`
- Alfred-NIM: `Co-Authored-By: Alfred-NIM · ClaudeCodeCLI · NVIDIA NIM · Z.ai [GLM-4.7]`
  (gateway then provider — `NVIDIA NIM` routes, `Z.ai` makes GLM; `Moonshot AI` for Kimi,
  `MiniMaxAI` for MiniMax. Only those three have ever served through the proxy, and the proxy
  is Alfred's alone — Fortuna and Mystarch run on Anthropic.)
- Kavanah-AugmentIntentUI-AuggieLogin: `Co-Authored-By: Kavanah · AugmentIntent · [model]`
- Kavanah-AugmentIntentUI-AnthropicLogin ("ClaudeMent"): `Co-Authored-By: Kavanah · ClaudeMent · Anthropic [model]`
- Kavanah-TerminalUI(macOS/Intent/VSCode standard terminal instance)-AnthropicLogin: `Co-Authored-By: Kavanah · ClaudeCodeCLI · Anthropic [model]`
- Mystarch (app-level Chief of Staff, cross-workspace reach): same engine options as Kavanah above, swap the agent name
- Auggie (native Augment CLI — currently hibernating, may return): `Co-Authored-By: Auggie · AugmentCLI · [model]`

## Commit attribution (enforced by hook)

Every commit must carry two git trailers:

```
Co-Authored-By: <Agent> · <Engine> · <Provider> [<Model>]                  # direct
Co-Authored-By: <Agent> · <Engine> · <Gateway> · <Provider> [<Model>]      # proxied
<Platform>-Session: <full session URL>
```

Model in **square brackets**, separator is U+00B7 MIDDLE DOT ( · ). Add `<Gateway>` **only when
inference is proxied** — it names what *routed* the request (`NVIDIA NIM`, `OpenRouter`), never who
made the model (`Z.ai`, `Moonshot AI`, `MiniMaxAI`). The field order mirrors the `/model` selector
string, so `anthropic/nvidia_nim/z-ai/glm4.7` transcribes to `NVIDIA NIM · Z.ai [GLM-4.7]` —
read it left to right rather than memorising it. Local runtimes (`Ollama`, `llama.cpp`,
`LM Studio`) have no gateway: the weights ran on your machine, so the runtime is the Provider. The session
trailer is a **separate** line — folding it onto the `Co-Authored-By:` line breaks git trailer
parsing. Use the full session URL, never a truncated prefix. Key varies by platform:
`Claude-Session:` for Claude Code CLI, `Cosmos-Session:` for Cosmos.

`.githooks/commit-msg` rejects non-conforming commits. **Activate it once per clone:**

```sh
sh scripts/install-hooks.sh
```

Human-only commits: `git commit --no-verify`. **Canonical spec — single source of truth. Do not restate the field table locally; link it:**
[`my-template/AGENT-SYNC/README.md`](https://github.com/drasticstatic/my-template/blob/main/AGENT-SYNC/README.md)
