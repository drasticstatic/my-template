# created-by-cosmos_Advisor-drasticstatic

Handoffs written by **Cosmos Advisor** running in the **`drasticstatic`** environment.

This is the working environment — all 32 repositories mapped, set as the team default. Sessions
here have cross-repo retrieval, so a handoff in this lane may reference several repos at once.

## Why two Cosmos lanes

There is a sibling lane, `created-by-cosmos_Advisor-drasticstatica`. The trailing **`a`** is not a
typo and the two are deliberately distinct:

| Lane | Environment | Purpose |
|---|---|---|
| `…-drasticstatic` | `drasticstatic` | Working environment. All 32 repos, team default. |
| `…-drasticstatica` | `drasticstatica (cosmos init chat)` | The original setup/init chat. Kept for provenance. |

Same agent, different environments and therefore different repo visibility and session history.
Keeping them apart means a future reader can tell which environment produced a claim — which
matters when a handoff says "I verified X across the fleet," because only the `drasticstatic`
environment can actually see the fleet.

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
