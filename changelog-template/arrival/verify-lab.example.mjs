// Verify the drasticstatic ORG lab (O-R-G-astro-public) with ORG's arrival kit.
//   node verify-lab.mjs            -> live
//   node verify-lab.mjs --local    -> lab URLs served from O-R-G-astro/dist (ORG's kit stays live)
import { chromium } from "playwright-core";
import fs from "node:fs";
import path from "node:path";

const LOCAL = process.argv.includes("--local");
const LAB = "https://drasticstatic.github.io/O-R-G-astro-public";
const DAPP = "https://drasticstatic.github.io/O-R-G-dapp-public-preview/";
const DIST = process.env.HOME + "/code/O-R-G/O-R-G-astro/dist";
const SHOTS = path.resolve("../shots/arrival/lab");
fs.mkdirSync(SHOTS, { recursive: true });
const types = { ".html": "text/html", ".css": "text/css", ".js": "application/javascript", ".json": "application/json", ".png": "image/png", ".webp": "image/webp" };
function serve(route) {
  let p = decodeURIComponent(new URL(route.request().url()).pathname).slice("/O-R-G-astro-public".length) || "/";
  let f = path.join(DIST, p);
  if (fs.existsSync(f) && fs.statSync(f).isDirectory()) f = path.join(f, "index.html");
  else if (!fs.existsSync(f) && fs.existsSync(f + "/index.html")) f += "/index.html";
  if (!fs.existsSync(f)) return route.fulfill({ status: 404, contentType: "text/html", body: fs.readFileSync(path.join(DIST, "404.html")) });
  return route.fulfill({ status: 200, contentType: types[path.extname(f)] || "application/octet-stream", body: fs.readFileSync(f), headers: { "access-control-allow-origin": "*" } });
}
const results = [];
const ok = (n, c, x = "") => results.push(`${c ? "PASS" : "FAIL"}  ${n}${x !== "" ? "  (" + x + ")" : ""}`);
const browser = await chromium.launch({ channel: "chrome" });
async function fresh(opts = {}) {
  const ctx = await browser.newContext({ viewport: { width: 1280, height: 900 }, ...opts });
  if (LOCAL) await ctx.route(LAB + "/**", serve);
  const page = await ctx.newPage();
  page._errors = [];
  page.on("pageerror", (e) => page._errors.push(e.message));
  page.on("console", (m) => { if (m.type() === "error" && !/Failed to load resource/.test(m.text())) page._errors.push(m.text()); });
  return { ctx, page };
}
const splashOpen = (p) => p.evaluate(() => !!document.querySelector("dialog.arr-splash[open]"));
{
  const { ctx, page } = await fresh();
  const r = await page.goto(LAB + "/", { waitUntil: "networkidle" });
  ok("lab porch loads", r.status() === 200, r.status());
  await page.waitForTimeout(400);
  ok("lab: splash on first visit", await splashOpen(page));
  const text = await page.evaluate(() => document.querySelector("dialog.arr-splash")?.innerText || "");
  ok('lab splash teaches "Press / to search"', /Choose how you arrive/.test(text) && /Press \/ to search/.test(text));
  await page.screenshot({ path: SHOTS + "/01-splash.png" });
  let trapped = true;
  for (let i = 0; i < 20; i++) { await page.keyboard.press("Tab"); if (!(await page.evaluate(() => !!document.activeElement?.closest("dialog.arr-splash")))) trapped = false; }
  ok("lab splash traps focus", trapped);
  await page.click('dialog.arr-splash label[data-theme="stone"]');
  await page.keyboard.press("Escape");
  await page.waitForTimeout(200);
  ok("Esc closes the lab splash", !(await splashOpen(page)));
  await page.reload({ waitUntil: "networkidle" });
  ok("lab: no splash on second visit", !(await splashOpen(page)));
  ok("lab: chosen light kept (stone)", (await page.evaluate(() => document.documentElement.dataset.theme)) === "stone");
  await page.screenshot({ path: SHOTS + "/02-porch-stone.png", fullPage: true });
  const txt = await page.evaluate(() => document.body.innerText);
  ok("lab porch points to ORG's official changelog", /official changelog/i.test(txt) && /ORG AstroLog/.test(txt));
  const av = await page.evaluate(() => [...document.querySelectorAll(".people arrival-avatar img")].map((i) => i.src.slice(0, 30)));
  ok("lab porch shows avatars", av.length === 4, av.join(" | "));
  await page.keyboard.press("/");
  await page.keyboard.type("perforated");
  await page.waitForTimeout(1200);
  const orgHit = await page.evaluate(() => [...document.querySelectorAll(".arr-pal-list [data-i]")].map((l) => l.innerText.replace(/\n/g, " ")).join(" || "));
  ok('"/" in the lab finds ORG AstroLog content (cross-origin)', /ORG AstroLog/i.test(orgHit), orgHit.slice(0, 140));
  await page.fill("#arr-pal-input", "sidecar becomes");
  await page.waitForTimeout(300);
  const labHit = await page.evaluate(() => document.querySelector(".arr-pal-list [data-i]")?.innerText || "");
  ok('"/" in the lab finds lab entries', /sidecar becomes the drasticstatic ORG lab/i.test(labHit), labHit.split("\n")[0]);
  await page.screenshot({ path: SHOTS + "/03-search.png" });
  await Promise.all([page.waitForURL(/changelog/), page.keyboard.press("Enter")]);
  ok("search result jumps to the entry", /changelog\/(#)?2026-10-12-the-sidecar-becomes/.test(page.url()), page.url());
  for (const [n, u] of [["changelog", LAB + "/changelog"], ["map", LAB + "/map"], ["search.json", LAB + "/search.json"]]) {
    const rr = await page.goto(u, { waitUntil: "networkidle" });
    ok(`lab ${n} loads`, rr.status() === 200, rr.status());
  }
  await page.goto(LAB + "/changelog", { waitUntil: "networkidle" });
  const n = await page.evaluate(() => document.querySelectorAll(".timeline li").length);
  ok("lab changelog keeps every entry (19 history + 3 new)", n === 22, n);
  await page.screenshot({ path: SHOTS + "/04-changelog.png" });
  const r404 = await page.goto(LAB + "/nope/deeper/still", { waitUntil: "networkidle" });
  ok("lab nested 404 is the lab's page", r404.status() === 404 && /isn't in the lab/.test(await page.content()), r404.status());
  ok("lab 404: no splash", !(await splashOpen(page)));
  await Promise.all([page.waitForLoadState("networkidle"), page.click("text=Back to the lab")]);
  ok("lab 404 back button reaches the lab", page.url() === LAB + "/", page.url());
  ok("lab: no console errors", page._errors.length === 0, page._errors.join(" / "));
  await page.goto(DAPP, { waitUntil: "networkidle" });
  const dappTheme = await page.evaluate(() => document.documentElement.dataset.theme);
  ok("light chosen in the lab carries to the dApp preview (same origin)", dappTheme === "stone", dappTheme);
  await ctx.close();
}
{
  const { ctx, page } = await fresh({ viewport: { width: 390, height: 844 }, isMobile: true, hasTouch: true });
  await page.goto(LAB + "/", { waitUntil: "networkidle" });
  await page.waitForTimeout(300);
  await page.screenshot({ path: SHOTS + "/05-phone-splash.png" });
  await page.click("[data-arr-enter]");
  const over = await page.evaluate(() => document.documentElement.scrollWidth - innerWidth);
  ok("lab phone: no horizontal scroll", over <= 0, over);
  await page.screenshot({ path: SHOTS + "/06-phone-porch.png" });
  await ctx.close();
}
await browser.close();
console.log((LOCAL ? "[local] " : "[live] ") + results.filter((r) => r.startsWith("PASS")).length + "/" + results.length + " passed");
console.log(results.join("\n"));
