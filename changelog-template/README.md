# Changelog template — fleet-wide convention

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

## Future adopters (breadcrumbed, not built — 2026-09-23)

- **`O-R-G`** already has the right instinct half-built: `O-R-G-astro`/`O-R-G-astro-public`'s own
  README states "changelog-as-content... rendered as a public, browsable site" but it was never
  finished (placeholder page only, no content collection). When O-R-G is ready, finish that
  existing scaffold using this template rather than starting a second, separate site.
  **Done differently (2026-10-11/12):** ORG got its own org-owned AstroLog
  (`Octagon-Religious-Research-Group-ORG/changelog-astro`), and `O-R-G-astro` became the
  *drasticstatic ORG lab*, Christopher's changelog and portfolio of work for ORG, with its
  sidecar-era entries kept as history. See wave 4 below.
- **dappU/Ethereal Offering** (`gratitude-token-project` — already using the sync-workflow's
  allowlist model, per `sync-public-allowlist.yml`'s own comment header) is a personal-repo
  candidate for this template "when we get there with Mystarch."
- **`psanctuarychurch/`** — not yet a real GitHub org (placeholder only, per
  `~/code/README.md`'s org-vs-personal notes). Tripp (O-R-G) is a friend of Psanctuary the way
  Kenney (THEF) is a friend of PIR — worth keeping in mind if/when Psanctuary's work professionalizes
  into its own community org the way THEF and PIR already have.

## 🎁 The richer pattern, proven out 2026-09-24 (PIR + THEF)

Once a project outgrows a single flat changelog list, this is the real, working shape both PIR and
THEF now use — copy it wholesale rather than reinventing:

- **`/changelog` is a repo picker, not a flat list.** Add `repo` to the frontmatter schema (above).
  `changelog/index.astro` shows one card per contributing repo; `changelog/[repo]/index.astro` is
  the filtered listing for that repo; `changelog/[repo]/[slug].astro` is the entry, with prev/next
  links computed at build time from that repo's own date-sorted list. Repos that don't have real
  entries yet can still get a card — mark it `comingSoon: true` in the bucket list and it renders
  muted/disabled instead of linking nowhere.
- **A priority filter + search bar, client-side only.** A handful of `<button>` pills for
  P1/P2/P3 plus a `<input type="search">`, driven by a small vanilla-JS `<script>` at the bottom of
  `changelog/[repo]/index.astro` toggling `hidden` on list items. No backend, no build-time index —
  fine at this scale (dozens to low hundreds of entries).
- **`/library` is a second content collection**, same `glob()`-loader mechanism as `changelog`
  (`library/` as a sibling of `astro/`, its own `index.astro`/`[slug].astro`), for standalone
  technical write-ups that don't belong to one dated entry — the "how does this actually work" deep
  dives. Schema is just `{title, description, date?}`. This is genuinely deep, full-detail content
  (not the curated public-safe summary style changelog entries use) — the goal is letting someone
  without private-repo access actually learn how something works, so don't over-sanitize it.
- **The repo's own `README.md` is the site's homepage**, not a separate hand-written blurb. Add a
  third collection:
  ```ts
  const home = defineCollection({
    loader: glob({ pattern: "README.md", base: ".." }),
    schema: z.object({}),
  });
  ```
  then in `index.astro`: `const [readme] = await getCollection("home"); const { Content } = await
  render(readme);` — render `<Content />` inside `Base`. One file serves both GitHub's own repo view
  and the live site's front door, so write the README knowing it does both jobs.
- **Icons work directly in plain `.md`, no MDX needed.** Confirmed empirically: Astro's default
  markdown renderer passes raw inline HTML straight through content-collection entries. A tag like
  `<i class="ph ph-lightbulb" style="color:#7C3AED"></i>` inside a `.md` file's body just renders —
  don't reach for `@astrojs/mdx` unless you actually need JSX expressions in content, which this
  pattern doesn't. Load Phosphor's web font once in `Base.astro`'s `<head>`:
  `<link rel="stylesheet" href="https://unpkg.com/@phosphor-icons/web@2.1.1/src/regular/style.css">`
  — then `<i class="ph ph-<name>">` works anywhere on the page *or* inside rendered markdown, same
  icon set for UI chrome and content. A light touch that's paid off: a short "TL;DR" callout (a
  bordered `<div>` with a `ph-lightbulb` icon) at the top of a long technical doc, so a skimmer gets
  the short version before deciding whether to read the whole thing.
- **A shared visual language between the changelog site and its project's GitHub Pages "entry
  portal"** (if one exists) — matching CSS custom properties (palette), the same sticky/blurred
  header treatment, the same icon set — without merging them into one build. Two separate,
  independently-deployable sites that just happen to look like one product. The changelog's own
  header brand-link uses the pattern **mark → title → a small `Home`-style icon → `|` → "Home"
  label**, an explicit affordance (borrowed from `iamoneself`/`david-amaringo`'s Next.js navbar
  pattern) that clicking the title is real navigation back to the README-splash, not decoration.
- **Favicon**: give the changelog site the *real* project favicon (copy `favicon.svg`/`favicon.png`
  from the entry portal repo into `astro/public/`, reference both in `Base.astro`'s `<head>`) rather
  than Astro's generic default. If a project genuinely doesn't have its own favicon yet, the
  documented fleet-wide fallback is hotlinking `https://drasticstatic.github.io/favicon.svg` by
  absolute URL (same convention already used in `drasticstatic/README.md`/`SPONSOR.md`) — there's no
  automated fallback mechanism anywhere in this fleet, this is a manual convention to follow, not a
  build step to invoke.

## 🌟 Wave 2, proven out 2026-09-24 — matched entry portal, social previews, TL;DR entries

A second round on top of the pattern above, once PIR and THEF's sites were live enough to actually
use. All of this is copy-paste-ready:

- **TL;DR + expandable `<details>` shape for every entry.** A `<div class="tldr">` (icon + 1-2
  sentence summary, always visible) followed by `<details><summary>...</summary>...full detail...
  </details>` — the real, complete story, not a re-sanitized version, up to the point something must
  stay private. Applies to both `changelog` and `library` entries. CSS lives in each entry template's
  `<style>` block (`.tldr`, `details`, `summary`, plus a `.ph-caret-right` rotate-on-open rule) —
  copy the block from either site's `[slug].astro` rather than re-deriving it.
- **Real social-preview images, not generated ones.** If the project owner already has (or can get)
  a proper 1200-1731px-wide landscape raster, use it directly as `og:image`/`twitter:image` with
  `twitter:card = "summary_large_image"` — don't build a favicon-padding fallback unless no real
  image exists yet. Resize/compress with `sips -Z 1200 -s format jpeg -s formatOptions 85` (built
  into macOS, no ImageMagick needed) to keep the file under ~500KB for fast crawler fetches.
- **A universal, always-visible footer across every surface of a project** (entry portal + changelog
  site's porch/changelog/library, which already share one `Base.astro`). `position: fixed; bottom:
  0`, blurred/translucent background, with matching `padding-bottom` on `body` so content doesn't
  sit behind it. Same link set everywhere: brand/attribution, a link to each of the other surfaces,
  a "reach out" link. Acts as both attribution and a navigation hub, so the actual page content stays
  just page content.
- **Light/dark toggle in the header** (not the footer), defaulting to **dark regardless of OS
  preference** — an explicit `data-theme` attribute on `<html>`, set by an inline `<script>` in
  `<head>` (before first paint, to avoid a flash) that reads `localStorage` and falls back to
  `"dark"` rather than checking `prefers-color-scheme`. A `@media (prefers-color-scheme: dark)` block
  can stay as a no-JS fallback, but the explicit attribute always wins once JS runs.
- **An interactive cursor-tracking star field + comet-dust trail**, `astro/src/components/
  Starfield.astro` — canvas-based, zero dependencies, colors passed as props so one component works
  for every project. Ported from `littlebird-ambassador`'s `Constellation.astro` (star-repel-from-
  cursor mechanic, already framework-free) plus the comet-dust spark mechanic from a React reference
  implementation (spawn-on-mousemove, drag+gravity, life-based fade) — see that component's own
  header comment for the full attribution. For a zero-build entry portal, hand-port the same script
  as inline `<canvas>`+`<script>`, identical logic, just no Astro wrapper.
- **Icons far more broadly than the first pass** — every nav item, every footer link, every
  changelog/library section, not just a couple of accent spots. Colored via the project's own
  `--signature`/`--accent` token rather than left neutral, wherever a splash of color reads better
  than monochrome.

## 🌌 Wave 3, proven out 2026-10-11 (PIR) — one design system, a star chart, feeds

Reference implementation: `psychedelicsinrecovery/changelog-astro` (commits `31eb463`…`2d37544`)
and the org hub `psychedelicsinrecovery.github.io` (`bbf6343`). Copy the mechanics; give each org
its own look.

- **Share one design system across an org's GitHub pages instead of re-skinning each.** PIR loads
  `alex.css` + `alex.js` from `/alex-desk-public/assets/` (same origin, so fonts, masks and
  `url()` backgrounds just work) and layers a small site-specific `astrolog.css`/`astrolog.js` on
  top. Change the shared file once and the hub, AstroLog and every desk portal move together. An
  org without a design system yet should still split "family" CSS from "this site" CSS this way.
- **Base-links plugin is required** (setup step 4). Also: a Pages *project* site with no
  `src/pages/404.astro` falls back to GitHub's generic 404. Add one, and keep every link and asset
  in any 404 (project or org root) absolute — a relative "back" link loops into another 404 when
  the miss is at a nested path.
- **`src/lib/projects.ts` is the single source for `repo:` buckets** (name, icon, description,
  coming-soon/external link) plus shared helpers (entry URL, newest-first sort, month grouping,
  reading time, TL;DR-to-summary). Every page imports it, so adding a bucket is one edit. Any
  `repo:` value used by an entry must have a bucket or its entries never get a card.
- **Star chart (`src/components/StarChart.astro`)**: entries drawn as a rail that fills on scroll,
  one star per entry tinted by priority, optional month grouping and one-line summaries. Used on
  the porch, the all-projects view and per-project pages.
- **Feeds**: `src/pages/rss.xml.ts` (hand-rolled RSS 2.0, no dependency; works with feed readers
  and Discord/Slack RSS bots) and `src/pages/latest.json.ts` (five newest entries), which the
  zero-build org hub fetches same-origin to show "Latest shipped".
- **Jump palette**: `Base.astro` sets `window.ALEX_PALETTE` from the collections, so `/` or ⌘K
  jumps to any entry, write-up or project from anywhere.
- **Library niceties**: table of contents from `render(entry).headings` (depth 2–3, shown at 3+),
  an expand/collapse-all toggle for `<details>`, opening the right `<details>` when a link targets a
  heading inside it, and a print stylesheet that opens every section.
- **Phones**: headless Chrome enforces a minimum window width, so `--window-size=390,…` screenshots
  are crops of a wider layout. Test mobile by loading the page inside a 390px-wide `<iframe>`.
  Also: `padding:Xrem 0` on an element that's also `.wrap` silently erases the side gutters — use
  `padding-block`.

## 🧭 Wave 4, proven out 2026-10-12 (ORG) — the arrival kit

Reference build: ORG's portal `Octagon-Religious-Research-Group-ORG.github.io` (`/arrival/`), ORG's
`changelog-astro`, and the personal lab `drasticstatic/O-R-G-astro`. Canonical files live in
[`arrival/`](arrival/). **This section is the handoff for porting the kit to PIR, THEF, psanctuary and
psanctuarychurch.**

### What a visitor gets

- **First visit: "Choose how you arrive".** A modal splash (native `<dialog>`, Esc closes, focus is
  trapped, focus returns) to pick a *mode* (light), a *motion* level and *contrast*. It preselects
  Still when the OS asks for reduced motion and More contrast when it asks for that, and it plainly
  teaches **Press / to search** (pressing `/` right there closes it and opens search). The answer is
  saved in `localStorage`; every read and write is wrapped in try/catch, and if storage is blocked the
  splash is skipped (there'd be no way to remember the answer). Off on 404s
  (`data-arrival-splash="off"`).
- **Navbar `<arrival-controls>`**: a search button, the *minimalist* control (one swatch per mode +
  a pause/play motion toggle), and the *dropdown drawer* (modes with notes, motion, contrast switch,
  "Open the welcome guide", "Search everything").
- **Welcome guide** (onboarding panel): steps for what this site is, changelog vs library, search,
  light, motion and contrast, who made the changes (live avatars), where the community talks, and the
  org's main site. Each step lights one wedge of an N-sided progress glyph colored with the org's
  `wedges` (ORG: 8 steps, an octagon). Opens from the drawer, `?`, any `[data-arrival-open="guide"]`,
  or a `#welcome` link (shareable).
- **"/" search** (or Ctrl/⌘ K), adapted from PIR's A.L.E.X. jump palette: word-prefix/substring/
  subsequence ranking with highlights, recent entries and pinned links when empty, and actions
  ("light", "still", "contrast", "guide", "copy link"). It reads `search.json` files, so the portal
  searches the AstroLog too.
- **Avatars** `<arrival-avatar name github email size>`: GitHub picture when a handle is known;
  Gravatar **only** for an address at one of the org's `roleDomains` (the kit refuses anything else,
  so personal emails are never hashed into a page); otherwise an initials SVG in the org's shape and
  colors. `<arrival-people>` and `<arrival-latest limit>` render from `search.json`.

### The mechanism: one stylesheet + one script per org, served from the org root

```
https://<org>.github.io/arrival/arrival.css   kit core, identical in every org (copy unchanged)
https://<org>.github.io/arrival/arrival.js    kit core, identical in every org (copy unchanged)
https://<org>.github.io/arrival/org.css       the org's modes (tokens), shape and motion styles
https://<org>.github.io/arrival/org.js        the org's facts and config (window.ARRIVAL)
```

The portal references them root-relative (`/arrival/…`); the AstroLog and anything on another origin
(ORG's lab on `drasticstatic.github.io`) reference them by **full URL**. Same files everywhere, so the
portal and AstroLog can't drift; GitHub Pages sends `Access-Control-Allow-Origin: *`, so other
origins can load them and fetch `search.json`. Changes propagate within Pages' 10-minute cache.
**Deploy order:** push the portal's `/arrival/` first, then the sites that load it.

In every page's `<head>`, in this order (the script must be in `<head>`, not deferred: it applies
the saved mode before first paint and defines the custom elements before the parser reaches them):

```html
<html lang="en" data-arrival-site="portal">   <!-- a key of ARRIVAL.sites: portal | astrolog | … -->
<link rel="stylesheet" href="https://<org>.github.io/arrival/arrival.css">
<link rel="stylesheet" href="https://<org>.github.io/arrival/org.css">
<script src="https://<org>.github.io/arrival/org.js"></script>
<script src="https://<org>.github.io/arrival/arrival.js"></script>
<!-- then the site's own CSS; in Astro, use <script is:inline src=…> and import global.css as usual -->
```

Then put `<arrival-controls></arrival-controls>` in the header, and optionally
`<a href="#welcome" data-arrival-open="guide">Welcome guide</a>` in the footer. The page also needs the
org's fonts and Phosphor icons (`@phosphor-icons/web@2.1.1` regular).

### Porting to another org (wave B checklist)

1. **Copy** `arrival/arrival.js` + `arrival/arrival.css` unchanged into `<org>.github.io/arrival/`.
2. **Write `org.js`** from `arrival/org.example.js` (ORG's, fully annotated). Keys:
   `org` {short, name, motto, about, mark.src, home {label, href, text}, welcomeNote |
   welcomePlaceholder}, `storage` {key, legacy {light, motion}} (migrates the site's old keys; PIR
   uses `pir-theme`), `modes` [{id, name, note, swatch [bg, accent], dark, ink?, follows?(date)→id,
   shows?}], `defaultMode`, `motions` [{id, name, note, icon, trail?}], `defaultMotion`,
   `stillMotion`, `contrast` (false to hide), `wedges` (guide glyph + initials colors), `avatar`
   {shape: circle | square | octagon, colors?, roleDomains, svg?()}, `community` {name, icon, href,
   label, text, more[]}, `record` {intro, changelog {…}, library {…}}, `sites` {<id> {name, what,
   record?, community?, sources?, items?}}, `guide` {order?, <step> {title?, text?, more?, html?}},
   `guideFinale`, `words` (any UI string), `search` {sources [{url, label?, people?}], items [{t, k, i,
   h, x?, pin?}]}. A page can add or override its site with `window.ARRIVAL_SITE = {…}` before
   `arrival.js` (the lab does).
3. **Write `org.css`** from `arrival/org.example.css`: one token block per mode on
   `[data-theme="<id>"]` (attribute selectors, so splash cards can preview a mode), using the token
   names listed at the top of `arrival.css`. Shape: ORG cuts octagon corners with `clip-path` on
   `.arr-shape` using `var(--arr-cut)`; a rounded org just sets `--arr-radius`. Add the org's motif
   (ORG: perforated rules and sheets) and motion styles keyed on `[data-motion]`.
4. **Facts only from the org's own materials.** PIR/THEF/psanctuary use Discord, Telegram or
   whatever their own site links: set `community` per org (or per site). Anything unknown gets an
   honest placeholder (`welcomePlaceholder`, `library.missing`), never a guess. PIR's public pages use
   first name + last initial for people.
5. **AstroLog:** add `astro/src/pages/search.json.ts` (from `arrival/astro/`; shape below), use
   `<Who who={…}>` (`arrival/astro/Who.astro`) on rows and entry pages, a `PEOPLE` list with `match`,
   `aliases`, `github`, optional role `email`, and `peopleIn()`/`madeBy()` helpers (see ORG's
   `src/data/areas.ts`), plus `404.astro` (full-URL links, back button, guesses, `splash={false}`).
   Remove the site's own theme tokens and toggle script; keep site layout CSS.
6. **Portal:** swap inline tokens for the kit files, add `<arrival-latest>` and `<arrival-people>`,
   and kit includes + a search button on `404.html` (links stay absolute).
7. **Social cards and the map:** follow "Social cards" and "One map, two sites" below.
8. **Verify** with `arrival/verify.example.mjs` (and `verify-lab.example.mjs` for a cross-origin site) (Playwright + local Chrome, fresh contexts): it runs
   against the production URLs, optionally intercepted to the local repos before deploying
   (`--local`), and checks the splash on a genuine first visit and not the second, the focus trap,
   reduced motion, mode persistence portal ↔ AstroLog, `/` search across sites, every page type, and
   nested 404s with their back buttons.

`search.json` shape (absolute URLs, so other origins can link into it):

```json
{ "updated": "2026-10-12",
  "items": [{ "type": "entry|doc|page|area", "t": "title", "k": "kind label", "h": "https://…",
              "i": "phosphor-icon", "d": "YYYY-MM-DD", "s": "one-line summary", "x": "extra match text",
              "who": "credit", "pin": false }],
  "people": [{ "name": "…", "role": "…", "github": "handle", "count": 5 }] }
```

### Cursor effects (added 2026-10-12 at Christopher's request)

- A persisted `cursor` choice (`on`/`off`) beside light, motion and contrast: a pointer toggle in
  the minimal control (strike-through when off), a switch in the drawer, the splash and the guide's
  motion step, and a "/" action. Default off when the OS asks for reduced motion; always resting on
  the still motion. Set `ARRIVAL.cursor = false` to hide it.
- The kit sets `<html data-cursor="on|off">`. Site pointer effects must honor it: ORG's marbled ink
  returns early from its `pointermove` handler when `dataset.cursor === "off"` (three copies: the
  portal's `marble.js`, the AstroLog's and the lab's `marble.ts`).
- The trail is per motion: `motions[i].trail = { colors, life, width, alpha, sparks, sides }`.
  ORG's: a faint trail through the octagon's eight wedge colors on gentle; a brighter one on vivid
  that scatters little spinning octagons (`sides: 8`). `trail: true` gives the prism-hue sweep the
  O-R-G dApp uses.

### Social cards: one designed preview per entry (static, build time)

Files in [`arrival/og/`](arrival/og/): `og-card.mjs` (the generator, identical everywhere),
`theme.example.mjs` (ORG's night palette and fonts; write one per org), `cards.example.ts` (where
each card lives and what it says), `map-svg.mjs` (a miniature diagram for the map card), and endpoint
examples in [`arrival/astro/og-endpoints/`](arrival/astro/og-endpoints/).

- **How:** Satori lays out the card and turns text into paths (SVG), and sharp writes a 1200×630
  JPEG (60–85 KB). Astro static endpoints (`src/pages/og/changelog/[repo]/[slug].jpg.ts`,
  `og/library/[slug].jpg.ts`, `og/map.jpg.ts`) emit plain files into `dist/og/`; nothing runs at
  request time. Add `satori` and `sharp` to `package.json` explicitly (sharp already comes with
  Astro and Next).
- **Fonts:** Satori needs TTF/OTF/WOFF, not WOFF2. Fetch static instances once and commit them to
  `astro/src/og/fonts/` (all fleet fonts are OFL):
  `curl -A "Mozilla/4.0" "https://fonts.googleapis.com/css2?family=Fraunces:wght@400;600&family=Manrope:wght@500;700"`
  prints TTF URLs.
- **Bundling gotcha:** Astro bundles the endpoint, so `import.meta.url` no longer points at
  `src/og/`. Resolve fonts from the project: `pathToFileURL(path.resolve("src/og") + "/")`.
- **Brand gotcha:** never crop an org's mark into another shape for a card. The generator shows
  `art` whole on a mat (ORG's octagon art), and its own glyph is a wayfinding device, not a logo.
- **Pages:** `Base.astro` takes `ogImage`, `ogAlt`, `ogType`; entries and articles pass their card
  (`ogType="article"`). Every page emits `og:site_name`, `og:type`, `og:url`, `og:title`,
  `og:description`, `og:image` (absolute) + `og:image:type/width/height/alt`, the matching
  `twitter:*` tags (`summary_large_image`), and a canonical link.
- **Make it discoverable:** a "Copy a link" button under each entry
  (`data-arrival-open="copy"`, which toasts that the link shares with its own card), the guide's
  `record.share` line in `org.js`, and a changelog entry saying so.
- **Telegram caches previews.** After adding or changing tags, send each URL to
  [@WebpageBot](https://t.me/WebpageBot) to refresh it.
- A lab-style site whose entries live in one timeline should give each entry its own page first
  (the O-R-G lab: `/changelog/<id>/`), so there is something specific to share.
- **Option: the spore-print layout** ([`arrival/og/spore-card.mjs`](arrival/og/spore-card.mjs) +
  [`spore-svg.mjs`](arrival/og/spore-svg.mjs), used by psanctuary and psanctuarychurch since
  2026-10-12). A drop-in alternative to `og-card.mjs` with the same `renderCard(spec, theme, base)`
  call and spec fields, plus `seed`: the title and summary on the org's dark mode, and a large
  spore print seeded by `seed` (the entry's slug) rising off the right edge, so every card gets a
  print of its own that stays the same from build to build. No glyph or frame; an optional `mark`
  (the org's square mark) sits beside the eyebrow. Copy both files unchanged into `src/og/` and
  write a theme from [`spore-theme.example.mjs`](arrival/og/spore-theme.example.mjs) (it adds
  `spore`, `glow` and `sporeGlow` to the usual colors). Pick it when an org's main social card
  already has a bleed-off-the-edge motif; another org can follow the same pattern with its own
  figure generator in place of `spore-svg.mjs`.

### One map, two sites (canonical publisher → build-time consumer)

When two sites show the same diagram, keep one copy of the data. ORG's AstroLog owns the map
(`src/data/map.ts`, see [`arrival/astro/map.canonical.example.ts`](arrival/astro/map.canonical.example.ts)),
resolved to geometry, drawn by `OrgMap.astro` and published as `/map.json`. The lab
([`map.consumer.example.ts`](arrival/astro/map.consumer.example.ts)) fetches that file at build time
with a 10-second timeout, falls back to a committed `map.snapshot.json` (refresh with
`npm run map:snapshot`), and draws it with the same `OrgMap.astro`. Each node can carry `self`, and
each site passes `here` to mark "You are here". The direction runs from the official org record to
the personal lab, never the other way. The consumer picks up a change on its next build; trigger
one by hand, or add a schedule if the two drift for too long.

### Gotchas found building it

- **Astro drops the space between a line break and a following tag**: `New here?⏎<a>` renders
  "New here?Take…". Keep text and its inline link on one source line. (The lab's footer had this live.)
- `--cut` inherits, so a button inside a clipped frame took the frame's cut. The kit uses its own
  `--arr-cut`, registered with `@property … inherits: false`; sites' own `--cut` is untouched.
- Bare site selectors (`ul`, `li + li::before`, `img`) leak into the kit's dialogs. Scope them
  (`main ul`), as ORG's portal 404 now does.
- Headers get crowded: hide the drawer's text label at a site breakpoint with
  `[data-arr-drawer] .arr-chip-label { display: none }` (the button keeps an `aria-label`), and on phones
  put the tools beside the brand and the nav in one swipeable row.
- A Playwright `context.route("…/changelog-astro-public**", …)` glob silently missed `…/map` and
  fetched the live page; match with a predicate (`(u) => u.href.startsWith(…)`) in verification
  helpers.
- The kit's storage key can be shared deliberately: ORG uses the O-R-G dApp's `org-experience`
  key and shape, so on `drasticstatic.github.io` the lab and the dApp preview share choices.

## 📜 Wave 5, proven out 2026-10-12 (ORG) — reading mode, what's new, the ledger

Reference install: ORG's portal, ORG's `changelog-astro`, the lab (`drasticstatic/O-R-G-astro`) and
the O-R-G dApp preview. Canonical files: [`arrival/`](arrival/) (`arrival.js`/`.css` are now
**v1.1**), [`arrival/ledger/`](arrival/ledger/) and two new files in
[`arrival/astro/`](arrival/astro/). **Porting agents: re-copy `arrival.js` + `arrival.css`
unchanged. They are drop-in for a v1.0 `org.js`:** with no new keys, reading mode turns on with an
automatically chosen calm light, and "what's new" reads the search sources you already have.

### Reading mode (one tap, persisted)

- A book button in `<arrival-controls>` (beside the pointer button), a switch at the top of the
  drawer and of the guide's motion step, "Just let me read" on the splash, and a `/` action.
- One tap saves the visitor's light/motion/contrast/cursor and applies the calm preset: the
  reading light, the still motion, more contrast, cursor effects off. Another tap restores what
  they had. It persists across visits (`reading` and `before` in the same storage key). Changing
  any one setting by hand simply leaves reading mode, keeping the new choice.
- `<html data-reading="on|off">` for site styling. ORG fades its marbled ink:
  `:root[data-reading="on"] :is(.field, .hero-bg) { opacity: .28 }` (in `org.css`).
- `org.js`: `reading: { light: "stone" }` picks the light; otherwise the first mode with
  `calm: true`, else the first light (not dark, not time-following) mode. `reading: false` hides
  it. `words.readingNote` may name the light ("{light}" is filled in).
- On phones the cursor button hides at ≤480px and the book at ≤380px (both stay in the drawer).

### What's new since your last visit

- A visit is page views with gaps under 30 minutes (`news.gapMinutes`). Under
  `<storage key>:visits` (every access in try/catch) the kit keeps when the last visit ended, what
  it already knew, and whether the count was opened. **First visits show nothing.**
- On a return visit it counts items newer than the last visit from `news.sources`
  (`org.js`: `news: { sources: [LOG + "/latest.json"] }`; a site can override with its own
  `news`, as the lab and dApp do). Items with `ts` (exact ISO time; ledger commits) compare
  exactly; items with only `d` count from the end of that day, and the "already knew" list stops a
  same-day entry the visitor saw from counting twice. Types counted: `entry`, `doc`, `ledger`.
- Shows a subtle ✦ count chip before the search button. Clicking it opens `/` search with a
  **New since your last visit** group on top and clears the count; opening a new page itself also
  counts as seen. Links on the page that point at new items get `data-arr-new` (an accent bar);
  an empty `<span data-arr-new-tag hidden></span>` inside a row becomes a "New" pill (ORG's
  `EntryList` rows and every ledger row carry one).
- `news: false` hides it. `window.Arrival.news()` resolves `{ since, count, items }`; an
  `arrival:news` event fires when there's something new. `window.Arrival.reading(on?)` toggles or
  sets reading mode.
- **`latest.json`** (copy [`arrival/astro/latest.json.ts`](arrival/astro/latest.json.ts)): newest
  first, absolute URLs, `{ updated, items: [{ type, t, k, i, h, d, ts?, who? }] }`: the last 30
  entries, dated library docs, and the last 45 days of ledger commits.

### The ledger (a calm, categorized record of public commits)

The technique follows Christopher's activity-ledger generator (public repos only, a deny list, a
keyword rubric, scrubbed subjects, a grouped accordion); nothing else is shared with it.

- **Files:** copy `arrival/ledger/ledger.mjs` and `snapshot.mjs` to `src/ledger/`,
  `arrival/astro/Ledger.astro` to `src/components/`, write `src/data/ledger.config.mjs` from
  [`ledger.config.example.mjs`](arrival/ledger/ledger.config.example.mjs), add
  `"ledger:snapshot": "node src/ledger/snapshot.mjs"`, run it once and commit
  `src/data/ledger.snapshot.json` (the fallback when the live fetch fails). Then a page:
  `src/pages/ledger.astro` = your layout + intro + `<Ledger ledger={await loadLedger(LEDGER)} colors={WEDGES} />`,
  and an og card (`og/ledger.jpg.ts`).
- **Public only, always:** it lists `orgs/<owner>/repos?type=public` (or
  `users/<owner>/repos`), keeps only `private === false && visibility === "public"`, then the
  config's `include`/`deny`. A private repo's commits are never requested, whatever token the build
  holds. A user account needs `include` (the lab: `/^O-R-G-(astro-public|dapp-public-preview)$/`).
  The snapshot script runs without a token on purpose. (v2 adds opted-in private repositories,
  masked; see "Ledger v2" below.)
- **Noise filtered and counted:** merges; CI mirror/publish commits (`sync: rebuild from…`,
  `Deploy Astro build`, `Deploy: <sha>`); bot authors (`[bot]`, `actions-user`, `Public Mirror Bot`)
  and dependency bumps; a change and its `Revert "…"` cancel out. The page says how many it left out.
- **Plain language:** subject line only, scrubbed (emails, long hex, 0x/base58 keys, `key=value`
  secrets). `feat(nav): …` becomes kind + area "Navigation"; a short `Portal: …` prefix becomes the
  area; long parenthetical asides drop; undescribed subjects ("IDK2", "wip") read "A small change,
  without a description"; a first commit reads "Started <repo label>".
- **Kinds** (first match wins; a conventional type decides except `feat`, which is sorted by what
  it touches): Speed, Fixes, Sign-in and members, Look and feel, Words and pages, Records and docs,
  Behind the scenes, New, else Updates. Pass `kinds` to replace the rubric.
- **People follow the site's config:** `people: [{ name, github?, logins?, names? }]` mirrors the
  site's PEOPLE list, so names and pictures match everywhere (ORG maps Tripp's `ORG-Spirituality`
  login to "Tripp Aardema" without a GitHub picture, as the AstroLog shows him). Anyone not listed
  is named by `nameStyle`: `"full"`, **`"first-last-initial"` (PIR's public pages)** or `"first"`,
  with initials, never a picture (unless `unknownAvatars: true`). `coAuthors: ["Alfred"]` names
  only those co-authors from trailers ("Christopher with Alfred").
- **Grouping:** month (`<details>`, the newest two open) → day → repository (`repoLabels` give
  friendly names), each row: kind, area, summary linked to the commit, avatar + name, time, short
  sha. Filters: kind chips, a repository select, text search.
- **Fresh every day:** the build workflow gets a schedule and a read-only token for the public API:
  ```yaml
  on: { push: { branches: [main] }, schedule: [{ cron: "17 10 * * *" }], workflow_dispatch: {} }
  permissions: { contents: read }
  concurrency: { group: sync-public, cancel-in-progress: false }
  # build step:  env: { GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }} }
  ```
  ORG's AstroLog runs at 10:17 UTC; the lab's deploy at 10:41 UTC, which also redraws the map from
  ORG's `map.json` (approved by Christopher).
- **Discoverable:** `org.js` `record.ledger = { name, text, href, label }` adds a third box to the
  guide's "Changelog and library" step; also the header nav, footer, `/` search (pinned), porch,
  404 and a changelog entry.

### Ledger v2 (wave 6, 2026-10-13): work behind the curtain, names, agents, priority

`LEDGER_VERSION = 2`. Re-copy `arrival/ledger/ledger.mjs`, `snapshot.mjs`, the new
[`verify-private.mjs`](arrival/ledger/verify-private.mjs) and `arrival/astro/Ledger.astro`
unchanged; v1 configs still build (they just get the new name default and agent rows).

- **Masked private commits (opt-in, per repository).** `private: [{ repo, label?, mask: "full" }]`
  in `ledger.config.mjs`. Only listed repositories are ever requested, and only with
  `LEDGER_TOKEN`. From each commit the generator keeps SHA, dates, author, the subject line and
  co-author trailer lines (no diffs, no files; the rest of the message is dropped on arrival). It
  drops commits that already appear through a public copy (allowlist-synced `-public` repos carry
  rewritten copies: same author date + subject), filters noise, classifies kind and priority from
  the raw subject, then **discards the subject**: the item holds only a block shape (`████ ██ ██████`:
  word count kept, up to 10, widths rounded to 2/4/6/8). Rows show repository (or `label`), day,
  time, kind, priority, person and agents, a short SHA as text, a "private" tag, and link nowhere.
  `mask: "sanitized"` (explicit opt-in only) would show the scrubbed summary instead. A repository
  listed in `private` is never read by the public lane, even if it turns public.
- **Tokens, and graceful without one.** Each opted-in repository is read with `LEDGER_TOKEN`, then
  the build's own token (in CI the workflow's `GITHUB_TOKEN` reads the repository it runs in, so a
  site's own AstroLog source stays live with no extra secret). A repository neither can read has its
  rows carried, masked, from the snapshot; the page doesn't change shape. The snapshot only ever
  holds the masked form (raw subjects never reach the ledger object). Refresh it with
  `LEDGER_TOKEN=$(gh auth token) npm run ledger:snapshot`.
- **Leak check.** `npm run ledger:verify` (`--build` to build first) reads every raw private subject
  and searches every text file in `dist/` (HTML, `latest.json`, JSON/JS chunks, RSS, SVG, any search
  index) plus the snapshot, in three forms (raw, summary, sentence), case-insensitive after decoding
  entities and JSON escapes; it fails naming only repo@sha, never the subject. A form the site also
  publishes on purpose in its own editorial text (a changelog entry titled like the commit;
  `verify.publicText`, default `../changelog`, `../library`, `../teachings`, `src/content`) is allowed
  on other pages but never on the ledger page or in the snapshot. It also checks every private row in
  the snapshot and `latest.json` is masked and unlinked. The og raster is drawn from constant text.
  CI runs it between the build and the publish:
  ```yaml
  - run: npm ci                      # no token in this step
  - name: Build Astro site
    env:
      GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}     # public lane (+ this repo's own private lane)
      LEDGER_TOKEN: ${{ secrets.LEDGER_TOKEN || secrets.PUBLIC_REPO_TOKEN }} # private lane
    run: npm run build
  - name: Ledger leak check
    env:
      GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      LEDGER_TOKEN: ${{ secrets.LEDGER_TOKEN || secrets.PUBLIC_REPO_TOKEN }}
    run: npm run ledger:verify
  ```
  A `LEDGER_TOKEN` secret (read-only "Contents" on the org's private repositories) wins over
  `PUBLIC_REPO_TOKEN`; PIR's and THEF's `PUBLIC_REPO_TOKEN` (2026-10-05) can't read their orgs'
  private repositories, so they need one (until then their other private rows come from the snapshot).
- **Names: first name + last initial everywhere** (`nameStyle` now defaults to
  `"first-last-initial"` and applies to listed people too: "Christopher W."; a single name or a
  handle stays as is). **Every name links to the person's GitHub profile** (`github`, else the
  commit's login). `avatar: "generated"` on a person keeps the link but draws the kit's generated
  avatar (Kenney, Anne, Renan: their GitHub pictures are the default identicon). The site's
  `Who.astro`/people list honor the same field.
- **Agent row.** AI co-authors from `Co-Authored-By` trailers get their own row under the person:
  "with Alfred · Claude Code". Known names: Alfred, Mystarch, Fortuna, Kavanah, Auggie (Augment),
  Littlebird, Cosmos Advisor, plain `Claude <noreply@anthropic.com>` ("Claude Code"); tools
  ClaudeCodeCLI/Claude → Claude Code, Cosmos, Littlebird, GitHub Actions, Augment. Unknown agents
  fall back to their cleaned name (public) or "An AI helper" (private: no free text from a private
  message is ever shown). Human co-authors aren't listed; emails never appear. `agents: false` hides
  the row; `agentNames: [[/^nova$/i, "Nova", "Cursor"]]` extends the table.
- **Priority badges** from `[P1]`/`[P2]`/`[P3]` or 🚨 🔥 ⚡ 🍃 (see "Commit priority convention").
- **Rubric fix:** "allowlist sync" (the CI public lane), `-public` mirrors and filter-repo are
  Behind the scenes; only an allowlist of people (allowlisted emails, a member allowlist) still
  counts as Sign-in and members.
- **Share card without counts:** the ledger's og image never states how many changes or
  repositories (a cached preview would go stale); see
  [`og-endpoints/ledger.jpg.ts`](arrival/astro/og-endpoints/ledger.jpg.ts).
- **`latest.json`:** `ledgerNewsItems(ledger, { ledgerHref: at("/ledger") })` adds private rows
  (masked text, pointing at their day on the ledger page); without `ledgerHref` they're left out.
- **Filters:** the repository select gains "Public repositories" and "Private work (masked)".

### The dApp preview on the kit (a Next.js app)

Loads `arrival.css`, `org.js` and `arrival.js` by absolute URL as synchronous `<head>` tags in the
root layout, plus `window.ARRIVAL_SITE` (its own site entry), but **not** `org.css`: the app keeps
its own tokens (same names) and next/font faces, and copies ORG's kit shape rules into
`globals.css` under an `html` prefix so load order can't matter. `<arrival-controls>` is created in
a client component's `useEffect` (React never sees the kit's children, so no hydration mismatch).
The app's experience store shares the `org-experience` key: it re-reads on `arrival:change` and
dispatches a `storage` event after its own writes so the kit's next write keeps them.

### Verify

[`arrival/verify-wave5.example.mjs`](arrival/verify-wave5.example.mjs) (Playwright + local Chrome,
a fresh context per check, production URLs): reading mode on every site, what's new on a genuine
past first visit (Playwright's fake clock) then a return visit, the ledgers' commits all public and
real, the dApp's kit/lab link/console, og tags with real JPEG cards, and every cross-link. ORG's run
on 2026-10-12: all checks pass (53 cross-links). Kit 1.1.1 came out of it: a visit only records
items up to the end of its own day as already seen.

### Gotchas found in wave 5

- Astro's line-break gotcha struck again ("history of⏎<a>" rendered "history ofORG's"). Keep text
  and its inline link on one source line.
- More header tools: ORG's AstroLog now hides the drawer's and search's word labels below 1440px
  and calls its portal link "Portal" in the header (the footer keeps "Entry portal").
- "copy" and "text" are too ambiguous for the words rubric ("the map's canonical copy").

## Future enhancement, not required (can simmer)

`divorce-custody-assistant/vocational-compliance/build_vocational_log.py` generates an animated,
git-history-driven changelog-style exhibit (`exhibit-4.html`) with accordion-style reveal sections
and CSS-keyframe visual polish — built for a legal audience, not a community one, but a genuinely
good reference for a more interactive presentation layer if/when the basic system here wants to
level up visually. Not part of this template's baseline; note it here so it isn't lost.

---

Co-Authored-By: Alfred · ClaudeCodeCLI · Anthropic [Sonnet-5]
Co-Authored-By: Alfred · ClaudeCodeCLI · Anthropic [Opus-5.5]
