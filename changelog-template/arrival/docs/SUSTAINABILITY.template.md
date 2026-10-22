# 🌱 Sustainability: what keeps these pages running

<!-- Template (arrival kit 1.4). Put the full version at the AstroLog repo's root (it renders at
     /sustainability through the `docs` collection and RepoDoc.astro, and it's allowlisted to the
     public repo), and a short one in the portal repo listing only that repo's items with a link to
     the page. Use absolute links: the file is read on GitHub too. Keep only what's TRUE for this
     org; delete the rest. Worked examples: psanctuary/changelog-astro and
     psanctuarychurch/changelog-astro (SUSTAINABILITY.md). -->

<div class="tldr"><i class="ph ph-plant"></i> <span><strong>TL;DR:</strong> Nothing here costs money. What keeps it alive is a short list of things that quietly expire or drift: one access token, the scheduled jobs, a vendored kit, cached link previews, and a wallet allowlist. And today one person holds most of the keys, so there's a plan to change that.</span></div>

## The pieces

| Repository | What it is | How it goes live |
| --- | --- | --- |
| `<ORG>.github.io` (public) | The entry portal and the arrival kit every page loads | GitHub Pages, from `main` |
| `changelog-astro` (private) | The AstroLog's source | A workflow builds it and publishes only the finished pages |
| `changelog-astro-public` (public) | The built AstroLog | GitHub Pages, from what the workflow pushes |

## What can quietly stop, and what to do

### 🔑 The publishing token (`PUBLIC_REPO_TOKEN`)
A classic personal access token, stored on `changelog-astro`, pushes the build into
`changelog-astro-public`. When it expires, **the site stops updating with no sign on the site
itself**. It also lets the ledger read the private lane (masked). *What to do:* renew before the
expiry date (`repo` + `workflow` scopes), update the secret, run the workflow once by hand.

### 🗓️ The daily ledger rebuild
The publish workflow also runs on a schedule (`cron: "MM 10 * * *"`, UTC) so the ledger stays fresh.
*What to do:* if the ledger's newest day looks old, read the workflow's run history.

### 🪞 The hourly README mirror
The portal's `README.md` copies the org profile (`<ORG>/.github`) every hour. GitHub switches off
scheduled workflows in a public repository after 60 days without activity. *What to do:* edit the
profile, not the copy; re-enable the workflow if it stops.

### 🧰 The arrival kit is vendored
`arrival.js`, `arrival.css`, `give/give.js` and `pledge/pledge.js` are copies of
`drasticstatic/my-template` → `changelog-template/arrival/`; `org.js` + `org.css` are this org's.
*What to do:* upgrade by copying the kit files unchanged; push the portal **before** the AstroLog.
The pledge (kit 1.4) pins its signature checker (`@noble/curves@1.9.7`, `@noble/hashes@1.8.0`, from
jsDelivr); upgrade those in the kit, not here.

### 🖼️ Cached link previews
Apps cache a link's share image for days or weeks. Cards never carry counts. *What to do:* after a
card changes, refresh important links (Telegram: @WebpageBot; LinkedIn and Facebook inspectors).

### 👛 Wallet giving (kit v1.3, `arrival/give/give.js`)
`/donate/` has the kit's wallet module: one Connect button (Reown AppKit) for browser wallets, phone
wallets by QR code, and email or social sign-in. It only works on sites listed in the Reown project's
allowlist. *What to do:* make sure the project in `give.reownProjectId` (`arrival/org.js`) lists
**`https://<ORG>.github.io`** at dashboard.reown.com; until it does, the page calmly says "Wallet
connect isn't switched on for this site yet". `give.addresses` stays `null` until the org publishes a
treasury address: never a placeholder. AppKit is pinned (`@reown/appkit-cdn@1.8.24`); upgrade it in
the kit, not here.

### 🔌 Wallet connect (Reown project)
Every org's wallet features (giving with crypto, and the kit 1.4 pledge of support) connect through
**one shared Reown project today: `00b6a1cd528ff580f1fd845ed08b0187`**, made for the O-R-G dApp and
held in Christopher W's Reown account. Its allowlist lists all five org origins plus
`https://drasticstatic.github.io`. If that project is deleted, suspended or runs past its free-plan
limit, wallet connect stops on every site at once (each page then says so calmly; nothing breaks).
*What to do:* an org gets its own project with a **one-line `org.js` change**: create a free project
at dashboard.reown.com under an account the org controls, add `https://<ORG>.github.io` to its
allowlist, and set `give.reownProjectId` in `arrival/org.js` to the new ID (the pledge uses it too,
unless `pledge.reownProjectId` is set). Do it before the org publishes a treasury address.

### 🔗 Links that leave GitHub
*What to do:* if the org's site, form or community links change, update `arrival/org.js` (nav,
modals) and the AstroLog's `src/data/map.ts`.

## 🤝 Stewardship and succession

**Today, one person holds most of the keys.** drasticstatic (Christopher W) owns or administers the
GitHub organizations behind these pages, and holds the personal access tokens that publish them
(`PUBLIC_REPO_TOKEN` and its siblings) and the Reown account above. That's a single point of failure:
if he stepped away, tokens would expire on schedule and the sites would quietly stop updating, with
nobody else able to renew them. The plan, so these pages outlive any one person:

1. **At least two owners per GitHub organization**, from the org's own people, each with two-factor
   sign-in. Owners can do everything; give everyone else the narrowest role that works.
2. **Org-owned automation, not personal tokens.** Publishing moves to a GitHub App installed on the
   org (short-lived tokens, scoped to the repositories it needs), or failing that a dedicated org bot
   account whose credentials the owners share. No workflow should depend on one person's account.
3. **A token register**: every token, key and secret the sites use, with what it does, which
   secret holds it, who owns it, its scopes and its expiry date, kept where every owner can read it
   (never the values themselves).
4. **A renewal runbook**: for each item in the register, how to renew it, step by step, and a
   reminder a month before each expiry date.
5. **Documented hand-over steps**: how to add an owner, transfer a repository, move the custom
   domains, transfer the Reown project (or create the org's own), and remove someone who's leaving.
6. **Exports and backups**: the repositories (with their issues and history) cloned or exported
   somewhere the org controls, on a schedule; the same for anything that lives outside GitHub
   (forms, community platforms, mailing lists).

Progress on each step is on the [roadmap](https://<ORG>.github.io/changelog-astro-public/roadmap).

## Who looks after it
<Name + last initial>, with Alfred (Claude Code). *Last reviewed YYYY-MM-DD.*
