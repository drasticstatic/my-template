# 🌱 Organization onboarding kit

**TL;DR:** the same welcome for every GitHub organization we look after, so every newcomer (and every
newcomer's AI helper) lands on solid, friendly ground.

| File | Where it goes | What it does |
|---|---|---|
| [`ONBOARDING.template.md`](ONBOARDING.template.md) | the org's `.github` repo as `ONBOARDING.md`, linked from the profile and from `CONTRIBUTING.md` | Welcomes members: invitation, two-factor login, connecting a helper, house rules, credit, who to ask |
| [`AGENTS.template.md`](AGENTS.template.md) | each repository's root as `AGENTS.md` | The rulebook every AI helper reads |
| [`githooks/commit-msg.advisory`](githooks/commit-msg.advisory) | each repository as `.githooks/commit-msg` | Suggests the credit line and **never blocks**, so nobody needs `--no-verify` |
| [`githooks/pre-commit`](githooks/pre-commit) | each repository as `.githooks/pre-commit` | Runs the secret scan (ggshield), the one check that does stop a commit |

## Why it's shaped this way

- **Structure without friction.** The credit line keeps the history legible for anyone looking back, but a
  person or helper should never be stopped by it. Only real secrets stop a commit.
- **One rulebook, read by every tool.** Codex reads `AGENTS.md` natively, and Claude Code's `CLAUDE.md`
  points to it. Cursor and Cosmos are told to.
- **Honest in chat, careful in public.** People can think out loud with their helpers. The never-publish
  rule and the safety checks decide what reaches GitHub.

## Rolled out

| Organization | `ONBOARDING.md` | Notes |
|---|---|---|
| The Holy Earth Foundation | ✅ 2026-10-25 | Site repos carry `AGENTS.md` and the advisory hook at Genesis |
| Psychedelics in Recovery | ✅ 2026-10-25 | Anonymity first in its welcome |
| Psanctuary | ✅ 2026-10-25 | |
| Psanctuary Church | ✅ 2026-10-25 | |
| Octagon Religious Research Group | ✅ 2026-10-25 | |

See also: [walkthroughs/](../walkthroughs/) · [BUILD_YOUR_OWN_FLEET.md](../BUILD_YOUR_OWN_FLEET.md)
