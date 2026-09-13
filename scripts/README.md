# `scripts/`

Setup scripts for this template. Two of them matter when bootstrapping a repo or onboarding an
agent; run both once per clone.

---

## `install-hooks.sh` — activate the commit-attribution hook

```sh
sh scripts/install-hooks.sh
```

Run this **once per clone**, including fresh clones of a repo that already has the hook committed.

### Why it needs running at all

Git deliberately does not version-control hooks. `.git/hooks/` is local-only, and for good reason —
a repository that could ship executable code which runs automatically on `git commit` would be an
obvious attack vector against anyone who cloned it.

So a hook committed to the repo is inert by default. The script does the one thing that cannot be
done for you:

```sh
git config core.hooksPath .githooks
```

That points this clone at the version-controlled `.githooks/` directory. It is a local config write,
which is why *you* have to run it — and why an agent working in a fresh clone should run it before
its first commit rather than discovering the convention through a rejection.

### What the hook enforces

`.githooks/commit-msg` rejects any commit whose message lacks the fleet attribution footer:

```
Co-Authored-By: <Agent> · <Engine> · <Provider> [<Model>]                  # direct
Co-Authored-By: <Agent> · <Engine> · <Gateway> · <Provider> [<Model>]      # proxied
<Platform>-Session: <full session URL>
```

**The field definitions live in exactly one place and are deliberately not repeated here:**
[`AGENT-SYNC/README.md`](../AGENT-SYNC/README.md). That file documents the *convention*; this one
documents the *scripts*.

The split is not tidiness. This file used to restate the whole field table, and when the convention
gained a Gateway field, this copy was missed — it spent a release telling readers to write
`NVIDIA NIM` in the Provider slot, which credits a router for work it did not do. A second copy of a
spec is a second thing to forget.

What the hook *does*, as distinct from what the convention *says*:

| Outcome | Trigger |
|---|---|
| **Reject** | The shape is wrong — no footer, hyphens instead of `·`, missing `[Model]`, too few fields |
| **Warn** | The shape is fine but the content looks wrong — five semantic checks |
| **Pass** | Merge, revert, fixup and squash commits are exempt |

It rejects on shape and only warns on meaning, deliberately. The footer's job is to record what
happened; a hook that blocks an honest-but-unusual record just teaches agents to write a tidy false
one.

### Escape hatches

```sh
git commit --no-verify     # human-only commit, bypasses the hook
```

Use it for your own commits. An agent bypassing this hook is a problem: the footer is how a change
is traced back to the run that produced it, which matters most precisely when something went wrong.

### Why attribution is enforced rather than requested

A convention documented in a README gets followed until someone is in a hurry. With several agents
and a human committing to 40 repositories, "mostly attributed" history is not much better than
unattributed — you cannot tell whether a missing footer means a human wrote it or an agent skipped
it. A hook makes the convention true by construction instead of by diligence.

---

## `scaffold-agent-sync.sh` — create the right coordination layout

```sh
sh scripts/scaffold-agent-sync.sh            # detect visibility automatically
sh scripts/scaffold-agent-sync.sh --private  # or state it explicitly
sh scripts/scaffold-agent-sync.sh --public
```

Creates the correct agent-coordination directories for the repository's visibility, because the
choice is not cosmetic:

| | Private repo | Public repo |
|---|---|---|
| `AGENT-SYNC/` | the coordination lane | **never** — internal handoffs would be world-readable |
| `AGENT-SYNC_PUBLIC/` | not used | the coordination lane |
| `logs/` | private session timeline | **never** |

Visibility is detected via `gh`, then an anonymous API call, then a naming heuristic — in that order,
so it still works without a GitHub token. Pass `--private` or `--public` to skip detection.

### The trap this script exists to prevent

Getting it wrong is silent. Committing `AGENT-SYNC/` to a public repo does not error; it publishes
internal agent coordination and nobody notices. That is not hypothetical — it happened across five
repositories in this fleet, and exports of working conversations sat publicly readable for months
before an audit caught them.

If your repo publishes through a sync workflow, note the related trap: **a new root directory must be
classified in `.github/workflows/sync-public.yml` in the same commit.** Under an allowlist model an
unclassified directory fails the next sync; under an exclude model it silently publishes. The second
is worse.

---

## Before you start work in an existing clone

Fetch first, and do it in a way that cannot lose uncommitted work:

```sh
git pull --rebase --autostash
```

With several agents and a human pushing to these repos, a clone goes stale quickly — and a stale
clone does not fail loudly. It fails at push time, after the work is done, as a non-fast-forward
rejection. `--autostash` stashes uncommitted changes, rebases, and reapplies them, so running it is
safe even with a dirty working tree.

See `AGENTS.md` § *Start of session* for the full rule.
