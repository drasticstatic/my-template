// The AstroLog's search index, read by ORG's arrival kit ("/" search, <arrival-latest>,
// <arrival-people>). The entry portal fetches it same-origin, so "/" on the portal finds AstroLog
// entries too; the drasticstatic ORG lab fetches it cross-origin (GitHub Pages allows that).
// URLs are absolute for that reason. Shape: { updated, items: [{ t, k, h, i, d?, s?, x?, who?, type }],
// people: [{ name, role, github?, count }] } — documented in my-template/changelog-template/README.md.
import { getCollection } from "astro:content";
import { AREAS, PEOPLE, SITE, WEIGHT, areaBySlug, entrySlug, madeBy, tldrOf } from "../data/areas";

const plain = (md = "") =>
  md
    .replace(/<[^>]+>/g, " ")
    .replace(/!\[[^\]]*\]\([^)]*\)/g, " ")
    .replace(/\[([^\]]*)\]\([^)]*\)/g, "$1")
    .replace(/[#>*_`|~-]+/g, " ")
    .replace(/\s+/g, " ")
    .trim();

export async function GET() {
  const base = import.meta.env.BASE_URL;
  const at = (path: string) => `${SITE}${base}${path}`;
  const entries = (await getCollection("changelog")).sort((a, b) => b.data.date.localeCompare(a.data.date));
  const docs = await getCollection("library");

  const items = [
    { type: "page", t: "AstroLog porch", k: "page", i: "door-open", h: at("/"), x: "home latest astrolog" },
    { type: "page", t: "Changelog: every change", k: "page", i: "clock-counter-clockwise", h: at("/changelog"), x: "entries history what changed", pin: true },
    { type: "page", t: "Library: the write-ups", k: "page", i: "books", h: at("/library"), x: "docs how it works", pin: true },
    { type: "page", t: "Map of ORG's sites", k: "page", i: "tree-structure", h: at("/map"), x: "diagram hosting repositories how it connects" },
    ...AREAS.filter((a) => entries.some((e) => e.data.repo === a.slug)).map((a) => ({
      type: "area",
      t: `${a.name}: changelog`,
      k: "area",
      i: "polygon",
      h: at(`/changelog/${a.slug}`),
      s: a.blurb,
    })),
    ...entries.map((e) => {
      const area = areaBySlug(e.data.repo);
      const tldr = tldrOf(e.body);
      return {
        type: "entry",
        t: e.data.title,
        k: `changelog · ${area?.name ?? e.data.repo ?? "ORG"}`,
        i: e.data.priority === "P1-high" ? "sparkle" : "clock-counter-clockwise",
        h: at(`/changelog/${e.data.repo}/${entrySlug(e.id)}`),
        d: e.data.date,
        s: tldr,
        who: e.data.who,
        x: `${WEIGHT[e.data.priority]} ${plain(e.body).slice(0, 700)}`,
      };
    }),
    ...docs.map((d) => ({
      type: "doc",
      t: d.data.title,
      k: "library",
      i: "book-open-text",
      h: at(`/library/${entrySlug(d.id)}`),
      d: d.data.date,
      s: d.data.description,
      x: plain(d.body).slice(0, 700),
    })),
  ];

  const people = PEOPLE.map((p) => ({
    name: p.name,
    role: p.role,
    github: p.github,
    count: entries.filter((e) => madeBy(p, e.data.who)).length,
  }));

  const body = { updated: entries[0]?.data.date ?? null, items, people };
  return new Response(JSON.stringify(body), { headers: { "Content-Type": "application/json" } });
}
