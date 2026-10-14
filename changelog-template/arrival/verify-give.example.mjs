// Verification for kit v1.3, give with crypto (arrival/give/give.js), on every portal's /donate/.
// Run from a folder with playwright-core installed:
//   npm i playwright-core && node verify-give.example.mjs [pir thef org psanctuary psanctuarychurch]
//   --local <id>=<path to the portal repo>  serves that portal's files in place of the live ones
//                                            (pre-deploy); anything missing falls through to live.
// Uses local Chrome (channel "chrome") and a fresh browser context per check. Per org:
//   1. The section is drawn at first paint; give.js loads lazily (only once the section nears the
//      screen); nothing from Reown or the CDN loads before a click; the page height doesn't move.
//   2. Connect opens the AppKit window (site on the Reown allowlist) or shows the calm "isn't
//      switched on for this site yet" state with the guide (not on it). Never a red console error.
//   3. The guide traps focus, closes on Esc and returns focus to Connect.
//   4. No wallet address text anywhere on the page (all orgs: addresses are null today).
//   5. 320–1440px: one header row, no horizontal scroll, no page errors.
//   An org with give.enabled false (PIR) keeps the empty slot and never requests give.js.
import { chromium } from "playwright-core";
import fs from "node:fs";
import path from "node:path";

const SITES = {
  pir: { root: "https://psychedelicsinrecovery.github.io", key: "pir-arrival", give: false },
  thef: { root: "https://theholyearthfoundation.github.io", key: "thef-arrival", give: true },
  org: { root: "https://octagon-religious-research-group-org.github.io", key: "org-experience", give: true },
  psanctuary: { root: "https://psanctuary.github.io", key: "psanctuary-arrival", give: true },
  psanctuarychurch: { root: "https://psanctuarychurch.github.io", key: "psanctuarychurch-arrival", give: true },
};
const WIDTHS = [320, 360, 390, 768, 1024, 1280, 1440];
const ADDR = /\b0x[0-9a-fA-F]{20,}|\bbc1[0-9a-z]{20,}|\b[13][a-km-zA-HJ-NP-Z1-9]{25,34}\b/;
const THIRD = (u) => /appkit-cdn|walletconnect|web3modal|reown/.test(u);
const SHOTS = "shots-give";
fs.mkdirSync(SHOTS, { recursive: true });

const args = process.argv.slice(2);
const LOCAL = {};
for (let i = 0; i < args.length; i++) if (args[i] === "--local") { const [id, p] = args[++i].split("="); LOCAL[id] = p; }
const ids = args.filter((a, i) => !a.startsWith("--") && args[i - 1] !== "--local");
const types = { ".html": "text/html", ".js": "text/javascript", ".css": "text/css", ".json": "application/json", ".svg": "image/svg+xml", ".png": "image/png", ".jpg": "image/jpeg" };

const results = [];
const ok = (name, cond, extra = "") => {
  results.push(`${cond ? "PASS" : "FAIL"}  ${name}${extra ? "  (" + extra + ")" : ""}`);
  console.log(results[results.length - 1]);
};
const bust = (u) => u + (u.includes("?") ? "&" : "?") + "v=" + Date.now();
const browser = await chromium.launch({ channel: "chrome" });
async function fresh(id, width = 1280) {
  const S = SITES[id];
  const ctx = await browser.newContext({ viewport: { width, height: 900 } });
  await ctx.addInitScript((k) => { try { if (!localStorage.getItem(k)) localStorage.setItem(k, JSON.stringify({ chosen: true })); } catch (e) {} }, S.key);
  if (LOCAL[id]) {
    await ctx.route((u) => u.href.startsWith(S.root + "/"), (route) => {
      const u = new URL(route.request().url());
      let f = path.join(LOCAL[id], decodeURIComponent(u.pathname));
      if (f.endsWith("/")) f += "index.html";
      if (!fs.existsSync(f)) return route.continue();
      return route.fulfill({ status: 200, contentType: types[path.extname(f)] || "application/octet-stream", body: fs.readFileSync(f) });
    });
  }
  const page = await ctx.newPage();
  page._errors = [];
  page._console = [];
  page._req = [];
  page.on("pageerror", (e) => page._errors.push(e.message));
  page.on("console", (m) => { if (m.type() === "error") page._console.push(m.text().slice(0, 200)); });
  page.on("request", (r) => page._req.push(r.url()));
  return { ctx, page };
}

for (const id of ids.length ? ids : Object.keys(SITES)) {
  const S = SITES[id];
  const URL_ = S.root + "/donate/";
  console.log(`\n=== ${id}${LOCAL[id] ? " (local files)" : ""} ===`);

  // 1. Lazy, quiet, no shift.
  {
    const { ctx, page } = await fresh(id);
    await page.goto(bust(URL_), { waitUntil: "networkidle" });
    const slot = page.locator("[data-arr-wallet-slot]");
    await slot.scrollIntoViewIfNeeded();
    const h0 = await slot.evaluate((e) => e.getBoundingClientRect().height);
    await page.waitForTimeout(1500);
    const r = await page.evaluate(() => ({
      give: !!document.querySelector("[data-arr-give]"),
      loaded: !!window.ArrivalGive,
      kit: window.Arrival && window.Arrival.version,
      coins: document.querySelectorAll(".arr-coin").length,
      soon: document.querySelectorAll(".arr-coin.is-soon").length,
      addr: false,
    }));
    r.addr = ADDR.test(await page.evaluate(() => document.body.innerText));
    const h1 = await slot.evaluate((e) => e.getBoundingClientRect().height);
    const giveReq = page._req.filter((u) => /\/give\/give\.js/.test(u)).length;
    const third = page._req.filter(THIRD);
    if (S.give) {
      ok(`${id}: kit ${r.kit}; the section is drawn with every coin "coming soon"; give.js loaded lazily; nothing from Reown or the CDN before a click; no shift`, r.give && r.loaded && r.coins >= 1 && r.soon === r.coins && giveReq === 1 && !third.length && h0 === h1, JSON.stringify({ ...r, giveReq, third: third.length, h0, h1 }));
    } else {
      ok(`${id}: give is off: the empty slot stays, give.js is never requested`, !r.give && !r.loaded && giveReq === 0 && !third.length, JSON.stringify({ ...r, giveReq }));
    }
    ok(`${id}: no wallet address text on the page`, !r.addr);
    ok(`${id}: no page errors, no console errors`, !page._errors.length && !page._console.length, [...page._errors, ...page._console].join(" | "));
    await ctx.close();
  }
  if (!S.give) continue;

  // 2 + 3. Connect: AppKit or the calm state; the guide's focus trap.
  {
    const { ctx, page } = await fresh(id);
    await page.goto(bust(URL_), { waitUntil: "networkidle" });
    await page.locator("[data-arr-give]").scrollIntoViewIfNeeded();
    await page.waitForTimeout(800);
    await page.click('[data-give="connect"]');
    let r = null;
    for (let i = 0; i < 40; i++) {
      await page.waitForTimeout(500);
      r = await page.evaluate(() => {
        const m = document.querySelector("w3m-modal");
        const d = [...document.querySelectorAll("dialog.arr-learn")].find((x) => x.open);
        return {
          appkit: !!(m && m.shadowRoot && m.shadowRoot.querySelector("wui-card, w3m-router") && m.getBoundingClientRect().height > 0),
          state: document.querySelector("[data-arr-give]").getAttribute("data-give-state"),
          guide: !!d,
          focusIn: !!(d && d.contains(document.activeElement)),
        };
      });
      if (r.appkit || r.state === "origin") break;
    }
    await page.screenshot({ path: `${SHOTS}/${id}-connect.png` });
    ok(`${id}: Connect opens AppKit, or the calm "isn't switched on for this site yet" state with the guide`, r.appkit || (r.state === "origin" && r.guide && r.focusIn), JSON.stringify(r));
    if (!r.appkit) {
      let inside = true;
      for (let i = 0; i < 25; i++) {
        await page.keyboard.press("Tab");
        inside = inside && (await page.evaluate(() => !!document.activeElement.closest("dialog[open]")));
      }
      await page.keyboard.press("Escape");
      await page.waitForTimeout(300);
      const a = await page.evaluate(() => ({ open: !![...document.querySelectorAll("dialog.arr-learn")].find((x) => x.open), focus: document.activeElement && document.activeElement.getAttribute("data-give") }));
      ok(`${id}: the guide traps focus, Esc closes it, focus returns to Connect`, inside && !a.open && a.focus === "connect", JSON.stringify(a));
      ok(`${id}: the AppKit bundle never loaded on a site that isn't on the allowlist`, !page._req.some((u) => /appkit-cdn/.test(u)));
    }
    ok(`${id}: no page errors and no red console after Connect`, !page._errors.length && !page._console.length, [...page._errors, ...page._console].join(" | "));
    await page.locator("[data-arr-give]").screenshot({ path: `${SHOTS}/${id}-section.png` });
    await ctx.close();
  }

  // 5. Widths.
  {
    const bad = [];
    for (const w of WIDTHS) {
      const { ctx, page } = await fresh(id, w);
      await page.goto(bust(URL_), { waitUntil: "networkidle" });
      await page.waitForTimeout(500);
      const r = await page.evaluate(() => {
        const h = document.querySelector("header");
        const sec = document.querySelector("[data-arr-give]");
        // One row: every visible header item overlaps every other vertically.
        const boxes = [...h.children].filter((c) => c.getClientRects().length && getComputedStyle(c).position !== "absolute").map((c) => c.getBoundingClientRect());
        return {
          h: Math.round(h.getBoundingClientRect().height),
          rows: Math.max(...boxes.map((b) => b.top)) < Math.min(...boxes.map((b) => b.bottom)) ? 1 : 2,
          hs: document.documentElement.scrollWidth > document.documentElement.clientWidth,
          over: [...sec.querySelectorAll("*")].some((e) => e.getBoundingClientRect().right > document.documentElement.clientWidth + 1),
        };
      });
      if (r.h >= 72 || r.rows !== 1 || r.hs || r.over || page._errors.length) bad.push(`${w}px ${JSON.stringify(r)} ${page._errors.join(";")}`);
      if (w === 320) {
        await page.locator("[data-arr-give]").scrollIntoViewIfNeeded();
        await page.locator("[data-arr-give]").screenshot({ path: `${SHOTS}/${id}-320.png` });
      }
      await ctx.close();
    }
    ok(`${id}: one header row, no horizontal scroll, the section fits (${WIDTHS[0]}–${WIDTHS[WIDTHS.length - 1]}px)`, !bad.length, bad.join(" | "));
  }
}

await browser.close();
const fails = results.filter((r) => r.startsWith("FAIL"));
console.log(`\n${results.length - fails.length}/${results.length} passed`);
process.exit(fails.length ? 1 : 0);
