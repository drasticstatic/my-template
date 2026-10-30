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

## The hook-in note

The members' page (`.github-private/profile/members-section.md`) opens with one purple
`> [!IMPORTANT]` box: **how to bring your AI helper in, in three steps**. It's the first thing a member
sees when signed in, so nobody has to hunt for it.

1. **Connect it to GitHub:** a link to [JOIN-AN-ORGANIZATION.md](../walkthroughs/JOIN-AN-ORGANIZATION.md),
   plus the one ChatGPT line (connect **GitHub** from the apps list).
2. **A first message to paste:** read the org's `ONBOARDING.md`, then the working repo's `AGENTS.md`, and
   say what it will do before changing anything.
3. **Ask in your own words:** every change goes to a pull request a person reviews.

Below it, a one-line `<sub>` note: an owner may need to approve the helper and choose its repositories,
plus the org's own public-safety line. Keep the green `[!TIP]` box for "What's happening" (proposals), so
the two colours always mean the same thing.

**When a person needs more:** write a `WELCOME-FOR-YOUR-HELPER.md` in `.github-private`, beside the
members' page, and name it first in step 2's prompt. THEF's (for Kenney's ChatGPT) is the model: TL;DR,
a word about names when two helpers share one, what to read in order, the house rules short, how to hand
answers back, which repositories the connector reaches and how an owner adds one, ready prompts, and a
plain-words table. Keep it in `.github-private`, not a site repo, so every helper finds it in one place;
leave a short "this has moved" page at any old address. The connector must reach `.github-private`
for the helper to read it.

## Rolled out

| Organization | `ONBOARDING.md` | Hook-in note | Notes |
|---|---|---|---|
| The Holy Earth Foundation | ✅ 2026-10-25 | ✅ 2026-10-29, for Kenney | Site repos carry `AGENTS.md` and the advisory hook at Genesis. `WELCOME-FOR-YOUR-HELPER.md` in `.github-private` |
| Psychedelics in Recovery | ✅ 2026-10-25 | ✅ 2026-10-29 | Anonymity first in its welcome |
| Psanctuary | ✅ 2026-10-25 | ✅ 2026-10-29 | |
| Psanctuary Church | ✅ 2026-10-25 | ✅ 2026-10-29 | |
| Octagon Religious Research Group | ✅ 2026-10-25 | ✅ 2026-10-29 | |

See also: [walkthroughs/](../walkthroughs/) · [BUILD_YOUR_OWN_FLEET.md](../BUILD_YOUR_OWN_FLEET.md)

## The `legal` repository

Every organisation also gets one private repository named `legal` (entity, tax, filings, counsel, policies): the convention is in [LEGAL-REPO.md](LEGAL-REPO.md). Proposals ask; `legal` keeps.
