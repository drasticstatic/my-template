// Verification for arrival kit v1.4 (2026-10-22), live or pre-deploy. Run from a folder with
// playwright-core and viem installed (viem signs the in-memory test pledge):
//   npm i playwright-core viem && node verify-v14.example.mjs [psanctuary thef org psanctuarychurch …]
//   --local <id>=<path to the portal repo>   serve that portal's files over its live origin (pre-deploy;
//                                             anything missing falls through to the live site)
//   --deep <id>                              which org gets the full feature checks (default psanctuary)
// Uses local Chrome (channel "chrome") and a fresh browser context per check.
//
// Every org (no org.js changes needed):
//   1. Donate and the welcome guide are in the footer, the More dropdown (1440px) and the Menu (390px),
//      on the portal and the AstroLog porch.
//   2. One header row from 320 to 1920px, no horizontal scroll, no page errors, no red console.
// The deep org also gets v1.4's configured features, switched on for the test by wrapping
// window.ARRIVAL as org.js sets it (nothing is written to the site):
//   3. The footer ignores hostile host CSS (section padding, `footer a { display: block }`, list
//      bullets) and balances its columns (never one orphan group on a row).
//   4. The dock at 320px: a fade and a right chevron; the chevron scrolls it, a left one appears,
//      focus survives the end; reduced motion scrolls instantly; it shows in every light, more
//      contrast and reading mode.
//   5. A grouped dropdown ("Foyers": Committees, then Infrastructure) renders with headings and a
//      divider, opens with ArrowDown, and keeps its headings in the Menu.
//   6. /donate/ shows "Receipts and taxes" with the claim-nothing defaults (no status row).
//   7. The pledge: drawn at first paint, pledge.js lazy, nothing third-party before a click; Connect
//      opens Reown AppKit; the verify tool accepts a signature made in memory (a random key that is
//      never written down) and rejects a tampered message and a malformed address; no counts and no
//      address text on the page.
//   8. Signing with a stand-in browser wallet (the same in-memory key, wallet connect off for the
//      test): connected, signed, "checked" in the tab, "Copy my signed pledge" offered, and still no
//      address text on the page.
import { chromium } from "playwright-core";
import { generatePrivateKey, privateKeyToAccount } from "viem/accounts";
import fs from "node:fs";
import path from "node:path";

const SITES = {
  psanctuary: { root: "https://psanctuary.github.io", key: "psanctuary-arrival" },
  psanctuarychurch: { root: "https://psanctuarychurch.github.io", key: "psanctuarychurch-arrival" },
  thef: { root: "https://theholyearthfoundation.github.io", key: "thef-arrival" },
  org: { root: "https://octagon-religious-research-group-org.github.io", key: "org-experience" },
};
const WIDTHS = [320, 360, 390, 480, 768, 1024, 1099, 1100, 1280, 1440, 1920];
const ADDR = /\b0x[0-9a-fA-F]{20,}|\bbc1[0-9a-z]{20,}|\b[13][a-km-zA-HJ-NP-Z1-9]{25,34}\b/;
const COUNT = /\b\d[\d,]*\s+(pledges?|signatures?|supporters?|people have|signers?)\b/i;
const THIRD = (u) => /appkit-cdn|walletconnect|web3modal|reown|@noble/.test(u);
const SHOTS = "shots-v14";
fs.mkdirSync(SHOTS, { recursive: true });

const args = process.argv.slice(2);
const LOCAL = {};
let DEEP = "psanctuary";
for (let i = 0; i < args.length; i++) {
  if (args[i] === "--local") { const [id, p] = args[++i].split("="); LOCAL[id] = p; }
  else if (args[i] === "--deep") DEEP = args[++i];
}
const ids = args.filter((a, i) => !a.startsWith("--") && !["--local", "--deep"].includes(args[i - 1]));
const types = { ".html": "text/html", ".js": "text/javascript", ".css": "text/css", ".json": "application/json", ".svg": "image/svg+xml", ".png": "image/png", ".jpg": "image/jpeg" };

const results = [];
const ok = (name, cond, extra = "") => {
  results.push(`${cond ? "PASS" : "FAIL"}  ${name}${extra && !cond ? "  (" + extra + ")" : ""}`);
  console.log(results[results.length - 1]);
};
const bust = (u) => u + (u.includes("?") ? "&" : "?") + "v=" + Date.now();
async function go(page, url) {
  await page.goto(bust(url), { waitUntil: "load", timeout: 90000 });
  await page.waitForLoadState("networkidle", { timeout: 12000 }).catch(() => {});
}
// Wraps window.ARRIVAL as org.js assigns it, merging the test's config (JSON only).
function patcher(patch) {
  let A;
  Object.defineProperty(window, "ARRIVAL", {
    configurable: true,
    get() { return A; },
    set(v) {
      A = v;
      if (!v || !patch) return;
      for (const k in patch) {
        if (k === "navAdd") { v.nav = v.nav || { items: [] }; v.nav.items = v.nav.items.concat(patch.navAdd); }
        else if (k === "donateTax") v.donate = Object.assign({}, v.donate, { tax: patch.donateTax });
        else v[k] = patch[k];
      }
    },
  });
}

const browser = await chromium.launch({ channel: "chrome" });
async function fresh(id, { width = 1280, patch = null, reduced = false } = {}) {
  const S = SITES[id];
  const ctx = await browser.newContext({ viewport: { width, height: 860 }, reducedMotion: reduced ? "reduce" : "no-preference" });
  await ctx.addInitScript((k) => { try { if (!localStorage.getItem(k)) localStorage.setItem(k, JSON.stringify({ chosen: true })); } catch (e) {} }, S.key);
  if (patch) await ctx.addInitScript(patcher, patch);
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
const clean = (page) => !page._errors.length && !page._console.length;
const noise = (page) => [...page._errors, ...page._console].join(" | ");
// Visible link labels inside an element.
const labels = (page, sel) => page.evaluate((s) => [...document.querySelectorAll(s + " a")].filter((a) => a.getClientRects().length).map((a) => (a.querySelector(".arr-nav-label") || a).textContent.trim()), sel);

for (const id of ids.length ? ids : Object.keys(SITES)) {
  const S = SITES[id];
  const LOG = S.root + "/changelog-astro-public";
  console.log(`\n=== ${id}${LOCAL[id] ? " (local files)" : ""} ===`);

  // 1. Essentials everywhere.
  for (const [name, url] of [["portal", S.root + "/"], ["porch", LOG + "/"]]) {
    const { ctx, page } = await fresh(id, { width: 1440 });
    await go(page, url);
    await page.waitForTimeout(600);
    const kit = await page.evaluate(() => window.Arrival && window.Arrival.version);
    const foot = await labels(page, "arrival-footer");
    await page.click("[data-arr-nav-more] [data-arr-nav-toggle]");
    await page.waitForTimeout(200);
    const more = await labels(page, ".arr-nav-more");
    await page.keyboard.press("Escape");
    await page.setViewportSize({ width: 390, height: 860 });
    await page.waitForTimeout(400);
    await page.click("[data-arr-menu]");
    await page.waitForTimeout(200);
    const menu = await labels(page, ".arr-menu-panel");
    const has = (list) => list.includes("Donate") && list.some((x) => /welcome guide/i.test(x));
    ok(`${id} ${name}: kit ${kit}; Donate + Welcome guide in the footer, More and the Menu`, kit === "1.4.0" && has(foot) && has(more) && has(menu), JSON.stringify({ kit, foot: has(foot), more, menu: has(menu) }));
    ok(`${id} ${name}: no page errors, no red console`, clean(page), noise(page));
    await ctx.close();
  }

  // 2. One header row at every width.
  for (const [name, url] of [["portal", S.root + "/"], ["donate", S.root + "/donate/"], ["porch", LOG + "/"]]) {
    const bad = [];
    for (const w of WIDTHS) {
      const { ctx, page } = await fresh(id, { width: w });
      await go(page, url);
      await page.waitForTimeout(350);
      const r = await page.evaluate(() => {
        const h = document.querySelector("header");
        const boxes = [...h.children].filter((c) => c.getClientRects().length && getComputedStyle(c).position !== "absolute").map((c) => c.getBoundingClientRect());
        const bar = document.querySelector(".arr-nav-bar");
        return {
          h: Math.round(h.getBoundingClientRect().height),
          rows: Math.max(...boxes.map((b) => b.top)) < Math.min(...boxes.map((b) => b.bottom)) ? 1 : 2,
          hs: document.documentElement.scrollWidth > document.documentElement.clientWidth,
          over: bar ? bar.scrollWidth > bar.clientWidth + 1 && document.querySelector("arrival-nav").getAttribute("data-mode") === "bar" : false,
        };
      });
      if (r.h >= 72 || r.rows !== 1 || r.hs || r.over || !clean(page)) bad.push(`${w}px ${JSON.stringify(r)} ${noise(page)}`);
      await ctx.close();
    }
    ok(`${id} ${name}: one header row, no horizontal scroll, no errors (${WIDTHS[0]}–${WIDTHS[WIDTHS.length - 1]}px)`, !bad.length, bad.join(" | "));
  }

  if (id !== DEEP) continue;

  // 3. The footer against hostile host CSS, and balanced columns.
  {
    const { ctx, page } = await fresh(id, { width: 1280 });
    await go(page, S.root + "/");
    const measure = () => page.evaluate(() => {
      const f = document.querySelector("arrival-footer");
      const sec = f.querySelector(".arr-foot-group");
      const a = f.querySelector(".arr-foot-a");
      const ul = f.querySelector(".arr-foot-list");
      return { h: Math.round(f.getBoundingClientRect().height), pad: getComputedStyle(sec).paddingTop, disp: getComputedStyle(a).display, m: getComputedStyle(a).marginTop, ulPad: getComputedStyle(ul).paddingLeft, ls: getComputedStyle(ul).listStyleType };
    });
    const before = await measure();
    await page.addStyleTag({ content: "section{padding:5.5rem 0} footer a, .page-foot a, arrival-footer a{display:block;margin:.25rem 0} ul{margin-left:2rem;padding-left:1.5rem;list-style:disc} li::before{content:'• '} nav{padding:2rem}" });
    await page.waitForTimeout(200);
    const after = await measure();
    ok(`${id}: the footer ignores hostile host CSS (section padding, footer a, list bullets)`, JSON.stringify(before) === JSON.stringify(after) && after.pad === "0px" && after.disp === "inline-flex" && after.m === "0px" && after.ulPad === "0px" && after.ls === "none", JSON.stringify({ before, after }));
    const cols = [];
    for (const w of [1280, 1000, 820, 600, 390]) {
      await page.setViewportSize({ width: w, height: 860 });
      await page.waitForTimeout(250);
      cols.push(await page.evaluate(() => { const g = document.querySelector(".arr-foot-groups"); return [g.children.length, getComputedStyle(g).gridTemplateColumns.split(" ").length]; }));
    }
    // Balanced: the last row is never shorter by more than one, and never a lone group under a fuller row.
    const balanced = cols.every(([n, c]) => { const rows = Math.ceil(n / c); const last = n - (rows - 1) * c; return rows === 1 || c === 1 || last >= c - 1 && !(last === 1 && c > 2); });
    ok(`${id}: footer columns balanced at 1280/1000/820/600/390px`, balanced, JSON.stringify(cols));
    await page.setViewportSize({ width: 1280, height: 860 });
    await page.locator("arrival-footer").screenshot({ path: `${SHOTS}/${id}-footer.png` });
    await ctx.close();
  }

  // 4. The dock at 320px.
  {
    const patch = { dock: { scroll: true } };
    const { ctx, page } = await fresh(id, { width: 320, patch });
    await go(page, S.root + "/");
    await page.waitForTimeout(500);
    const st = () => page.evaluate(() => {
      const s = document.querySelector(".arr-strip");
      const [L, R] = [...document.querySelectorAll("[data-arr-strip]")];
      const vis = (b) => !!b && !b.hidden && b.getBoundingClientRect().width > 0 && b.getBoundingClientRect().right <= innerWidth + 1;
      return { strip: !!s, x: s ? Math.round(s.scrollLeft) : -1, l: vis(L), r: vis(R), mask: s ? getComputedStyle(s).maskImage || getComputedStyle(s).webkitMaskImage : "", focus: document.activeElement && (document.activeElement.getAttribute("data-arr-strip") || document.activeElement.tagName) };
    });
    const a = await st();
    await page.screenshot({ path: `${SHOTS}/${id}-dock-320-start.png`, clip: { x: 0, y: 790, width: 320, height: 70 } });
    await page.click('[data-arr-strip="r"]');
    await page.waitForTimeout(800);
    const b = await st();
    await page.screenshot({ path: `${SHOTS}/${id}-dock-320-scrolled.png`, clip: { x: 0, y: 790, width: 320, height: 70 } });
    ok(`${id} dock @320: a fade and a right chevron; it scrolls, and a left one appears`, a.strip && a.r && !a.l && /gradient/.test(a.mask) && b.x > a.x && b.l, JSON.stringify({ a, b }));
    // Keyboard: Tab reaches a chevron; pressing it at the end hands focus on rather than dropping it.
    await page.focus('[data-arr-strip="r"]').catch(() => {});
    for (let i = 0; i < 8; i++) {
      const s = await st();
      if (!s.r) break;
      await page.focus('[data-arr-strip="r"]');
      await page.keyboard.press("Enter");
      await page.waitForTimeout(700);
    }
    const c = await st();
    ok(`${id} dock @320: keyboard reachable, and at the end the right chevron hides without losing focus`, !c.r && c.l && c.focus !== "BODY", JSON.stringify(c));
    await ctx.close();
    // Reduced motion: an instant scroll.
    const rm = await fresh(id, { width: 320, patch, reduced: true });
    await go(rm.page, S.root + "/");
    await rm.page.waitForTimeout(400);
    const x0 = await rm.page.evaluate(() => document.querySelector(".arr-strip").scrollLeft);
    await rm.page.click('[data-arr-strip="r"]');
    const x1 = await rm.page.evaluate(() => document.querySelector(".arr-strip").scrollLeft);
    ok(`${id} dock @320: reduced motion scrolls instantly (no smooth scroll)`, x1 > x0, `${x0} → ${x1}`);
    await rm.ctx.close();
    // Every mode.
    const modes = [];
    const m = await fresh(id, { width: 320, patch });
    await go(m.page, S.root + "/");
    const lights = await m.page.evaluate(() => (window.ARRIVAL.modes || []).filter((x) => !x.follows).map((x) => x.id));
    for (const set of [...lights.map((l) => ({ light: l })), { contrast: "more" }, { reading: true }]) {
      await m.page.evaluate((s) => (s.reading ? window.Arrival.reading(true) : window.Arrival.set(s)), set);
      await m.page.waitForTimeout(250);
      const r = await m.page.evaluate(() => { const b = document.querySelector('[data-arr-strip="r"]'); const cs = getComputedStyle(b); return !b.hidden && cs.visibility !== "hidden" && +cs.opacity > 0.5 && cs.backgroundColor !== cs.color; });
      modes.push(`${JSON.stringify(set)}:${r}`);
    }
    ok(`${id} dock @320: the chevron shows in every light, more contrast and reading mode`, modes.every((x) => x.endsWith(":true")), modes.join(" "));
    ok(`${id} dock: no page errors`, clean(m.page), noise(m.page));
    await m.ctx.close();
  }

  // 5. A grouped dropdown.
  {
    const patch = {
      navAdd: [{
        id: "foyers", label: "Foyers", icon: "door-open", keep: true, priority: 9,
        groups: [
          { label: "Committees", icon: "users-three", items: [{ id: "v14-a", label: "Committee A", icon: "chats", href: S.root + "/v14-a/" }, { id: "v14-b", label: "Committee B", icon: "chats", href: S.root + "/v14-b/" }] },
          { label: "Infrastructure", icon: "wrench", items: [{ id: "v14-c", label: "Website", icon: "globe", href: S.root + "/v14-c/" }] },
        ],
      }],
    };
    const { ctx, page } = await fresh(id, { width: 1440, patch });
    await go(page, S.root + "/");
    await page.waitForTimeout(400);
    const btn = page.locator('.arr-nav-bar [data-arr-nav-toggle]:has-text("Foyers")');
    await btn.focus();
    await page.keyboard.press("ArrowDown");
    await page.waitForTimeout(200);
    const r = await page.evaluate(() => {
      const p = [...document.querySelectorAll(".arr-nav-menu")].find((x) => !x.hidden && x.querySelector(".arr-nav-grp"));
      if (!p) return null;
      const g = [...p.querySelectorAll(".arr-nav-grp")];
      return {
        heads: g.map((x) => x.querySelector(".arr-nav-grp-h").textContent.trim()),
        labelled: g.every((x) => x.getAttribute("role") === "group" && document.getElementById(x.getAttribute("aria-labelledby"))),
        divider: getComputedStyle(g[1]).borderTopStyle,
        focus: document.activeElement && document.activeElement.textContent.trim(),
      };
    });
    await page.screenshot({ path: `${SHOTS}/${id}-grouped-1440.png`, clip: { x: 0, y: 0, width: 1440, height: 360 } });
    ok(`${id}: a grouped dropdown shows "Committees" then "Infrastructure" with a divider, and opens with ArrowDown`, r && r.heads.join("|") === "Committees|Infrastructure" && r.labelled && r.divider === "solid" && /Committee A/.test(r.focus), JSON.stringify(r));
    await page.keyboard.press("Escape");
    await page.setViewportSize({ width: 390, height: 860 });
    await page.waitForTimeout(400);
    await page.click("[data-arr-menu]");
    await page.waitForTimeout(200);
    const m = await page.evaluate(() => [...document.querySelectorAll(".arr-menu-panel .arr-nav-grp-h")].map((x) => x.textContent.trim()));
    ok(`${id}: the Menu keeps the group headings`, m.join("|") === "Committees|Infrastructure", m.join("|"));
    ok(`${id} grouped dropdown: no page errors`, clean(page), noise(page));
    await ctx.close();
  }

  // 6. Receipts and taxes.
  {
    const { ctx, page } = await fresh(id, { width: 1024, patch: { donateTax: {} } });
    await go(page, S.root + "/donate/");
    const r = await page.evaluate(() => {
      const t = document.querySelector(".arr-tax");
      return t && { h: t.querySelector("h2").textContent.trim(), text: t.innerText, rows: [...t.querySelectorAll("dt")].map((d) => d.textContent.trim()) };
    });
    await page.locator(".arr-tax").screenshot({ path: `${SHOTS}/${id}-tax.png` }).catch(() => {});
    ok(`${id} /donate/: "Receipts and taxes" with the claim-nothing defaults and no status row`, r && r.h === "Receipts and taxes" && /Ask us for a receipt/.test(r.text) && /depends on the organization's status and your own situation/.test(r.text) && /isn't tax advice/.test(r.text) && !r.rows.includes("Status"), JSON.stringify(r));
    ok(`${id} /donate/ with the tax section: no page errors`, clean(page), noise(page));
    await ctx.close();
  }

  // 7. The pledge: lazy, AppKit, the verify tool.
  const acct = privateKeyToAccount(generatePrivateKey()); // in memory only, never written down
  const pledgeText = "I support the people these pages serve.";
  {
    const patch = { pledge: { text: pledgeText, href: S.root + "/pledge/" } };
    const { ctx, page } = await fresh(id, { width: 1024, patch });
    await go(page, S.root + "/donate/");
    await page.evaluate(() => { const el = document.createElement("arrival-pledge"); (document.querySelector("main") || document.body).appendChild(el); });
    const shell = await page.evaluate(() => ({ drawn: !!document.querySelector("arrival-pledge [data-arr-pledge] [data-pledge='connect']"), verify: !!document.querySelector("arrival-pledge form[data-pledge-form='verify']") }));
    await page.locator("arrival-pledge").scrollIntoViewIfNeeded();
    await page.waitForTimeout(1500);
    const lazy = { pledgeJs: page._req.filter((u) => /\/pledge\/pledge\.js/.test(u)).length, third: page._req.filter(THIRD).length, loaded: await page.evaluate(() => !!window.ArrivalPledge) };
    ok(`${id} pledge: drawn at first paint; pledge.js loads lazily; nothing third-party before a click`, shell.drawn && shell.verify && lazy.pledgeJs === 1 && lazy.loaded && lazy.third === 0, JSON.stringify({ shell, lazy }));
    // The verify tool, with a signature made in memory.
    const msg = "Psanctuary: a pledge of support\n\n" + pledgeText + "\n\nSigned on test, 2026-10-22.";
    const sig = await acct.signMessage({ message: msg });
    const check = async (address, message, signature) => {
      await page.fill("arrival-pledge input[name=address]", address);
      await page.fill("arrival-pledge input[name=signature]", signature);
      await page.fill("arrival-pledge textarea[name=message]", message);
      await page.click("arrival-pledge form[data-pledge-form] button[type=submit]");
      await page.waitForFunction(() => { const r = document.querySelector("[data-pledge-result]"); return r && r.getAttribute("data-state") && r.getAttribute("data-state") !== "busy"; }, null, { timeout: 20000 });
      return page.evaluate(() => { const r = document.querySelector("[data-pledge-result]"); return { state: r.getAttribute("data-state"), text: r.textContent }; });
    };
    const good = await check(acct.address, msg, sig);
    const lower = await check(acct.address.toLowerCase(), msg, sig);
    const tampered = await check(acct.address, msg.replace("support", "oppose"), sig);
    const badAddr = await check("0x1234", msg, sig);
    await page.locator("arrival-pledge .arr-pledge-verify").screenshot({ path: `${SHOTS}/${id}-verify.png` });
    ok(`${id} pledge verify tool: a good signature is Valid (any case), a tampered message doesn't match, a malformed address is refused`, good.state === "ok" && lower.state === "ok" && tampered.state === "bad" && badAddr.state === "warn", JSON.stringify({ good, lower, tampered, badAddr }));
    await page.click("arrival-pledge button[type=reset]");
    const body = await page.evaluate(() => document.body.innerText);
    ok(`${id} pledge: no counts and no wallet address text on the page`, !COUNT.test(body) && !ADDR.test(body));
    // Connect: AppKit opens (the origin is on the Reown allowlist).
    await page.click("arrival-pledge [data-pledge='connect']");
    let r = null;
    for (let i = 0; i < 40; i++) {
      await page.waitForTimeout(500);
      r = await page.evaluate(() => {
        const m = document.querySelector("w3m-modal");
        return { appkit: !!(m && m.shadowRoot && m.shadowRoot.querySelector("wui-card, w3m-router") && m.getBoundingClientRect().height > 0), live: document.querySelector("[data-pledge-live]").textContent, panel: document.querySelector("[data-pledge-panel]").textContent.slice(0, 80) };
      });
      if (r.appkit || /isn't switched on/.test(r.panel)) break;
    }
    await page.screenshot({ path: `${SHOTS}/${id}-pledge-appkit.png` });
    ok(`${id} pledge: Connect opens the Reown AppKit window`, r && r.appkit, JSON.stringify(r));
    ok(`${id} pledge: no page errors, no red console`, clean(page), noise(page));
    await page.keyboard.press("Escape");
    await page.locator("arrival-pledge").screenshot({ path: `${SHOTS}/${id}-pledge.png` });
    await ctx.close();
  }

  // 8. Signing, with a stand-in browser wallet (wallet connect off for the test, so the page uses it).
  {
    const patch = { pledge: { text: pledgeText }, give: { enabled: false } };
    const { ctx, page } = await fresh(id, { width: 1024, patch });
    await ctx.exposeBinding("__v14sign", async (_src, hexMsg) => acct.signMessage({ message: { raw: hexMsg } }));
    await ctx.addInitScript((address) => {
      window.ethereum = {
        isMetaMask: false,
        on() {},
        async request({ method, params }) {
          if (method === "eth_requestAccounts" || method === "eth_accounts") return [address];
          if (method === "eth_chainId") return "0x1";
          if (method === "personal_sign") return window.__v14sign(params[0]);
          throw Object.assign(new Error("unsupported " + method), { code: 4200 });
        },
      };
    }, acct.address);
    await go(page, S.root + "/donate/");
    await page.evaluate(() => { const el = document.createElement("arrival-pledge"); (document.querySelector("main") || document.body).appendChild(el); });
    await page.locator("arrival-pledge").scrollIntoViewIfNeeded();
    await page.click("arrival-pledge [data-pledge='connect']");
    await page.waitForFunction(() => !document.querySelector("arrival-pledge [data-pledge='sign']").disabled, null, { timeout: 20000 });
    await page.click("arrival-pledge [data-pledge='sign']");
    await page.waitForFunction(() => /checked/i.test(document.querySelector("[data-pledge-live]").textContent), null, { timeout: 30000 });
    const r = await page.evaluate(() => ({
      done: [...document.querySelectorAll(".arr-pledge-step.is-done")].map((x) => x.getAttribute("data-pledge-step")),
      copy: !!document.querySelector("[data-pledge='copy']"),
      body: document.body.innerText,
    }));
    await page.locator("arrival-pledge [data-arr-pledge]").screenshot({ path: `${SHOTS}/${id}-pledge-signed.png` });
    ok(`${id} pledge: connected through the browser wallet, signed, checked in the tab, copy offered`, r.done.join(",") === "read,connect,sign" && r.copy, JSON.stringify({ done: r.done, copy: r.copy }));
    ok(`${id} pledge after signing: no counts and no wallet address text on the page`, !COUNT.test(r.body) && !ADDR.test(r.body));
    ok(`${id} pledge signing: no page errors, no red console`, clean(page), noise(page));
    await ctx.close();
  }
}

await browser.close();
const fails = results.filter((r) => r.startsWith("FAIL"));
console.log(`\n${results.length - fails.length}/${results.length} passed`);
process.exit(fails.length ? 1 : 0);
