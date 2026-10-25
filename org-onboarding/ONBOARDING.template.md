# 🌱 Welcome to {{ORG_NAME}}

**TL;DR:** you're part of the team. You can build here in plain words, with the AI helpers you already
like.
1. **Accept the invitation.**
2. **Turn on two-factor login.**
3. **Connect a helper.**
4. **Ask for what you want.**

Every change rehearses before it goes live, so nothing you try can break anything.

| | Step | How |
|---|---|---|
| 🚪 | **Accept the invitation** | The email from GitHub, or the notification on github.com, then **Join** |
| 🔐 | **Turn on two-factor login** | github.com → your picture → **Settings → Password and authentication → Enable two-factor authentication**. Save your recovery codes offline |
| 🧰 | **Connect a helper** | Claude Code, Codex, ChatGPT, Littlebird or Cosmos: [the walkthrough](https://github.com/drasticstatic/my-template/blob/main/walkthroughs/JOIN-AN-ORGANIZATION.md) shows each one |
| 🗣️ | **Ask in your own words** | *"On the preview branch, change … Follow AGENTS.md, then open a pull request."* |

## 🏡 How we work

- **`AGENTS.md` is the rulebook:** the house rules every AI helper follows, at the root of each
  repository. Your helper reads it for you; where one is missing yet, this page is the rulebook.
- **Rehearse first.** Where a site has a rehearsal copy, changes go to `preview` and show there first, and
  live changes come only through a "Promote" pull request. Where it doesn't yet, your helper opens a pull
  request for a person to review.
- **Never publish what isn't ours to share:**{{NEVER_PUBLISH_EXTRA}}
  - anyone's recovery or fellowship involvement, or any sponsor relationship;
  - private messages;
  - anyone's personal, medical or legal history.
- **No secrets, ever.** Never paste a password or key into a chat or a file. The secret scan stops one
  that slips through.

## 🛡️ The secret scan (GitGuardian): the one check that stops a commit

- **You don't need your own key to contribute.** Each private workshop repository carries **one** CI key
  (`GITGUARDIAN_API_KEY`, added once by an owner), and it checks every push. That includes changes made on
  GitHub's website or by Codex, which skip checks on your computer.
- **Optional, and nice:** turn on the earlier check on your own computer with a free personal login.
  Run `brew install ggshield` (or `pipx install ggshield`), then `ggshield auth login`.
- **If it stops a commit, a secret is in the change.** Don't bypass it (never `--no-verify`). Ask your
  helper. Every message it can show, and what to do about each, is in
  [The secret scan](https://github.com/drasticstatic/my-template/blob/main/walkthroughs/SECRET-SCAN.md).

## 💬 Be honest with your helper; GitHub keeps only what's meant to be public

You can talk to your AI helper openly, the way you'd think out loud with a trusted friend. Drafts,
doubts, your story, your reasons. **Only what's meant to be shared goes into a repository**: the
rulebook, the safety checks and your own final "yes" make sure of that. A helper that isn't sure asks
first.

## ✍️ Credit (it advises, it never blocks)

When an AI helped write a change, the commit ends with one line naming it, for example:

```
Co-Authored-By: Codex · CodexCloud · OpenAI [<model>]
```

- **No AI helped?** Leave it off; it's recorded as your work.
- The local check only offers a gentle note, and **nobody ever needs `--no-verify`**.
- One good habit keeps the history legible for whoever reads it years from now.

## 🤝 Who to ask

{{WHO_TO_ASK}}

## 🔗 More

- [Many AI tools, one team](https://github.com/drasticstatic/my-template/blob/main/walkthroughs/MANY-AI-TOOLS-ONE-TEAM.md)
- Connect a tool:
  [Firecrawl](https://github.com/drasticstatic/my-template/blob/main/walkthroughs/CONNECT-FIRECRAWL.md) ·
  [Wix](https://github.com/drasticstatic/my-template/blob/main/walkthroughs/CONNECT-WIX.md) ·
  [WordPress](https://github.com/drasticstatic/my-template/blob/main/walkthroughs/CONNECT-WORDPRESS.md) ·
  [Google Drive](https://github.com/drasticstatic/my-template/blob/main/walkthroughs/CONNECT-GOOGLE-DRIVE.md) ·
  [Graphify](https://github.com/drasticstatic/my-template/blob/main/walkthroughs/CONNECT-GRAPHIFY.md)
- [Why we use Augment Cosmos](https://github.com/drasticstatic/augment-intent-properties-public-preview/blob/main/proposals/WHY-COSMOS.md)
  · [How Cosmos Spaces work for us](https://github.com/drasticstatic/augment-intent-properties-public-preview/blob/main/docs/COSMOS-SPACES.md)
- Contributing from outside the organization? See [CONTRIBUTING.md](CONTRIBUTING.md).

<details>
<summary><b>For the AI helper reading this</b></summary>

In any repository of {{ORG_NAME}}:
1. Read `AGENTS.md` first, then sync: `git pull --rebase --autostash`.
2. Work on `preview`. Never commit to `main`, never force-push.
3. Follow the never-publish rule above. When unsure, ask your person before writing anything public.
4. Never paste, commit or ask for secrets. If the secret scan stops a commit or says it was skipped, follow
   [SECRET-SCAN.md](https://github.com/drasticstatic/my-template/blob/main/walkthroughs/SECRET-SCAN.md):
   name the file and line, never the value, and never use `--no-verify`.
5. Build before you finish. Credit your work with the line for your tool and model.
6. Explain the change in plain words and where to see it on the rehearsal copy.

</details>
