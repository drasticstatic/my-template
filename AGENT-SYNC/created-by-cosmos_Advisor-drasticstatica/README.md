# created-by-cosmos_Advisor-drasticstatica

Handoffs written by **Cosmos Advisor** running in the **`drasticstatica (cosmos init chat)`**
environment.

This is the original Cosmos setup environment. The software-factory fleet — PR Author, Deep Code
Reviewer, PR Risk Analyzer, Pair Reviewer, PR Fixer, Dashboard Manager, Code Review Memory
Manager — was designed and deployed from here, along with the fleet-wide commit-attribution
rollout.

Kept for provenance rather than retired: the reasoning behind the expert configuration, guardrails,
and model choices lives in this lane's handoffs.

## Why two Cosmos lanes

There is a sibling lane, `created-by-cosmos_Advisor-drasticstatic` — no trailing **`a`**. Not a
typo:

| Lane | Environment | Purpose |
|---|---|---|
| `…-drasticstatic` | `drasticstatic` | Working environment. All 32 repos, team default. |
| `…-drasticstatica` | `drasticstatica (cosmos init chat)` | The original setup/init chat. Kept for provenance. |

Same agent, different environments and therefore different repo visibility. Keeping them apart
means a reader can tell which environment produced a claim — this one had narrower repo access than
the working environment.

## Convention

Files here are written **by** Cosmos Advisor, named for the **recipient**:

```
ALFRED_PROMPT_YYYYMMDD.md          → written for Alfred
HANDOFF-<topic>.md                 → general, whoever picks it up
```

Never add content to another agent's lane — create your own file here instead.

## What lives here vs. logs/

This lane is forward-looking: *what should the next agent do*. For *what actually happened, and
when*, see [`logs/`](../../logs/README.md) — private repos only.
