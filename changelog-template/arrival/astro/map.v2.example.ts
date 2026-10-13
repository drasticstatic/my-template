// The map of everywhere Psanctuary's pages lead: THE canonical copy (kit 1.2, map version 2).
//
// This AstroLog draws it at /map (MapGrid.astro, at build time) and publishes it at /map.json; the
// entry portal's /map/ draws the same file with the kit's <arrival-map>. Each destination carries
// `og`, the share image its link shows, which both maps use as its thumbnail, so you can see where
// a link goes before you go. Destinations on another site get a card of our own (src/og/pages.ts)
// rather than a hotlinked image. `self` lets a page mark "You are here" (the portal's map passes
// here="portal", this one here="map"). Change the map here; the portal follows on its next load.
import { SITE } from "./site";
import { pageCardUrl } from "../og/pages";

export type MapGroup = { id: string; label: string; icon?: string; note?: string };
export type MapNode = {
  id: string;
  group: string;
  name: string;
  line?: string;
  href?: string;
  /** Opens one of the kit's windows instead of following the link ("contact" | "community"). */
  open?: string;
  og?: string;
  icon?: string;
  self?: string;
  external?: boolean;
};
export type SiteMap = { version: 2; title: string; desc: string; groups: MapGroup[]; nodes: MapNode[] };

const LOG = `${SITE}/changelog-astro-public`;
const CHURCH = "https://www.psanctuary.org";
const MIGHTY = "https://psanctuary-member-community.mn.co/";
const SIBLING = "https://psanctuarychurch.github.io";

export const SITE_MAP: SiteMap = {
  version: 2,
  title: "Where everything is",
  desc: "Every place Psanctuary's GitHub pages lead, grouped: the two front doors, the record, the ways to get involved, and the places beyond GitHub. Each one shows the picture its link shows when shared.",
  groups: [
    { id: "start", label: "Start here", icon: "signpost", note: "Two front doors: one for the organization, one for its record." },
    { id: "record", label: "The record", icon: "clock-counter-clockwise", note: "What changed, how it works, every public change, and where it's all headed." },
    { id: "involved", label: "Get involved", icon: "hand-heart", note: "Where the community gathers, how to reach the church, and how to give." },
    { id: "beyond", label: "Beyond GitHub", icon: "globe-simple", note: "The church's own site, the sibling organization, and the code." },
  ],
  nodes: [
    { id: "portal", group: "start", name: "Entry portal", line: "Psanctuary's playful front door on GitHub.", href: `${SITE}/`, og: pageCardUrl("portal"), icon: "house-simple", self: "portal" },
    { id: "porch", group: "start", name: "AstroLog porch", line: "The front door to the record.", href: `${LOG}/`, og: pageCardUrl("porch"), icon: "door-open", self: "porch" },

    { id: "changelog", group: "record", name: "Changelog", line: "Every notable change, newest first.", href: `${LOG}/changelog`, og: pageCardUrl("changelog"), icon: "clock-counter-clockwise" },
    { id: "library", group: "record", name: "Library", line: "Longer write-ups on how things work.", href: `${LOG}/library`, og: pageCardUrl("library"), icon: "books" },
    { id: "ledger", group: "record", name: "Ledger", line: "Every public change, in plain words, refreshed daily.", href: `${LOG}/ledger`, og: `${LOG}/og/ledger.jpg`, icon: "scroll" },
    { id: "map", group: "record", name: "Map", line: "This page: everywhere at a glance.", href: `${LOG}/map`, og: pageCardUrl("map"), icon: "map-trifold", self: "map" },
    { id: "roadmap", group: "record", name: "Roadmap", line: "Where these pages are headed.", href: `${LOG}/roadmap`, og: pageCardUrl("roadmap"), icon: "path" },
    { id: "sustainability", group: "record", name: "Sustainability", line: "What it takes to keep them running.", href: `${LOG}/sustainability`, og: pageCardUrl("sustainability"), icon: "plant" },

    { id: "community", group: "involved", name: "Community", line: "The member network: a public front page, and plans to join.", href: MIGHTY, open: "community", og: pageCardUrl("community"), icon: "users-three" },
    { id: "contact", group: "involved", name: "Reach out", line: "The contact form, or an email to the team.", href: `${CHURCH}/contact`, open: "contact", og: pageCardUrl("contact"), icon: "envelope-simple" },
    { id: "donate", group: "involved", name: "Donate", line: "Ways to give, and thanks by name.", href: `${SITE}/donate/`, og: pageCardUrl("donate"), icon: "heart" },

    { id: "church", group: "beyond", name: "psanctuary.org", line: "The church's real home: service, membership, courses, events.", href: CHURCH, og: pageCardUrl("psanctuary-org"), icon: "globe-simple", external: true },
    { id: "sibling", group: "beyond", name: "Psanctuary Church", line: "The sibling organization: the church's professional face on GitHub.", href: `${SIBLING}/`, og: `${SIBLING}/social-card.jpg`, icon: "tree-structure", external: true },
    { id: "github", group: "beyond", name: "On GitHub", line: "The organization and its public code.", href: "https://github.com/psanctuary", og: pageCardUrl("github"), icon: "github-logo", external: true },
  ],
};
