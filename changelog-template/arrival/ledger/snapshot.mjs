// Refresh the ledger's committed fallback from the live history.
//   node src/ledger/snapshot.mjs                   (package.json: "ledger:snapshot")
//   node src/ledger/snapshot.mjs path/to/ledger.config.mjs
// The public lane runs without a token on purpose: an unauthenticated request can only ever see
// public data. The private lane (v2) runs only for the repositories the config opts in, and only when
// LEDGER_TOKEN is set (e.g. LEDGER_TOKEN=$(gh auth token) npm run ledger:snapshot); without it the
// previous snapshot's masked rows are kept. Either way the snapshot holds the MASKED form only: raw
// private subjects never reach the ledger object, so they can't reach this file.
import fs from "node:fs";
import path from "node:path";
import { pathToFileURL } from "node:url";
import { buildLedger } from "./ledger.mjs";

const configPath = path.resolve(process.argv[2] ?? "src/data/ledger.config.mjs");
const { LEDGER } = await import(pathToFileURL(configPath).href);
const ledger = await buildLedger({ ...LEDGER, token: "", privateToken: process.env.LEDGER_TOKEN ?? "" });
fs.writeFileSync(LEDGER.snapshot, JSON.stringify(ledger, null, 1) + "\n");
console.log(
  `[ledger] wrote ${ledger.shownPublic} public + ${ledger.shownPrivate} private (masked) commits from ${ledger.repos.length} repositories to ${path.relative(process.cwd(), LEDGER.snapshot)}`
);
