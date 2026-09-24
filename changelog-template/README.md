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
4. Adjust the `Base` import path in `index.astro`/`[slug].astro` to your project's own layout, and
   re-skin the inline `<style>` blocks to match your project's look — the collection-query logic
   and priority-badge markup are the reusable part, the visual design is meant to differ per
   project ("front ends look a bit tastefully different in appearance, but the backend logic is
   the same" — the whole point of building this as a template).
5. Add one entry (real, not placeholder) to prove it end-to-end before considering the setup done.

## Future adopters (breadcrumbed, not built — 2026-09-23)

- **`O-R-G`** already has the right instinct half-built: `O-R-G-astro`/`O-R-G-astro-public`'s own
  README states "changelog-as-content... rendered as a public, browsable site" but it was never
  finished (placeholder page only, no content collection). When O-R-G is ready, finish that
  existing scaffold using this template rather than starting a second, separate site.
- **dappU/Ethereal Offering** (`gratitude-token-project` — already using the sync-workflow's
  allowlist model, per `sync-public-allowlist.yml`'s own comment header) is a personal-repo
  candidate for this template "when we get there with Mystarch."
- **`psanctuarychurch/`** — not yet a real GitHub org (placeholder only, per
  `~/code/README.md`'s org-vs-personal notes). Tripp (O-R-G) is a friend of Psanctuary the way
  Kenney (THEF) is a friend of PIR — worth keeping in mind if/when Psanctuary's work professionalizes
  into its own community org the way THEF and PIR already have.

## Future enhancement, not required (can simmer)

`divorce-custody-assistant/vocational-compliance/build_vocational_log.py` generates an animated,
git-history-driven changelog-style exhibit (`exhibit-4.html`) with accordion-style reveal sections
and CSS-keyframe visual polish — built for a legal audience, not a community one, but a genuinely
good reference for a more interactive presentation layer if/when the basic system here wants to
level up visually. Not part of this template's baseline; note it here so it isn't lost.

---

Co-Authored-By: Alfred · ClaudeCodeCLI · Anthropic [Sonnet-5]
