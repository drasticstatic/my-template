# Building your own version of this

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

## If you want to see it working end to end

This template repo is deliberately generic and doesn't carry real-world specifics. If whoever
pointed you here also gave you access to their actual fleet, that's where to see the pattern
actually load-bearing real work — multiple agents, real handoffs, real task trackers with months
of history. Ask them for a pointer into one of their repos if you want a worked example rather
than just this description.
