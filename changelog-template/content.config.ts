// Changelog content collection — fleet-wide template, see README.md in this directory for the
// full convention. Copy into your project's astro/src/content.config.ts (merge with any existing
// collections rather than overwrite if the project already has one, e.g. littlebird-ambassador's
// `proposals` collection).
//
// Pattern proven in littlebird-ambassador/astro/src/content.config.ts — same mechanism (Astro's
// built-in glob() loader), generalized here with a changelog-specific frontmatter schema.
import { defineCollection, z } from "astro:content";
import { glob } from "astro/loaders";

const changelog = defineCollection({
  // "../changelog" = a directory named `changelog/` at the project root, OUTSIDE `astro/` — keep
  // it there, not inside astro/src/. The sync-public-allowlist.yml workflow builds the Astro site
  // (which reads this directory at build time) and THEN strips the whole `astro/` source tree
  // before pushing to the public repo — if `changelog/` lived inside `astro/`, its raw markdown
  // source would ship to the public repo alongside the private site source. Keeping it as a
  // sibling of `astro/` means only the compiled HTML ever reaches the public side, same as
  // proposals/ does for littlebird-ambassador.
  loader: glob({ pattern: "*.md", base: "../changelog" }),
  schema: z.object({
    title: z.string(),
    date: z.string(), // YYYY-MM-DD
    priority: z.enum(["P1-high", "P2-medium", "P3-low"]).default("P2-medium"),
    // Optional: which project/org this entry belongs to, for a shared multi-project changelog
    // site if one is ever built. Each project's OWN changelog-astro instance (the default per the
    // README) doesn't need this — only set it if you're deliberately running one shared site.
    org: z.string().optional(),
  }),
});

export const collections = { changelog };
