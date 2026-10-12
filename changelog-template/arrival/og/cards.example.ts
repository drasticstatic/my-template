// Per-page social cards for the AstroLog: where each card lives, and what it says. The endpoints in
// src/pages/og/ render them at build time with the arrival kit's generator (og-card.mjs).
import path from "node:path";
import { pathToFileURL } from "node:url";
import type { CollectionEntry } from "astro:content";
import { renderCard } from "./og-card.mjs";
import { ORG_CARD_THEME } from "./theme.mjs";
import { mapSvg } from "./map-svg.mjs";
import { ORG_MAP } from "../data/map";
import { SITE, areaBySlug, entrySlug, formatDate, tldrOf } from "../data/areas";

const BASE = "/changelog-astro-public";
// Astro bundles this file, so resolve fonts from the project folder, not import.meta.url.
const OG_DIR = pathToFileURL(path.resolve("src/og") + "/");

export const entryCardUrl = (e: CollectionEntry<"changelog">) => `${SITE}${BASE}/og/changelog/${e.data.repo}/${entrySlug(e.id)}.jpg`;
export const docCardUrl = (d: CollectionEntry<"library">) => `${SITE}${BASE}/og/library/${entrySlug(d.id)}.jpg`;
export const mapCardUrl = `${SITE}${BASE}/og/map.jpg`;

const jpeg = (buf: Buffer) =>
  new Response(new Uint8Array(buf), { headers: { "Content-Type": "image/jpeg" } });

export async function entryCard(e: CollectionEntry<"changelog">) {
  const area = areaBySlug(e.data.repo);
  return jpeg(
    await renderCard(
      {
        eyebrow: "ORG AstroLog · Changelog",
        kicker: area?.name ?? "ORG",
        title: e.data.title,
        summary: tldrOf(e.body),
        meta: [formatDate(e.data.date), e.data.who ? `By ${e.data.who}` : ""].filter(Boolean).join(" · "),
        footer: "ORG AstroLog",
        lit: area?.wedge ?? null,
      },
      ORG_CARD_THEME,
      OG_DIR
    )
  );
}

export async function docCard(d: CollectionEntry<"library">) {
  return jpeg(
    await renderCard(
      {
        eyebrow: "ORG AstroLog · Library",
        kicker: "How it works",
        title: d.data.title,
        summary: d.data.description,
        meta: d.data.date ? `Written ${formatDate(d.data.date)}` : "A library write-up",
        footer: "ORG AstroLog",
        lit: null,
      },
      ORG_CARD_THEME,
      OG_DIR
    )
  );
}

export async function pageCard(spec: { eyebrow: string; kicker?: string; title: string; summary?: string; meta?: string }) {
  return jpeg(await renderCard({ footer: "ORG AstroLog", lit: null, ...spec }, ORG_CARD_THEME, OG_DIR));
}

export async function mapCard() {
  const svg = mapSvg(ORG_MAP, { accent: "#e9be72", muted: "#b4abc9", border: "#4a4170", node: "#221d3a", heading: "#f4effc" }, "astrolog");
  return jpeg(
    await renderCard(
      {
        eyebrow: "ORG AstroLog · Map",
        kicker: "How it fits together",
        title: "Map of ORG's sites",
        summary: "Repositories, where they run, and the previews and proposals around them.",
        meta: "The drasticstatic ORG lab draws the same map",
        footer: "ORG AstroLog",
        lit: null,
        figure: { svg, width: 520, height: Math.round((520 * (ORG_MAP.height - 20)) / ORG_MAP.width) },
      },
      ORG_CARD_THEME,
      OG_DIR
    )
  );
}
