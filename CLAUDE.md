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

## Before Cloning or Installing Any External Repo / Package

Before running `git clone`, `npm install`, `pip install`, `cargo build`, or adding any external dependency:
1. **Review install/build scripts** — `package.json` (`postinstall`/`preinstall`/`prepare`), `pyproject.toml`, `build.rs`/`Cargo.toml` build scripts — flag anything that executes shell commands
2. **Scan for credential harvesting** — look for patterns accessing `~/.ssh`, `~/.aws`, `.env`, `process.env`, or system credential paths in unexpected files
3. **Verify provenance** — check GitHub repo age, star/fork count, recent commit activity, contributor count, and maintainer identity
4. **Check for typosquatting** — verify package/repo names exactly match the intended one (e.g. `lodash` not `1odash`)
5. **Audit unexpected network calls** — flag external HTTP requests in scripts, entrypoints, or install hooks
6. **When in doubt, ask before proceeding** with any install or clone

**When a repo's legitimacy is genuinely in question** (not just routine dependency hygiene — something feels off, or it was flagged by the repo owner or a third party): prefer **read-only inspection via the GitHub API over cloning**. `gh api repos/<owner>/<repo>` for metadata (age, stars, forks, contributors), `gh api repos/<owner>/<repo>/commits` for activity pattern, and — critically — `gh api repos/<owner>/<repo>/contents/<path>` to pull actual **source file contents as text** without ever cloning or running anything. Weigh these red flags specifically (a confirmed real-world case surfaced a repo shaped exactly like this):
- A single commit-burst history (e.g. an entire project's commits landing within minutes/hours) followed by dormancy — real projects have activity spread over time
- One contributor, inflated-looking star count relative to actual engagement (issues/forks/discussion)
- Marketing claims in the README not matched by the actual open-sourced source — read the source as text and check
- **Most importantly: a real "product" distributed as a separate, unreviewable compiled binary (a `.exe`/`.dmg`/`.7z`/`.zip` in Releases) that is functionally disconnected from a harmless-looking open-sourced stub.** This is the standard bait-and-switch shape — the visible source builds legitimacy while the actual behavior ships unreviewable. Never download or run the binary to "just check" — the read-only source/metadata inspection above is sufficient to form a judgment without that risk.
- If the read-only inspection can't resolve the question either way, that's what "ask before proceeding" in step 6 is for — don't escalate to actually running anything as the next step.

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
