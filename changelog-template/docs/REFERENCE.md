# 📐 AstroLog reference: the convention, the schema, and setting it up

**TL;DR:** the working rules for an AstroLog, the public-safe changelog site:
- what goes in it,
- the frontmatter every entry carries,
- the commit-priority emoji,
- where an org's public repo lives,
- how to stand one up.

This page holds, word for word, the reference sections that used to open the kit's
[README](../README.md). The story of how the kit grew lives in [JOURNEY.md](JOURNEY.md).

## What this is

**What this is:** a reusable pattern for a public-safe, browsable changelog site, so every project
doesn't reinvent this from scratch. Two proven pieces, combined:

1. **Astro content collections** for markdown-as-pages (`content.config.ts` + `glob()` loader +
   `index.astro`/`[slug].astro`) — the exact mechanism already proven in
   `littlebird-ambassador/astro/src/pages/proposals/`, generalized here for changelog entries with
   a priority-tagged frontmatter schema.
2. **`sync-public-allowlist.yml`** (`../workflow-templates/sync-public-allowlist.yml`) — the
   existing private→public sync workflow. For a changelog site, the Astro build happens first, the
   entire source tree (including your raw changelog markdown) gets stripped, and only the compiled
   static HTML reaches the public repo. Your changelog markdown source, and anything else private,
   never leaves the private repo.

First real builds: `pir/changelog-astro` and `the-holy-earth-foundation/changelog-astro`
(2026-09-23). Read those for a working example before adapting this template — copying a real,
working instance is usually faster than assembling the template pieces from scratch.

## The convention: confirmed-done + public-safe → straight to changelog

Most of this fleet's projects track open work in a `pending-tasks.md`/`PENDING-TASKS.md` file, and
several of those files already had a stated-but-unused intent: "move done items to a dated
changelog section... once this file gets long." **Once a project has a changelog site set up, that
intent is fulfilled directly** — a confirmed-complete, public-safe item gets a real changelog entry
(a new `.md` file in the project's `changelog/` directory), and the tracker gets a one-line pointer
to it instead of accumulating an internal holding section. Two different documents for two
different audiences, linked rather than duplicated:

- **The private technical record** (`FOOTER-RECONNAISSANCE.md`-style docs, `AGENT-SYNC/` handoffs,
  raw debugging trails) stays exactly where it already lives, in full detail, forever private.
- **The changelog entry** is a short, deliberately-curated, public-safe summary — what happened and
  why it mattered, not the blow-by-blow. If something genuinely can't be described publicly at all,
  it simply doesn't get an entry; there's no obligation to write around a gap.

This is never an automatic mirror of private repo content. Someone (an agent or Christopher)
writes each changelog entry as a real editorial step, the same way a human would write release
notes — not a script that dumps git log into markdown.

## Frontmatter schema

```yaml
---
title: "Header now reappears on scroll-up, mobile and desktop"
date: "2026-09-23"
priority: "P1-high" # P1-high | P2-medium | P3-low, default P2-medium
repo: "wordpress" # which contributing repo this entry belongs to — powers the /changelog picker
org: "pir" # optional — only needed for a shared multi-project site, see below
---
```

**Why priority is frontmatter, not a commit-message prefix:** Christopher's own research this
session covered conventional-commit priority prefixes (`fix(P1-high): ...`), which fit teams
already using GitHub Issues/Jira to manage priority. This fleet uses neither right now, and
retrofitting every future commit message across every repo would be disruptive for a benefit that
only matters at the curated-changelog layer. Scoping priority to changelog frontmatter gets the
same visible-at-a-glance benefit (a badge on the entry, sortable/filterable) without touching commit
hygiene at all. If the fleet ever does adopt GitHub Issues/Jira, this can be revisited — not before.

## Commit priority convention (optional; the ledger reads it)

Revisited 2026-10-13 for ledger v2, without making it a rule: a commit **may** carry a priority
prefix, and the ledger shows it as a small badge (the tag itself is stripped from the summary).
Untagged commits get no badge, so nothing breaks for commits that don't use it.

```text
[P2] fix(calendar): events keep their time zone

Why P2: members saw the wrong start time on two events this week; nothing was lost.
```

- **Format:** `[P1]` / `[P2]` / `[P3]` first, matching the frontmatter's `P1-high` / `P2-medium` /
  `P3-low`, then the usual `type(scope): short description`. The gitmoji form works too:
  🚨 critical, 🔥 high, ⚡ medium, 🍃 low (`🔥 fix: …`).
- **Why this priority** goes in the body, one line. The subject stays a plain description.
- On a private repository the badge still shows (with the kind, day and repository); the words don't.

## Org-owned vs. personal-repo changelogs — where the public repo lives

This matters and is easy to get backwards:

- **A community/multi-owner GitHub org project** (PIR, THEF) gets its public changelog repo pushed
  *into that org* — e.g. `psychedelicsinrecovery/changelog-astro-public`,
  `theholyearthfoundation/changelog-astro-public`. The private source repo still lives under
  Christopher's own `~/code/<project>/changelog-astro`, but the *published* output belongs to the
  community, alongside that org's other public repos (its own `.github.io` Pages site,
  `wordpress-crawls`-style archives, etc.) — matching how those orgs already do things.
- **A personal `drasticstatic`-owned project** (dappU/Ethereal Offering, O-R-G, and anything else
  without a separate community org) gets its public repo under personal `drasticstatic`, same as
  every other `-public-preview` pair already in the fleet (`littlebird-ambassador-public-preview`,
  `anthropas-argus-alfred-public-preview`, `gratitude-token-project_astro-public`, etc.).

The private source location and the astro/content-collection mechanism are identical either way —
only the *push target* in `sync-public-allowlist.yml`'s final step differs.

## Setting this up in a new project

1. Copy `content.config.ts`, `index.astro`, `[slug].astro` from this directory into your project's
   `astro/src/content.config.ts` and `astro/src/pages/changelog/` (merge `content.config.ts` if the
   project already defines other collections, don't overwrite).
2. Create a `changelog/` directory at the project root, a sibling of `astro/` — not inside it. This
   is what keeps raw entries private-source-only; see the comment in `content.config.ts`.
3. Copy `../workflow-templates/sync-public-allowlist.yml` into `.github/workflows/`, following the
   Astro-build variant pattern in `littlebird-ambassador/.github/workflows/sync-public.yml`: build
   the site, stash `dist/`, strip source (add `"changelog"` and `"astro"` to `private_allowlist`),
   restore `dist/`, push. Point the final push step at the correct target repo per the
   org-vs-personal rule above.
4. **Required: copy `base-links.mjs` into `astro/src/plugins/` and wire it into `astro.config.mjs`.**
   On a GitHub Pages *project* site the base is the repo path (e.g. `/changelog-astro-public`), and
   Astro does **not** add `base` to links inside Markdown. Without this plugin, every base-less
   internal link an author writes (`[see this](/library/some-doc)`) resolves to the **org root** and
   404s — PIR shipped exactly that bug until 2026-10-11. The plugin prefixes the base onto
   root-relative `<a href>`/`<img src>` in Markdown at build time and leaves external, `//`,
   `#anchor`, relative and already-based URLs alone, so authors keep writing base-less links with
   no trailing slash. It's a **Sätteri hast plugin**, not rehype: Astro 7's default Markdown engine
   is Sätteri, and rehype plugins only run if you swap to the unified processor.
   ```js
   import { satteri } from "@astrojs/markdown-satteri"; // add it to package.json at the version
   import { baseLinks } from "./src/plugins/base-links.mjs"; // your lockfile already resolves
   const BASE = "/changelog-astro-public";
   export default defineConfig({ base: BASE, trailingSlash: "never",
     markdown: { processor: satteri({ hastPlugins: [baseLinks(BASE)] }) } });
   ```
   Verify after building: `grep -rhoE '(href|src)="/(library|changelog)/' astro/dist` must print nothing.

   **The other required pieces** (each one broke something live before it was added):
   - **`astro/public/.nojekyll`** (an empty file). GitHub Pages runs Jekyll, which silently drops
     any `_`-prefixed directory, and Astro emits CSS/JS past its inline threshold into `_astro/`.
     Without this the live site loses its styles with no build error (THEF, `46ae8bf`). Check
     `ls -a astro/dist | grep nojekyll`, and after deploy fetch one `_astro/*` file for a 200.
   - **TL;DR card as block layout, not flex.** `.tldr { display: block; }` with the icon absolutely
     positioned in the left padding. A flex row wraps the label and text into vertical columns on
     narrow screens.
   - **Footer/dock as one swipeable row on phones**: `overflow-x: auto`, hidden scrollbar,
     `white-space: nowrap` items, short labels below ~520px. Wrapping it into several lines eats
     the bottom of the screen on a phone.
   - **Absolute asset and link paths on org-root pages** (`<org>.github.io` `index.html` and
     `404.html`): `/favicon.svg`, `/`, full URLs. The org-root 404 is served for *every* missing
     path at any depth, so a relative `index.html` or `favicon.svg` resolves under the bad path and
     loops into another 404.
5. Adjust the `Base` import path in `index.astro`/`[slug].astro` to your project's own layout, and
   re-skin the inline `<style>` blocks to match your project's look — the collection-query logic
   and priority-badge markup are the reusable part, the visual design is meant to differ per
   project ("front ends look a bit tastefully different in appearance, but the backend logic is
   the same" — the whole point of building this as a template).
6. Add one entry (real, not placeholder) to prove it end-to-end before considering the setup done.

