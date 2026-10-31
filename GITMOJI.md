# Gitmoji — the fleet's commit subject convention

**Decided 2026-10-31. Warn-only: a commit that doesn't follow it still lands, with a one-line hint.**

A commit subject starts with **one gitmoji in its colon-alias form**, then a
[conventional commit](https://www.conventionalcommits.org/) type, an optional scope, and the subject:

```text
:sparkles: feat(scope): what the change does
```

```text
:bug: fix(calendar): events keep their time zone
:memo: docs(sop): SOP-OPS-002 lists the merge-commit-only repositories
:truck: move(assets): banners move under assets/banners/
```

This page is the single source of truth for the subject line. The **footer** (the attribution
trailers) has its own single source, [`AGENT-SYNC/README.md`](./AGENT-SYNC/README.md), and has not changed.

---

## The twelve

Each gitmoji goes with one type. These are the ones the fleet actually uses. Twelve is a short enough
list to remember, and long enough that nobody has to stretch one to fit.

| Gitmoji | Alias | Type | Use it for |
|---|---|---|---|
| ✨ | `:sparkles:` | `feat` | something new a reader or user can see or use |
| 🐛 | `:bug:` | `fix` | something that was wrong, now right |
| 📝 | `:memo:` | `docs` | documentation, SOPs, READMEs, CLAUDE.md, plans |
| ✅ | `:white_check_mark:` | `test` | tests, checks and their fixtures |
| 🔒 | `:lock:` | `security` | secrets hygiene, access, gates, privacy fixes |
| ♻️ | `:recycle:` | `refactor` | same behaviour, better shape |
| 🔧 | `:wrench:` | `config` | settings, workflows, hooks, tooling config |
| 🚀 | `:rocket:` | `deploy` | a publish, a Pages build, a Promote's follow-through |
| 🔖 | `:bookmark:` | `release` | a release or version tag |
| ⏪ | `:rewind:` | `revert` | a hand-written revert (git's own `Revert "…"` is exempt) |
| 🚚 | `:truck:` | `move` | files moved or renamed (say where they went in the body) |
| 🚧 | `:construction:` | `wip` | work in progress, pushed so it isn't lost |

A scope is optional: `:wrench: config: …` is fine. A `!` after the type or scope marks a breaking
change, as conventional commits do: `:sparkles: feat(api)!: …`.

## Why the alias form (`:sparkles:`), not the glyph (✨)

- **It survives every terminal and every host.** A colon alias is plain ASCII. It reads the same in
  a macOS terminal, an SSH session, a Windows console, a CI log, an email patch and the GitHub web
  UI, which draws it as the glyph anyway. A raw glyph can turn into `?`, a box or mojibake on the
  way, and some emoji differ only by an invisible variation selector (♻ vs ♻️), so two commits that
  look the same can be stored differently.
- **It's greppable.** `git log --grep '^:bug:'` and `git log --oneline | grep ':truck:'` work
  everywhere with no Unicode escaping. The type that follows (`fix`, `move`) means the subject
  still reads to anyone who doesn't know the emoji.

A glyph-form subject (`✨ feat: …`) is **accepted**: the hook recognises the twelve glyphs and only
suggests the alias.

## Exempt

Commits that git or a tool writes for you are never checked:

- `Merge …` (merge commits, including `Merge pull request #…` and every Promote)
- `Revert "…"` (git's own revert message)
- `fixup! …`, `squash! …`, `amend! …` (autosquash markers)

## What stays the way it was

- **AstroLog priority markers** stay a separate marker, never fused into the gitmoji. Put `[P1]` /
  `[P2]` / `[P3]` **straight after the type**, where the ledger already looks for it
  ([`changelog-template/docs/REFERENCE.md`](./changelog-template/docs/REFERENCE.md), "Commit priority
  convention"):

  ```text
  :bug: fix(calendar): [P2] events keep their time zone
  ```

  The ledger's priority glyphs (🚨 `:rotating_light:`, 🔥 `:fire:`, ⚡ `:zap:`, 🍃 `:leaves:`) are
  **not** in the twelve and must not be used as the type gitmoji. The ledger would read them as a
  priority, not a kind.
- **Approval tags stay git tags.** An approval is recorded with `git tag`, not in a subject line;
  `:bookmark: release` is for the commit that a release or version tag points at.
- **Attribution trailers are unchanged.** `Co-Authored-By: <Agent> · <Engine> · <Provider> [<Model>]`
  and `<Platform>-Session: <url>`, exactly as in [`AGENT-SYNC/README.md`](./AGENT-SYNC/README.md). The
  hook still **rejects** a bad footer. The gitmoji check runs only after that check passes, and it
  only ever **warns**.

## The hook

`.githooks/commit-msg` runs the attribution check first, unchanged. When that check passes it calls
`.githooks/gitmoji-check.sh`. That script reads the subject and, if the subject doesn't follow this
page, prints **one line** such as:

```text
  ⚠ gitmoji: subject has no gitmoji; start it like ':sparkles: feat(scope): subject' (GITMOJI.md)
```

It always exits 0. Nothing is blocked. It's activated with the attribution hook, by the same
one-time `sh scripts/install-hooks.sh` per clone. The fleet rolls it out when Christopher says.

Tests: `sh scripts/test-gitmoji.sh` (valid, missing gitmoji, unknown gitmoji, wrong type for the
gitmoji, merge, revert, fixup/squash/amend, glyph form, priority marker placement, and the
attribution check still rejecting and passing as before).

## Finding things later

```sh
git log --oneline --grep '^:bug:'            # every fix
git log --oneline --grep '^:truck:'          # every move: where did that file go?
git log --oneline --grep '^:lock:' --since=2026-10-01
git log --format=%s | grep -oE '^:[a-z_]+:' | sort | uniq -c | sort -rn   # what the fleet writes most
```
