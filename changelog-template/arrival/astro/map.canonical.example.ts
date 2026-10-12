// The map of ORG's sites, previews and proposals: THE canonical copy.
//
// The ORG AstroLog draws it at /map and publishes it, geometry included, at /map.json. The
// drasticstatic ORG lab (drasticstatic/O-R-G-astro) fetches that file when it builds and draws the
// same map at its own /map, falling back to a committed snapshot if the fetch fails. So: change the
// map here, deploy, and the lab follows on its next build. Each site marks its own node ("You are
// here") through `self`. Documented in my-template/changelog-template/README.md (wave 4).
import { SITE } from "./areas";

export type MapNode = {
  id: string;
  x: number;
  y: number;
  name: string;
  line: string;
  href?: string;
  private?: boolean;
  /** Which site this node is, so that site can mark it "You are here". */
  self?: "astrolog" | "lab" | "portal";
};
export type MapEdge = { d: string; label: string; lx: number; ly: number; soft?: boolean };
export type OrgMapData = {
  version: 1;
  title: string;
  desc: string;
  width: number;
  height: number;
  nodeW: number;
  nodeH: number;
  columns: { x: number; label: string }[];
  nodes: (MapNode & { points: string })[];
  edges: MapEdge[];
};

const W = 300;
const H = 66;
const ORGH = "https://github.com/Octagon-Religious-Research-Group-ORG/";

const nodes: MapNode[] = [
  { id: "fe", x: 40, y: 110, name: "org-frontend", line: "The live site's code, in TanStack Start", href: `${ORGH}org-frontend` },
  { id: "be", x: 40, y: 230, name: "org-backend", line: "API for offerings and editable pages", href: `${ORGH}org-backend` },
  { id: "prof", x: 40, y: 350, name: ".github", line: "The organization's public profile", href: `${ORGH}.github` },
  { id: "brand", x: 40, y: 440, name: "brand-assets", line: "Logo, avatar, and favicons", href: `${ORGH}brand-assets` },
  { id: "cla", x: 40, y: 530, name: "changelog-astro", line: "Source for the ORG AstroLog", private: true },
  { id: "root", x: 40, y: 620, name: "…ORG.github.io", line: "The entry portal and arrival kit", href: `${ORGH}Octagon-Religious-Research-Group-ORG.github.io` },

  { id: "live", x: 420, y: 110, name: "orgspirituality.org", line: "Hosted on Netlify", href: "https://orgspirituality.org" },
  { id: "api", x: 420, y: 230, name: "ORG API", line: "Hosted on Heroku" },
  { id: "astrolog", x: 420, y: 530, name: "ORG AstroLog", line: "The official changelog, on GitHub Pages", href: `${SITE}/changelog-astro-public/`, self: "astrolog" },
  { id: "rootpage", x: 420, y: 620, name: "Entry portal", line: "Hosted on GitHub Pages", href: `${SITE}/`, self: "portal" },

  { id: "dapp", x: 800, y: 110, name: "O-R-G-dapp", line: "Source for the dApp preview", private: true },
  { id: "dapppub", x: 800, y: 230, name: "dApp preview", line: "Christopher's preview, on GitHub Pages", href: "https://drasticstatic.github.io/O-R-G-dapp-public-preview/" },
  { id: "design", x: 800, y: 350, name: "Design directions", line: "Renan Teixeira's proposal, on Netlify", href: "https://org-new-look.netlify.app/" },
  { id: "labsrc", x: 800, y: 470, name: "O-R-G-astro", line: "Source for the lab", private: true },
  { id: "lab", x: 800, y: 590, name: "drasticstatic ORG lab", line: "Christopher's lab changelog and portfolio", href: "https://drasticstatic.github.io/O-R-G-astro-public/", self: "lab" },
];

const by = Object.fromEntries(nodes.map((n) => [n.id, n]));
const right = (n: MapNode) => [n.x + W, n.y + H / 2];
const left = (n: MapNode) => [n.x, n.y + H / 2];
const top = (n: MapNode) => [n.x + W / 2, n.y];
const bottom = (n: MapNode) => [n.x + W / 2, n.y + H];
const line = (a: number[], b: number[]) => `M${a[0]},${a[1]} L${b[0]},${b[1]}`;

const edges: MapEdge[] = [
  { d: line(right(by.fe), left(by.live)), label: "deploys", lx: 380, ly: 136 },
  { d: line(right(by.be), left(by.api)), label: "deploys", lx: 380, ly: 256 },
  { d: line(bottom(by.live), top(by.api)), label: "calls", lx: 570, ly: 207 },
  { d: line(right(by.cla), left(by.astrolog)), label: "publishes", lx: 380, ly: 556 },
  { d: line(right(by.root), left(by.rootpage)), label: "serves", lx: 380, ly: 646 },
  { d: line(bottom(by.dapp), top(by.dapppub)), label: "syncs public files", lx: 950, ly: 207 },
  { d: line(bottom(by.labsrc), top(by.lab)), label: "syncs public files", lx: 950, ly: 567 },
  {
    d: `M${by.fe.x + W - 40},${by.fe.y} C${by.fe.x + W - 40},30 ${by.dapp.x + W - 40},30 ${by.dapp.x + W - 40},${by.dapp.y}`,
    label: "artwork and words, copied in",
    lx: 680,
    ly: 46,
    soft: true,
  },
  { d: line(right(by.brand), top(by.astrolog)), label: "logo files", lx: 452, ly: 492, soft: true },
  { d: line(left(by.design), right(by.astrolog)), label: "three lights", lx: 745, ly: 455, soft: true },
];

const chamfer = (n: MapNode, c = 10) =>
  [
    [n.x + c, n.y],
    [n.x + W - c, n.y],
    [n.x + W, n.y + c],
    [n.x + W, n.y + H - c],
    [n.x + W - c, n.y + H],
    [n.x + c, n.y + H],
    [n.x, n.y + H - c],
    [n.x, n.y + c],
  ]
    .map((p) => p.join(","))
    .join(" ");

export const ORG_MAP: OrgMapData = {
  version: 1,
  title: "Map of ORG's sites, previews, and proposals",
  desc:
    "ORG's organization holds org-frontend, deployed to orgspirituality.org on Netlify, and org-backend, deployed as an API on Heroku that the site calls. It also holds its profile, brand assets, the private source for the ORG AstroLog, which publishes the official changelog to GitHub Pages, and the entry portal, which also serves the arrival kit every ORG page shares. Christopher's private dApp source syncs public files to the dApp preview, which copies artwork and words from org-frontend. Renan Teixeira's design directions are on Netlify, and their three lights are used by the AstroLog, as are the logo files from brand-assets. The drasticstatic ORG lab, synced from its own private source, keeps the changelog and portfolio of what Christopher builds for ORG.",
  width: 1140,
  height: 720,
  nodeW: W,
  nodeH: H,
  columns: [
    { x: 40, label: "ORG on GitHub" },
    { x: 420, label: "Where it runs" },
    { x: 800, label: "Previews and proposals" },
  ],
  nodes: nodes.map((n) => ({ ...n, points: chamfer(n) })),
  edges,
};
