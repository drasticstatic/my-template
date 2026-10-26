#!/usr/bin/env node
// verify-i18n.mjs — does every language pack carry every word the kit draws? (kit v1.5)
//
//   node verify-i18n.mjs            check every pack in i18n/ (exit 1 if anything is missing)
//   node verify-i18n.mjs es         check one pack
//   node verify-i18n.mjs --english  print the English tables (what a new pack translates)
//
// It reads the English words from their marked tables (WORDS and PWORDS in arrival.js, W in
// give/give.js and pledge/pledge.js), runs each pack in a sandbox, and reports per section:
// missing keys, keys the kit doesn't have (typos), {slots} that don't match the English, and
// lists whose length differs. Run it beside arrival.js; it needs no install.
import { readFileSync, readdirSync, existsSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import vm from "node:vm";

const HERE = dirname(fileURLToPath(import.meta.url));
const read = (f) => readFileSync(join(HERE, f), "utf8");

// The object literal between /* <name>:begin */ and /* <name>:end */, evaluated on its own.
function table(file, name) {
  const src = read(file);
  const a = src.indexOf(`/* ${name}:begin */`);
  const b = src.indexOf(`/* ${name}:end */`);
  if (a < 0 || b < 0) throw new Error(`${file}: no ${name} markers`);
  const body = src.slice(a, b);
  const open = body.indexOf("{");
  const close = body.lastIndexOf("}");
  return vm.runInNewContext("(" + body.slice(open, close + 1) + ")", {});
}

const english = {
  words: table("arrival.js", "WORDS"),
  pledge: { ...table("arrival.js", "PWORDS"), ...table("pledge/pledge.js", "WORDS") },
  give: table("give/give.js", "WORDS"),
};

if (process.argv.includes("--english")) {
  console.log(JSON.stringify(english, null, 2));
  process.exit(0);
}

const slots = (s) => (typeof s === "string" ? (s.match(/\{\w+\}/g) || []).sort().join(" ") : "");
const tags = (s) => (typeof s === "string" ? (s.match(/<\/?[a-z]+/g) || []).sort().join(" ") : "");

function check(id) {
  const file = join("i18n", id + ".js");
  const window = {};
  vm.runInNewContext(read(file), { window });
  const pack = (window.ARRIVAL_I18N || {})[id];
  if (!pack) return [`${file}: doesn't set window.ARRIVAL_I18N.${id}`];
  const out = [];
  for (const [section, en] of Object.entries(english)) {
    const tr = pack[section] || {};
    for (const k of Object.keys(en)) {
      if (!(k in tr)) {
        out.push(`${section}.${k}: missing`);
        continue;
      }
      if (Array.isArray(en[k])) {
        if (!Array.isArray(tr[k]) || tr[k].length !== en[k].length) out.push(`${section}.${k}: should be a list of ${en[k].length}`);
        continue;
      }
      if (slots(en[k]) !== slots(tr[k])) out.push(`${section}.${k}: slots ${slots(tr[k]) || "none"}, English has ${slots(en[k]) || "none"}`);
      if (k.endsWith("Html") && tags(en[k]) !== tags(tr[k])) out.push(`${section}.${k}: markup differs from the English`);
    }
    for (const k of Object.keys(tr)) if (!(k in en)) out.push(`${section}.${k}: not a kit word (a typo?)`);
  }
  for (const kind of ["modes", "motions", "sizes"]) if (!pack[kind]) out.push(`${kind}: missing (the kit's default ${kind}, by id)`);
  if (!pack.langNames) out.push("langNames: missing (language names in this language)");
  if (typeof pack.reviewed !== "boolean") out.push("reviewed: set it to false until a native speaker has read it");
  return out;
}

const dir = join(HERE, "i18n");
const want = process.argv.slice(2).filter((a) => !a.startsWith("-"));
const ids = want.length ? want : existsSync(dir) ? readdirSync(dir).filter((f) => f.endsWith(".js")).map((f) => f.slice(0, -3)) : [];
let bad = 0;
const total = Object.values(english).reduce((n, t) => n + Object.keys(t).length, 0);
for (const id of ids) {
  const problems = check(id);
  bad += problems.length;
  console.log(problems.length ? `✗ ${id}: ${problems.length} to fix (of ${total} words)` : `✓ ${id}: all ${total} words, slots and lists match`);
  problems.forEach((p) => console.log("    " + p));
}
if (!ids.length) console.log("No packs found in i18n/.");
process.exit(bad ? 1 : 0);
