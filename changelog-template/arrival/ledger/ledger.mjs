// Arrival kit · the ledger (v2): an owner's GitHub commit history as a calm, plain-language record.
// Every PUBLIC change in plain words, linked to the change itself; and, for the private repositories a
// site opts in by name, the work "behind the curtain": repository, day, kind and priority, with the
// description MASKED (████ ██ ███████). Canonical copy: drasticstatic/my-template
// changelog-template/arrival/ledger/ledger.mjs. Copy it unchanged; tailor it through the site's
// ledger.config.mjs (see ledger.config.example.mjs).
//
// Build time only (an Astro page or endpoint calls loadLedger(config)); nothing runs in the browser
// except the page's small filter script. Dependency-free: Node 22's fetch.
//
// What it does, in order:
//   1. PUBLIC lane. Lists the owner's repositories and keeps only PUBLIC ones (private === false AND
//      visibility === "public"), then the config's include/deny, and never one named in `private`.
//      Reads each one's default-branch commits (paginated, up to maxPerRepo).
//   2. PRIVATE lane (v2). Only the repositories named in config.private, and only with a token
//      (config.privateToken or LEDGER_TOKEN). An unlisted private repository is never requested.
//      From each commit it keeps the SHA, dates, author, subject line and co-author trailer lines;
//      the rest of the message is dropped on arrival, and diffs or files are never asked for.
//   3. Drops private commits that already appear through a public copy (allowlist-synced `-public`
//      repositories carry rewritten copies of the same commits: same author date, same subject).
//   4. Filters noise in both lanes: merges, CI mirror/sync commits, bot authors, dependency bumps and
//      revert pairs. Every filtered commit is counted, so the page can say what it left out.
//   5. Reads each subject's priority tag ([P1]/[P2]/[P3], or 🚨 🔥 ⚡ 🍃 first) and sorts it into a kind
//      (conventional prefix, else a small keyword rubric). Public subjects become a plain summary
//      (scrubbed of secret-shaped text). A private subject is classified and then DISCARDED: the item
//      carries only a shape of blocks, so no page, JSON, image or snapshot can ever contain it.
//   6. Credits each commit through the site's people list; names follow config.nameStyle (default
//      "first-last-initial": Christopher W.) and link to the person's GitHub profile. AI co-authors
//      from Co-Authored-By trailers become an agent row ("with Alfred · Claude Code"); emails never
//      appear. Then groups everything by month, day and repository.
//   7. On a total failure (offline, rate limit) it falls back to the committed snapshot, which holds
//      only the masked form; if just the private lane is unavailable (no token, no access), that
//      repository's masked rows are carried over from the snapshot instead.
//
// The technique (public repos only, deny list, a regex rubric, scrubbed subjects, grouped accordion)
// follows Christopher's activity-ledger generator; the private lane follows his privateWitness design
// (explicit opt-in, metadata only, dedupe against public copies, classify then discard).
import fs from "node:fs";

export const LEDGER_VERSION = 2;

// The kinds a change can be, checked in this order. `types` are conventional-commit prefixes that
// decide it outright; `words` are matched against the subject. A site may pass its own list.
// v2: "allowlist sync" (the CI public lane) is behind the scenes; only an allowlist OF PEOPLE
// (allowlisted emails, a member allowlist) still counts as sign-in.
export const DEFAULT_KINDS = [
  { id: "speed", name: "Speed", icon: "lightning", types: ["perf"], words: /\b(faster|speed(s|ed)? up|performance|optimi[sz]\w*|cach(e|es|ing)|webp|lazy[- ]load\w*)\b/i },
  { id: "fix", name: "Fixes", icon: "wrench", types: ["fix", "hotfix", "bugfix"], words: /\b(fix(e[sd])?|bug|broken|repair\w*|stabili[sz]\w*|resolve[sd]?|typo|grammar|correct(ion|ions|ed)?|keep .* together)\b/i },
  { id: "access", name: "Sign-in and members", icon: "key", types: ["auth"], words: /\b(auth0?|clerk|oauth|sign[- ]?in|log[- ]?in|login|members?|membership|admin\w*|accounts?|(e-?mail|member|user|sign[- ]?in) allowlists?|allowlisted (e-?mails?|members?|users?|accounts?|addresses))\b/i },
  { id: "look", name: "Look and feel", icon: "palette", types: ["style", "ui", "design"], words: /\b(style[sd]?|styling|restyle\w*|ui|design\w*|colou?rs?|accents?|fonts?|typography|layout|padding|align\w*|markers?|perforat\w*|icons?|images?|art(work)?|animat\w*|spin\w*|shadows?|themes?|lights?|look|logo|banners?|badges?|tabs?|octagon|tiles?|marble|cursor|trail|ink|visual\w*)\b/i },
  { id: "words", name: "Words and pages", icon: "article", types: ["content", "copy"], words: /\b(wording|words|about( us)?|charter|ceremony|reference pages?|page content|beliefs?|faq|inclusive|labels?)\b/i },
  { id: "records", name: "Records and docs", icon: "notebook", types: ["docs", "doc"], words: /\b(docs?|documentation|document (the|how|backend|frontend)\b|readme|changelog|astrolog|notes?|license|ledger|link[- ]previews?|social cards?|og|map)\b/i },
  { id: "under", name: "Behind the scenes", icon: "gear-six", types: ["refactor", "chore", "test", "tests", "build", "ci", "revert"], words: /\b(refactor\w*|chores?|tests?|testing|ci|workflows?|deploy\w*|config\w*|runtime|heroku|netlify|eslint|lint\w*|renam\w*|clean\s?up|dependenc\w*|hooks?|tooling|route tree|dead code|extract\w*|decompos\w*|isolat\w*|ignore|allowlist\w*|filter-repo|public[- ](lanes?|mirrors?|cop(y|ies))|mirror(s|ed|ing)?|sync(s|ed|ing)? (to|from|with|into) \S*-public(-preview)?)\b/i },
  { id: "new", name: "New", icon: "sparkle", types: ["feat", "feature", "add"], words: /\b(add(s|ed)?|new|introduc\w*|launch\w*|creat\w*|build|builds|built|begin|begins|start\w*|first commit|initiali[sz]\w*|scaffold\w*|give[sn]?)\b/i },
];
export const DEFAULT_KIND = { id: "update", name: "Updates", icon: "arrows-clockwise" };

// Priority, from an optional subject prefix: [P1] / [P2] / [P3] (the changelog frontmatter's
// P1-high / P2-medium / P3-low) or a gitmoji (🚨 critical, 🔥 high, ⚡ medium, 🍃 low). The tag is
// stripped from the summary; an untagged commit has no priority and gets no badge.
export const PRIORITIES = {
  critical: { id: "critical", name: "Critical", icon: "warning-octagon" },
  high: { id: "high", name: "High", icon: "flame" },
  medium: { id: "medium", name: "Medium", icon: "lightning" },
  low: { id: "low", name: "Low", icon: "leaf" },
};
const P_LEVEL = { 1: "high", 2: "medium", 3: "low" };
const P_MARKS = [
  [/^\[\s*p([123])(?:\s*[-:]\s*(?:high|medium|low))?\s*\]\s*/i, (m) => P_LEVEL[m[1]]],
  [/^(?:\u{1F6A8}|:rotating_light:)️?\s*/u, () => "critical"],
  [/^(?:\u{1F525}|:fire:)️?\s*/u, () => "high"],
  [/^(?:⚡|:zap:)️?\s*/u, () => "medium"],
  [/^(?:\u{1F343}|:leaves:)️?\s*/u, () => "low"],
];
export function priorityOf(subject) {
  const s = String(subject || "").trimStart();
  for (const [re, level] of P_MARKS) {
    const m = re.exec(s);
    if (m) return { priority: PRIORITIES[level(m)], rest: s.slice(m[0].length) };
  }
  return { priority: null, rest: s };
}

// Friendly names for conventional-commit scopes. Unknown scopes are title-cased.
const SCOPES = {
  nav: "Navigation", home: "Home page", search: "Search", join: "Joining", about: "About page", community: "Community page",
  content: "Content", links: "Links", layout: "Layout", sections: "Sections", router: "Pages and routing", assets: "Images and icons",
  auth: "Sign-in", api: "API", deps: "Dependencies", ui: "Interface", docs: "Docs", ci: "Automation", i18n: "Languages",
};

// Commits that aren't anyone's work: merges, mirrors, deploy pushes and bots.
const MIRROR = [
  /^sync: rebuild from\b/i,
  /^deploy astro build$/i,
  /^deploy: [0-9a-f]{7,40}$/i,
  /^deploy to (github )?pages\b/i,
  /^(auto(mated)?[: -]+)?(sync|mirror)(ed)? (from|to|public|mirror)\b/i,
  /^\[(skip ci|bot|auto)\]/i,
];
const BOT_NAMES = /(\[bot\]$|^dependabot|^renovate|^github-actions|^actions-user$|^public (mirror|pages) bot$|\bbot$)/i;
const BUMP = [/^(chore|build)\(deps(-dev)?\):/i, /^bump \S+ from \S+ to \S+/i];
const VERB = /^(add|update|fix|remove|change|make|move|use|set|give|let|keep|show|hide|create|build|scaffold|refactor|replace|rename|restyle|redesign|fall|fade|link|draw|serve|initiali[sz]e|start|bump)\b/i;
const UNSAID = /^(wip|idk\d*|update[sd]?|updates?|misc|tmp|temp|changes?|fixes|stuff|test(ing)?|minor|\.+|-+|x+|asdf|save|commit)$/i;

/* ── helpers ──────────────────────────────────────────────────────────────────────────────── */
export function scrub(s) {
  return String(s || "")
    .replace(/https?:\/\/[^\s/@]+:[^\s/@]+@\S+/g, "[link]") // credentials in a URL
    .replace(/[\w.+-]+@[\w-]+\.[\w.-]+/g, "[email]")
    .replace(/\b0x[0-9a-fA-F]{20,}\b/g, "[address]")
    .replace(/\b[0-9a-fA-F]{32,}\b/g, "[redacted]")
    .replace(/\b(gh[pousr]_[A-Za-z0-9]{20,}|sk-[A-Za-z0-9]{20,}|xox[abp]-[A-Za-z0-9-]{10,})\b/g, "[redacted]")
    .replace(/\b[1-9A-HJ-NP-Za-km-z]{36,44}\b/g, "[redacted]")
    .replace(/\b(token|secret|password|passwd|api[_-]?key|private[_ -]?key|seed|mnemonic)\s*[:=]\s*\S+/gi, "[redacted]")
    .replace(/`/g, "'")
    .replace(/\s+/g, " ")
    .trim();
}
// A private subject's stand-in: one block run per word (at most 10 words), each rounded to a width of
// 2, 4, 6 or 8 blocks. It reads like a redacted sentence but can't confirm a guess letter for letter.
export const BLOCK = "█";
export function maskText(s) {
  const words = String(s || "").split(/\s+/).filter(Boolean).slice(0, 10);
  if (!words.length) return BLOCK.repeat(4);
  return words.map((w) => BLOCK.repeat(Math.min(8, Math.max(2, 2 * Math.round([...w].length / 2))))).join(" ");
}
const MASKED = new RegExp(`^[${BLOCK} ]+$`);
const cap = (s) => String(s || "").replace(/^([^A-Za-z]*)([a-z])/, (m, pre, c) => pre + c.toUpperCase());
const titleCase = (s) => String(s).replace(/[-_]+/g, " ").replace(/\b\w/g, (c) => c.toUpperCase());
function trim(s, n = 140) {
  if (s.length <= n) return s;
  const semi = s.indexOf("; ");
  if (semi > 24 && semi < n) return s.slice(0, semi);
  const cut = s.lastIndexOf(" ", n - 1);
  return s.slice(0, cut > 40 ? cut : n - 1).replace(/[,;:.\s]+$/, "") + "…";
}
// "first-last-initial" (the default since v2): "Christopher Wilson" → "Christopher W."; a single
// name or handle stays as it is. "first": "Christopher". "full": as written.
export function nameAs(name, style = "first-last-initial") {
  const parts = String(name || "").trim().split(/\s+/).filter(Boolean);
  if (style === "first-last-initial" && parts.length > 1) return `${parts[0]} ${parts[parts.length - 1].charAt(0).toUpperCase()}.`;
  if (style === "first" && parts.length) return parts[0];
  return parts.join(" ");
}
function dayOf(iso, timeZone) {
  // YYYY-MM-DD in the site's time zone (en-CA formats dates that way).
  return new Intl.DateTimeFormat("en-CA", { timeZone, year: "numeric", month: "2-digit", day: "2-digit" }).format(new Date(iso));
}
function timeOf(iso, timeZone) {
  return new Intl.DateTimeFormat("en-US", { timeZone, hour: "numeric", minute: "2-digit" }).format(new Date(iso));
}
const MONTHS = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
const DAYS = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
function dayLabel(d) {
  const [y, m, dd] = d.split("-").map(Number);
  const wd = DAYS[new Date(Date.UTC(y, m - 1, dd, 12)).getUTCDay()];
  return `${wd}, ${MONTHS[m - 1]} ${dd}`;
}

/* ── one commit → one plain line ──────────────────────────────────────────────────────────── */
export function summarize(subject, kinds = DEFAULT_KINDS, { first = false } = {}) {
  let { priority, rest } = priorityOf(scrub(subject));
  let s = rest.replace(/\s*\(#\d+\)\s*$/, "").replace(/\.$/, "");
  let type = "";
  let area = "";
  const cc = /^([a-z]+)(?:\(([^)]{1,40})\))?(!)?:\s+(.+)$/i.exec(s);
  if (cc && /^(feat|feature|fix|hotfix|bugfix|docs?|style|refactor|perf|test|tests|build|ci|chore|revert|ui|content|copy|design|auth|add)$/i.test(cc[1])) {
    type = cc[1].toLowerCase();
    area = cc[2] ? SCOPES[cc[2].toLowerCase()] || titleCase(cc[2]) : "";
    s = cc[4];
    if (!priority) ({ priority, rest: s } = priorityOf(s)); // "fix(nav): [P2] …"
  } else if (!first) {
    // "Portal: complete the link-preview tags" → area "Portal". Short prefixes only (a first
    // commit's "Scaffold X: …" stays whole).
    const pre = /^([A-Z][\w .&'/-]{1,32}?):\s+(.+)$/.exec(s);
    if (pre && pre[1].split(/\s+/).length <= 3 && !VERB.test(pre[1])) {
      area = pre[1];
      s = pre[2];
    }
  }
  const core = cap(s.trim()); // the whole sentence, before trimming (a private one is masked from this)
  // Long asides in parentheses are for developers; the ledger keeps the sentence.
  if (s.length > 100) s = s.replace(/\s*\([^()]*\)/g, "");
  s = cap(s.trim());
  const letters = s.replace(/[^A-Za-z]/g, "");
  const said = letters.length >= 4 && !UNSAID.test(s.trim());
  const text = said ? trim(s) : "A small change, without a description";
  // A conventional type decides outright, except for features, which are sorted by what they touch
  // (a feature is never "behind the scenes", "docs" or a "fix").
  const feature = /^(feat|feature|add)$/.test(type);
  let kind = null;
  if (type && !feature) kind = kinds.find((k) => k.types?.includes(type)) || null;
  if (!kind) kind = kinds.find((k) => k.words && (!feature || !["under", "records", "fix"].includes(k.id)) && k.words.test(s)) || null;
  if (!kind && type) kind = kinds.find((k) => k.types?.includes(type)) || null;
  return { text, area, type, kind: kind || DEFAULT_KIND, said, priority, core };
}

/* ── AI co-authors → the agent row ────────────────────────────────────────────────────────── */
// From `Co-Authored-By: <name> · <tool> · <vendor> [<model>]` (the fleet's form) or a plain
// `Claude <noreply@anthropic.com>`. Shown as "Alfred · Claude Code". Emails never leave this function.
const AGENTS = [
  [/^alfred$/i, "Alfred"],
  [/^mystarch$/i, "Mystarch"],
  [/^fortuna$/i, "Fortuna"],
  [/^kavanah$/i, "Kavanah"],
  [/^auggie$/i, "Auggie", "Augment"],
  [/^littlebird(\s?ai)?$/i, "Littlebird", "Littlebird"],
  [/^cosmos[- ]?advisor$/i, "Cosmos Advisor", "Cosmos"],
  [/^alex[- ]reindex$/i, "A.L.E.X. reindex", "GitHub Actions"],
  [/^claude\b/i, "Claude", "Claude Code"], // "Claude", "Claude Sonnet 5", "Claude Opus 5 (1M context)"
];
const TOOLS = [
  [/^(claude ?code(cli)?|claudecodecli)$/i, "Claude Code"],
  [/^claude\b/i, "Claude Code"], // "Alfred · Claude · glm-5.2", "Fortuna · Claude Sonnet 5"
  [/^cosmos$/i, "Cosmos"],
  [/littlebird|desktop oracle/i, "Littlebird"],
  [/^github ?actions$/i, "GitHub Actions"],
  [/^(augment|auggie)/i, "Augment"],
  [/^cursor/i, "Cursor"],
  [/^copilot/i, "Copilot"],
  [/^codex/i, "Codex"],
  [/^gemini/i, "Gemini"],
];
const AI_EMAIL = /@(anthropic\.com|openai\.com|cursor\.(sh|com)|augmentcode\.com)\s*$/i;
const AI_WORDS = /\b(claude|chatgpt|gpt-?\d[\w.-]*|copilot|codex|gemini|devin|aider|bot)\b|\[bot\]/i;
const AI_CAPS = /\b(AI|LLM)\b/; // case-sensitive, so a person named "Ai" stays a person
const clean = (s, n = 24) => String(s || "").replace(/[^\p{L}\p{N} .'&+-]/gu, " ").replace(/\s+/g, " ").trim().slice(0, n).trim();
export function trailersOf(message) {
  return [...String(message || "").matchAll(/^co-authored-by:[ \t]*(.+)$/gim)].map((m) => m[1].trim());
}
// `masked`: a private commit. Its trailer lines came from a private message, so only agents the table
// knows are named; anything else is "an AI helper" (free text from a private body is never shown).
export function agentsOf(trailers, { masked = false, extra = [] } = {}) {
  const out = [];
  for (const t of trailers ?? []) {
    const email = (/<([^>]*)>/.exec(t) || [])[1] || "";
    const bare = t.replace(/<[^>]*>/g, " ").replace(/\[[^\]]*\]/g, " ").replace(/\([^)]*\)/g, " ");
    const parts = bare.split(/\s+·\s+|\s+\|\s+/).map((p) => p.trim()).filter(Boolean);
    const head = parts[0] || "";
    const known = [...extra, ...AGENTS].find(([re]) => re.test(head));
    const fleet = parts.length > 1;
    const ai = known || fleet || AI_EMAIL.test(`@${email.split("@")[1] || ""}`) || AI_WORDS.test(bare) || AI_CAPS.test(bare);
    if (!ai) continue; // a person, not an agent: the person row already credits whoever committed
    let name = known ? known[1] : masked ? "An AI helper" : clean(head.replace(/[-_]+/g, " ")) || "An AI helper";
    const toolRaw = parts[1] || "";
    const toolHit = TOOLS.find(([re]) => re.test(toolRaw));
    let tool = toolHit ? toolHit[1] : known?.[2] ?? (masked || !toolRaw ? "" : clean(toolRaw, 20));
    if (known && /^claude$/i.test(known[1])) tool = "Claude Code";
    const label = name === "Claude" && tool === "Claude Code" ? "Claude Code" : tool && tool !== name ? `${name} · ${tool}` : name;
    if (!out.some((a) => a.label === label)) out.push({ name, tool, label });
  }
  // "Claude Code" alone adds nothing when a named agent already ran in Claude Code.
  return out.filter((a) => a.label !== "Claude Code" || !out.some((b) => b !== a && b.tool === "Claude Code"));
}

/* ── GitHub ──────────────────────────────────────────────────────────────────────────────── */
const API = "https://api.github.com";
async function gh(url, token, timeoutMs) {
  const res = await fetch(url, {
    headers: {
      Accept: "application/vnd.github+json",
      "User-Agent": "arrival-ledger",
      "X-GitHub-Api-Version": "2022-11-28",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    signal: AbortSignal.timeout(timeoutMs),
  });
  if (res.status === 409) return { json: [], next: null }; // an empty repository
  if (!res.ok) throw new Error(`GitHub ${res.status} for ${url.replace(/\?.*/, "")}`);
  const next = /<([^>]+)>;\s*rel="next"/.exec(res.headers.get("link") || "");
  return { json: await res.json(), next: next ? next[1] : null };
}
async function pages(url, token, timeoutMs, max) {
  const out = [];
  let u = url;
  while (u && out.length < max) {
    const { json, next } = await gh(u, token, timeoutMs);
    if (!Array.isArray(json)) break;
    out.push(...json);
    u = next;
  }
  return out.slice(0, max);
}
// The opted-in private repositories, normalized: [{ repo, owner, label, blurb, mask }].
// `mask` is "full" (the default: blocks only) or "sanitized" (an explicit opt-in that shows the
// scrubbed summary, still with no link).
export function privateList(cfg) {
  return (cfg.private ?? [])
    .map((p) => (typeof p === "string" ? { repo: p } : p))
    .filter((p) => p && p.repo)
    .map((p) => ({ repo: p.repo, owner: p.owner ?? cfg.owner, label: p.label ?? null, blurb: p.blurb ?? "", mask: p.mask === "sanitized" ? "sanitized" : "full" }));
}
export async function publicRepos(cfg) {
  const list =
    cfg.ownerType === "user"
      ? `${API}/users/${cfg.owner}/repos?type=owner&per_page=100`
      : `${API}/orgs/${cfg.owner}/repos?type=public&per_page=100`;
  const repos = await pages(list, cfg.token, cfg.timeoutMs ?? 10000, 1000);
  const deny = new Set(cfg.deny ?? []);
  const masked = new Set(privateList(cfg).map((p) => p.repo)); // listed as private: always masked, even if it turns public
  return repos
    .filter((r) => r && r.private === false && r.visibility === "public") // public only, always
    .filter((r) => cfg.forks || !r.fork)
    .filter((r) => !deny.has(r.name) && !masked.has(r.name))
    .filter((r) => (cfg.include ? (cfg.include instanceof RegExp ? cfg.include.test(r.name) : cfg.include(r.name)) : true));
}
// One commit, reduced to what the ledger may read: SHA, dates, author, subject line, co-author
// trailer lines. Nothing else of the message is kept.
function reduce(repo, c, isPrivate) {
  const msg = String(c.commit?.message || "");
  return {
    repo,
    private: isPrivate,
    sha: c.sha,
    parents: c.parents?.length ?? 1,
    login: c.author?.login || "",
    authorName: c.commit?.author?.name || "",
    authored: c.commit?.author?.date || c.commit?.committer?.date,
    landed: c.commit?.committer?.date || c.commit?.author?.date,
    subject: msg.split("\n")[0].trim(),
    trailers: trailersOf(msg),
    url: isPrivate ? null : c.html_url || null,
  };
}
const since = (cfg) => (cfg.since ? `&since=${cfg.since}T00:00:00Z` : "");
async function commitsOf(owner, repo, token, cfg) {
  return pages(`${API}/repos/${owner}/${repo}/commits?per_page=100${since(cfg)}`, token, cfg.timeoutMs ?? 10000, cfg.maxPerRepo ?? 400);
}
// For the leak check only (verify-private.mjs), never used by a page: every public subject (those
// may appear anywhere) and the raw private subjects (which must appear nowhere).
export async function publicSubjects(cfg) {
  const out = [];
  for (const r of await publicRepos(cfg)) for (const c of await commitsOf(cfg.owner, r.name, cfg.token, cfg)) out.push(String(c.commit?.message || "").split("\n")[0].trim());
  return out;
}
export async function privateSubjects(cfg, tokens) {
  const out = [];
  for (const p of privateList(cfg)) {
    if (p.mask !== "full") continue;
    try {
      for (const c of await privateCommits(p, tokens, cfg)) out.push({ repo: p.repo, short: c.sha.slice(0, 7), authored: c.commit?.author?.date, subject: String(c.commit?.message || "").split("\n")[0].trim() });
    } catch (e) {
      out.push({ repo: p.repo, error: e.message });
    }
  }
  return out;
}
// A private repository's commits with the first token that can read it: LEDGER_TOKEN, then the
// build's own token (in CI, the workflow's GITHUB_TOKEN can read the repository it runs in, so a
// site's own AstroLog source stays live even when LEDGER_TOKEN can't reach it).
async function privateCommits(p, tokens, cfg) {
  let last = new Error("no token");
  for (const t of [...new Set([tokens].flat().filter(Boolean))]) {
    try {
      return await commitsOf(p.owner, p.repo, t, cfg);
    } catch (e) {
      last = e;
    }
  }
  throw last;
}

/* ── the whole ledger ─────────────────────────────────────────────────────────────────────── */
function readSnapshot(cfg) {
  try {
    return JSON.parse(fs.readFileSync(cfg.snapshot, "utf8"));
  } catch {
    return null;
  }
}
// A previous build's masked rows for one private repository (when the private lane can't run).
function carried(snap, p) {
  return (snap?.items ?? [])
    .filter((it) => it.private && it.repo === p.repo)
    .map((it) => ({ ...it, url: null, sha: undefined, text: p.mask === "full" && !MASKED.test(it.text ?? "") ? maskText("private change") : it.text, area: p.mask === "full" ? "" : it.area ?? "", masked: p.mask === "full" }));
}

export async function buildLedger(cfg) {
  const timeoutMs = cfg.timeoutMs ?? 10000;
  const tz = cfg.timeZone ?? "UTC";
  const kinds = cfg.kinds ?? DEFAULT_KINDS;
  const repos = await publicRepos({ ...cfg, timeoutMs });
  const raw = [];
  for (const r of repos) for (const c of await commitsOf(cfg.owner, r.name, cfg.token, cfg)) raw.push(reduce(r.name, c, false));

  const priv = privateList(cfg);
  const privateRepos = [];
  const keep = [];
  const notes = [];
  let snap;
  const tokens = [cfg.privateToken, cfg.privateToken ? cfg.token : null];
  for (const p of priv) {
    if (cfg.privateToken) {
      try {
        for (const c of await privateCommits(p, tokens, cfg)) raw.push(reduce(p.repo, c, true));
        privateRepos.push(p);
        continue;
      } catch (e) {
        notes.push(`${p.repo}: ${e.message}`);
      }
    }
    snap ??= readSnapshot(cfg);
    const old = carried(snap, p);
    keep.push(...old);
    privateRepos.push({ ...p, carried: true });
  }
  if (priv.length && !cfg.privateToken) console.warn(`[ledger] no private token: ${priv.length} private repositories carried from the snapshot (masked)`);
  for (const n of notes) console.warn(`[ledger] private lane unavailable for ${n}; carried from the snapshot (masked)`);
  return shape(raw, repos, cfg, { tz, kinds, privateRepos, carried: keep });
}

function personFor(login, authorName, cfg) {
  const people = cfg.people ?? [];
  const l = login.toLowerCase();
  const style = cfg.nameStyle ?? "first-last-initial";
  const hit =
    people.find((p) => l && [p.github, ...(p.logins ?? [])].filter(Boolean).some((x) => x.toLowerCase() === l)) ||
    people.find((p) => [p.name, ...(p.names ?? [])].some((n) => n && n.toLowerCase() === authorName.toLowerCase()));
  if (hit) {
    // `github` links the name; the picture is GitHub's unless the person asks for a generated one
    // (avatar: "generated", for anyone whose GitHub picture is the default identicon).
    const handle = hit.github ?? (login || null);
    return { name: nameAs(hit.name, style), github: handle, avatar: hit.github && hit.avatar !== "generated" ? "github" : "generated", known: true };
  }
  return { name: nameAs(authorName || login || "A contributor", style), github: login || null, avatar: cfg.unknownAvatars && login ? "github" : "generated", known: false };
}

export function shape(raw, repos, cfg, { tz = cfg.timeZone ?? "UTC", kinds = cfg.kinds ?? DEFAULT_KINDS, privateRepos = [], carried: old = [] } = {}) {
  const labels = cfg.repoLabels ?? {};
  const privBy = new Map(privateRepos.map((p) => [p.repo, p]));
  const label = (name) => privBy.get(name)?.label ?? labels[name]?.label ?? name;
  const filtered = { merges: 0, mirrors: 0, bots: 0, undone: 0, copies: 0 };
  // A private commit that also lives in a public copy (same author date and subject) is shown there.
  const publicCopies = new Set(raw.filter((k) => !k.private).map((k) => `${k.authored}\n${k.subject}`));
  const keep = [];
  for (const k of raw) {
    if (k.private && publicCopies.has(`${k.authored}\n${k.subject}`)) filtered.copies++;
    else if (k.parents > 1 || /^merge (pull request|branch|remote-tracking|tag)\b/i.test(k.subject)) filtered.merges++;
    else if (MIRROR.some((re) => re.test(k.subject))) filtered.mirrors++;
    else if (BOT_NAMES.test(k.login) || BOT_NAMES.test(k.authorName) || BUMP.some((re) => re.test(k.subject))) filtered.bots++;
    else keep.push(k);
  }
  // A change and its revert cancel out (both leave the record).
  const reverts = new Map();
  for (const k of keep) {
    const m = /^revert "(.+)"$/i.exec(k.subject);
    if (m) reverts.set(`${k.repo}\n${m[1]}`, k);
  }
  const gone = new Set();
  for (const k of keep) {
    const r = reverts.get(`${k.repo}\n${k.subject}`);
    if (r && !gone.has(r) && !gone.has(k)) {
      gone.add(k);
      gone.add(r);
    }
  }
  filtered.undone = gone.size;

  const fresh = keep
    .filter((k) => !gone.has(k))
    .map((k) => {
      const first = k.parents === 0;
      const sum = summarize(k.subject, kinds, { first });
      const p = k.private ? privBy.get(k.repo) : null;
      const masked = !!p && p.mask === "full";
      // A private subject is classified (kind, priority) and then discarded: only its shape stays.
      const text = masked
        ? maskText(sum.core)
        : first && (!sum.said || /^(first|initial) commit$/i.test(k.subject))
          ? `Started ${label(k.repo)}`
          : sum.text;
      return {
        id: k.sha.slice(0, 12),
        ...(k.private ? {} : { sha: k.sha }),
        short: k.sha.slice(0, 7),
        repo: k.repo,
        repoLabel: label(k.repo),
        private: k.private,
        masked,
        url: k.private ? null : k.url || `https://github.com/${cfg.owner}/${k.repo}/commit/${k.sha}`,
        d: dayOf(k.authored, tz),
        time: timeOf(k.authored, tz),
        ts: k.landed,
        text,
        area: masked ? "" : sum.area,
        kind: { id: sum.kind.id, name: sum.kind.name, icon: sum.kind.icon },
        priority: sum.priority ? { ...sum.priority } : null,
        who: personFor(k.login, k.authorName, cfg),
        agents: cfg.agents === false ? [] : agentsOf(k.trailers, { masked: k.private, extra: cfg.agentNames ?? [] }),
      };
    });
  const items = [...fresh, ...old].sort((a, b) => b.ts.localeCompare(a.ts) || b.d.localeCompare(a.d));

  // Month → day → repository.
  const months = [];
  for (const it of [...items].sort((a, b) => b.d.localeCompare(a.d) || b.ts.localeCompare(a.ts))) {
    const mk = it.d.slice(0, 7);
    let mo = months[months.length - 1];
    if (!mo || mo.key !== mk) {
      const [y, m] = mk.split("-").map(Number);
      mo = { key: mk, label: `${MONTHS[m - 1]} ${y}`, count: 0, days: [] };
      months.push(mo);
    }
    let day = mo.days[mo.days.length - 1];
    if (!day || day.date !== it.d) {
      day = { date: it.d, label: dayLabel(it.d), groups: [] };
      mo.days.push(day);
    }
    let g = day.groups.find((x) => x.repo === it.repo);
    if (!g) {
      g = { repo: it.repo, label: it.repoLabel, private: !!it.private, items: [] };
      day.groups.push(g);
    }
    g.items.push(it);
    mo.count++;
  }
  const count = (key) => {
    const m = new Map();
    for (const it of items) {
      const k = key(it);
      m.set(k, (m.get(k) ?? 0) + 1);
    }
    return m;
  };
  const byKind = count((it) => it.kind.id);
  const byRepo = count((it) => it.repo);
  const byWho = count((it) => it.who.name);
  const allKinds = [...kinds, DEFAULT_KIND];
  const shownPrivate = items.filter((it) => it.private).length;
  return {
    version: LEDGER_VERSION,
    owner: cfg.owner,
    generated: new Date().toISOString(),
    timeZone: tz,
    total: raw.length + old.length,
    shown: items.length,
    shownPublic: items.length - shownPrivate,
    shownPrivate,
    filtered,
    repos: [
      ...repos.map((r) => ({ name: r.name, label: label(r.name), blurb: labels[r.name]?.blurb ?? "", url: r.html_url, private: false, count: byRepo.get(r.name) ?? 0 })),
      ...privateRepos.map((p) => ({ name: p.repo, label: label(p.repo), blurb: p.blurb ?? "", url: null, private: true, count: byRepo.get(p.repo) ?? 0 })),
    ]
      .filter((r) => r.count > 0)
      .sort((a, b) => b.count - a.count),
    kinds: allKinds.map((k) => ({ id: k.id, name: k.name, icon: k.icon, count: byKind.get(k.id) ?? 0 })).filter((k) => k.count > 0),
    priorities: Object.values(PRIORITIES)
      .map((p) => ({ ...p, count: items.filter((it) => it.priority?.id === p.id).length }))
      .filter((p) => p.count > 0),
    people: [...byWho.entries()]
      .map(([name, n]) => {
        const who = items.find((it) => it.who.name === name)?.who;
        return { name, github: who?.github ?? null, avatar: who?.avatar ?? "generated", count: n };
      })
      .sort((a, b) => b.count - a.count),
    first: items.length ? items[items.length - 1].d : null,
    last: items.length ? items[0].d : null,
    months,
    items,
  };
}

/* ── live with a snapshot fallback, cached per build ──────────────────────────────────────── */
let cached = null;
export function loadLedger(cfg) {
  cached ??= (async () => {
    const env = process.env;
    // Public lane: any token (a read-only Actions token is plenty). Private lane: LEDGER_TOKEN only,
    // a token that can read the opted-in private repositories (none: they're carried, masked).
    const token = cfg.token ?? env.GITHUB_TOKEN ?? env.GH_TOKEN ?? env.LEDGER_TOKEN ?? "";
    const privateToken = cfg.privateToken ?? env.LEDGER_TOKEN ?? "";
    if (!cfg.offline && env.LEDGER_OFFLINE !== "1") {
      try {
        const live = await buildLedger({ ...cfg, token, privateToken });
        console.log(`[ledger] ${live.shownPublic} public + ${live.shownPrivate} private (masked) commits from ${live.repos.length} repositories (live, ${token ? "token" : "no token"}${privateToken ? ", private token" : ""})`);
        return { ...live, from: "live" };
      } catch (e) {
        console.warn(`[ledger] live fetch failed (${e.message}); using the snapshot`);
      }
    }
    const snap = readSnapshot(cfg);
    if (snap) return { ...snap, from: "snapshot" };
    console.warn("[ledger] no snapshot either; the ledger page will say so");
    return { version: LEDGER_VERSION, owner: cfg.owner, generated: null, total: 0, shown: 0, shownPublic: 0, shownPrivate: 0, filtered: { merges: 0, mirrors: 0, bots: 0, undone: 0, copies: 0 }, repos: [], kinds: [], priorities: [], people: [], months: [], items: [], from: "none" };
  })();
  return cached;
}

// For latest.json: the newest ledger items in the kit's item shape (type "ledger", exact `ts`).
// Private rows carry their masked text and point at their day on the ledger page (`ledgerHref`, the
// page's absolute URL); without one they're left out.
export function ledgerNewsItems(ledger, { days = 45, max = 60, kicker = "ledger", ledgerHref = null } = {}) {
  const from = Date.now() - days * 86400000;
  return ledger.items
    .filter((it) => Date.parse(it.ts) >= from)
    .filter((it) => !it.private || ledgerHref)
    .slice(0, max)
    .map((it) => ({
      type: "ledger",
      t: it.text,
      k: `${kicker} · ${it.repoLabel}${it.private ? " · private" : ""}`,
      i: it.private ? "lock-simple" : it.kind.icon,
      h: it.private ? `${ledgerHref}#d-${it.d}` : it.url,
      d: it.d,
      ts: it.ts,
      who: it.who.name,
    }));
}
