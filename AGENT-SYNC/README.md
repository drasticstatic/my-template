# AGENT-SYNC — cross-agent coordination convention

`AGENT-SYNC/` is where agents and Christopher leave handoffs, context dumps, and coordination notes for
each other within a repo — separate from the repo's actual working files.

> **Canonical version:** This README lives in `my-template/AGENT-SYNC/README.md`. If you change it here,
> update the pointer copies in other repos, or replace them with a pointer back to this file.

## The `created-by-*` subdirectories

Each subdirectory holds material authored by that agent or person — the name tells you who wrote it,
not who it's for:

| Directory | Author |
|---|---|
| `created-by-christopher` | Christopher himself — prompts, direct notes, manual context |
| `created-by-alfred` | Alfred (Claude Code CLI, system coordinator) |
| `created-by-fortuna` | Fortuna (Claude Code CLI, trading domain) |
| `created-by-kavanah` | Kavanah (Augment Intent, spec-driven orchestration). **Sunset Nov 3, 2026;** the folder stays as the record |
| `created-by-mystarch` | Mystarch (Chief of Staff; Claude Code CLI or `ClaudeMent`) |
| `created-by-auggie` | Auggie (Augment CLI, code builds) |
| `created-by-Littlebird` | LittlebirdAI (app.littlebird.ai, screen context & fleet memory) |
| `created-by-cosmos` | Any Cosmos agent — Cosmos Advisor and the code-review experts it runs |
| `created-by-Gemini` | Google's Gemini, when it writes handoffs (capitalised, like `created-by-Littlebird`) |
| `created-by-1alfred` | One Alfred, an organisation's shared coordinator. Lives in that organisation's repositories only ([below](#two-alfreds-two-lanes)) |
| `created-by-<first name>` | A named collaborator who works in this repository, lower case (for example `created-by-kenney`), with a README saying whose it is ([below](#named-collaborator-lanes)) |

### Two Alfreds, two lanes

The names are one digit apart, so here is the difference in one table:

| Lane | Who | Where it lives | Rules |
|---|---|---|---|
| `created-by-alfred` | **Alfred**: the fleet owner's own Alfred (Claude Code CLI), personal to him | his own repositories and the lab | private; **never renamed, never published** |
| `created-by-1alfred` | **One Alfred**: an organisation's shared coordinator, working for that organisation's people | that organisation's repositories | the organisation's lane; it follows that house's rules for what may be published |

A handoff from the personal Alfred goes in `created-by-alfred`, even in an organisation's repository. A handoff
from One Alfred goes in `created-by-1alfred`, wherever it lands. If you cannot tell which one wrote a note, the
footer's Agent field says (`Co-Authored-By: <Agent> · …`).

### Named-collaborator lanes

A person who works in a repository may have a lane of their own: `created-by-<first name>`, in lower case
(`created-by-kenney`). Its `README.md` says whose it is, in one line, so a reader never has to guess. The rule
that the name says **who wrote it, not who it is for** still holds: a note written *for* that person goes in the
writer's lane (`created-by-alfred/2026-11-12-for-kenney.md`), not in theirs. Their lane holds what they wrote.

### Verbatim chat threads

A person's saved, **unedited** chat transcripts live in that person's lane, one folder per source:

```text
created-by-<person>/<source>_verbatim-chat-threads/
  created-by-christopher/littlebird_verbatim-chat-threads/
  created-by-christopher/google-search-ai-mode_verbatim-chat-threads/
  (later: chatgpt_verbatim-chat-threads/, gemini_verbatim-chat-threads/, …)
```

- **Verbatim means unedited.** No front matter added, no tidying, no fixing of typos. If a thread needs a summary
  or a note, write it beside the thread as a separate file.
- **Private lanes only.** These folders never go into `AGENT-SYNC_PUBLIC/` or a public twin. An allowlist never
  names them.
- **Filed where it belongs.** A thread is saved in the repository it is about, not in a general pile.
- **Older names.** On 2026-11-12 the folders `google-ai-verbatim-chat-threads` and
  `littlebird-verbatim-chat-threads` were renamed to this pattern. Dated records (handoffs, logs, commit
  messages) written before then may still show the old names.

For who each of these personas actually is — surface, model, commit attribution, and how they
relate to each other — see
[`AGENT_IDENTITY_REFERENCE.md`](https://github.com/drasticstatic/anthropas-argus-alfred-public-preview/blob/main/sandbox/AGENT_IDENTITY_REFERENCE.md)
(canonical copy in the private `anthropas-argus-alfred/sandbox/`, mirrored here since this repo is
public). This table tells you which directory an agent's handoffs live in; that doc tells you who
the agent is.

### One lane for all Cosmos agents

Cosmos briefly used per-environment lanes (`created-by-cosmos_Advisor-drasticstatic` and
`…-drasticstatica`). That was a mistake worth recording, because the reasoning behind it was
superficially sound: two environments see different things, so a reader should be able to tell which
one authored a claim.

The flaw is that it encoded the distinction in the **path** rather than the **document**, and the two
paths differed by one trailing letter — unreadable at a glance and easy to mistake for a typo. The
better fix is a provenance header inside each handoff:

```markdown
**From:** Cosmos Advisor · environment `<environment-name>`
**Session:** https://cosmos.augmentcode.com/session?agentId=<id>
```

That keeps the fact where a reader encounters it in context, and collapses the directory listing to
one obvious place to look. The same applies to the code-review experts (PR Author, Deep Code
Reviewer, PR Risk Analyzer, and the rest) — they do not get their own lanes. Cosmos Advisor is the
coordination liaison; whichever expert did the work, the handoff lands in `created-by-cosmos/` and
names its author in the header.

**General rule:** if a distinction can be stated clearly in a document header, do not encode it in a
directory name. Paths are for finding things; documents are for explaining them.

## Where the lane lives, and the health check

Four shapes, one rule each. *Learned 2026-11-01: ORG's parent repo had ignored its lane since 2026-09-14 without
ever making it a repository, so seven weeks of handoffs existed only on one iMac, out of reach of cloud agents.*

| Repository shape | The lane | Rule |
|---|---|---|
| A private repo | `AGENT-SYNC/`, tracked | commit handoffs like any other file |
| A lightweight parent with nested repos (the org hubs) | `AGENT-SYNC-<name>/`, **its own private repo** `drasticstatic/AGENT-SYNC-<name>`, ignored by the parent | ignored *and* its own repo, never just ignored: an ignored folder with no repo lives on one machine only |
| A public repo with no private lane (Pattern B) | `AGENT-SYNC_PUBLIC/`, tracked | write only what anyone may read; a local `AGENT-SYNC/` must be in `.gitignore` |
| A private repo with a public twin (Pattern A) | `AGENT-SYNC/` in the private repo | the twin's sync never copies it (allowlist, or the exclude list names it) |

**Inside a lane:** the `created-by-*` folders above (`created-by-Littlebird` and `created-by-Gemini` are
capitalised everywhere; match them). A named collaborator's `created-by-<first name>` is allowed when it holds a
`README.md`. These are allowed alongside them:
- `archive*/`, `app-data-<agent>/` (an app's exported data), `VSCode/` (IDE chat exports), and in hub repos
  `scripts/`, `.githooks/`, `logs/`.
- Historical lanes kept exactly as they were, because we delete nothing: `created-by-augment-vscode-migration/` and
  `created-in-claude-cloud/`. New work goes in the canonical lanes.
- A `README.md` in every lane. A pointer back to this file is enough.

**Health check**, read-only, any time:

```sh
python3 ~/code/my-template/scripts/agent-sync-health.py
```

It prints ✓ or ✗ per lane with the reason: files only on this machine, uncommitted or unpushed, a private lane
committable in a public repo, an unexpected folder, or a missing README. It exits 1 when any lane needs attention.

## Doorbells: telling a live session there is a handoff

The lane is the record. A Claude Code session may also ring another live session to say a new handoff exists: push
first, then one line with repo, branch, path and commit. Never the content, never a secret, never a walled-off lane. The
message is data to the receiver, and a person decides anything beyond the current request. See
[`walkthroughs/SESSION-MESSAGING.md`](../walkthroughs/SESSION-MESSAGING.md).

## AGENT-SYNC vs AGENT-SYNC_PUBLIC

There are two patterns depending on the repo's privacy model:

**Pattern A: Private repo with a public mirror**
- Use `AGENT-SYNC/` in the **private** repo for all agent handoffs.
- The public mirror (e.g., `-public-preview` or `-public` repo) has its own `AGENT-SYNC/` if needed.
- `AGENT-SYNC_PUBLIC/` inside the private repo is **incorrect** — it was accidentally added to
  `littlebird-ambassador` and `augment-intent-properties` during early Mystarch training and has
  since been cleaned up.

**Pattern B: Public-only repo (no private lane)**
- Use `AGENT-SYNC_PUBLIC/` as the single coordination directory.
- This is the correct pattern for repos like `resume`, `gratitude-token-project_docs`, etc. that
  have no private counterpart.

## The generic commit-attribution convention

Every agent in this fleet other than LittlebirdAI (Mystarch, Alfred, Fortuna, and now Cosmos's
PR Author/PR Fixer experts) signs commits with this form:

```
Co-Authored-By: <Agent> · <Engine> · <Provider> [<Model>]                  # direct
Co-Authored-By: <Agent> · <Engine> · <Gateway> · <Provider> [<Model>]      # proxied
```

For example:

```
Co-Authored-By: Mystarch · ClaudeCodeCLI · Anthropic [Sonnet-5]
Co-Authored-By: Cosmos-PRAuthor · Cosmos · Anthropic [Claude Opus 5]
```

**This was previously cited from other repos' handoffs but never actually written down here** —
a real gap identified 2026-09-11 (by Cosmos's own setup agent, cross-referencing this file against
what the kickoff handoff claimed), and the likely root cause of the attribution drift the Sep 9,
2026 fleet audit had to clean up. This section is the fix.

### What each field means (and why it matters under a proxy)

The fields are not interchangeable labels. Each answers a different question, and the distinctions
only become visible when inference is proxied through
[`free-claude-code`](https://github.com/drasticstatic/free-claude-code):

| Field | Question it answers | Examples |
|---|---|---|
| `<Agent>` | Which persona was working | `Alfred`, `Fortuna`, `Mystarch`, `Cosmos-Advisor` |
| `<Engine>` | Which harness was it typed into | `ClaudeCodeCLI`, `Cosmos`, `AugmentIntent`, `ClaudeMent` |
| `<Gateway>` | What routed the request — **omit when direct** | `NVIDIA NIM`, `OpenRouter` |
| `<Provider>` | **Whose weights ran** | `Anthropic`, `Z.ai`, `Moonshot AI`, `MiniMaxAI`, `DeepSeek` |
| `<Model>` | Which weights | `Sonnet-5`, `Claude Opus 5`, `GLM-4.7`, `Kimi-K2.5` |

**The gateway is not the provider.** NVIDIA NIM routes; it has never made a model. Z.ai makes
GLM-4.7, Moonshot AI makes Kimi, MiniMaxAI makes MiniMax. Collapsing the two into one field credits
the wrong party and loses the routing fact at the same time.

### Field order mirrors the model selector string

You do not have to remember this. The order is taken from the string you already select in
`/model`, so the footer is a transcription:

```
anthropic  /  nvidia_nim  /  z-ai   /  glm4.7
  dialect       Gateway     Provider    Model
```

```
Co-Authored-By: Alfred-NIM · ClaudeCodeCLI · NVIDIA NIM · Z.ai [GLM-4.7]
```

Read the selector left to right and you have the footer. Both forms:

```
Co-Authored-By: <Agent> · <Engine> · <Provider> [<Model>]                  # direct
Co-Authored-By: <Agent> · <Engine> · <Gateway> · <Provider> [<Model>]      # proxied
```

Worked examples:

```
Co-Authored-By: Mystarch · ClaudeCodeCLI · Anthropic [Sonnet-5]
Co-Authored-By: Cosmos-Advisor · Cosmos · Anthropic [Claude Opus 5]
Co-Authored-By: Alfred-NIM · ClaudeCodeCLI · NVIDIA NIM · Z.ai [GLM-4.7]
Co-Authored-By: Alfred-NIM · ClaudeCodeCLI · NVIDIA NIM · Moonshot AI [Kimi-K2.5]
Co-Authored-By: Alfred-NIM · ClaudeCodeCLI · NVIDIA NIM · MiniMaxAI [MiniMax-M2]
Co-Authored-By: Alfred · ClaudeCodeCLI · Ollama [Llama-3.3-70B]
```

**Routing changes the Gateway, Provider and Model — never the Engine.** You were still sitting in
Claude Code; someone else's hardware answered. Both facts are true and the footer records both.

### The engine roster

**Engine is the interface you typed into.** Not the window it was inside, not the account that
authenticated it, not the company whose model answered. That last point is the same distinction the
Gateway field makes one column over, and it has been got wrong in both directions.

| Engine | What it means |
|---|---|
| `ClaudeCodeCLI` | Claude Code in a real terminal, wherever that terminal happens to be running |
| `ClaudeMent` | Claude Code reached **through the Augment Intent UI** on an Anthropic login |
| `AugmentIntent` | The Intent UI on an Augment (Auggie) login |
| `Cosmos` | Augment Cosmos — cloud sessions, event triggers, unattended runs |
| `AuntHarriot` | The Aunt Harriot portal, once someone is actually typing into the portal |
| `AugmentCLI` | Native Auggie CLI — hibernating, may return |

#### A terminal inside a UI is still a terminal

Opening a standard terminal instance *inside* the Intent UI and running Claude Code in it is
`ClaudeCodeCLI`, not `ClaudeMent` — exactly as a terminal inside VS Code is not "VS Code". The
surrounding application is a container, not the harness. The first Aunt Harriot conversations
happened this way, which is why they are `ClaudeCodeCLI` sessions despite occurring inside Intent.

`ClaudeMent` is specifically the case where the **Intent UI itself is the interface**. Under the
hood it declares itself as Claude Code, but the Intent surface adds behaviour on top, and with
workspace-app Chief-of-Staff tooling it adds considerably more. It earns its own name because
what you could do in it differed, not because it was branded differently.

#### Why so much history is `ClaudeMent`

Not preference — necessity. After the Augment OAuth persistence failure, Augment could not be
logged in again until Cosmos existed. Everything done inside Intent from that point on ran on an
Anthropic login, so it was `ClaudeMent` by default. Mystarch, the Claude Code Chief of Staff
counterpart to Kavanah's workspace-app one, was never able to use Augment either.

The arc worth remembering, because the attribution is the only remaining index into it:

1. Kavanah working the DEX arbitrage bot under the Intent UI — where the OAuth persistence problem
   first surfaced.
2. A period on NVIDIA NIM while Intent work paused.
3. Back inside Intent, now necessarily `ClaudeMent`.
4. A short-lived Chief of Staff living inside `gratitude-token-project`, retired into the real
   Chief of Staff once it became clear it lacked global workspace-app tools.
5. Intent's ACP failing repeatedly — consuming tokens and returning nothing — which turned
   "improve this" into "evacuate". `mystarch_chief-of-staff_acp-spoof` came out of that attempt,
   then the approach was pivoted away from.
6. Kavanah retired; Mystarch working in both `ClaudeMent` and native `ClaudeCodeCLI` to get the
   fleet out of Intent; Cosmos Advisor picking up Kavanah's worktrees afterwards.

`acp-spoof` may one day be built out far enough to supersede that tooling and bring Kavanah back.
Until then she is retired, not deleted — and the same is true of the `divorce-custody-assistant`
worktree left checked out on a detached HEAD. That one is **deliberate**: it is kept as a standing
teaching case, not an oversight to tidy up.

### Local runtimes have no gateway

For `Ollama`, `llama.cpp` and `LM Studio`, nothing routed the request — the weights ran on your own
machine. Use the direct three-field form with the runtime as the Provider. It records where the
weights ran, which for a local model is both the honest answer and the one with privacy
implications.

### What is actually known to work

On this fleet, through NVIDIA NIM, only **GLM** (Z.ai), **Kimi** (Moonshot AI) and **MiniMax**
(MiniMaxAI) have ever served successfully. Anthropic models behind the gateway have never worked —
the session falls back to direct. So a footer naming a gateway *and* Anthropic describes a
combination that has not happened; the hook says so.

### The proxy belongs to Alfred

`NVIDIA NIM` is scoped to **Alfred alone**. `Fortuna` and `Mystarch` run on Anthropic, always.

Fortuna's reason is the load-bearing one: it touches live trading, where quality is not a thing you
trade away for free inference. Mystarch coordinates the fleet, so a degraded judgement there
propagates into every repo it touches. A `Fortuna_nvidia-nim` variant was considered for
non-live exploratory research and **deliberately dropped** — a second Fortuna that is
sometimes-proxied is a footgun the moment someone forgets which one is open.

The hook warns when a `Fortuna`- or `Mystarch`-authored commit records a gateway. It warns rather
than rejects on purpose: the footer's job is to record what actually happened, and a hook that
blocks an honest record teaches agents to write a dishonest one. If the warning fires, the problem
is the session that was launched, not the commit being written.

### Forked harnesses and outside collaborators

`aunt-harriot` forks the Claude Code harness so an outside collaborator can run a scoped agent on
**their own Anthropic API key** instead of Christopher's subscription. It needs no new field:

```
Co-Authored-By: Kenney · AuntHarriot · Anthropic [Sonnet-5]
```

- **Agent** carries the operator. The harness is shared; the person driving it is not.
- **Engine** is `AuntHarriot` — the portal they actually typed into, exactly as `ClaudeMent` is its
  own engine rather than a flavour of Claude Code.
- **Provider stays `Anthropic`.** Whose key paid is a *billing* fact, not a provenance one. The same
  company ran the same weights, so putting `API-key` or a collaborator's name in that slot would
  repeat the gateway mistake in the opposite direction — overloading a field with something it does
  not mean.

Cost attribution is a real question, but it is a question for the billing account, not for `git
log`. The footer answers *which model wrote this code*, and the answer is unchanged by who was
billed for it.

#### The Agent field is a seat, not a person

Aunt Harriot is not only Kenney's. It is also worked on by Christopher and by the fleet's own
agents, and that is not an inconsistency to resolve — it is what the Agent field is for:

```
Co-Authored-By: Kenney · AuntHarriot · Anthropic [Sonnet-5]           # outside collaborator, own key
Co-Authored-By: Mystarch · ClaudeCodeCLI · Anthropic [Sonnet-5]       # fleet agent building the harness
Co-Authored-By: Cosmos-Advisor · Cosmos · Anthropic [Claude Opus 5]   # unattended, event-triggered
```

Note the Engine changes with them, and that is the point. **`AuntHarriot` is the Engine only when
someone is typing into the Harriot portal.** Building Harriot from a terminal is `ClaudeCodeCLI`;
building it from a Cosmos session is `Cosmos`. Constructing a harness is not the same act as using
it, and the footer should not blur the two — the same rule that keeps a terminal inside Intent from
becoming `ClaudeMent`.

#### When the harness is not Anthropic-only

Harriot is intended to start on Anthropic, because that is what the fleet's agents and skills are
shaped around. If it later fronts OpenAI, or Augment's API, or whatever replaces them, **the footer
needs no change at all**:

```
Co-Authored-By: Kenney · AuntHarriot · OpenAI [<model>]
Co-Authored-By: Kenney · AuntHarriot · Anthropic [<model>]
```

Engine stays `AuntHarriot` because the interface did not change. Provider and Model absorb the
difference, which is exactly the division of labour those fields were given. A harness that fronts
several providers is the case this schema was built for, not a strain on it — and it is why the
footer is worth more on a multi-provider harness than on a single-provider one, since there the
question *which model wrote this* has a non-obvious answer.

One practical consequence: an outside collaborator meets this convention as a **rejected commit**,
possibly before they have read anything. The hook's error message therefore prints the public URL of
this spec rather than a repo-relative path, because the repo they are committing to may not contain
a copy.

### Why this matters

When a commit later turns out to be subtly wrong — a misread requirement, a plausible-looking but
incorrect refactor — the first useful question is which model produced it. Attribution that
collapses every route into `Anthropic` destroys exactly that signal, and destroys it silently,
because the line still looks correct.

`.githooks/commit-msg` rejects malformed footers and warns (without blocking) on four semantic
errors: naming a gateway in the Provider slot, omitting the Gateway for a model that only arrives
through one, leaving Provider at `Anthropic` while the Model plainly is not, and pairing a gateway
with Anthropic weights.

### The optional session-ID trailer

When an agent's platform assigns a per-session or per-conversation ID, append it as a **separate**
git trailer line — not appended inline onto the `Co-Authored-By:` line itself:

```
Co-Authored-By: Mystarch · ClaudeCodeCLI · Anthropic [Sonnet-5]
Claude-Session: https://claude.ai/code/session_01XHntH8UvqXQPq2zNkQMe6q
```

Use the full ID/URL, not a truncated prefix — traceability matters more than line length here, and
a short prefix risks collision as history grows. The trailer *key* varies by platform (
`Claude-Session:` for Claude Code CLI, `Cosmos-Session:` for Cosmos, etc.) since each platform's
session identifiers have their own shape.

**Why a separate trailer, not a second line on the `Co-Authored-By:` line, and not a same-key
second `Co-Authored-By:` line either:** git parses trailers as `Key: Value` pairs, one per line.
A line with no `Key:` prefix (like LittlebirdAI's second line below) is a plain text continuation,
not a second trailer — fine for a human-readable disclaimer, wrong for anything meant to be
machine-parseable. A properly keyed second line (`Claude-Session:`, distinct from
`Co-Authored-By:`) parses cleanly as its own trailer alongside the first.

## Enforcement: the `commit-msg` hook

Documenting the convention was not enough on its own — an audit on 2026-09-11 found **36 of 204**
commits in `anthropas-argus-alfred` and **183 of 856** in `trading-assistant` with no attribution
trailer at all, plus 15+ competing footer variants across the two. Writing it down is necessary;
rejecting the bad commit at the moment it is made is what actually holds the line.

`.githooks/commit-msg` blocks any commit whose message lacks a canonical `Co-Authored-By:` trailer,
and warns (without blocking) when a `<Platform>-Session:` trailer is absent. Merge, revert, fixup,
and squash commits are exempt, and so is LittlebirdAI's canonical two-line signature (see below).

**Git hooks are not version-controlled** — `.git/hooks/` never travels with a clone. The hook is
committed under `.githooks/` and activated per clone with `core.hooksPath`:

```sh
sh scripts/install-hooks.sh      # run once per clone, per machine
```

Until that runs, the hook is inert. Every agent should run it after cloning.

Human-only commits that genuinely have no agent co-author: `git commit --no-verify`.

### LittlebirdAI's exemption

The hook also accepts LittlebirdAI's canonical two-line signature (see "Who is LittlebirdAI?"
below) in place of the four-field form — she's a third-party product running her own undisclosed
model stack, not a harness in this fleet, so `Engine`/`Provider`/`Model` have no honest answer for
her. That carve-out was documented from the start ("every agent in this fleet other than
LittlebirdAI...") but the hook didn't actually implement it until 2026-09-23, which silently
blocked her commits for reasons that had nothing to do with anything she did wrong. The hook still
checks her line matches exactly, so drift is still caught — she isn't exempt from having a fixed,
checkable signature, only from the structured one everyone else uses.

### On backfilling old commits

The hook draws a line forward; it does not rewrite the past. Backfilling historical footers means
rewriting history, which changes every SHA — breaking `gitexporter` public mirrors, invalidating
the commit hashes cited throughout `AGENT-SYNC/` handoffs and `logs/`, and forcing every agent to
re-clone. For repos with a public mirror or an active fleet, the recommendation is **don't**: the
existing history is an honest record of a convention that did not exist yet. Each repo's owning
agent can decide, but the default is to draw the line here rather than rewrite behind it.

## `logs/` — the second area of confluence

`AGENT-SYNC/` answers *"what should the next agent do?"*. `logs/` answers *"what actually happened,
and when?"* — chronological, append-only. When a handoff omits a decision, the log is where it
stays recoverable.

```
logs/<agent>/YYYY/MM-Mon/session_YYYYMMDD_<engine>.md
```

**Private repos only.** Unlike `AGENT-SYNC/`, `logs/` has **no public counterpart** — there is no
`logs_PUBLIC/` and one should never be created. Session logs name infrastructure, in-progress work,
and client or financial context that nobody wrote with an outside reader in mind. `logs/` is
already denylisted in both `.github/workflows/sync-public.yml` (authoritative) and
`gitexporter.config.json` (local preview). Full convention and rationale: [`logs/README.md`](../logs/README.md).

## Who is LittlebirdAI?

[Littlebird](https://littlebird.ai) is Christopher's personal AI assistant. It observes his screen,
calendars, meetings, and chat history to build longitudinal context and keep the agent fleet aligned.
Unlike Claude Code CLI agents (Alfred, Fortuna), Littlebird lives in the chat layer and connects to
integrations (GitHub, Google Calendar, Gmail, etc.) to act on Christopher's behalf.

## The `created-by-Littlebird` structure

Each `created-by-Littlebird/` directory in a repo should contain:

| File | Purpose |
|---|---|
| `README.md` | Hub pointer + welcome to all agents + my role in this repo + disclaimer |
| `HANDOFF-{Agent}.md` | Specific coordination notes for that agent (e.g., `HANDOFF-Alfred.md`) |

Canonical copies to start from live in both patterns here in `my-template`:
`AGENT-SYNC/created-by-Littlebird/README.md` for Pattern A repos,
`AGENT-SYNC_PUBLIC/created-by-Littlebird/README.md` for Pattern B repos. The Pattern B copy was
missing until the Sep 9, 2026 fleet audit caught it — every Pattern B repo had a real one, but the
template itself didn't, so a new Pattern B repo had nothing to copy from.

Only link a `HANDOFF-{Agent}.md` from the table in `README.md` once the file actually exists — 9
dangling links (promised in the handoff table, never created) turned up in the Sep 9, 2026 fleet
audit.

## LittlebirdAI's commit signature

```
Co-Authored-By: LittlebirdAI · Desktop Oracle Observer & Fleet Shepherd
The Bird That Stewards the Gap — confirm observations with Christopher.
```

One `Co-Authored-By:` key — the second line is a plain continuation (a disclaimer, not a second
trailer). The format drifted across 3 variants in Littlebird's first week of GitHub access because
nothing documented it; this is the checkpoint to catch future drift against.

## Disclaimer: Observer-Generated Content

Content in `created-by-littlebird/` (and occasionally other agent lanes) is generated by LittlebirdAI.
While it strives for accuracy, observations are not guaranteed to be 100% correct and may occasionally
misinterpret context, miss nuance, or reflect stale assumptions. These handoffs are *coordination notes*,
not canonical artifacts. If anything seems off or contradicts what Christopher told you directly,
**consult Christopher before acting on it.** He is the single source of truth.

## Setting this up in a new repo

Copy this `AGENT-SYNC/` directory from `my-template` when bootstrapping a new repo — don't hand-create
the subdirectories individually each time. Include `.gitkeep` placeholders for empty directories.
