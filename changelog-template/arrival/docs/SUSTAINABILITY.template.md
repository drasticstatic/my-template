# 🌱 Sustainability: what keeps these pages running

<!-- Template (arrival kit 1.2). Put the full version at the AstroLog repo's root (it renders at
     /sustainability through the `docs` collection and RepoDoc.astro, and it's allowlisted to the
     public repo), and a short one in the portal repo listing only that repo's items with a link to
     the page. Use absolute links: the file is read on GitHub too. Keep only what's TRUE for this
     org; delete the rest. Worked examples: psanctuary/changelog-astro and
     psanctuarychurch/changelog-astro (SUSTAINABILITY.md). -->

<div class="tldr"><i class="ph ph-plant"></i> <span><strong>TL;DR:</strong> Nothing here costs money. What keeps it alive is a short list of things that quietly expire or drift: one access token, the scheduled jobs, a vendored kit, cached link previews, and a wallet allowlist.</span></div>

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
`arrival.js` + `arrival.css` are copies of `drasticstatic/my-template` →
`changelog-template/arrival/`; `org.js` + `org.css` are this org's. *What to do:* upgrade by copying
the two kit files unchanged; push the portal **before** the AstroLog.

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

### 🔗 Links that leave GitHub
*What to do:* if the org's site, form or community links change, update `arrival/org.js` (nav,
modals) and the AstroLog's `src/data/map.ts`.

## Who looks after it
<Name + last initial>, with Alfred (Claude Code). *Last reviewed YYYY-MM-DD.*
