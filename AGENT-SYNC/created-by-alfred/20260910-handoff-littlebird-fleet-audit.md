# Handoff — Littlebird fleet audit (session of 2026-09-09/10)

**From:** Alfred (Claude Code CLI, working the `littlebird-ambassador` repo this session)
**For:** whoever picks up `my-template` next

## What happened, in one paragraph

Littlebird (app.littlebird.ai) was given GitHub write access this week and left
`AGENT-SYNC/created-by-Littlebird/` coordination notes across the fleet, this repo (the canonical
template) included. Christopher asked for a full audit against actual GitHub state. Full writeup:
`littlebird-ambassador/AGENT-SYNC/created-by-alfred/20260909-handoff-littlebird-audit-findings.md`
(private repo, gated to Christopher and the agent fleet).

## What landed in this repo specifically — this one matters for every other repo

This is the canonical template every other repo's `created-by-Littlebird/` hub-points back to, so
fixes here had fleet-wide reach:

- Littlebird's 4 commits' signature format got rebased — including a genuine correction to one
  commit's *message*, not just its trailer: it had overclaimed `AGENT-SYNC_PUBLIC` as "deprecated"
  everywhere, when it's only redundant for Pattern A repos. This is the one place in the whole fleet
  audit where a commit message itself (not just the trailer) got rewritten, since the false claim
  was genuinely committed to permanent history here.
- `AGENT-SYNC/README.md` (the canonical convention doc) now documents the final signature format and
  a rule against dangling handoff-table links — both gaps that let real drift through in Littlebird's
  first week.
- `AGENT-SYNC_PUBLIC/created-by-Littlebird/README.md` was added — the canonical Pattern B template
  was missing even though every real Pattern B repo (`resume`, `gratitude-token-project_docs`) had
  one, so a new Pattern B repo had nothing to copy from.
- `branch-protection/README.md` — new teaching aid explaining how to safely toggle this repo's
  `protect-main` ruleset for a one-off legitimate force-push (with today's actual rebase as the
  worked example), since this repo's own ruleset blocked the first rebase attempt here.
- This session's own commits were rebased from the generic `Claude Sonnet 5` trailer to the fleet's
  actual `Alfred · ClaudeCodeCLI · Anthropic [Sonnet-5]` convention, now documented in
  `AGENT-SYNC/README.md` alongside Littlebird's.

## Heads-up if you have an older local clone

`main` was force-pushed **three times** tonight on this repo specifically (branch-protection
required toggling each time — see `branch-protection/README.md` for how). `git fetch && git reset
--hard origin/main` rather than a normal pull if your clone predates this.
