// Example live verification for arrival kit wave 5 (written for ORG, the lab and the O-R-G dApp).
// To port: change the URLs, PRIVATE (your private repo names) and the og page list, then run from a
// folder with playwright-core installed:  npm i playwright-core && node verify-wave5.example.mjs
// Checks: reading mode toggles/restores/persists per site; what's new on a genuine past first visit
// (Playwright's fake clock) then a return visit, opened and cleared; the ledgers link only public
// repos' real commits with noise filtered; the dApp has the kit, the lab link, no allowlist error;
// complete og tags with real JPEG cards; and every cross-link between the sites resolves.
import { chromium } from "playwright-core";
import fs from "node:fs";

const ORG = "https://octagon-religious-research-group-org.github.io";
const LOG = ORG + "/changelog-astro-public";
const LAB = "https://drasticstatic.github.io/O-R-G-astro-public";
const DAPP = "https://drasticstatic.github.io/O-R-G-dapp-public-preview";
const PRIVATE = ["changelog-astro", ".github-private", "O-R-G", "O-R-G-astro", "O-R-G-dapp"];
const SHOTS = "shots";
fs.mkdirSync(SHOTS, { recursive: true });

const results = [];
const ok = (name, cond, extra = "") => {
  results.push(`${cond ? "PASS" : "FAIL"}  ${name}${extra ? "  (" + extra + ")" : ""}`);
  console.log(results[results.length - 1]);
};
const bust = (u) => u + (u.includes("?") ? "&" : "?") + "v=" + Date.now();

const browser = await chromium.launch({ channel: "chrome" });
async function fresh(opts = {}) {
  const ctx = await browser.newContext({ viewport: { width: 1280, height: 900 }, ...opts });
  const page = await ctx.newPage();
  page._console = [];
  page._errors = [];
  page.on("pageerror", (e) => page._errors.push(e.message));
  page.on("console", (m) => page._console.push(`${m.type()}: ${m.text()}`));
  return { ctx, page };
}
const ds = (p) => p.evaluate(() => ({ ...document.documentElement.dataset }));

// 1. Reading mode toggles, restores and persists, on every site (fresh profile each).
for (const [name, url] of [["portal", ORG + "/"], ["AstroLog", LOG + "/"], ["lab", LAB + "/"], ["dApp", DAPP + "/"]]) {
  const { ctx, page } = await fresh();
  await page.goto(url, { waitUntil: "networkidle" });
  await page.waitForTimeout(900);
  await page.keyboard.press("Escape");
  await page.waitForTimeout(250);
  const before = await ds(page);
  await page.click("[data-arr-reading-toggle]");
  await page.waitForTimeout(250);
  const on = await ds(page);
  ok(`${name}: reading mode on = stone/still/more/cursor off`, on.reading === "on" && on.light === "stone" && on.motion === "still" && on.contrast === "more" && on.cursor === "off", JSON.stringify({ light: on.light, motion: on.motion, contrast: on.contrast, cursor: on.cursor }));
  await page.reload({ waitUntil: "networkidle" });
  await page.waitForTimeout(600);
  const after = await ds(page);
  ok(`${name}: reading mode persists across a reload`, after.reading === "on" && (await page.getAttribute("[data-arr-reading-toggle]", "aria-pressed")) === "true");
  await page.click("[data-arr-reading-toggle]");
  await page.waitForTimeout(250);
  const off = await ds(page);
  ok(`${name}: second tap restores the previous choices`, off.reading === "off" && off.light === before.light && off.motion === before.motion && off.contrast === before.contrast, `${before.light}/${before.motion} -> ${off.light}/${off.motion}`);
  if (name === "dApp") await page.screenshot({ path: `${SHOTS}/dapp-kit.png` });
  ok(`${name}: no page errors`, page._errors.length === 0, page._errors.join(" | ").slice(0, 200));
  await ctx.close();
}

// 2. What's new: a genuine first visit in the past (fake clock), then a return visit now.
for (const [name, url] of [["AstroLog", LOG + "/"], ["portal", ORG + "/"], ["lab", LAB + "/"]]) {
  const { ctx, page } = await fresh();
  await ctx.clock.install({ time: new Date(Date.now() - 4 * 86400000) });
  await page.goto(url, { waitUntil: "networkidle" });
  await page.waitForTimeout(500);
  await page.keyboard.press("Escape");
  await ctx.clock.runFor(3000);
  const firstHidden = await page.evaluate(() => document.querySelector("[data-arr-news]")?.hidden);
  ok(`${name}: first visit shows no what's-new count`, firstHidden === true);
  await ctx.clock.setSystemTime(new Date());
  await page.reload({ waitUntil: "networkidle" });
  await ctx.clock.runFor(3000);
  await page.waitForTimeout(1500);
  const badge = await page.evaluate(() => {
    const b = document.querySelector("[data-arr-news]");
    return b ? { hidden: b.hidden, n: b.querySelector("[data-arr-news-n]")?.textContent, label: b.getAttribute("aria-label") } : null;
  });
  ok(`${name}: return visit shows the count`, badge && !badge.hidden && +badge.n > 0, badge && badge.label);
  const marked = await page.evaluate(() => document.querySelectorAll("[data-arr-new]").length);
  ok(`${name}: new items marked on the page`, marked > 0, `${marked} marked`);
  await page.screenshot({ path: `${SHOTS}/${name}-news.png` });
  if (!badge || badge.hidden) { await ctx.close(); continue; }
  await page.click("[data-arr-news]");
  await page.waitForTimeout(500);
  const group = await page.evaluate(() => document.querySelector(".arr-pal-group")?.textContent || "");
  ok(`${name}: the count opens "New since your last visit"`, /New since your last visit/.test(group), group);
  await page.screenshot({ path: `${SHOTS}/${name}-news-open.png` });
  await page.keyboard.press("Escape");
  await page.waitForTimeout(300);
  ok(`${name}: the count clears once seen`, await page.evaluate(() => document.querySelector("[data-arr-news]").hidden));
  await page.reload({ waitUntil: "networkidle" });
  await page.waitForTimeout(1500);
  ok(`${name}: and stays cleared for this visit`, await page.evaluate(() => document.querySelector("[data-arr-news]").hidden));
  await ctx.close();
}

// 3. The ledgers: real public commits only.
const publicRepos = new Map();
async function isPublic(owner, repo) {
  const key = `${owner}/${repo}`;
  if (!publicRepos.has(key)) {
    const r = await fetch(`https://api.github.com/repos/${key}`, { headers: { "User-Agent": "verify" } });
    publicRepos.set(key, r.ok && (await r.json()).private === false);
  }
  return publicRepos.get(key);
}
for (const [name, url, owner] of [["ORG ledger", LOG + "/ledger", "Octagon-Religious-Research-Group-ORG"], ["lab ledger", LAB + "/ledger/", "drasticstatic"]]) {
  const { ctx, page } = await fresh();
  const r = await page.goto(url, { waitUntil: "networkidle" });
  await page.keyboard.press("Escape");
  ok(`${name}: loads`, r.status() === 200, r.status());
  const rows = await page.$$eval("[data-lg-item] a.lg-text", (as) => as.map((a) => ({ h: a.href, t: a.textContent.trim() })));
  ok(`${name}: renders commits`, rows.length > 0, `${rows.length} rows`);
  const repos = [...new Set(rows.map((x) => new URL(x.h).pathname.split("/")[2]))];
  const priv = repos.filter((x) => PRIVATE.includes(x));
  ok(`${name}: no private repositories`, priv.length === 0, `repos: ${repos.join(", ")}`);
  let allPublic = true;
  for (const repo of repos) if (!(await isPublic(owner, repo))) allPublic = false;
  ok(`${name}: every linked repository is public on GitHub`, allPublic);
  const sample = rows[0].h;
  const commit = await fetch(sample.replace("https://github.com/", "https://api.github.com/repos/").replace("/commit/", "/commits/"), { headers: { "User-Agent": "verify" } });
  ok(`${name}: the newest row is a real commit`, commit.ok, sample);
  const noise = rows.filter((x) => /^(Merge |Deploy Astro build|Deploy: |sync: rebuild)/i.test(x.t));
  ok(`${name}: merges and mirror pushes filtered`, noise.length === 0);
  // filters work
  await page.click('[data-lg-kind="look"]').catch(() => {});
  await page.waitForTimeout(200);
  const shown = await page.$$eval("[data-lg-item]:not([hidden])", (els) => els.length);
  ok(`${name}: kind filter narrows the list`, shown > 0 && shown < rows.length, `${shown}/${rows.length}`);
  await page.screenshot({ path: `${SHOTS}/${name.replace(" ", "-")}.png` });
  await ctx.close();
}

// 4. The dApp: the kit, the lab link, no allowlist error, no three-directions showcase.
{
  const { ctx, page } = await fresh();
  await page.goto(bust(DAPP + "/"), { waitUntil: "networkidle" });
  await page.waitForTimeout(4000);
  ok("dApp: kit splash on a first visit", await page.evaluate(() => !!document.querySelector("dialog.arr-splash[open]")));
  await page.keyboard.press("Escape");
  await page.waitForTimeout(300);
  ok("dApp: kit controls in the header", await page.evaluate(() => !!document.querySelector("header arrival-controls .arr-controls [data-arr-reading-toggle]")));
  const lab = await page.evaluate(() => [...document.querySelectorAll("header a")].find((a) => /Lab changelog/.test(a.textContent))?.href);
  ok("dApp: visible link to the lab changelog", lab === "https://drasticstatic.github.io/O-R-G-astro-public/changelog/", lab);
  ok("dApp: three-directions showcase removed", await page.evaluate(() => !/Renan's three directions|three directions, living together/i.test(document.querySelector("main").innerText)));
  await page.keyboard.press("/");
  await page.waitForTimeout(800);
  ok("dApp: / opens search", await page.evaluate(() => !!document.querySelector("dialog.arr-palette[open]")));
  await page.keyboard.press("Escape");
  const allow = page._console.filter((l) => /Allowlist|not found on Allowlist/i.test(l));
  const reown = page._console.filter((l) => /Reown Config|403/i.test(l));
  ok("dApp: no WalletConnect allowlist error in the console", allow.length === 0, allow.join(" | ").slice(0, 200));
  ok("dApp: Reown remote config loads (no 403)", reown.length === 0, reown.join(" | ").slice(0, 200));
  ok("dApp: no page errors", page._errors.length === 0, page._errors.join(" | ").slice(0, 200));
  fs.writeFileSync(`${SHOTS}/dapp-console.txt`, page._console.join("\n"));
  await ctx.close();
}

// 5. og tags complete on every page type, and each card is a real JPEG.
const OG = [
  ORG + "/", LOG + "/", LOG + "/ledger", LOG + "/three-directions", LOG + "/changelog/github/2026-10-12-the-ledger-every-public-change",
  LOG + "/changelog/previews/2026-10-12-three-directions-kept-as-history", LAB + "/", LAB + "/ledger/", DAPP + "/",
];
const need = ["og:site_name", "og:type", "og:url", "og:title", "og:description", "og:image", "og:image:type", "og:image:width", "og:image:height", "og:image:alt", "twitter:card", "twitter:title", "twitter:description", "twitter:image", "twitter:image:alt"];
for (const u of OG) {
  const html = await (await fetch(bust(u))).text();
  const got = (k) => new RegExp(`<meta[^>]+(property|name)="${k.replace(/:/g, ":")}"[^>]+content="([^"]+)"`).exec(html)?.[2];
  const missing = need.filter((k) => !got(k));
  const canonical = /<link[^>]+rel="canonical"[^>]+href="([^"]+)"/.exec(html)?.[1];
  const img = got("og:image");
  const ir = img ? await fetch(img) : null;
  ok(`og: ${u.replace(/^https:\/\//, "")}`, !missing.length && !!canonical && ir?.ok && /image\/jpeg/.test(ir.headers.get("content-type")), missing.length ? "missing " + missing.join(",") : `${img.split("/").slice(-2).join("/")} ${ir?.status}`);
}

// 6. Cross-links resolve: every link between ORG's sites, the lab, the dApp and the profile.
const SITES = [ORG + "/", LOG + "/", LOG + "/ledger", LOG + "/three-directions", LAB + "/", LAB + "/ledger/", DAPP + "/"];
const targets = new Set();
for (const u of SITES) {
  const { ctx, page } = await fresh();
  await page.goto(u, { waitUntil: "networkidle" });
  const links = await page.$$eval("a[href]", (as) => as.map((a) => (typeof a.href === "string" ? a.href : new URL(a.getAttribute("href"), location.href).href)));
  for (const h of links) {
    const x = h.split("#")[0];
    if (/octagon-religious-research-group-org\.github\.io|drasticstatic\.github\.io\/O-R-G|orgspirituality\.org|github\.com\/Octagon-Religious|t\.me\//.test(x) && !/\/commit\//.test(x)) targets.add(x);
  }
  await ctx.close();
}
const profile = await (await fetch("https://raw.githubusercontent.com/Octagon-Religious-Research-Group-ORG/.github/main/profile/README.md")).text();
for (const m of profile.matchAll(/https:\/\/(octagon-religious-research-group-org\.github\.io|drasticstatic\.github\.io)[^\s)"<]*/g)) targets.add(m[0].split("#")[0]);
const bad = [];
for (const t of targets) {
  let r = await fetch(t, { method: "GET", redirect: "follow" }).catch(() => null);
  if (!r || r.status >= 400) bad.push(`${r ? r.status : "ERR"} ${t}`);
}
ok(`cross-links resolve (${targets.size} distinct links across ${SITES.length} pages + the profile)`, bad.length === 0, bad.join(" | "));
ok("profile README: no Sidecar badge, links lab/dApp/ledger/map/portal/AstroLog/site", !/sidecar/i.test(profile) && ["O-R-G-astro-public", "O-R-G-dapp-public-preview", "/ledger", "/map", "changelog-astro-public/", "octagon-religious-research-group-org.github.io/", "orgspirituality.org"].every((s) => profile.includes(s)));

await browser.close();
fs.writeFileSync(`${SHOTS}/results.txt`, results.join("\n") + "\n");
const fails = results.filter((r) => r.startsWith("FAIL"));
console.log(`\n${results.length - fails.length}/${results.length} passed`);
