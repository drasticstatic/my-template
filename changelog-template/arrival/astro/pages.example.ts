// Share cards for the site's own pages (kit 1.2): the portal and the porch (the big-name "hero"
// layout), the record's pages, the ways to get involved, and the places beyond GitHub. Each one is
// also the thumbnail the map shows for that destination, so the map's pictures are exactly what a
// shared link shows. Built once per build at /og/page/<slug>.jpg (src/pages/og/page/[slug].jpg.ts).
// No counts on any card: link previews are cached for weeks.
import path from "node:path";
import { pathToFileURL } from "node:url";
import { renderCard } from "./spore-card.mjs";
import { CARD_THEME } from "./theme.mjs";
import { NAME, SITE } from "../data/site";

const BASE = "/changelog-astro-public";
const HOST = new URL(SITE).host;
const OG_DIR = pathToFileURL(path.resolve("src/og") + "/");

export const pageCardUrl = (slug: string) => `${SITE}${BASE}/og/page/${slug}.jpg`;

type PageCard = { slug: string; eyebrow: string; kicker?: string; title: string; summary?: string; footer?: string; hero?: boolean };
const LOG = `${NAME} AstroLog`;

export const PAGE_CARDS: PageCard[] = [
  { slug: "portal", hero: true, eyebrow: `${NAME} · On GitHub`, title: NAME, summary: "The playful side: GitHub home, changelog and library", footer: HOST },
  { slug: "porch", hero: true, eyebrow: `${NAME} · AstroLog`, title: "The AstroLog", summary: "What changed, how it works, and every public change, in plain words", footer: `${HOST}/changelog-astro-public` },
  { slug: "changelog", eyebrow: `${LOG} · Changelog`, kicker: "What changed", title: "Every change, newest first", summary: "Short, dated entries in plain language, each with the full story folded underneath and credit to whoever did the work.", footer: HOST },
  { slug: "library", eyebrow: `${LOG} · Library`, kicker: "How it works", title: "The write-ups behind the changes", summary: "Longer pieces on how these pages are built and why, for anyone curious.", footer: HOST },
  { slug: "map", eyebrow: `${LOG} · Map`, kicker: "Where everything is", title: "Every place these pages lead", summary: "The portal, the record, the ways to get involved and the church's own site, each with a picture of where it goes.", footer: HOST },
  { slug: "roadmap", eyebrow: `${LOG} · Roadmap`, kicker: "Where it's headed", title: "What comes next", summary: "Giving from a crypto wallet, thanks you can claim, and further out, a network of the community's own. No dates, no promises.", footer: HOST },
  { slug: "sustainability", eyebrow: `${LOG} · Sustainability`, kicker: "What keeps it running", title: "Nothing left to memory", summary: "The token, the scheduled jobs, the shared kit and the cached previews that keep these pages alive, and what to do for each.", footer: HOST },
  { slug: "donate", eyebrow: `${NAME} · Donate`, kicker: "Ways to give", title: `Give to ${NAME}`, summary: "Giving through psanctuary.org, thanks by name for those who'd like it, and giving with crypto, coming soon.", footer: `${HOST}/donate` },
  { slug: "community", eyebrow: `${NAME} · Community`, kicker: "Where we gather", title: "The member community", summary: "The church's member network on Mighty Networks: events, clubs, courses and messages. A public front page, and plans to join.", footer: "psanctuary-member-community.mn.co" },
  { slug: "contact", eyebrow: `${NAME} · Reach out`, kicker: "Every way in", title: "Reach the church", summary: "The contact form on psanctuary.org, or an email to the team. Every way in, in one place.", footer: "psanctuary.org/contact" },
  { slug: "psanctuary-org", eyebrow: "Psanctuary · The church", kicker: "psanctuary.org", title: "Psanctuary, the church", summary: "Sunday service, membership, courses, ceremonies and events: the church's real home.", footer: "psanctuary.org" },
  { slug: "github", eyebrow: `${NAME} · GitHub`, kicker: "The organization", title: "The code, in the open", summary: "Every public repository behind these pages.", footer: "github.com/psanctuary" },
];

export async function pageCard(slug: string) {
  const c = PAGE_CARDS.find((x) => x.slug === slug);
  if (!c) throw new Error(`[og] no page card "${slug}"`);
  const buf = await renderCard({ ...c, seed: `page/${slug}` }, CARD_THEME, OG_DIR);
  return new Response(new Uint8Array(buf), { headers: { "Content-Type": "image/jpeg" } });
}
