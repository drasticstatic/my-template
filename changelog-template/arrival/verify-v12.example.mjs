// Live verification for arrival kit v1.2 (wave 6, the interface half), written for the psanctuary pair.
// To port: edit SITES (portal origin, AstroLog URL, storage key, whether a "coming soon" community
// placeholder is expected) and run from a folder with playwright-core installed:
//   npm i playwright-core && node verify-v12.example.mjs [psanctuary psanctuarychurch …]
// Uses local Chrome (channel "chrome") and a fresh browser context per check.
// Checks, per org:
//   1. Every page returns 200 (and a nested miss returns the site's 404) with complete og tags,
//      and every og:image is a real 1200×630 JPEG.
//   2. The header is ONE row at every width from 320px up (no wrap, no horizontal scroll), with the
//      kit's nav; below nav.fold it's a Menu button, above it a bar (extra items in "More").
//   3. Every nav, menu and footer link has an icon; the Menu opens, lists every link, closes on Esc
//      and returns focus; a dropdown opens with ArrowDown and closes on Esc.
//   4. Contact and community modals open from their links, are labelled, trap focus, close on Esc
//      and the backdrop, and return focus; placeholders are marked; no link is empty.
//   5. What's new: a genuine first visit in the past (Playwright's fake clock) shows nothing, a return
//      visit shows a filled count, the one-time tip, the count on the Menu, and the Menu's row.
//   6. Reading round 2: text size and line length apply and persist.
//   7. /map: every thumbnail loads; "You are here" on the right card. /donate/: the crypto slot is
//      present and no wallet address appears anywhere.
//   8. No page errors anywhere.
import { chromium } from "playwright-core";
import fs from "node:fs";

const SITES = {
  psanctuary: { root: "https://psanctuary.github.io", key: "psanctuary-arrival", soonExpected: true },
  psanctuarychurch: { root: "https://psanctuarychurch.github.io", key: "psanctuarychurch-arrival", soonExpected: false },
};
const WIDTHS = [320, 360, 390, 480, 768, 1000, 1024, 1099, 1100, 1280, 1440, 1920];
const SHOTS = "shots-v12";
fs.mkdirSync(SHOTS, { recursive: true });

const results = [];
const ok = (name, cond, extra = "") => {
  results.push(`${cond ? "PASS" : "FAIL"}  ${name}${extra ? "  (" + extra + ")" : ""}`);
  console.log(results[results.length - 1]);
};
const bust = (u) => u + (u.includes("?") ? "&" : "?") + "v=" + Date.now();

const browser = await chromium.launch({ channel: "chrome" });
async function fresh(key, { width = 1280, chosen = true } = {}) {
  const ctx = await browser.newContext({ viewport: { width, height: 860 } });
  if (chosen) await ctx.addInitScript((k) => { try { if (!localStorage.getItem(k)) localStorage.setItem(k, JSON.stringify({ chosen: true })); } catch (e) {} }, key);
  const page = await ctx.newPage();
  page._errors = [];
  page.on("pageerror", (e) => page._errors.push(e.message));
  return { ctx, page };
}

for (const id of process.argv.slice(2).length ? process.argv.slice(2) : Object.keys(SITES)) {
  const S = SITES[id];
  const LOG = S.root + "/changelog-astro-public";
  const PAGES = [
    ["portal", S.root + "/"],
    ["donate", S.root + "/donate/"],
    ["portal map", S.root + "/map/"],
    ["porch", LOG + "/"],
    ["changelog", LOG + "/changelog"],
    ["library", LOG + "/library"],
    ["ledger", LOG + "/ledger"],
    ["map", LOG + "/map"],
    ["roadmap", LOG + "/roadmap"],
    ["sustainability", LOG + "/sustainability"],
  ];
  console.log(`\n=== ${id} ===`);

  // 1. Status and og tags, plus nested 404s.
  for (const [name, url] of PAGES) {
    const res = await fetch(bust(url));
    const html = await res.text();
    const og = (p) => (html.match(new RegExp(`<meta property="og:${p}" content="([^"]*)"`)) || [])[1];
    const img = og("image");
    let jpeg = false;
    if (img) {
      const r = await fetch(img);
      const b = Buffer.from(await r.arrayBuffer());
      jpeg = r.ok && b[0] === 0xff && b[1] === 0xd8 && b.length > 20000;
    }
    ok(`${id} ${name}: 200 with og title/description/url/image, image is a real JPEG`, res.status === 200 && og("title") && og("description") && og("url") && /^https:\/\//.test(img || "") && og("image:width") === "1200" && jpeg, `${res.status} ${img}`);
  }
  for (const u of [S.root + "/no/such/page/deep", LOG + "/no/such/page"]) {
    const r = await fetch(u);
    const t = await r.text();
    ok(`${id} nested 404 serves the site's own 404 with the nav: ${u.replace(S.root, "")}`, r.status === 404 && t.includes("arrival-nav"));
  }

  // 2. One header row at every width, on every page type (porch, ledger, map, portal, donate).
  for (const [name, url] of [PAGES[0], PAGES[1], PAGES[3], PAGES[6], PAGES[7]]) {
    const bad = [];
    for (const w of WIDTHS) {
      const { ctx, page } = await fresh(S.key, { width: w });
      await page.goto(bust(url), { waitUntil: "networkidle" });
      await page.waitForTimeout(400);
      const r = await page.evaluate(() => {
        const h = document.querySelector("header");
        const nav = document.querySelector("arrival-nav");
        const bar = document.querySelector(".arr-nav-bar");
        return {
          h: Math.round(h.getBoundingClientRect().height),
          hs: document.documentElement.scrollWidth > document.documentElement.clientWidth,
          mode: nav && nav.getAttribute("data-mode"),
          over: bar ? bar.scrollWidth > bar.clientWidth + 1 : false,
          kids: [...h.children].filter((c) => c.getClientRects().length && getComputedStyle(c).position !== "absolute").map((c) => Math.round(c.getBoundingClientRect().top)),
        };
      });
      const oneRow = r.h < 72 && new Set(r.kids.map((t) => Math.round(t / 14))).size === 1;
      const wantMode = w < 1100 ? "menu" : "bar";
      if (!oneRow || r.hs || r.over || (r.mode !== wantMode && !(wantMode === "bar" && r.mode === "menu"))) bad.push(`${w}px h=${r.h} mode=${r.mode} hs=${r.hs}`);
      if (name === "ledger" && (w === 1000 || w === 390)) await page.screenshot({ path: `${SHOTS}/${id}-ledger-${w}.png`, clip: { x: 0, y: 0, width: w, height: 120 } });
      if (page._errors.length) bad.push(`${w}px errors: ${page._errors.join(";")}`);
      await ctx.close();
    }
    ok(`${id} ${name}: one header row, no horizontal scroll, Menu below 1100px (${WIDTHS[0]}–${WIDTHS[WIDTHS.length - 1]}px)`, !bad.length, bad.join(" | "));
  }

  // 3. Icons everywhere; the Menu and a dropdown by keyboard.
  {
    const { ctx, page } = await fresh(S.key, { width: 390 });
    await page.goto(bust(LOG + "/ledger"), { waitUntil: "networkidle" });
    const icons = await page.evaluate(() => {
      const links = [...document.querySelectorAll("arrival-nav a, arrival-footer a, .universal-footer a")];
      return { n: links.length, missing: links.filter((a) => !a.querySelector(".ph")).map((a) => a.textContent.trim()) };
    });
    ok(`${id}: every nav, menu, footer and dock link has an icon`, icons.n > 20 && !icons.missing.length, `${icons.n} links; missing: ${icons.missing.join(", ")}`);
    await page.click("[data-arr-menu]");
    const m = await page.evaluate(() => {
      const b = document.querySelector("[data-arr-menu]");
      const p = document.getElementById(b.getAttribute("aria-controls"));
      const r = p.getBoundingClientRect();
      return { open: b.getAttribute("aria-expanded"), links: p.querySelectorAll("a[href]").length, inView: r.left >= 0 && r.right <= innerWidth };
    });
    await page.screenshot({ path: `${SHOTS}/${id}-menu-390.png` });
    await page.keyboard.press("Escape");
    const back = await page.evaluate(() => document.activeElement?.hasAttribute("data-arr-menu") && document.querySelector("[data-arr-menu]").getAttribute("aria-expanded") === "false");
    ok(`${id}: Menu opens a panel of every link, in view; Esc closes it and returns focus`, m.open === "true" && m.links >= 12 && m.inView && back, JSON.stringify(m));
    await ctx.close();
    const d = await fresh(S.key, { width: 1440 });
    await d.page.goto(bust(LOG + "/"), { waitUntil: "networkidle" });
    await d.page.locator(".arr-nav-bar [data-arr-nav-toggle]:visible").first().focus();
    await d.page.keyboard.press("ArrowDown");
    const f = await d.page.evaluate(() => !!document.activeElement?.closest(".arr-nav-menu"));
    await d.page.keyboard.press("Escape");
    const f2 = await d.page.evaluate(() => document.activeElement?.hasAttribute("data-arr-nav-toggle"));
    ok(`${id}: a dropdown opens with ArrowDown into its links, Esc returns to its button`, f && f2);
    await d.ctx.close();
  }

  // 4. Contact and community modals.
  for (const what of ["contact", "community"]) {
    const { ctx, page } = await fresh(S.key);
    await page.goto(bust(LOG + "/library"), { waitUntil: "networkidle" });
    const sel = `.universal-footer [data-arrival-open="${what}"]`;
    await page.click(sel);
    await page.waitForTimeout(400);
    const d = await page.evaluate((w) => {
      const dl = document.querySelector(`.arr-${w}[open]`);
      if (!dl) return null;
      return {
        label: document.getElementById(dl.getAttribute("aria-labelledby"))?.textContent,
        hrefs: [...dl.querySelectorAll("a[href]")].map((a) => a.getAttribute("href")),
        placeholders: dl.querySelectorAll(".is-soon, .is-placeholder, .arr-placeholder").length,
        bespoke: !!dl.querySelector(".arr-plat-bespoke"),
        focusIn: dl.contains(document.activeElement),
      };
    }, what);
    for (let i = 0; i < 20; i++) await page.keyboard.press("Tab");
    const trapped = await page.evaluate((w) => !!document.querySelector(`.arr-${w}[open]`)?.contains(document.activeElement), what);
    await page.keyboard.press("Escape");
    const ret = await page.evaluate((s) => !document.querySelector(".arr-dialog[open]") && document.activeElement === document.querySelector(s), sel);
    await page.click(sel);
    await page.waitForTimeout(300);
    await page.mouse.click(6, 430);
    const bd = await page.evaluate(() => !document.querySelector(".arr-dialog[open]"));
    const linksOk = d && d.hrefs.length && d.hrefs.every((h) => /^(https:|mailto:)/.test(h));
    ok(`${id} ${what}: opens labelled with focus inside, traps Tab, Esc + backdrop close, focus returns, every link real`, !!d && d.label && d.focusIn && trapped && ret && bd && linksOk, d && d.hrefs.join(" "));
    if (what === "community") ok(`${id} community: the sneak-peek card${S.soonExpected ? ", and a coming-soon placeholder" : ""}`, d && d.bespoke && (!S.soonExpected || d.placeholders > 0));
    if (what === "contact") ok(`${id} contact: the placeholder slot is clearly marked`, d && d.placeholders > 0);
    ok(`${id} ${what}: no page errors`, !page._errors.length, page._errors.join(" | "));
    await ctx.close();
  }

  // 5. What's new: a past first visit, then a return visit now.
  for (const [w, url] of [[1440, LOG + "/"], [390, S.root + "/"]]) {
    const { ctx, page } = await fresh(S.key, { width: w });
    await ctx.clock.install({ time: new Date(Date.now() - 5 * 86400000) });
    await page.goto(bust(url), { waitUntil: "networkidle" });
    await ctx.clock.runFor(3000);
    const first = await page.evaluate(() => document.querySelector("[data-arr-news]")?.hidden);
    await ctx.clock.setSystemTime(new Date());
    await page.reload({ waitUntil: "networkidle" });
    await ctx.clock.runFor(4000);
    await page.waitForTimeout(1200);
    const r = await page.evaluate(() => {
      const b = document.querySelector("arrival-controls [data-arr-news]");
      const cs = b && getComputedStyle(b);
      const tip = document.querySelector("[data-arr-news-tip]");
      const dot = document.querySelector("[data-arr-news-dot]");
      return {
        shown: b && !b.hidden,
        n: b && b.querySelector("[data-arr-news-n]")?.textContent,
        filled: cs && cs.backgroundColor === getComputedStyle(document.documentElement).getPropertyValue("--accent").trim() ? true : cs && cs.backgroundColor,
        tip: tip && !tip.hidden && tip.textContent,
        dot: dot && !dot.hidden && dot.textContent,
      };
    });
    await page.screenshot({ path: `${SHOTS}/${id}-news-${w}.png`, clip: { x: 0, y: 0, width: w, height: 160 } });
    ok(`${id} what's new @${w}px: nothing on a first visit; a filled count and a one-time tip on the return visit`, first === true && r.shown && +r.n > 0 && !!r.tip, JSON.stringify(r));
    if (w < 1100) ok(`${id} what's new @${w}px: the count rides on the Menu button`, r.dot === r.n, JSON.stringify(r));
    await ctx.close();
  }

  // 6. Reading round 2.
  {
    const { ctx, page } = await fresh(S.key);
    await page.goto(bust(LOG + "/roadmap"), { waitUntil: "networkidle" });
    await page.click("[data-arr-drawer]");
    await page.click('.arr-drawer label:has(input[data-arr-text][value="large"])');
    await page.click(".arr-drawer label.arr-switch-measure");
    await page.reload({ waitUntil: "networkidle" });
    const r = await page.evaluate(() => ({ text: document.documentElement.dataset.text, measure: document.documentElement.dataset.measure, fs: getComputedStyle(document.documentElement).fontSize, pw: Math.round(document.querySelector("main p").getBoundingClientRect().width) }));
    ok(`${id}: text size and comfortable line length apply and persist`, r.text === "large" && r.measure === "comfy" && r.fs === "18px", JSON.stringify(r));
    await ctx.close();
  }

  // 7. Map thumbnails, donate slot.
  for (const [name, url, here] of [["AstroLog map", LOG + "/map", "map"], ["portal map", S.root + "/map/", "portal"]]) {
    const { ctx, page } = await fresh(S.key);
    await page.goto(bust(url), { waitUntil: "networkidle" });
    await page.evaluate(async () => {
      for (const img of document.querySelectorAll(".arr-map img")) { img.loading = "eager"; }
      await new Promise((r) => setTimeout(r, 2500));
    });
    const r = await page.evaluate(() => {
      const imgs = [...document.querySelectorAll(".arr-map img")];
      return { n: imgs.length, broken: imgs.filter((i) => !i.complete || !i.naturalWidth).map((i) => i.src), here: document.querySelector(".arr-map-card.is-here .arr-map-name")?.textContent.trim() };
    });
    await page.screenshot({ path: `${SHOTS}/${id}-${name.replace(" ", "-")}.png`, fullPage: true });
    ok(`${id} ${name}: every destination has a loaded share-image thumbnail; "You are here" on ${here}`, r.n >= 10 && !r.broken.length && !!r.here, `${r.n} thumbs; here=${r.here}; broken: ${r.broken.join(" ")}`);
    await ctx.close();
  }
  {
    const { ctx, page } = await fresh(S.key);
    await page.goto(bust(S.root + "/donate/"), { waitUntil: "networkidle" });
    await page.waitForTimeout(800);
    const r = await page.evaluate(() => ({
      slot: !!document.querySelector("[data-arr-wallet-slot]"),
      give: [...document.querySelectorAll(".arr-give-card a")].map((a) => a.href),
      addr: /\b0x[0-9a-fA-F]{20,}|\bbc1[0-9a-z]{20,}|\b[13][a-km-zA-HJ-NP-Z1-9]{25,34}\b/.test(document.body.innerText),
      ledger: !!document.querySelector(".arr-contrib-empty, .arr-contrib-list"),
    }));
    ok(`${id} donate: giving path, contribution ledger, an empty crypto slot, and no wallet address`, r.slot && r.give.length && r.ledger && !r.addr, JSON.stringify(r));
    ok(`${id} donate: no page errors`, !page._errors.length, page._errors.join(" | "));
    await ctx.close();
  }
}

await browser.close();
const fails = results.filter((r) => r.startsWith("FAIL"));
console.log(`\n${results.length - fails.length}/${results.length} passed`);
process.exit(fails.length ? 1 : 0);
