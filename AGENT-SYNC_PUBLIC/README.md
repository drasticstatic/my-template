# AGENT-SYNC_PUBLIC

Agent coordination that is **safe to publish**.

## Which directory does this repo use?

Decide once, by repository visibility. `scripts/scaffold-agent-sync.sh` makes the choice for you
and creates the right layout.

| | Private repo | Public repo |
|---|---|---|
| `AGENT-SYNC/` | ✅ the coordination lane | ❌ do not create |
| `AGENT-SYNC_PUBLIC/` | ✅ only for material meant to reach the public mirror | ✅ the coordination lane |
| `logs/` | ✅ | ❌ **never** — and no `logs_PUBLIC/` exists |

**Private repo.** `AGENT-SYNC/` is the working lane and is filtered out of the public mirror.
`AGENT-SYNC_PUBLIC/` is optional here — use it only for coordination you intend to publish. Both
live in the private source; the sync pipeline is what separates them.

**Public repo (no private counterpart).** `AGENT-SYNC_PUBLIC/` is the only lane. Repos like
`resume` and `gratitude-token-project_docs` work this way.

## Assume every word here is public

This directory is either already public or explicitly allowlisted to become public. Write
accordingly:

- No infrastructure detail, credentials, tokens, or internal hostnames
- No client, financial, legal, or custody specifics
- No in-progress work you would not want read by a stranger
- Link to private material by **pointer**, never by copying it inline

That last point is the working pattern: a public skill or handoff may reference `specs/…` in a
private repo by path, so the public artifact stays useful as a teaching example while the sensitive
detail stays private.

### Why the rule is written this strictly

Because getting it wrong is silent, and undoing it is not.

Putting internal coordination in a public repo does not error. It does not warn. It publishes, and
nobody notices — in this fleet, several mirrors carried agent coordination and raw exports of
working conversations for months before an audit found them.

What that costs is the part worth knowing in advance. Deleting the files is not a fix: every
previous commit still serves them, so cleanup means rewriting history across every ref, force-
pushing, temporarily lifting branch protection, and invalidating every outstanding clone and fork.
Even then it is not total — a merged pull request's refs are frozen by the host and cannot be
rewritten by anyone, so whatever they captured stays reachable permanently.

A five-second decision about which directory to write into is therefore not reversible by a later
five-second decision. Write as though it is already published, because in practice it is.

## Convention

Files are written **by** one agent, named for the **recipient**, inside the author's own lane:

```
AGENT-SYNC_PUBLIC/created-by-<author>/<RECIPIENT>_PROMPT_YYYYMMDD.md
```

Never add content to another agent's lane — create your own file instead.

## No logs here

`logs/` is private-repo-only and has no public counterpart by design. If you are an agent working
in a public repo and want to record a session log, write it in the corresponding private repo. See
[`logs/README.md`](../logs/README.md).

## Commit attribution applies here too

Public repos carry the same footer as private ones — more importantly, not less, since this is where
outside readers form their impression of how the fleet works:

```
Co-Authored-By: <Agent> · <Engine> · <Provider> [<Model>]
<Platform>-Session: <full session URL>
```

The field definitions are not restated here. They live in
[`AGENT-SYNC/README.md`](../AGENT-SYNC/README.md), which is publicly readable, and
`.githooks/commit-msg` enforces them. One spec, one copy.

## If this repo is a generated mirror

Some public repos are built from a private source by a `sync-public.yml` workflow rather than
edited directly. In those, **an edit made here is lost on the next sync** — change the private
source instead. If you are unsure which kind you are in, check for `.github/workflows/sync-public.yml`:
its presence means this repo is a *source*, its absence in a repo that obviously mirrors one means
this is the *output*.

## Outside contributors

If you have arrived from a fork — for example a harness fork running on your own API key — the
first thing you meet may be a rejected commit, before you have read any of this. That is a blunt
introduction, so the hook's error message prints the public URL of the spec rather than a path
inside a repo you may not be able to open.

Your footer names **you** in the Agent field and the harness you actually used in the Engine field.
It does not need a new field for whose key paid; that is a billing fact, and the footer records
which model wrote the code. Worked example in
[`AGENT-SYNC/README.md`](../AGENT-SYNC/README.md) § *Forked harnesses and outside collaborators*.

Human-only commit with no agent involved? `git commit --no-verify` is the intended path, not a
workaround.
