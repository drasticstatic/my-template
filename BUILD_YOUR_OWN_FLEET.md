# Building your own version of this

**TL;DR:** a fleet of AI helpers that never loses the thread rests on four habits:
- **A notebook per repo:** `AGENT-SYNC/` handoffs.
- **One credit line:** a commit trailer naming the helper.
- **Skills where each tool can find them.**
- **A to-do list written before the work starts:** `PENDING-TASKS.md`.

Start with those, add helpers as the work grows, and let one rulebook (`AGENTS.md`) speak to all of them.

**Just joining someone else's organization?** You don't need any of this. Read
[walkthroughs/JOIN-AN-ORGANIZATION.md](walkthroughs/JOIN-AN-ORGANIZATION.md) instead.

If someone pointed you here — human or AI agent — it's because they want to set up something
similar to this fleet: several coding agents, each with their own persona and repo scope,
coordinating across many git repositories without losing context between sessions. This doc is
the fast path in, written for both audiences at once.

## The one-sentence pitch

A handful of durable conventions, applied consistently across every repo, let AI coding agents
(Claude Code, Augment/Cosmos, Codex, or a mix) hand off work to each other and to their future
selves — across repos, across sessions, across weeks — without a human having to re-explain
context every time.

## The four conventions that actually matter

Everything else in this fleet is downstream of these. Read them in this order:

1. **[`AGENT-SYNC/README.md`](./AGENT-SYNC/README.md)** — the cross-agent coordination convention.
   Each repo gets an `AGENT-SYNC/` directory with `created-by-<agent>/` subdirectories, so any
   agent (or person) can leave a handoff for whoever picks up next, and know who wrote what. Also
   documents the commit-attribution footer convention (`Co-Authored-By: <Agent> · <Engine> ·
   <Provider> [<Model>]`) that keeps authorship legible across a multi-agent, multi-model fleet.
2. **[`NESTED-REPOS-GUIDE.md`](./NESTED-REPOS-GUIDE.md)** — how to group several
   related-but-independent repos under one lightweight parent directory, without any of them
   tracking each other's content. Useful once you have more than one repo per initiative/client.
3. **[`SKILLS_LOCATIONS.md`](./SKILLS_LOCATIONS.md)** — where each coding CLI actually looks for
   custom skill/prompt files on disk, and the frontmatter fields that are portable across tools.
   Get this wrong and your skills silently don't load, with no error.
4. **A durable task tracker** (`PENDING-TASKS.md`, root of your equivalent of this fleet's
   "chief of staff" repo) — the practice of writing down what's in flight *before* doing it, so a
   session timeout, a fresh chat thread, or a different agent picking up mid-task never loses
   scope. This is the single highest-leverage habit in the whole setup; everything else is
   secondary to it.

## What you don't need on day one

- A coordination repo per initiative (`AGENT-SYNC-<name>`) — start with one `AGENT-SYNC/` in your
  main repo and split out only once you actually have multiple initiatives needing separate lanes.
- The nested-parent pattern — only needed once a single initiative genuinely spans multiple repos.
- Multiple named agent personas — this fleet grew several over time (a system coordinator, a
  domain specialist, an app-level chief of staff) because the work grew into those shapes. Don't
  invent personas in advance of a real need for the separation.

## What to copy vs. what to adapt

Copy directly: the `AGENT-SYNC/` directory structure (this template's own copy is the canonical
starting point — see its own README for the exact subdirectories), the commit-attribution
convention, `.githooks/` (commit-msg + pre-commit, if you use a secret scanner like ggshield —
see `scripts/install-hooks.sh`'s notes on why both hooks need to coexist).

Adapt to your own situation: the specific agent personas and their names, the specific repos and
naming scheme, whether you need a nested-parent pattern at all.

## Your first 30 minutes

1. Make a repo, and copy this template's `AGENT-SYNC/`, `.githooks/` and `scripts/install-hooks.sh` into
   it. Run `sh scripts/install-hooks.sh`.
2. Write an `AGENTS.md`: the house rules every helper should follow. The organization template in
   [org-onboarding/](org-onboarding/) is a good start.
3. Write `PENDING-TASKS.md` with the one thing you're doing today.
4. Connect one helper ([walkthroughs/](walkthroughs/)), and ask it to read `AGENTS.md`, then the task list.
5. At the end, ask it to leave a handoff in `AGENT-SYNC/created-by-<its name>/`. Tomorrow's session (or
   another helper) starts from there.

## Connecting more helpers and tools

| To… | Read |
|---|---|
| Use several AI tools side by side | [walkthroughs/MANY-AI-TOOLS-ONE-TEAM.md](walkthroughs/MANY-AI-TOOLS-ONE-TEAM.md) |
| Read whole websites (research, refreshes) | [walkthroughs/CONNECT-FIRECRAWL.md](walkthroughs/CONNECT-FIRECRAWL.md) |
| Work with a Wix or WordPress site | [CONNECT-WIX.md](walkthroughs/CONNECT-WIX.md) · [CONNECT-WORDPRESS.md](walkthroughs/CONNECT-WORDPRESS.md) |
| Read documents kept in Google Drive | [walkthroughs/CONNECT-GOOGLE-DRIVE.md](walkthroughs/CONNECT-GOOGLE-DRIVE.md) |
| Give helpers a map of a codebase | [walkthroughs/CONNECT-GRAPHIFY.md](walkthroughs/CONNECT-GRAPHIFY.md) |
| Welcome people into a GitHub organization | [org-onboarding/](org-onboarding/) |

## If you want to see it working end to end

This template repo is deliberately generic and doesn't carry real-world specifics. Public worked
examples from the fleet that grew it:

- **How a fleet's helpers are named and credited:**
  [AGENT_IDENTITY_REFERENCE.md](https://github.com/drasticstatic/anthropas-argus-alfred-public-preview/blob/main/sandbox/AGENT_IDENTITY_REFERENCE.md).
  It names which application decides the name, local helpers versus cloud ones, and how the memory layer
  (Littlebird) fits.
- **The cloud side:**
  [COSMOS_AGENT_ROLE_REFERENCE.md](https://github.com/drasticstatic/anthropas-argus-alfred-public-preview/blob/main/sandbox/COSMOS_AGENT_ROLE_REFERENCE.md).
  It covers an advisor that builds the other helpers, and a code-review team that wakes on GitHub events.
- **A community's public changelog and welcome kit**, built and kept by several helpers:
  [changelog-template/](changelog-template/), with its whole build story in
  [changelog-template/docs/JOURNEY.md](changelog-template/docs/JOURNEY.md).

If whoever pointed you here also gave you access to their actual fleet, that's where to see the pattern
carrying real work: multiple agents, real handoffs, and task trackers with months of history.
