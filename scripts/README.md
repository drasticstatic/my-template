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
Co-Authored-By: <Agent> · <Engine> · <Provider> [<Model>]
<Platform>-Session: <full session URL>
```

Four fields, model in square brackets, separator `·` (U+00B7 MIDDLE DOT — not a hyphen). Real
examples:

```
Co-Authored-By: Fortuna · ClaudeCodeCLI · Anthropic [Sonnet-5]
Claude-Session: https://claude.ai/code/session_01XHntH8UvqXQPq2zNkQMe6q

Co-Authored-By: Cosmos-Advisor · Cosmos · Anthropic [Claude Opus 5]
Cosmos-Session: https://cosmos.augmentcode.com/session?agentId=01M27N...
```

Two rules people get wrong:

- **The session must be its own line.** Folding it onto the `Co-Authored-By:` line stops both from
  parsing as git trailers, which defeats the point — the footer exists so `git log` can be queried by
  author and session, not just read by humans.
- **Use the full session URL**, never a truncated prefix. A prefix is not resolvable later.

The `Co-Authored-By:` trailer is **required**. The `<Platform>-Session:` trailer is **advisory** —
the hook warns but allows, since not every engine assigns a session ID. If yours does, include it.

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
