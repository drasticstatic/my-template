// Refresh the ledger's committed fallback from the live public history.
//   node src/ledger/snapshot.mjs                   (package.json: "ledger:snapshot")
//   node src/ledger/snapshot.mjs path/to/ledger.config.mjs
// Runs without a token on purpose: an unauthenticated request can only ever see public data.
import fs from "node:fs";
import path from "node:path";
import { pathToFileURL } from "node:url";
import { buildLedger } from "./ledger.mjs";

const configPath = path.resolve(process.argv[2] ?? "src/data/ledger.config.mjs");
const { LEDGER } = await import(pathToFileURL(configPath).href);
const ledger = await buildLedger({ ...LEDGER, token: "" });
fs.writeFileSync(LEDGER.snapshot, JSON.stringify(ledger, null, 1) + "\n");
console.log(`[ledger] wrote ${ledger.shown} public commits from ${ledger.repos.length} repositories to ${path.relative(process.cwd(), LEDGER.snapshot)}`);
