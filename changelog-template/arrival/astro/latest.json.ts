// Arrival kit · /latest.json: what the "what's new since your last visit" count reads (wave 5).
// ORG's version; copy and change the collections and labels per site. Newest first, small, absolute
// URLs (the portal and other origins fetch it). Shape:
//   { updated: ISO time, items: [{ type: "entry" | "doc" | "ledger", t, k, i, h, d, ts?, who? }] }
// `ts` is an exact time (ledger commits); `d`-only items count from the end of their day, and the
// kit remembers what a visitor already saw so a same-day entry isn't counted twice.
import { getCollection } from "astro:content";
import { SITE, areaBySlug, entrySlug } from "../data/areas";
import { loadLedger, ledgerNewsItems } from "../ledger/ledger.mjs";
import { LEDGER } from "../data/ledger.config.mjs";

export async function GET() {
  const at = (p: string) => `${SITE}${import.meta.env.BASE_URL}${p}`;
  const entries = (await getCollection("changelog")).sort((a, b) => b.data.date.localeCompare(a.data.date)).slice(0, 30);
  const docs = (await getCollection("library")).filter((d) => d.data.date);
  const ledger = await loadLedger(LEDGER);
  const items = [
    ...entries.map((e) => ({
      type: "entry",
      t: e.data.title,
      k: `changelog · ${areaBySlug(e.data.repo)?.name ?? "ORG"}`,
      i: "clock-counter-clockwise",
      h: at(`/changelog/${e.data.repo}/${entrySlug(e.id)}`),
      d: e.data.date,
      who: e.data.who,
    })),
    ...docs.map((d) => ({ type: "doc", t: d.data.title, k: "library", i: "book-open-text", h: at(`/library/${entrySlug(d.id)}`), d: d.data.date })),
    ...ledgerNewsItems(ledger, { kicker: "ledger" }),
  ].sort((a, b) => String(b.ts ?? b.d).localeCompare(String(a.ts ?? a.d)));
  return new Response(JSON.stringify({ updated: new Date().toISOString(), items }), {
    headers: { "Content-Type": "application/json" },
  });
}
