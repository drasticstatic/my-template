// Example verification for an org's portal + AstroLog with the arrival kit (written for ORG).
// To port: change ORIGIN, PORTAL_DIR and DIST, the entry/library URLs and the expected texts
// ("tore off the sheet", entry titles), then run from a folder with playwright-core installed:
//   npm i playwright-core && node verify.example.mjs --local   (before deploy) / without --local (live)
// Verify ORG's portal + AstroLog with the arrival kit.
//   node verify-org.mjs            -> live production
//   node verify-org.mjs --local    -> production URLs, served from the local repos (pre-deploy)
import { chromium } from "playwright-core";
import fs from "node:fs";
import path from "node:path";

const LOCAL = process.argv.includes("--local");
const ORIGIN = "https://octagon-religious-research-group-org.github.io";
const LOG = ORIGIN + "/changelog-astro-public";
const PORTAL_DIR = process.env.HOME + "/Octagon-Religious-Research-Group-ORG/Octagon-Religious-Research-Group-ORG.github.io";
const DIST = process.env.HOME + "/Octagon-Religious-Research-Group-ORG/changelog-astro/astro/dist";
const SHOTS = path.resolve("../shots/arrival/verify");
fs.mkdirSync(SHOTS, { recursive: true });

const types = { ".html": "text/html", ".css": "text/css", ".js": "application/javascript", ".json": "application/json", ".png": "image/png", ".jpg": "image/jpeg", ".webp": "image/webp", ".svg": "image/svg+xml" };
function serve(route) {
  const u = new URL(route.request().url());
  let p = decodeURIComponent(u.pathname);
  let dir = PORTAL_DIR, notFound = path.join(PORTAL_DIR, "404.html");
  if (p.startsWith("/changelog-astro-public")) {
    dir = DIST;
    notFound = path.join(DIST, "404.html");
    p = p.slice("/changelog-astro-public".length) || "/";
  }
  let f = path.join(dir, p);
  if (fs.existsSync(f) && fs.statSync(f).isDirectory()) f = path.join(f, "index.html");
  else if (!fs.existsSync(f) && fs.existsSync(f + "/index.html")) f = f + "/index.html";
  if (!fs.existsSync(f)) return route.fulfill({ status: 404, contentType: "text/html", body: fs.readFileSync(notFound), headers: { "access-control-allow-origin": "*" } });
  return route.fulfill({ status: 200, contentType: types[path.extname(f)] || "application/octet-stream", body: fs.readFileSync(f), headers: { "access-control-allow-origin": "*" } });
}

const results = [];
const ok = (name, cond, extra = "") => {
  results.push(`${cond ? "PASS" : "FAIL"}  ${name}${extra ? "  (" + extra + ")" : ""}`);
};

const browser = await chromium.launch({ channel: "chrome" });
async function fresh(opts = {}) {
  const ctx = await browser.newContext({ viewport: { width: 1280, height: 900 }, ...opts });
  if (LOCAL) await ctx.route(ORIGIN + "/**", serve);
  const page = await ctx.newPage();
  page._errors = [];
  page.on("pageerror", (e) => page._errors.push(e.message));
  page.on("console", (m) => {
    if (m.type() === "error" && !/favicon|Failed to load resource/.test(m.text())) page._errors.push(m.text());
  });
  return { ctx, page };
}
const splashOpen = (p) => p.evaluate(() => !!document.querySelector("dialog.arr-splash[open]"));
const theme = (p) => p.evaluate(() => document.documentElement.dataset.theme);

// 1. First visit on the portal: splash, "/" teaching, focus trap, Esc, remembered.
{
  const { ctx, page } = await fresh();
  const r = await page.goto(ORIGIN + "/", { waitUntil: "networkidle" });
  ok("portal loads", r.status() === 200, r.status());
  await page.waitForTimeout(400);
  ok("portal: splash on first visit", await splashOpen(page));
  const text = await page.evaluate(() => document.querySelector("dialog.arr-splash")?.innerText || "");
  ok('splash asks "Choose how you arrive"', /Choose how you arrive/.test(text));
  ok('splash teaches "Press / to search"', /Press \/ to search/.test(text));
  await page.screenshot({ path: SHOTS + "/01-portal-splash.png" });
  let trapped = true;
  for (let i = 0; i < 30; i++) {
    await page.keyboard.press(i % 7 === 6 ? "Shift+Tab" : "Tab");
    if (!(await page.evaluate(() => !!document.activeElement?.closest("dialog.arr-splash")))) trapped = false;
  }
  ok("splash traps focus (30 Tab/Shift+Tab presses)", trapped);
  await page.click('dialog.arr-splash label[data-theme="prism"]');
  await page.keyboard.press("Escape");
  await page.waitForTimeout(250);
  ok("Esc closes the splash", !(await splashOpen(page)));
  ok("chosen light applied (prism)", (await theme(page)) === "prism");
  await page.reload({ waitUntil: "networkidle" });
  await page.waitForTimeout(400);
  ok("portal: no splash on second visit", !(await splashOpen(page)));

  // 2. Mode persists portal -> AstroLog -> portal
  await page.goto(LOG + "/", { waitUntil: "networkidle" });
  await page.waitForTimeout(300);
  ok("AstroLog: same light after portal (prism)", (await theme(page)) === "prism");
  ok("AstroLog: no splash once chosen on the portal", !(await splashOpen(page)));
  await page.click('[data-arr-swatch="stone"]');
  await page.goto(ORIGIN + "/", { waitUntil: "networkidle" });
  ok("portal: light chosen on AstroLog carries back (stone)", (await theme(page)) === "stone");

  // 3. "/" search on the portal reaches AstroLog content
  await page.waitForTimeout(500);
  await page.keyboard.press("/");
  await page.waitForTimeout(200);
  ok('"/" opens search on the portal', await page.evaluate(() => !!document.querySelector("dialog.arr-palette[open]")));
  await page.keyboard.type("arrive");
  await page.waitForTimeout(700);
  const first = await page.evaluate(() => document.querySelector(".arr-pal-list [data-i]")?.innerText || "");
  ok("portal search finds AstroLog entries", /Choose how you arrive/.test(first), first.split("\n")[0]);
  await page.screenshot({ path: SHOTS + "/02-portal-search.png" });
  await Promise.all([page.waitForURL(/choose-how-you-arrive/), page.keyboard.press("Enter")]);
  ok("Enter opens the entry", /changelog\/github\/2026-10-12-choose-how-you-arrive/.test(page.url()));

  // 4. Latest + people rendered on the portal from search.json
  await page.goto(ORIGIN + "/", { waitUntil: "networkidle" });
  await page.waitForTimeout(800);
  const latestN = await page.evaluate(() => document.querySelectorAll(".arr-latest li").length);
  const peopleN = await page.evaluate(() => document.querySelectorAll(".arr-people li").length);
  ok("portal shows latest AstroLog entries", latestN === 4, latestN);
  ok("portal shows who made the changes", peopleN >= 4, peopleN);
  const imgs = await page.evaluate(() => [...document.querySelectorAll(".arr-people arrival-avatar img")].map((i) => i.src.slice(0, 40)));
  ok("avatars: GitHub for handles, initials SVG otherwise", imgs.some((s) => s.startsWith("https://github.com/")) && imgs.some((s) => s.startsWith("data:image/svg")), imgs.join(" | "));
  await page.locator("#people").scrollIntoViewIfNeeded();
  await page.screenshot({ path: SHOTS + "/03-portal-people.png" });

  // 5. Drawer -> welcome guide
  await page.evaluate(() => scrollTo(0, 0));
  await page.click("[data-arr-drawer]");
  await page.waitForTimeout(200);
  ok("drawer opens", await page.evaluate(() => !document.querySelector(".arr-drawer").hidden));
  await page.screenshot({ path: SHOTS + "/04-drawer.png" });
  await page.click('.arr-drawer [data-arrival-open="guide"]');
  await page.waitForTimeout(400);
  ok("drawer link opens the welcome guide", await page.evaluate(() => !!document.querySelector("dialog.arr-guide[open]")));
  for (let i = 0; i < 5; i++) await page.click("[data-arr-next]");
  await page.waitForTimeout(800);
  await page.screenshot({ path: SHOTS + "/05-guide-people.png" });
  for (let i = 0; i < 2; i++) await page.click("[data-arr-next]");
  await page.waitForTimeout(300);
  const fin = await page.evaluate(() => document.querySelector("[data-arr-finale] span")?.textContent || "");
  ok("guide: eight steps, all wedges lit at the end", /all eight/.test(fin), fin);
  await page.screenshot({ path: SHOTS + "/06-guide-end.png" });
  ok("portal: no console errors", page._errors.length === 0, page._errors.join(" / "));
  await ctx.close();
}

// 6. Every AstroLog page, plus nested 404s with their back buttons
{
  const { ctx, page } = await fresh();
  await page.addInitScript(() => { try { localStorage.setItem("org-experience", JSON.stringify({ light: "night", motion: "gentle", chosen: true })); } catch (e) {} });
  const pages = [
    ["porch", LOG + "/"],
    ["changelog", LOG + "/changelog"],
    ["entry", LOG + "/changelog/github/2026-10-11-astrolog-moves-into-the-org"],
    ["library", LOG + "/library"],
    ["article", LOG + "/library/how-this-astrolog-works"],
    ["map", LOG + "/map"],
    ["search.json", LOG + "/search.json"],
  ];
  for (const [name, url] of pages) {
    const r = await page.goto(url, { waitUntil: "networkidle" });
    const styled = name === "search.json" ? true : await page.evaluate(() => getComputedStyle(document.body).backgroundColor !== "rgba(0, 0, 0, 0)");
    const controls = name === "search.json" ? true : await page.evaluate(() => !!document.querySelector(".arr-controls"));
    ok(`AstroLog ${name} loads`, r.status() === 200 && styled && controls, `${r.status()} ${url.replace(ORIGIN, "")}`);
  }
  await page.goto(LOG + "/changelog/github/2026-10-11-astrolog-moves-into-the-org", { waitUntil: "networkidle" });
  const av = await page.evaluate(() => [...document.querySelectorAll(".meta-who arrival-avatar img")].map((i) => i.src));
  ok("entry page shows the author's avatar", av.length > 0 && av[0].includes("github.com/drasticstatic"), av[0]);
  await page.screenshot({ path: SHOTS + "/07-entry.png" });
  const r404 = await page.goto(LOG + "/changelog/nope/deeper/still", { waitUntil: "networkidle" });
  const t404 = await page.evaluate(() => document.querySelector("h1")?.textContent || "");
  ok("AstroLog nested 404 is ORG's page", r404.status() === 404 && /tore off the sheet/.test(t404), `${r404.status()} ${t404}`);
  ok("AstroLog 404: no splash", !(await splashOpen(page)));
  await page.screenshot({ path: SHOTS + "/08-astrolog-404.png" });
  await Promise.all([page.waitForLoadState("networkidle"), page.click("text=Back to the porch")]);
  ok("AstroLog 404 back button reaches the porch", page.url() === LOG + "/" && /what's changed/i.test(await page.title()), page.url());
  const p404 = await page.goto(ORIGIN + "/no/such/place", { waitUntil: "networkidle" });
  ok("portal nested 404 is ORG's page", p404.status() === 404 && /doesn't lead to a page/.test(await page.content()));
  await Promise.all([page.waitForLoadState("networkidle"), page.click("text=Back to the ORG entry portal")]);
  ok("portal 404 back button reaches the portal", page.url() === ORIGIN + "/", page.url());
  await page.goto(LOG + "/library", { waitUntil: "networkidle" });
  await page.waitForTimeout(300);
  await page.keyboard.press("/");
  await page.keyboard.type("perforated");
  await page.waitForTimeout(600);
  const hit = await page.evaluate(() => document.querySelector(".arr-pal-list [data-i]")?.innerText || "");
  ok('"/" search on the AstroLog finds a library write-up', /perforated/i.test(hit), hit.split("\n")[0]);
  ok("AstroLog: no console errors", page._errors.length === 0, page._errors.join(" / "));
  await ctx.close();
}

// 7. First visit straight to the AstroLog, with reduced motion and more contrast asked by the OS
{
  const { ctx, page } = await fresh({ reducedMotion: "reduce", forcedColors: "none" });
  await page.emulateMedia({ reducedMotion: "reduce" });
  await page.goto(LOG + "/", { waitUntil: "networkidle" });
  await page.waitForTimeout(400);
  ok("AstroLog: splash on a genuine first visit", await splashOpen(page));
  const note = await page.evaluate(() => document.querySelector("dialog.arr-splash .arr-notice")?.textContent || "");
  ok("splash suggests reduced motion when the OS asks", /less motion/.test(note) && (await page.evaluate(() => document.documentElement.dataset.motion)) === "still", note);
  await page.screenshot({ path: SHOTS + "/09-astrolog-splash-reduced.png" });
  await page.keyboard.press("/");
  await page.waitForTimeout(300);
  ok('"/" from the splash closes it and opens search', !(await splashOpen(page)) && (await page.evaluate(() => !!document.querySelector("dialog.arr-palette[open]"))));
  await page.keyboard.press("Escape");
  await page.reload({ waitUntil: "networkidle" });
  ok("AstroLog: no splash on the second visit", !(await splashOpen(page)));
  await ctx.close();
}

// 8. Phone width
{
  const { ctx, page } = await fresh({ viewport: { width: 390, height: 844 }, isMobile: true, hasTouch: true });
  await page.goto(LOG + "/", { waitUntil: "networkidle" });
  await page.waitForTimeout(400);
  await page.screenshot({ path: SHOTS + "/10-phone-splash.png" });
  await page.click("[data-arr-enter]");
  const overflow = await page.evaluate(() => document.documentElement.scrollWidth - innerWidth);
  ok("phone: no horizontal scroll on the porch", overflow <= 0, overflow);
  await page.screenshot({ path: SHOTS + "/11-phone-porch.png" });
  await page.click("[data-arr-drawer]");
  await page.waitForTimeout(250);
  await page.screenshot({ path: SHOTS + "/12-phone-drawer.png" });
  await page.goto(ORIGIN + "/", { waitUntil: "networkidle" });
  const overflow2 = await page.evaluate(() => document.documentElement.scrollWidth - innerWidth);
  ok("phone: no horizontal scroll on the portal", overflow2 <= 0, overflow2);
  await page.screenshot({ path: SHOTS + "/13-phone-portal.png" });
  await ctx.close();
}

await browser.close();
console.log((LOCAL ? "[local] " : "[live] ") + results.filter((r) => r.startsWith("PASS")).length + "/" + results.length + " passed");
console.log(results.join("\n"));
