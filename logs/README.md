# logs/ — fleet session logs

**Private repos only.** See "The public case" below before copying this anywhere.

Second area of confluence. When a handoff is missing something, look here.

`AGENT-SYNC/` answers *"what should the next agent do?"* — curated, forward-looking, written for a
recipient. `logs/` answers *"what actually happened, and when?"* — chronological, append-only,
written for whoever is reconstructing a timeline later. Neither replaces the other. A handoff that
omits a decision is normal; the log is where the decision stays recoverable.

## Layout

```
logs/
  <agent>/YYYY/MM-Mon/session_YYYYMMDD_<engine>.md
```

`<engine>` distinguishes runs of the same agent on different backends — `anthropic`, `nvidia`,
`cosmos`. Matches the pattern Fortuna's `session-sync` skill already writes in `trading-assistant`,
so a reader moving between repos does not learn a second scheme.

## Entry format

```markdown
## YYYY-MM-DD — <session type: live / analysis / infra / skills / setup / cross-repo>
- What was accomplished
- Key decision or outcome
- Commit: <short hash> — <message>
```

Append to the day's file if one exists rather than creating a second. Keep entries short — the
commit and the handoff carry the detail; the log carries the sequence.

## When to write one

At minimum: any session that changed infrastructure, deployed or reconfigured an agent, made a
decision another agent would otherwise have to re-derive, or ended with work in progress.

Routine single-file commits do not need an entry. If unsure, write it — a redundant log line costs
nothing; a missing one costs someone an archaeology session.

## The public case — no `logs/`, and no `logs_PUBLIC/`

This is the half of the convention that is easy to get wrong.

`AGENT-SYNC/` has a public counterpart, `AGENT-SYNC_PUBLIC/`, for material that is *meant* to reach
the public mirror. **`logs/` has no such counterpart, by design.** There is no `logs_PUBLIC/` and
one should never be created.

Session logs routinely name infrastructure, in-progress work, client details, and financial or
legal context. Unlike a handoff, nobody writes them with an outside reader in mind — which is
exactly what makes them useful internally and unsafe externally.

So:

| | Private source repo | Public mirror |
|---|---|---|
| `AGENT-SYNC/` | ✅ | ❌ denylisted |
| `AGENT-SYNC_PUBLIC/` | ✅ | ✅ syncs out |
| `logs/` | ✅ | ❌ denylisted — **no public counterpart exists** |

`logs/` is already denylisted in both filter layers — `.github/workflows/sync-public.yml`
(authoritative) and `gitexporter.config.json` (local preview mirror of it). If you add `logs/` to a
repo that syncs outward, confirm both still list it. If you create a new private repo from this
template, that exclusion is already inherited.

**Agents:** if you are working in a repo whose name ends in `-public`, `-public-preview`, or
`_astro-public`, do not create `logs/` there. Write the log in the private source repo instead.

---

*Convention established 2026-09-11. Attribution and handoff conventions: `AGENT-SYNC/README.md`.*
