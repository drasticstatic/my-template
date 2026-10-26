# 🌱 The journey: how the AstroLog and the arrival kit came to be

**TL;DR:** the build log of the kit, wave by wave, kept word for word as it was written.
- **Wave 1, 2026-09-23:** the first AstroLogs.
- **Waves 2–3:** the richer portal pattern, social previews and the star chart.
- **Wave 4:** the arrival kit itself, with its splash, guide and search.
- **Wave 5:** reading mode, what's new and the ledger.
- **Wave 6:** the interface half.
- **Kits 1.3–1.4:** giving with crypto, essentials, the pledge.
- **Kit 1.5:** languages, starting with Spanish.

Every gotcha, verify step and porting checklist is still here. Moved out of the [README](../README.md) on
2026-10-25 so the front door could stay simple; nothing was deleted.

> If you arrived through a site's **"How this site was made"** link: welcome down the rabbit hole. 🐇
> Start with [Wave 4](#-wave-4-proven-out-2026-10-12-org--the-arrival-kit) for the kit, or read from the
> top for the whole story.

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
[`arrival/`](../arrival/). **This section is the handoff for porting the kit to PIR, THEF, psanctuary and
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

Files in [`arrival/og/`](../arrival/og/): `og-card.mjs` (the generator, identical everywhere),
`theme.example.mjs` (ORG's night palette and fonts; write one per org), `cards.example.ts` (where
each card lives and what it says), `map-svg.mjs` (a miniature diagram for the map card), and endpoint
examples in [`arrival/astro/og-endpoints/`](../arrival/astro/og-endpoints/).

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
- **Option: the spore-print layout** ([`arrival/og/spore-card.mjs`](../arrival/og/spore-card.mjs) +
  [`spore-svg.mjs`](../arrival/og/spore-svg.mjs), used by psanctuary and psanctuarychurch since
  2026-10-12). A drop-in alternative to `og-card.mjs` with the same `renderCard(spec, theme, base)`
  call and spec fields, plus `seed`: the title and summary on the org's dark mode, and a large
  spore print seeded by `seed` (the entry's slug) rising off the right edge, so every card gets a
  print of its own that stays the same from build to build. No glyph or frame; an optional `mark`
  (the org's square mark) sits beside the eyebrow. Copy both files unchanged into `src/og/` and
  write a theme from [`spore-theme.example.mjs`](../arrival/og/spore-theme.example.mjs) (it adds
  `spore`, `glow` and `sporeGlow` to the usual colors). Pick it when an org's main social card
  already has a bleed-off-the-edge motif; another org can follow the same pattern with its own
  figure generator in place of `spore-svg.mjs`.

### One map, two sites (canonical publisher → build-time consumer)

When two sites show the same diagram, keep one copy of the data. ORG's AstroLog owns the map
(`src/data/map.ts`, see [`arrival/astro/map.canonical.example.ts`](../arrival/astro/map.canonical.example.ts)),
resolved to geometry, drawn by `OrgMap.astro` and published as `/map.json`. The lab
([`map.consumer.example.ts`](../arrival/astro/map.consumer.example.ts)) fetches that file at build time
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
the O-R-G dApp preview. Canonical files: [`arrival/`](../arrival/) (`arrival.js`/`.css` are now
**v1.1**), [`arrival/ledger/`](../arrival/ledger/) and two new files in
[`arrival/astro/`](../arrival/astro/). **Porting agents: re-copy `arrival.js` + `arrival.css`
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
- **`latest.json`** (copy [`arrival/astro/latest.json.ts`](../arrival/astro/latest.json.ts)): newest
  first, absolute URLs, `{ updated, items: [{ type, t, k, i, h, d, ts?, who? }] }`: the last 30
  entries, dated library docs, and the last 45 days of ledger commits.

### The ledger (a calm, categorized record of public commits)

The technique follows Christopher's activity-ledger generator (public repos only, a deny list, a
keyword rubric, scrubbed subjects, a grouped accordion); nothing else is shared with it.

- **Files:** copy `arrival/ledger/ledger.mjs` and `snapshot.mjs` to `src/ledger/`,
  `arrival/astro/Ledger.astro` to `src/components/`, write `src/data/ledger.config.mjs` from
  [`ledger.config.example.mjs`](../arrival/ledger/ledger.config.example.mjs), add
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
[`verify-private.mjs`](../arrival/ledger/verify-private.mjs) and `arrival/astro/Ledger.astro`
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
  [`og-endpoints/ledger.jpg.ts`](../arrival/astro/og-endpoints/ledger.jpg.ts).
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

[`arrival/verify-wave5.example.mjs`](../arrival/verify-wave5.example.mjs) (Playwright + local Chrome,
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

## 🧩 Wave 6 / kit v1.2, proven out 2026-10-13 (psanctuary pair) — the interface half

Reference install: `psanctuary.github.io` + `psanctuary/changelog-astro` (the playful,
decentralized side) and `psanctuarychurch.github.io` + `psanctuarychurch/changelog-astro` (the
church's professional face). Same kit, two looks. The ledger half of wave 6 (ledger v2) is the
"Ledger v2" section under wave 5 above. **Rollout agents for PIR, THEF, ORG and the desks: this
section is your handoff.** Re-copy `arrival.js` + `arrival.css` unchanged; they're drop-in for a
v1.1 `org.js` (nothing new appears until you add the new keys and elements).

### What a visitor gets

- **A full navbar on every page** (portal, every AstroLog page, `/map`, `/ledger`, both 404s), with
  an icon beside every link in the nav, its dropdowns, the Menu and the footer. It **never wraps**:
  when the bar runs short, the lowest-priority items fold into a **More** dropdown (priority-plus);
  below `nav.fold` (1100px) the whole bar folds into a **Menu** button (the O-R-G dApp preview's
  pattern) that opens a grouped panel of everything and says "Close" while open. Dropdowns and the
  Menu are disclosure buttons (`aria-expanded`/`aria-controls`): ArrowDown opens and enters, arrows,
  Home and End move, Esc closes and returns focus, Tab out closes. This killed the two-row header on
  `psanctuarychurch.github.io/changelog-astro-public/ledger/`.
- **One contact modal.** Every "Reach out" link (`data-arrival-open="contact"`), and any plain click
  on a link to one of the configured paths (a form, a `CONTACTS.md`, a `mailto:` role address), opens
  one dialog listing every path, with "Copy address" for emails and marked placeholders for paths
  that don't exist yet. Modifier and middle clicks still go straight to the link.
- **One community modal.** Every platform the org has, each with a **public link** and a **sign-up
  link** (missing ones render "coming soon" so the slots are ready to wire), plus a **sneak-peek card**
  for the org's own network on Lens/Farcaster paired with its DAO, privacy first, never with a date.
  `#contact` and `#community` deep-link to the modals; both are in `/` search.
- **What's new, unmissable.** On a return visit the count is a filled accent pill ("✦ 22 new") with a
  gentle halo four times (a background swell where an org clips its shapes), a steady ring instead
  when motion is Still or reading mode is on, a **one-time tip** under it ("22 new since your last
  visit. Take a look"), the count on the **Menu button**, and a "new since your last visit" row at
  the top of the Menu. Links in the nav and footer to new things get a dot.
- **Reading, round 2.** Four **text size** steps (a scale on the root font size, so every `rem`
  grows) and a **comfortable line length** switch (paragraphs in `main` cap at 68ch with a taller
  line height), beside the reading switch in the drawer and the guide, and in `/` search ("text",
  "line"). Reading mode turns the shorter lines on and restores them after; text size is left alone.
  `<html data-text data-measure>`.
- **`/map/` on every site, with pictures.** Every destination as a card whose thumbnail is the
  share image its link shows, grouped (start here, the record, get involved, beyond GitHub), with
  "You are here". The AstroLog draws it at build time; the portal draws the same `map.json`.
- **A donate page** on each portal (`/donate/`): the org's own giving path (psanctuary links
  `psanctuary.org/donate`, never the Stripe link it forwards to), a per-org disclaimer slot, an
  **opt-in contribution ledger** (a JSON file, friendly when empty), and an empty, labelled **"Give
  with crypto, coming soon"** slot for the later wallet module. No wallet address, ever.
- **`/roadmap` and `/sustainability`** on every AstroLog, rendered from the repo's own `ROADMAP.md`
  and `SUSTAINABILITY.md`, linked from every footer.
- **A signature share card per org** and a card for every site page (the map's thumbnails).

### New org.js keys (all optional; annotated in [`arrival/org.example.js`](../arrival/org.example.js))

```js
nav: { label, fold: 1100, items: [
  { id, label, icon, href, hrefs?: { <siteId>: href }, open?: "contact" | "community" | "guide" | "search",
    exact?, priority? (lower folds first, default 2), keep?, sites?: [ids], hideOn?: [ids], note? },
  { id, label, icon, priority?, items: [ …links ] },              // a dropdown
] },
footer: { label?, groups: [{ label, icon, items: [navId | link] }], note? },  // default: repeat the nav
contact: { title?, intro?, paths: [{ kind: "form" | "email" | "page" | "github" | "chat", label,
  href?, note?, action?, icon?, placeholder? }], fine?, intercept? (default true) },
community: { …v1.0 keys (guide step)…, title?, intro?, eyebrow?, platforms: [{ id, kind:
  "discord" | "telegram" | "mighty" | "whatsapp" | "substack" | "bespoke" | "forum" | "email", name,
  text?, status?: "soon", public?: { href, label, note }, join?: { href, label, note } }],
  bespoke?: { title, tag?, icon?, text, points?: [], note? }, fine?, intercept? (default true) },
donate: { give: [{ label, href, icon?, note?, action? }], disclaimer?: { title?, text, placeholder? },
  ledger?: { src, title?, intro?, empty? }, crypto?: { title?, text?, note? } },
reading: { light, sizes?: [{ id, name, scale }], measure?: false },
```

Elements: `<arrival-nav current="<id>">` (in the header, between the brand and
`<arrival-controls>`), `<arrival-footer current>`, `<arrival-donate>`, `<arrival-map src here>`.
`data-arrival-open="contact" | "community"` on any link (keep a real `href` as the no-JS fallback).
`<html data-arr-nav="bar|menu">` lets site CSS react. `window.Arrival.open("contact")` works too.

### Porting checklist (per org)

1. **Kit:** copy `arrival/arrival.js` + `arrival.css` (1.2.1) unchanged into `<org>.github.io/arrival/`.
2. **org.js:** add `nav`, `footer`, `contact`, `community.platforms` + `bespoke`, `donate` (and
   `reading.sizes` if you want other steps). Facts only from the org's own materials; a path that
   doesn't exist is a `placeholder`, never a guessed URL. Contacts per org: PIR's `CONTACTS.md` +
   `psychedelicsinrecovery.org/contact/` + the service site's form; ORG's three role addresses (no
   `/contact` page, it 404s); psanctuary's `psanctuary.org/contact` + `info@psanctuary.org`.
3. **Portal header:** one row: `<a class="brand">…<span class="arr-brand-text">Name</span></a>`
   `<arrival-nav></arrival-nav><arrival-controls></arrival-controls>`, `flex-wrap: nowrap`, brand
   `min-width: 0`. Use [`arrival/portal/site.css`](../arrival/portal/site.css) (header, page footer,
   dock) or copy its four header rules; the kit also ships `.arr-header`. Put
   `<div class="page-foot"><arrival-footer></arrival-footer></div>` above the dock, and point the
   dock's Reach out / Community at `data-arrival-open`.
4. **Portal pages:** `/donate/` from [`portal/donate.example.html`](../arrival/portal/donate.example.html)
   with `donate/contributors.json` from [`contributors.example.json`](../arrival/portal/contributors.example.json)
   (empty array; names only with permission, first name + last initial, never an email or amount);
   `/map/` from [`portal/map.example.html`](../arrival/portal/map.example.html) (`<arrival-map
   src="…/changelog-astro-public/map.json" here="portal">`). The 404 gets the same header (links
   stay absolute). Write a short `SUSTAINABILITY.md` + `ROADMAP.md` for the portal repo.
5. **AstroLog `Base.astro`:** replace the old nav-links with `<arrival-nav current={active}>` and the
   one-row header from [`astro/Base.example.astro`](../arrival/astro/Base.example.astro); add the
   footer groups and the fuller dock. Widen `active` to the nav ids you use.
6. **AstroLog map:** `src/data/map.ts` from [`astro/map.v2.example.ts`](../arrival/astro/map.v2.example.ts)
   (version 2: groups + nodes with `og`), [`MapGrid.astro`](../arrival/astro/MapGrid.astro),
   [`map.json.ts`](../arrival/astro/map.json.ts), [`map.example.astro`](../arrival/astro/map.example.astro)
   → `src/pages/map.astro`. ORG and PIR already have a v1 diagram map (`OrgMap.astro`): keep it and
   add the v2 grid under it, or move the diagram's nodes into v2 groups. PIR's map lists every desk.
7. **Page cards:** [`astro/pages.example.ts`](../arrival/astro/pages.example.ts) → `src/og/pages.ts`
   (one card per site page and per external destination; external sites get a card of our own,
   never a hotlinked image) and [`og-endpoints/page-[slug].jpg.ts`](../arrival/astro/og-endpoints/)
   → `src/pages/og/page/[slug].jpg.ts`. Pass `ogImage={pageCardUrl("changelog")}` etc. on the index
   pages; make the default og the porch card. Copy the built `og/page/portal.jpg` over the portal's
   `social-card.jpg` (and `porch.jpg` over the AstroLog's).
8. **Roadmap + sustainability:** add the `docs` collection (`glob({ pattern: ["ROADMAP.md",
   "SUSTAINABILITY.md"], base: ".." })`), [`RepoDoc.astro`](../arrival/astro/RepoDoc.astro),
   [`roadmap.astro`](../arrival/astro/roadmap.astro), [`sustainability.astro`](../arrival/astro/sustainability.astro).
   Write the two files at the repo root from [`docs/`](../arrival/docs/) templates, **with absolute
   links** (they're read on GitHub too), and **add both to `public_allowlist` in
   `sync-public.yml`** or the validate tripwire fails the build.
9. **Signature card:** pick a look in `src/og/theme.mjs` (spore-card orgs: `frame: true, quiet: true`
   for formal, `prism: [colors]` for playful; og-card orgs can follow the same idea). No counts.
10. **People:** first name + last initial on public pages (`PEOPLE` in `site.ts`), roles only as the
    org states them. Changelog entry: `who: "Christopher W"`, TL;DR + `<details>`.
11. **Deploy order:** portal first (the AstroLog loads the kit from it), then the AstroLog.
12. **Verify:** [`arrival/verify-v12.example.mjs`](../arrival/verify-v12.example.mjs) against the live
    sites (edit `SITES`). psanctuary pair, 2026-10-13: **68/68 pass**, at 320–1920px.

### Signature share cards (spore-card.mjs, canonical in `arrival/og/`)

- `theme.frame: true` + `theme.quiet: true`: a double hairline frame in the accent, fewer and finer
  gills, an inner stem ring, a plain hairline rule. **psanctuarychurch**, the professional face.
- `theme.prism: ["#a88bc9", "#74bce0", "#9fe0c0", "#c9f76f", "#f0a6d0"]`: gills and dust sweep
  through those colors, ripple rings, tinted glows and a gradient rule. **psanctuary**, the playful
  side (it also got a Blacklight mode and an iridescent `.iris` title in `org.css`).
- `spec.hero: true`: the big-name layout for a site's own card (portal, porch).
- Never a count on a card: link previews are cached for weeks. Say what the page is.

### Gotchas found in wave 6

- **Two agents, one working tree.** A concurrent `git commit` swept my staged `arrival.js`/`.css`
  into the ledger agent's `6698c9c`. Stage nothing you aren't committing this second; commit with
  `git commit -- <paths>`; never `git add -A` in a shared clone.
- **The fold's safety net is `overflow: hidden` on the bar**, so the dropdown panels live outside
  it (siblings of the `<ul>`, positioned against `<arrival-nav>`), or they'd be clipped. The bar
  folds by measuring `scrollWidth > clientWidth` after fonts load and on every resize.
- **`<arrival-nav>` must keep `flex: 1 1 0`** in both modes: if it shrank to the Menu button in menu
  mode, a ResizeObserver would flip it back and forth.
- **Tight headers:** with the nav present the kit hides the light swatches, search's word and the
  drawer's word below 1500px, the cursor and book buttons below 1280px in bar mode, the motion button
  and drawer caret on small phones, and the brand's text at ≤400px (the mark stays, with an
  `aria-label`). "Psanctuary Church AstroLog" drops "AstroLog" between 1100 and 1279px.
- **Background-clip text and `text-shadow` don't mix:** an inherited text-shadow paints over the
  clipped gradient (an outlined, dark title). Set `text-shadow: none` and use `filter: drop-shadow`.
- **The "new" row bar looked broken on nav links;** inside `arrival-nav`/`arrival-footer` it's a dot.
- **Root files in the AstroLog repo** (`ROADMAP.md`, `SUSTAINABILITY.md`) must be classified in
  `sync-public.yml`, and root-relative links in them only work on the built site (base-links), not
  on GitHub, so write them absolute.
- **Mighty Networks blocks bots** (403 to curl and Firecrawl): its links can't be checked by
  machine. Use the paths the org gives; the verify script checks only that they're real URLs.
- Busy machine: other agents' `python -m http.server` held 8765 and 8791. Serve with
  `--directory` on an unusual port and check `lsof` before trusting a local result.

## 💳 Kit v1.3, 2026-10-14 — Give with crypto

Reference install: every portal's `/donate/` (THEF, ORG, psanctuary, psanctuarychurch on; PIR off).
Canonical files: [`arrival/arrival.js`](../arrival/arrival.js) + [`arrival.css`](../arrival/arrival.css)
(now **1.3.0**) and the new [`arrival/give/give.js`](../arrival/give/give.js). **Rollout agents: re-copy
all three unchanged** (`give.js` goes to `<org>.github.io/arrival/give/give.js`). They're drop-in for
a v1.2 `org.js`: with no `give` key, the donate page keeps its empty "coming soon" slot.

### What a visitor gets

- **At first paint** (drawn by `arrival.js`, so nothing moves later): "Give with crypto", a
  **Preview** badge while the org has no address, one row per coin (Ethereum, Bitcoin, Solana) that
  says **"Treasury address coming soon"**, a **Connect a wallet** button and **New to wallets?**
- **One Connect button for every kind of wallet** (Reown AppKit): browser extensions, phone wallets
  by **QR code** or deep link (so **Safari and phones work**), and **email or social sign-in**
  (Google, X, Discord, Farcaster, GitHub, Apple, Facebook). Email/social costs nothing extra: it
  comes with Reown's free plan and is on by default; the dashboard can narrow it (below).
- **No address, ever, until the org publishes one.** Connecting is then a labelled preview: "No
  treasury address is published yet, so there's nothing to send to, and nothing has been sent."
- **With an address** (none today): the address in groups of four, **Copy**, **Show QR code** (dark
  on white in every light), **Open in a wallet app** for BTC/SOL (`bitcoin:`/`solana:` links), and for
  ETH **Send with your wallet**: an amount, then a prefilled transfer the visitor approves in their
  own wallet (exact wei math, no floats; a mixed-case address is checksum-checked with viem first).
  Afterwards, optionally, **Add your name to the contributors list**: the donor signs a plain
  message (free, no gas) naming the transaction and the name to show, and gets a JSON note with
  **Copy** and a prefilled **Email it to …** (the first email in `contact.paths`, or `give.claim.to`).
  The page stores nothing and sends nothing.
- **"New to wallets?"**: a kit dialog in plain words (what a wallet is, browser vs phone wallets,
  why Safari can't use extensions, how to use a phone wallet instead, staying safe, where to get a
  wallet), from David's Web3 guide in `david-amaringo`. It opens by itself when nothing is available.
- **Calm when wallet connect isn't switched on for the site:** "Wallet connect isn't switched on for
  this site yet. Nothing is wrong with your wallet or your browser…", with the guide. If the visitor
  has a browser wallet, it connects that directly instead and says phone wallets aren't on yet.
- Keyboard throughout; the guide traps focus, Esc closes it, focus returns; still motion and
  reduced motion stop its animation; every light, more contrast (the hatching flattens) and reading
  mode; 320px up.

### The mechanism

- `arrival.js` draws the section from `ARRIVAL.give`, then loads `give/give.js` (resolved from its
  own `<script src>`, so it works cross-origin too) when the section comes within 600px of the
  screen, or on the first click. Every `[data-give]` button routes through the kit's click handler
  to `ArrivalGive.act()`.
- **Nothing leaves the page until a click.** On Connect, `give.js` first asks Reown's public
  allowlist endpoint (`api.web3modal.org/projects/v1/origins?projectId=…`, CORS-open, cached 5 min)
  whether this origin is listed, mirroring AppKit's own rules (an empty list allows every site;
  localhost always). Not listed: the calm state, and **AppKit is never downloaded**, so there's no
  "Origin … not in your allow list" console error to see.
- Listed: it imports **`@reown/appkit-cdn@1.8.24`** (published 2026-09-16, the latest stable) from
  jsDelivr, with the Wagmi adapter, the org's `chains`, `metadata` from `org.js` (name, mark, the
  page's origin, so wallets show the org), `analytics: false`, no swaps/on-ramp/send/receive, and
  plain (EOA) accounts for email sign-ins so signatures verify with ordinary tools. Theme follows the
  kit (dark/light from the mode, `--accent`, the body font) and updates on `arrival:change`.
- **Belt and braces:** if AppKit still reports the origin (a stale cached answer), `give.js`
  catches that console message (APKT002 and friends), shows the calm state and logs one
  `console.info` line pointing at `SUSTAINABILITY.md`.
- QR codes: `uqr@0.1.3` (MIT, no dependencies), imported only when someone opens one.
- New kit API for modules: `Arrival.dialog({ title, eyebrow, html, cls })` → `{ el, show, hide }`
  (the kit's dialog: focus trap, Esc, backdrop, focus return) and `Arrival.toast(text)`.

### org.js

```js
give: {
  reownProjectId: "00b6a1cd528ff580f1fd845ed08b0187", // public client ID (the O-R-G dApp's project)
  chains: ["mainnet"],                    // + base, arbitrum, optimism only if the address receives there
  addresses: { eth: null, btc: null, sol: null },    // null until the org publishes one
  note: "",                               // the org's own words, after the safety line
  // social: false (no email/social sign-in), claim: { to: "…" }, words: { … }, enabled: false
},
```

`give` (top level) is the wallet module; `donate.give` is still the list of giving links. **PIR:
`give: { enabled: false }`**: PIR can't accept outside contributions under its traditions; the
donate and sponsorship wording is the A.L.E.X. session's (`~/code/pir/pending-tasks.md`, "(Alex)
Donate-page disclaimer"). Its empty slot and placeholder disclaimer stay.

### For Christopher: switch wallet connect on (Reown dashboard)

1. Sign in at **https://dashboard.reown.com** with the account that owns project
   `00b6a1cd528ff580f1fd845ed08b0187` (the one made for the O-R-G dApp).
2. Open that project's **domain allowlist** and add these five origins exactly as written (scheme,
   lowercase, no trailing slash), keeping `https://drasticstatic.github.io`:
   - `https://psychedelicsinrecovery.github.io` (ready for later; PIR's module is off)
   - `https://theholyearthfoundation.github.io`
   - `https://octagon-religious-research-group-org.github.io`
   - `https://psanctuary.github.io`
   - `https://psanctuarychurch.github.io`
3. Save, wait up to 5 minutes (the allowlist answer is cached), reload any `/donate/` and press
   **Connect a wallet**: the wallet window opens instead of the calm state. Check with
   `curl -s "https://api.web3modal.org/projects/v1/origins?projectId=00b6a1cd528ff580f1fd845ed08b0187"`.
4. Optional: email/social sign-in is on with AppKit's default providers because the project leaves
   them unset. To pick providers or turn it off for everyone, use the project's AppKit features
   settings in the dashboard (they override `org.js`); per org, `give.social: false`.
5. Nothing to do in Web3Auth: the kit doesn't use it.

**One shared project, or one per org?** Shared (today): one allowlist, nothing to set up per org,
and wallets still show each org's own name and mark (from `metadata`). But all five share one
free-plan usage limit and one dashboard, the project lives in Christopher's account, and deleting or
breaking it switches wallet connect off everywhere. One per org: each org's keepers own their
project, limits and settings (and can later verify their domain for wallets' "verified" mark), at
the cost of five dashboards. **Recommendation:** keep the shared project while every address is
null (it's only a preview); give an org its own free project when it publishes a treasury address,
and change `give.reownProjectId` in its `org.js` (one line).

### Publishing an address later (per org)

1. Paste the address exactly as the org's wallet shows it (checksummed for ETH) into
   `give.addresses`; the kit refuses anything that doesn't look like its coin's address and shows
   "coming soon" instead. List in `chains` only networks the address really receives on.
2. Send a tiny test amount from another wallet using the page's own Copy, QR and Send, and confirm
   it arrived, before telling anyone.
3. "Add your name" notes: check the signature recovers to `proof.address` (for example
   `cast wallet verify --address <address> "<message>" <signature>`, or Etherscan's Verified
   Signatures page) and that `proof.tx` came from that address to the published one. Then add only
   `entry` to `donate/contributors.json`; keep `proof` private (it links a name to a wallet).

### Verify

[`arrival/verify-give.example.mjs`](../arrival/verify-give.example.mjs) (Playwright + local Chrome, a
fresh context per check, live URLs, `--local <id>=<repo>` to test before pushing): lazy load with no
third-party request before a click and no height change; Connect opens AppKit or the calm state with
the guide; the guide's focus trap, Esc and focus return; AppKit never downloaded on an unlisted
site; no address text; no page errors or red console; one header row at 320–1440px (every org,
PIR included). **Live, 2026-10-14: 36/36 pass** on all five portals (four show the calm state until
the allowlist is updated; PIR's slot stays empty), and every AstroLog and portal home loads kit
1.3.0 with no page errors. Address mode,
QR, send and the signed note were exercised locally with a random in-memory value and a mock wallet
(nothing written down), and AppKit was opened for real on `http://127.0.0.1` (Reown always allows
localhost): email, Google, X, Discord, Farcaster and GitHub sign-in, WalletConnect QR, wallet search.

### Gotchas

- **Native `<dialog>` sits in the top layer**, above any z-index, so AppKit's window would open
  *under* the kit's guide. `give.js` closes the guide before it opens AppKit.
- The kit opens the contact modal for any plain click on a configured `mailto:`; the "Email it to …"
  link carries `data-arr-direct` so it really opens the mail app.
- AppKit's remote config (the dashboard) wins over local `features` where it's set, and warns in the
  console when it overrides a local value; `give.js` only sets what the dashboard leaves unset today.
- A header-row check that scrolls first sees negative `top`s and mis-rounds them; measure the header
  before scrolling, and test "one row" as vertical overlap.

## 🤲 Kit v1.4, 2026-10-22 — essentials everywhere, a sturdier footer, a pledge of support

Canonical files: [`arrival/arrival.js`](../arrival/arrival.js) + [`arrival.css`](../arrival/arrival.css)
(now **1.4.0**), [`arrival/give/give.js`](../arrival/give/give.js) (1.4.0, its wallet layer now shared)
and the new [`arrival/pledge/pledge.js`](../arrival/pledge/pledge.js). **Rollout agents: re-copy all four
unchanged** (`pledge.js` goes to `<org>.github.io/arrival/pledge/pledge.js`). Drop-in for a v1.3
`org.js`: **only the essentials (Donate + Welcome guide) appear without new keys**; the dock
affordance, grouped dropdowns, the pledge and the tax section wait for their keys.

Rolled out 2026-10-22: **psanctuary, psanctuarychurch, THEF and ORG portals** (their AstroLogs and the
drasticstatic ORG lab load the kit from there, so they're on 1.4.0 too). **PIR followed the same day**
(hub `9693b2b`, byte-identical 1.4.0): its local "1.3.1" fork is retired. Foyers and Helpers became
native `groups`, and `concierge.js` and `more-tree.css` were deleted. The fork's More-panel flyouts were
not ported (the kit lists folded dropdowns as grouped rows). Policy reform's AstroLog moves from 1.2.1 in
its own pass.

### What a visitor gets

- **Donate and the welcome guide, always.** In every footer, in the navbar's **More** dropdown and in
  the **Menu**, whatever an org's config forgot. More now stays in the bar to hold them (closing rows
  under a hairline; a row hides while a folded item already shows it). In the Menu and the footer they
  join the group that holds contact or community ("Get involved"), or get a group of their own.
- **One footer, the same everywhere.** The kit's footer CSS is scoped: what's inside is styled at
  (0,2,1) and sets every box property a host stylesheet tends to touch, so a site's `section`,
  `footer a`, `.wrap a`, `ul`, `li::before` rules can't reach it. Columns are **balanced** (four groups
  in a row of three become 2 + 2, never 3 + 1). `<arrival-footer frame>` draws the kit's card for a
  page with no frame of its own.
- **You can tell the dock scrolls.** When the bottom strip overflows (phones): a soft fade on the edge
  with more beyond it and a small chevron button there. Only on the side with more; gone when it fits;
  keyboard reachable (Tab, Enter), focus is handed on when a chevron runs out of room, a focused link
  scrolls clear of the fade, instant under reduced motion or Still, and it shows in every light, more
  contrast and reading mode (shorter fade, firmer button there).
- **Grouped dropdowns.** A dropdown can have `groups`, each with a small heading and a hairline
  divider, in the dropdown, the More panel and the Menu (e.g. PIR's Foyers: "Committees", then
  "Infrastructure"). Each group is a labelled `role="group"`; arrows, Home/End and Esc work as before.
- **A pledge of support** (`<arrival-pledge>`, on a page of its own): the pledge in plain words, then
  three steps (read, connect a wallet, sign). Signing is an **EIP-191 message signature: no gas, no
  money, nothing sent, nothing recorded**; it's checked in the tab against the connected wallet and
  then forgotten, and the page never shows the wallet's address ("Copy my signed pledge" puts message,
  address and signature on the clipboard only). Two cards: **"Gratitude tokens (coming)"** (soulbound,
  non-transferable tokens of gratitude from Christopher W's gratitude-token project, an optional deeper
  commitment, no dates) and **"How you'll know these aren't bots"** (a signature proves a wallet
  signed, not that a unique person did; before any count or list appears, pledges will be published as
  verifiable records, e.g. Ethereum Attestation Service attestations, optionally gated by
  proof-of-personhood such as Human Passport (formerly Gitcoin Passport), World ID or BrightID, named
  only as options; **until then the page shows no counts at all**). And a **verify-a-signature tool**
  (`#verify-signature`): paste address, message and signature, and the signer is recovered in the
  browser; mixed-case addresses are checksum-checked; trailing blank space is forgiven and said so.
- **Receipts and taxes** on `/donate/`: a calm section that claims nothing by default ("Ask us for a
  receipt: reach out…"; "Whether a gift is tax-deductible depends on the organization's status and
  your own situation"; "This isn't tax advice"). Only the org's own config states a status.

### Config (annotated in [`arrival/org.example.js`](../arrival/org.example.js))

```js
essentials: { donate?: false | { label, href, icon, note }, guide?: false | { label, icon, note } },
                                         // or false; default: both on. Donate's href: the nav's own
                                         // "donate" item, else donate.href, else <portal>/donate/
dock: { scroll: true, selector? },       // or dock: true; data-arr-scroll on any strip opts it in
nav.items[]: { id, label, icon, items?: [link], groups: [{ label, icon?, items: [link] }] },
donate.tax: { status?, deductible?: "…" | true | false, receipts?, note?, title? },   // {} = defaults
pledge: { text, note?, href?, title?, intro?, reownProjectId? (default give.reownProjectId),
          tokens?: false | { title, text, href, label }, bots?: false | { title, points: [] },
          verify?: false, enabled?: false, words?: {} },
```

**Per org, later agents fill in:** `dock: { scroll: true }` (every org; PIR's `.dock .wrap` is
matched by default); `pledge.text` (+ `href`, `note`) in the org's own words, and a `/pledge/` page from
[`portal/pledge.example.html`](../arrival/portal/pledge.example.html) (+ a page card, a map node, and a nav
or footer link if wanted); `donate.tax` (`{}` until the org publishes a status; `status` and
`deductible` only from the org's own materials); PIR's Foyers as `groups` (then drop concierge.js's
separators, rename and reorder); `essentials` only to opt out or relabel. `give.reownProjectId` stays
the shared project until an org gets its own (one line).

### The mechanism

- **Essentials**: `essentials()` resolves Donate and the guide once; `withEssentials()` adds the
  missing ones to the footer's and Menu's groups; More gets a closing `[data-arr-ess]` block that
  `fitNav` measures (More stays) and `syncEssentials` dedupes against folded items (`data-arr-holds`).
- **Footer**: groups are resolved first (`{ label, icon, links }`), then rendered with
  `.arr-foot-list` / `.arr-foot-li`; a ResizeObserver sets `--arr-foot-cols` (the most columns at
  11.5rem each, then evened out), also on `arrival:change` (text size).
- **Strips**: `makeStrip()` adds `.arr-strip` and two absolutely placed buttons as siblings in the
  strip's parent (a static parent becomes `position: relative`); `syncStrip()` toggles
  `.arr-strip-l/-r` (mask gradients) and the buttons on scroll, resize and font load. RTL-aware.
  `Arrival.strips(scope)` picks up strips added later.
- **Pledge**: arrival.js draws the whole pledge at first paint, then loads `pledge/pledge.js` when it
  nears the screen (`loadModule`, shared with give.js). pledge.js imports `give/give.js?v=<version>`
  (the same URL arrival.js uses, so one module instance) and uses `ArrivalGive.wallet`: `allowed`,
  `load` (one AppKit per page), `connectBrowser`, `sign`, `on`, `learn`. The signer is recovered with
  `@noble/curves@1.9.7` (secp256k1) + `@noble/hashes@1.8.0` (keccak-256) from jsDelivr, imported on
  first use; 65-byte and EIP-2098 64-byte signatures. Nothing third-party loads before a click.
- **Signed message**: `<org.name>: a pledge of support` / the pledge / `Signed on <host>, <date>.` /
  `Signing this is free. It sends nothing and approves nothing, and for now nothing is recorded.`

### Footer: why PIR's looked different, and what every site must include

PIR's hub, AstroLog, convention, gallery and board desk put `<arrival-footer>` inside alex.css's
`footer .wrap` grid (a brand column beside it), so it got ~767px and three columns: four groups landed
3 + 1. alex.css's `section { padding: 5.5rem 0 }` and `footer a { display: block; margin }` also
reached the kit's groups; PIR's org.css patched those by hand, and `concierge.js` (another assistant's)
renames and reorders the nav at runtime with a 4-second poll. Where that patch isn't loaded, the damage
shows: **drasticstatic.github.io/alexandrina-public-preview/** has 96px of padding on every footer
group, and no Donate or guide. Kit 1.4 makes the patch unnecessary. Every site must include:

1. `arrival.css` before `org.css` and the site's own CSS, and `arrival.js` in `<head>`.
2. `<arrival-footer current="<nav id>">` in a block of its own: the portal's
   `<div class="page-foot">` (site.css) or `<arrival-footer frame>`; if a host grid puts it beside a
   brand column, give it the wider track (PIR: `minmax(15rem, 1.1fr) 3fr`).
3. A `donate` block (or a nav item with id `donate`) so the essential Donate has somewhere to go.
4. Restyle the footer only with the kit's own selectors (`arrival-footer .arr-foot .arr-foot-a`).

**PIR pages for the PIR agent** (checked live 2026-10-22 before PIR moved to 1.4.0; all fixed that day except catalyst-desk-public, which publishes once its `PUBLIC_REPO_TOKEN` exists): no kit and no
footer at all on **catalyst-desk-public/**; footer **without the Welcome guide** on **alex-desk-public/**
(and its `portal.html`, `web3.html`, `privacy.html`), **litcom-desk-public/**, **techcom-desk-public/**,
**github-desk-public/**, **pr-desk-public/** and **gsr-desk-public/** (the desks swap in their own footer
config); the Menu has no Welcome guide anywhere. On 1.4 the kit adds the guide and Donate itself; the
catalyst desk needs the kit added.

### Verify

[`arrival/verify-v14.example.mjs`](../arrival/verify-v14.example.mjs) (Playwright + local Chrome + viem;
`--local <id>=<repo>` before pushing, `--deep <id>` for the full feature checks). It switches the
configured features on for the test by wrapping `window.ARRIVAL` as org.js sets it, so nothing is
written to a site; the test pledge key is generated in memory and never written down. **Live,
2026-10-22: psanctuary 27/27** (essentials, one header row 320–1920px on portal/donate/porch, hostile
host CSS, balanced columns, dock fades + chevrons at 320px in every mode, keyboard and reduced motion,
the grouped dropdown, receipts and taxes, the pledge lazy-loading with nothing third-party before a
click, **AppKit opening on the allowlisted origin**, the verify tool accepting an in-memory signature and
rejecting a tampered one, signing through a stand-in browser wallet, no counts, no address text, no
console errors); **THEF, ORG, psanctuarychurch 21/21** (essentials + header rows); `verify-give` still
24/24 on all four (give.js's wallet layer changed); the drasticstatic ORG lab loads 1.4.0 with one
header row and no errors.

### Gotchas

- **More is always in the bar now** (it holds the essentials), so a bar folds one item sooner. All
  four orgs keep one header row from 320 to 1920px.
- **The guide's Connect button** is `data-give-learn="connect"`, handled inside give.js, so the
  "New to wallets?" guide works on a page with no give section (the pledge's); `learn(kind, { onConnect })`.
- **A custom `give.module` URL** would give pledge.js a second give.js instance (two AppKits on a page
  with both); leave it unset.
- **Smart-contract wallets** (a Safe) sign with ERC-1271, which can't be recovered offline: the page
  says so. AppKit already makes email sign-ins plain (EOA) accounts.
- **Equal specificity loses to source order**: v1.4's first footer pass at (0,1,1) still lost to a
  host `.page-foot a`; it's (0,2,1) now. Element-scoped resets alone weren't enough.
- **PIR's fork (resolved 2026-10-22)**: its More panel was a flyout tree (`.arr-nav-more-scroll`, `.arr-nav-fly`). Moving PIR
  to 1.4 means porting or dropping that (the essentials block closes the More panel), and replacing
  concierge.js's Foyers patching with `groups`.
- Copy-check before every rollout: `cmp` each destination against the previous canonical version;
  a mismatch is a fork, not a stale copy.

## 🗣️ Kit v1.5, 2026-10-26 — languages: a warm welcome in each visitor's own words

**Why:** Christopher asked for "a warm multilingual language welcome to all organizations". A read-only
recon across PIR, Psanctuary, Psanctuary Church, ORG and Psychedelic Policy Reform found every site
English only. Despite the README's old line about "language pickers", the kit had none: one `words`
hook, in one language. About 200 more English strings were drawn straight from the code, and dates
were fixed to `en-US`.

**What changed** (branch `kit-1.5-languages`, built and tested in the lab before any portal):
- **Every string the kit draws now lives in one table**, `WORDS` (arrival.js), plus `PWORDS` for the
  pledge. give.js and pledge.js keep their own tables. 215 kit words, 74 pledge words and 73 give
  words, all re-voiceable by an org and all translatable.
- **`arrival/i18n/es.js`**, the kit in Spanish. It's warm Latin-American Spanish using tú, with David
  Amaringo's site as the voice reference. It loads only for a visitor who chooses Spanish.
  `reviewed: false` until a native speaker reads it.
- **`languages` and `i18n` in org.js.** With two or more languages, the splash opens with "Your language
  · Tu idioma", and each language's door is written in that language. Choosing one redraws the splash at
  once. The drawer has the same row, and the header gets a small language chip.
- **Honest content:** a page without a translated twin keeps its words and says so in one quiet line,
  with no machine-translation widget. `<arrival-langnote>` places that line in a page.
- **A returning visitor never sees the wrong language flash.** The kit's elements wait up to 1.2s for
  the pack (usually from the cache, at once).

**Decisions worth keeping:**
- **`<html lang>` is left alone.** It describes the page's own words. The kit marks its own menus and
  dialogs with `lang`, so a screen reader voices English content in English and Spanish menus in
  Spanish. `data-lang` on `<html>` carries the choice for CSS. (The recon suggested setting `<html
  lang>`. That would make screen readers read English pages with Spanish pronunciation.)
- **An org.js without `languages` is byte-identical to 1.4.** It was checked by rendering main's kit and
  this one with the same v1.4 org.js in jsdom and comparing the whole document at 20 points: the
  splash, the drawer, all eight guide steps, search, contact and community. Every one was identical.
- **Doors, not a dropdown.** Each door's icon is closed until it's the chosen one, then open: the
  one small flourish. Doors sit side by side where there's room, and one per row on a phone, so each
  welcome stays on one line.
- **The legend asks in every language** ("Your language · Tu idioma"), in the drawer too, so someone
  who can't read the current language still finds the way back.
- **Search finds a language by its own name.** Typing "español" offers "Language: Español". Spanish search
  words keep the English ones too.

**Gotchas:**
- **jsdom fires DOMContentLoaded after a synchronous `eval`.** A harness that snapshots right away never
  sees the splash. Wait a tick first. (The first comparison run "passed" without the splash in it.)
- **A local test server needs `Cache-Control: no-store`.** Otherwise Chrome keeps the old `arrival.css`
  across reloads, and a fixed layout looks broken.
- **`height: 100%` on a door's inner panel** resolved against the grid row before the content was
  counted, and clipped the welcome line. `min-height` fixed it.
- **The toast must wait for the pack.** Fired at boot, the once-per-visit note came out in English
  ("Menus in Español…"). It now follows `langReady`.

**Rollout, when Christopher says go** (not done in this pass):
1. Copy `arrival.js`, `arrival.css`, `give/give.js`, `pledge/pledge.js` and the new `i18n/es.js`
   unchanged to each portal's `/arrival/`, and to the policy-reform AstroLog's self-hosted copy.
2. Each org adds `languages` (and as much of `i18n.es` as it has words for) to its own `org.js`.
3. PIR: the kit may translate its own buttons. PIR® literature stays in English until the Literature
   Committee provides official translations.

## 🧪 Kit v1.5.1, 2026-10-26: the practice wallet

Christopher asked: *"can you utilize a throwaway wallet for those who want to experience the site's
web3 function without having a wallet set up yet?!"* The pledge now offers **"Try it with a practice
wallet"**:
- **The key** is a secp256k1 key made in the tab with the pinned @noble code the pledge already uses to
  verify. It's held in memory and wiped on "End practice".
- **The flow:** it signs the pledge as `personal_sign` does, and the existing `recover()` checks it.
- **Never stored, never shown, never copied.** It never loads the wallet layer.
- **Tested in Chrome:** English and Spanish, keyboard, and 390px wide. During practice the only network
  requests were GETs for the @noble modules. No storage changed, and nothing showed in the console.

**Why not wagmi's `mock` connector?** It forwards `personal_sign` to the chain's RPC (it expects a local
Hardhat or Anvil node), and wagmi persists connections to localStorage. Both break "nothing sent,
nothing saved". The policy-reform dApp got the same practice wallet with viem's `generatePrivateKey`,
held in a React ref, outside wagmi.

**Also in 1.5.1:** the "New to wallets?" guide was written straight into give.js's HTML, so its
sections stayed in English on a Spanish page. Its words now live in give.js's `WORDS` table (`learnWhat…`
through `learnGet…`), with `{connect}` and `{who}` slots, and every pack carries them (389 words each).

## Future enhancement, not required (can simmer)

`divorce-custody-assistant/vocational-compliance/build_vocational_log.py` generates an animated,
git-history-driven changelog-style exhibit (`exhibit-4.html`) with accordion-style reveal sections
and CSS-keyframe visual polish — built for a legal audience, not a community one, but a genuinely
good reference for a more interactive presentation layer if/when the basic system here wants to
level up visually. Not part of this template's baseline; note it here so it isn't lost.

---

Co-Authored-By: Alfred · ClaudeCodeCLI · Anthropic [Sonnet-5]
Co-Authored-By: Alfred · ClaudeCodeCLI · Anthropic [Opus-5.5]

