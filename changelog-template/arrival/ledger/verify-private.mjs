// The ledger's leak check (v2): no raw private subject may reach the public build.
//   LEDGER_TOKEN=$(gh auth token) node src/ledger/verify-private.mjs --build   (build, then check)
//   node src/ledger/verify-private.mjs [--dist dist] [path/to/ledger.config.mjs]  (check only; CI)
// package.json: "ledger:verify": "node src/ledger/verify-private.mjs"
//
// Reads every raw subject of the opted-in private repositories (mask "full"), then searches every
// text file under dist/ (HTML, latest.json and other JSON, JS chunks, CSS, RSS/XML, SVG, a search
// index) and the committed snapshot for each one, in three forms: the raw subject, its plain summary
// and its sentence without the conventional prefix, case-insensitive, after decoding HTML entities and
// JSON escapes. Subjects that are also public (a public copy, or the same words in a public repo)
// and forms shorter than 12 characters are skipped and counted. A form that the site also publishes
// on purpose in its own editorial text (a changelog entry titled like the commit: config
// `verify.publicText`, default ../changelog, ../library, ../teachings, src/content) is allowed on
// other pages but never on the ledger page or in the snapshot, which stay strict. Also checks that
// every private row in the snapshot and in latest.json is masked and unlinked. Exits 1 on any hit,
// naming only the repository and short SHA, never the subject. Without LEDGER_TOKEN it can't read the subjects: it says so and checks the
// snapshot's structure only (and the build had no private subjects to leak either).
import fs from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { pathToFileURL } from "node:url";
import { privateList, privateSubjects, publicSubjects, summarize, BLOCK } from "./ledger.mjs";

const args = process.argv.slice(2);
const flag = (name) => args.includes(name);
const opt = (name, dflt) => (args.includes(name) ? args[args.indexOf(name) + 1] : dflt);
const positional = args.filter((a, i) => !a.startsWith("--") && args[i - 1] !== "--dist");
const configPath = path.resolve(positional[0] ?? "src/data/ledger.config.mjs");
const DIST = path.resolve(opt("--dist", "dist"));
const MIN = 12;
const { LEDGER } = await import(pathToFileURL(configPath).href);
const fail = (msg) => {
  console.error(`[leak-check] FAIL: ${msg}`);
  process.exit(1);
};

if (flag("--build")) {
  const b = spawnSync("npm", ["run", "build"], { stdio: "inherit", env: process.env });
  if (b.status !== 0) fail("the build failed");
}
const priv = privateList(LEDGER);
if (!priv.length) {
  console.log("[leak-check] no private repositories are opted in; nothing to check");
  process.exit(0);
}
if (!fs.existsSync(DIST)) fail(`no build at ${DIST} (run with --build, or build first)`);

// 1. The snapshot's private rows are masked and unlinked.
const MASKED = new RegExp(`^[${BLOCK} ]+$`);
let snapshot = null;
try {
  snapshot = JSON.parse(fs.readFileSync(LEDGER.snapshot, "utf8"));
} catch {}
const fullMask = new Set(priv.filter((p) => p.mask === "full").map((p) => p.repo));
for (const it of snapshot?.items ?? []) {
  if (!it.private) continue;
  if (it.url || it.sha) fail(`snapshot: a private row links out (${it.repo}@${it.short})`);
  if (fullMask.has(it.repo) && (!MASKED.test(it.text ?? "") || it.area)) fail(`snapshot: a private row isn't masked (${it.repo}@${it.short})`);
}

// latest.json's private rows too.
const latestPath = path.join(DIST, "latest.json");
if (fs.existsSync(latestPath)) {
  const latest = JSON.parse(fs.readFileSync(latestPath, "utf8"));
  for (const it of latest.items ?? []) {
    if (it.type !== "ledger" || !/ · private$/.test(it.k ?? "")) continue;
    const repo = priv.find((p) => it.k.includes(` · ${p.label ?? p.repo} · `));
    if (!MASKED.test(it.t ?? "") && repo?.mask !== "sanitized") fail("latest.json: a private row isn't masked");
    if (/github\.com/.test(it.h ?? "")) fail("latest.json: a private row links to GitHub");
  }
}

// 2. Every raw private subject, searched for everywhere.
const token = process.env.LEDGER_TOKEN ?? "";
if (!token) {
  console.warn("[leak-check] LEDGER_TOKEN isn't set, so the private subjects can't be read: checked the snapshot's masking only");
  process.exit(0);
}
const norm = (s) =>
  String(s)
    .replace(/\\u([0-9a-fA-F]{4})/g, (m, h) => String.fromCharCode(parseInt(h, 16)))
    .replace(/\\(["'\\/])/g, "$1")
    .replace(/\\[nrt]/g, " ")
    .replace(/&#x([0-9a-f]+);/gi, (m, h) => String.fromCodePoint(parseInt(h, 16)))
    .replace(/&#(\d+);/g, (m, d) => String.fromCodePoint(+d))
    .replace(/&quot;/g, '"')
    .replace(/&apos;/g, "'")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&nbsp;/g, " ")
    .replace(/&amp;/g, "&")
    .toLowerCase()
    .replace(/\s+/g, " ")
    .trim();
const forms = (subject) => {
  const s = summarize(subject);
  return [subject, s.said ? s.text : "", s.core].map(norm).filter(Boolean);
};

const pubToken = process.env.GITHUB_TOKEN ?? process.env.GH_TOKEN ?? token;
const publicForms = new Set((await publicSubjects({ ...LEDGER, token: pubToken })).flatMap(forms));
const subjects = await privateSubjects(LEDGER, [token, process.env.GITHUB_TOKEN]);
const unreadable = subjects.filter((s) => s.error);
for (const u of unreadable) console.warn(`[leak-check] couldn't read ${u.repo} (${u.error}); its rows came masked from the snapshot`);

// The site's own editorial text (what it publishes on purpose, e.g. changelog entries).
const EDITORIAL = /\.(md|mdx|markdown|json|ya?ml|ts|mjs|js|astro|txt)$/i;
let editorial = "";
const readAll = (p) => {
  const st = fs.statSync(p);
  if (st.isDirectory()) for (const e of fs.readdirSync(p)) readAll(path.join(p, e));
  else if (EDITORIAL.test(p)) editorial += norm(fs.readFileSync(p, "utf8")) + "\n";
};
for (const p of (LEDGER.verify?.publicText ?? ["../changelog", "../library", "../teachings", "src/content"]).map((x) => path.resolve(x))) if (fs.existsSync(p)) readAll(p);

const needles = [];
let skipped = 0;
for (const s of subjects.filter((x) => !x.error)) {
  for (const f of new Set(forms(s.subject))) {
    if (f.length < MIN || publicForms.has(f)) skipped++;
    else needles.push({ f, repo: s.repo, short: s.short, editorial: editorial.includes(f) });
  }
}

const TEXT = /\.(html?|json|js|mjs|cjs|css|xml|rss|atom|txt|svg|webmanifest|map|md)$/i;
const files = [];
const walk = (dir) => {
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) walk(p);
    else if (TEXT.test(e.name)) files.push(p);
  }
};
walk(DIST);
if (fs.existsSync(LEDGER.snapshot)) files.push(LEDGER.snapshot);

const hits = [];
const strictFile = (file) => file === LEDGER.snapshot || /^ledger(\/index)?\.html$/.test(path.relative(DIST, file).split(path.sep).join("/"));
for (const file of files) {
  const hay = norm(fs.readFileSync(file, "utf8"));
  const strict = strictFile(file);
  for (const n of needles) if ((strict || !n.editorial) && hay.includes(n.f)) hits.push(`${n.repo}@${n.short} in ${path.relative(process.cwd(), file)}`);
}
const editorialForms = needles.filter((n) => n.editorial).length;
const readable = subjects.filter((s) => !s.error).length;
if (hits.length) {
  console.error(`[leak-check] ${hits.length} raw private ${hits.length === 1 ? "subject" : "subjects"} found in the build:`);
  for (const h of [...new Set(hits)]) console.error(`  ${h}`);
  fail("raw private text reached the public build");
}
console.log(
  `[leak-check] OK: ${readable} private subjects from ${priv.length - new Set(unreadable.map((u) => u.repo)).size}/${priv.length} repositories, ${needles.length} forms searched (${skipped} skipped: shorter than ${MIN} characters or also public${editorialForms ? `; ${editorialForms} also in the site's own changelog text, so checked strictly on the ledger page and snapshot only` : ""}) across ${files.length} files; no raw private text found`
);
