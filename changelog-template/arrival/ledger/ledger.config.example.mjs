// ORG's ledger config (astro/src/data/ledger.config.mjs). Plain .mjs so the Astro build,
// `npm run ledger:snapshot` and `npm run ledger:verify` can all import it. Copy and change per org.
import path from "node:path";

export const LEDGER = {
  // Whose history: an organization ("org") or a person ("user", e.g. a lab's repos).
  owner: "Octagon-Religious-Research-Group-ORG",
  ownerType: "org",
  // Optional: only some PUBLIC repositories (a RegExp or a function of the name). A user account
  // usually needs this, e.g. the O-R-G lab keeps /^O-R-G-(astro-public|dapp-public-preview)$/.
  // include: /^O-R-G-/,
  // Never these public repositories.
  deny: [],
  // v2: the private repositories whose work shows "behind the curtain", by name. Only these are ever
  // requested, and only with LEDGER_TOKEN (a token that can read them; CI passes PUBLIC_REPO_TOKEN).
  // Each commit shows the repository (or `label`), day, time, kind, priority, person and agents, and
  // its description MASKED as blocks; it never links anywhere. `mask: "full"` is the default and the
  // only mode to use without a decision: `mask: "sanitized"` (explicit opt-in) shows the scrubbed
  // summary instead. A repository listed here is never read by the public lane, even if it turns
  // public. List them with `gh repo list <org> --visibility private`.
  private: [
    { repo: "changelog-astro", label: "AstroLog source", mask: "full" },
    { repo: ".github-private", label: "Organization notes", mask: "full" },
  ],
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
  // The people the site credits. `name` is shown through nameStyle (so give a last name or initial:
  // "Renan Teixeira" shows as "Renan T."). `github` links the name to their profile and gives the
  // picture; `avatar: "generated"` keeps the link but draws the kit's generated avatar instead (for
  // anyone whose GitHub picture is the default identicon). `logins` / `names` are other ways they
  // appear in commit history; a matched login also becomes the link when `github` isn't set.
  people: [
    { name: "Tripp Aardema", logins: ["ORG-Spirituality"], names: ["Tripp"] },
    { name: "Renan Teixeira", github: "SCDEVBrazil", avatar: "generated" },
    { name: "mitch8020", github: "mitch8020" },
    { name: "Christopher W", github: "drasticstatic", names: ["Christopher", "Christopher Wilson", "drasticstatic"] },
  ],
  // "first-last-initial" (the default since v2: "Christopher W.") | "first" | "full". Applies to
  // everyone, listed or not. A single name or handle stays as it is.
  nameStyle: "first-last-initial",
  // AI co-authors from Co-Authored-By trailers get their own row ("with Alfred · Claude Code").
  // `agents: false` hides it; `agentNames: [[/^nova$/i, "Nova", "Cursor"]]` adds names to the table.
  timeZone: "America/New_York",
  maxPerRepo: 400,
  // The committed fallback (masked form only), used when the live fetch fails.
  // Refresh: LEDGER_TOKEN=$(gh auth token) npm run ledger:snapshot
  snapshot: path.resolve("src/data/ledger.snapshot.json"),
};
