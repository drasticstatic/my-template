// ORG's ledger config (astro/src/data/ledger.config.mjs). Plain .mjs so both the Astro build and
// `npm run ledger:snapshot` can import it. Copy and change per org.
import path from "node:path";

export const LEDGER = {
  // Whose public history: an organization ("org") or a person ("user", e.g. a lab's repos).
  owner: "Octagon-Religious-Research-Group-ORG",
  ownerType: "org",
  // Optional: only some repositories (a RegExp or a function of the name). A user account usually
  // needs this, e.g. the O-R-G lab keeps /^O-R-G-.*-public(-preview)?$/.
  // include: /^O-R-G-/,
  // Never these, even when public.
  deny: [],
  // Friendly names. Anything not listed shows its repository name.
  repoLabels: {
    "org-frontend": { label: "orgspirituality.org", blurb: "The live site" },
    "org-backend": { label: "The API", blurb: "Offerings, members and editable pages" },
    "Octagon-Religious-Research-Group-ORG.github.io": { label: "Entry portal", blurb: "ORG's front door on GitHub" },
    "changelog-astro-public": { label: "AstroLog", blurb: "This record" },
    ".github": { label: "Organization profile" },
    "brand-assets": { label: "Brand assets" },
    "ORG-Website": { label: "The first site" },
  },
  // The same people the site already credits, named and pictured exactly as it does. `github` gives
  // the picture; `logins` / `names` are other ways they appear in commit history (no picture unless
  // `github` is set). Anyone else is named by config.nameStyle and gets initials.
  people: [
    { name: "Tripp Aardema", logins: ["ORG-Spirituality"], names: ["Tripp"] },
    { name: "Renan Teixeira", github: "SCDEVBrazil" },
    { name: "mitch8020", github: "mitch8020" },
    { name: "Christopher", github: "drasticstatic" },
  ],
  // "full" | "first-last-initial" (PIR's public pages) | "first". Applies to anyone not in people.
  nameStyle: "full",
  // Co-authors worth naming from commit trailers ("Christopher with Alfred"). Only these names.
  coAuthors: ["Alfred"],
  timeZone: "America/New_York",
  maxPerRepo: 400,
  // The committed fallback, used when the live fetch fails. Refresh: npm run ledger:snapshot
  snapshot: path.resolve("src/data/ledger.snapshot.json"),
};
