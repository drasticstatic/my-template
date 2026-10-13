#!/usr/bin/env node
// Arrival kit · SOCIAL-PREVIEWS.md generator.
// Canonical copy: drasticstatic/my-template changelog-template/arrival/social/social-previews.mjs
//
// Writes one standard file per org (kept in the org's `.github` repo) that answers two questions:
//   1. "I changed a share image. How do I make Telegram / LinkedIn / Facebook / Discord show it?"
//   2. "Which pages have their own tailored share image, and which fall back to the default?"
//
// It reads live pages only (no build needed): the portal root, any extra URLs you pass, and every
// page listed in the AstroLog's /search.json. For each page it records og:title and og:image, and
// marks the image "tailored" when it differs from the site's default card.
//
// Usage (Node 22+, no dependencies):
//   node social-previews.mjs --org "PIR®" \
//     --portal https://psychedelicsinrecovery.github.io/ \
//     --astrolog https://psychedelicsinrecovery.github.io/changelog-astro-public/ \
//     [--extra https://…/donate/,https://…/map/] \
//     --out ~/psychedelicsinrecovery/.github/SOCIAL-PREVIEWS.md
//
// Re-run after any deploy that adds pages or changes share images, then commit the result.

import fs from "node:fs";

const args = Object.fromEntries(
  process.argv.slice(2).reduce((acc, a, i, all) => (a.startsWith("--") ? [...acc, [a.slice(2), all[i + 1]?.startsWith("--") ? true : all[i + 1]]] : acc), []),
);
for (const k of ["org", "portal", "astrolog", "out"]) {
  if (!args[k]) {
    console.error(`missing --${k}`);
    process.exit(2);
  }
}
const ensureSlash = (u) => (u.endsWith("/") ? u : `${u}/`);
const portal = ensureSlash(args.portal);
const astrolog = ensureSlash(args.astrolog);
const extra = typeof args.extra === "string" ? args.extra.split(",").map((s) => s.trim()).filter(Boolean) : [];

const decode = (s) =>
  s.replace(/&amp;/g, "&").replace(/&quot;/g, '"').replace(/&#39;|&#x27;/g, "'").replace(/&lt;/g, "<").replace(/&gt;/g, ">");

function meta(html, key) {
  // property="og:image" content="…"  or  content="…" property="og:image"  (either attribute order)
  // The closing quote must match the opening one, so "PIR's …" isn't cut at the apostrophe.
  const a = new RegExp(`<meta[^>]+(?:property|name)=["']${key}["'][^>]*?content=(["'])(.*?)\\1`, "i").exec(html);
  const b = new RegExp(`<meta[^>]+content=(["'])(.*?)\\1[^>]*?(?:property|name)=["']${key}["']`, "i").exec(html);
  return decode((a || b || [])[2] || "");
}

async function get(url) {
  try {
    const r = await fetch(url, { redirect: "follow", headers: { "user-agent": "arrival-kit-social-previews/1.0" } });
    return { status: r.status, text: r.ok ? await r.text() : "" };
  } catch (e) {
    return { status: 0, text: "" };
  }
}

const urls = new Set([portal, ...extra, astrolog]);
const search = await get(`${astrolog}search.json`);
if (search.status === 200) {
  try {
    const d = JSON.parse(search.text);
    for (const it of d.items || d) if (it?.h) urls.add(it.h.split("#")[0]);
  } catch {}
}

const rows = [];
for (const url of urls) {
  const { status, text } = await get(url);
  rows.push({
    url,
    status,
    title: meta(text, "og:title") || (/<title>([^<]*)<\/title>/i.exec(text) || [])[1] || "",
    image: meta(text, "og:image"),
    card: meta(text, "twitter:card"),
  });
}

// The default card is whatever the portal and the AstroLog home use; anything else is tailored.
const defaults = new Set(rows.filter((r) => r.url === portal || r.url === astrolog).map((r) => r.image).filter(Boolean));
const tailored = rows.filter((r) => r.image && !defaults.has(r.image));
const fallback = rows.filter((r) => r.image && defaults.has(r.image));
const missing = rows.filter((r) => r.status === 200 && !r.image);
const broken = rows.filter((r) => r.status !== 200);

const short = (u) => u.replace(/^https?:\/\//, "");
const cell = (s) => String(s).replace(/\|/g, "\\|").replace(/\s+/g, " ").trim();
const today = new Date().toISOString().slice(0, 10);

const md = `# 🔄 Social previews: refresh guide + share-image ledger

When a link to one of ${args.org}'s GitHub Pages sites is pasted into a chat app, the app shows a
preview card (title, description and a share image) that it fetched **once** and then **cached**.
After a share image or title changes, old previews keep showing until each app is told to look again.
This file lists how to do that for each app, and which pages have their own tailored share image.

*Generated ${today} by the arrival kit's \`social/social-previews.mjs\` (canonical copy in
[my-template](https://github.com/drasticstatic/my-template/tree/main/changelog-template/arrival/social)).
Re-run it after deploys that add pages or change share images.*

## 🧰 How to refresh each app

| App | How to make it re-fetch | Notes |
|---|---|---|
| ✈️ **Telegram** | Message [@WebpageBot](https://t.me/WebpageBot) the link (you can send several links, one per line) | The bot replies with the fresh preview; new shares use it right away |
| 💼 **LinkedIn** | Paste the link into [Post Inspector](https://www.linkedin.com/post-inspector/) | Inspecting re-scrapes the page |
| 📘 **Facebook / Messenger** | Paste into the [Sharing Debugger](https://developers.facebook.com/tools/debug/) and press **Scrape Again** | Also accepts a batch of links |
| 💬 **Discord** | No refresh tool. Share the link with a harmless suffix such as \`?v=2\` | Discord caches per exact URL, so a new suffix gets a new preview |
| 🟪 **Slack** | No refresh tool. Use the \`?v=2\` suffix trick | Old messages keep their old unfurl |
| 🐦 **X (Twitter)** | No public validator any more. Use the \`?v=2\` suffix, or wait (cards refresh on their own, roughly a week) | |
| 🟢 **WhatsApp** | No refresh tool. Use the \`?v=2\` suffix | WhatsApp caches aggressively |
| 🦋 **Bluesky** / 🐘 **Mastodon** | Fetched when a post is written; nothing to clear | Each Mastodon server fetches its own copy |
| 💬 **iMessage** | Fetched on the sender's phone at send time | Nothing to clear |

**Rule of thumb:** after changing a share image, refresh Telegram (@WebpageBot), LinkedIn and
Facebook for the pages listed below. Use the \`?v=2\` suffix anywhere else.

## 🖼️ Share-image ledger

${rows.length} pages checked: **${tailored.length} tailored**, ${fallback.length} using the default card,
${missing.length} with no share image${broken.length ? `, ${broken.length} not reachable` : ""}.

### ✨ Pages with their own tailored share image

| Page | Title | Share image |
|---|---|---|
${tailored.map((r) => `| [${cell(short(r.url))}](${r.url}) | ${cell(r.title)} | [image](${r.image}) |`).join("\n") || "| _none yet_ | | |"}

### 🪪 Pages using the default card

${fallback.map((r) => `- [${cell(short(r.url))}](${r.url})`).join("\n") || "- _none_"}
${missing.length ? `\n### ⚠️ Pages with no share image (fix these)\n\n${missing.map((r) => `- [${cell(short(r.url))}](${r.url})`).join("\n")}\n` : ""}${broken.length ? `\n### ❌ Pages that didn't load when checked\n\n${broken.map((r) => `- ${cell(short(r.url))} (HTTP ${r.status || "error"})`).join("\n")}\n` : ""}
## 📋 Copy-paste list for @WebpageBot

\`\`\`
${rows.filter((r) => r.status === 200).map((r) => r.url).join("\n")}
\`\`\`
`;

fs.writeFileSync(args.out.replace(/^~(?=\/)/, process.env.HOME), md);
console.log(`${args.org}: ${rows.length} pages, ${tailored.length} tailored, ${fallback.length} default, ${missing.length} missing, ${broken.length} broken -> ${args.out}`);
