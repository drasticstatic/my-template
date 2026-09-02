# AGENT-SYNC — cross-agent coordination convention

`AGENT-SYNC/` is where agents and Christopher leave handoffs, context dumps, and coordination notes for
each other within a repo — separate from the repo's actual working files. `AGENT-SYNC_PUBLIC/` is the
same convention for repos that have a `-public-preview`/`-public` mirror: content that's safe to sync
publicly (e.g. a public-facing changelog of agent-driven work) goes there instead.

## The `created-by-*` subdirectories

Each subdirectory holds material authored by that agent or person — the name tells you who wrote it,
not who it's for:

| Directory | Author |
|---|---|
| `created-by-christopher` | Christopher himself — prompts, direct notes, manual context |
| `created-by-alfred` | Alfred (Claude Code CLI, this repo's system coordinator) |
| `created-by-fortuna` | Fortuna (Claude Code CLI, trading-assistant's domain) |
| `created-by-kavanah` | Kavanah (Augment Intent, spec-driven orchestration) |
| `created-by-mystarch` | Mystarch (Augment Intent, app-level Chief of Staff — `~/intent/workspaces/__chief__`) |
| `created-by-auggie` | Auggie (Augment CLI, code builds) |

Every new repo should start with all 6 present under both `AGENT-SYNC/` and (if the repo has a public
mirror) `AGENT-SYNC_PUBLIC/`, even if empty — `.gitkeep` placeholders exist for exactly this, since git
doesn't track empty directories. Drop the `.gitkeep` once real content lands in a given subdirectory;
add it back if that directory goes empty again (rare, but keeps the skeleton visible either way).

## Setting this up in a new repo

Copy this `AGENT-SYNC/` directory (and `AGENT-SYNC_PUBLIC/` if the new repo will have a public mirror)
from `my-template` or `my-template-clean` when bootstrapping a new repo — don't hand-create the 6
subdirectories individually each time.
