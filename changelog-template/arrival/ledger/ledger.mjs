// Arrival kit · the ledger: an owner's PUBLIC GitHub commit history as a calm, plain-language record.
// Canonical copy: drasticstatic/my-template changelog-template/arrival/ledger/ledger.mjs. Copy it
// unchanged; tailor it through the site's ledger.config.mjs (see ledger.config.example.mjs).
//
// Build time only (an Astro page or endpoint calls loadLedger(config)); nothing runs in the browser
// except the page's small filter script. Dependency-free: Node 22's fetch.
//
// What it does, in order:
//   1. Lists the owner's repositories and keeps only PUBLIC ones (private === false AND
//      visibility === "public"), then the config's include/deny. A private repository's commits are
//      never requested, whatever token the build has.
//   2. Reads each repo's default-branch commits (paginated, up to maxPerRepo).
//   3. Filters noise: merges, CI mirror/sync commits ("sync: rebuild from…", "Deploy Astro build",
//      "Deploy: <sha>"), bot authors and dependency bumps, and revert pairs (a change and its undo
//      cancel out). Every filtered commit is counted, so the page can say what it left out.
//   4. Turns each subject (first line only; bodies are never read past the co-author trailers) into
//      a plain summary: conventional prefixes ("feat(nav): …") become a kind and an area, the rest
//      is tidied and trimmed. Secrets-shaped text (emails, long hex, wallet/base58 keys,
//      key=value assignments) is scrubbed first.
//   5. Sorts each commit into a kind with a small keyword rubric (first match wins), credits it
//      through the site's people list (display names and avatars exactly as the site already shows
//      them; unknown authors follow config.nameStyle), and groups everything by month, day and repo.
//   6. On any failure (offline, rate limit) it falls back to the committed snapshot, so the build
//      never breaks. Refresh the snapshot with `node scripts/ledger-snapshot.mjs`.
//
// The technique (public repos only, deny list, a regex rubric, scrubbed subjects, grouped accordion)
// follows Christopher's activity-ledger generator; nothing else is shared with it.
import fs from "node:fs";

export const LEDGER_VERSION = 1;

// The kinds a change can be, checked in this order. `types` are conventional-commit prefixes that
// decide it outright; `words` are matched against the subject. A site may pass its own list.
export const DEFAULT_KINDS = [
  { id: "speed", name: "Speed", icon: "lightning", types: ["perf"], words: /\b(faster|speed(s|ed)? up|performance|optimi[sz]\w*|cach(e|es|ing)|webp|lazy[- ]load\w*)\b/i },
  { id: "fix", name: "Fixes", icon: "wrench", types: ["fix", "hotfix", "bugfix"], words: /\b(fix(e[sd])?|bug|broken|repair\w*|stabili[sz]\w*|resolve[sd]?|typo|grammar|correct(ion|ions|ed)?|keep .* together)\b/i },
  { id: "access", name: "Sign-in and members", icon: "key", types: ["auth"], words: /\b(auth0?|clerk|oauth|sign[- ]?in|log[- ]?in|login|members?|membership|admin\w*|accounts?|allowlist\w*)\b/i },
  { id: "look", name: "Look and feel", icon: "palette", types: ["style", "ui", "design"], words: /\b(style[sd]?|styling|restyle\w*|ui|design\w*|colou?rs?|accents?|fonts?|typography|layout|padding|align\w*|markers?|perforat\w*|icons?|images?|art(work)?|animat\w*|spin\w*|shadows?|themes?|lights?|look|logo|banners?|badges?|tabs?|octagon|tiles?|marble|cursor|trail|ink|visual\w*)\b/i },
  { id: "words", name: "Words and pages", icon: "article", types: ["content", "copy"], words: /\b(wording|words|about( us)?|charter|ceremony|reference pages?|page content|beliefs?|faq|inclusive|labels?)\b/i },
  { id: "records", name: "Records and docs", icon: "notebook", types: ["docs", "doc"], words: /\b(docs?|documentation|document (the|how|backend|frontend)\b|readme|changelog|astrolog|notes?|license|ledger|link[- ]previews?|social cards?|og|map)\b/i },
  { id: "under", name: "Behind the scenes", icon: "gear-six", types: ["refactor", "chore", "test", "tests", "build", "ci", "revert"], words: /\b(refactor\w*|chores?|tests?|testing|ci|workflows?|deploy\w*|config\w*|runtime|heroku|netlify|eslint|lint\w*|renam\w*|clean\s?up|dependenc\w*|hooks?|tooling|route tree|dead code|extract\w*|decompos\w*|isolat\w*|ignore)\b/i },
  { id: "new", name: "New", icon: "sparkle", types: ["feat", "feature", "add"], words: /\b(add(s|ed)?|new|introduc\w*|launch\w*|creat\w*|build|builds|built|begin|begins|start\w*|first commit|initiali[sz]\w*|scaffold\w*|give[sn]?)\b/i },
];
export const DEFAULT_KIND = { id: "update", name: "Updates", icon: "arrows-clockwise" };

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
const cap = (s) => String(s || "").replace(/^([^A-Za-z]*)([a-z])/, (m, pre, c) => pre + c.toUpperCase());
const titleCase = (s) => String(s).replace(/[-_]+/g, " ").replace(/\b\w/g, (c) => c.toUpperCase());
function trim(s, n = 140) {
  if (s.length <= n) return s;
  const semi = s.indexOf("; ");
  if (semi > 24 && semi < n) return s.slice(0, semi);
  const cut = s.lastIndexOf(" ", n - 1);
  return s.slice(0, cut > 40 ? cut : n - 1).replace(/[,;:.\s]+$/, "") + "…";
}
export function nameAs(name, style) {
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
  let s = scrub(subject).replace(/\s*\(#\d+\)\s*$/, "").replace(/\.$/, "");
  let type = "";
  let area = "";
  const cc = /^([a-z]+)(?:\(([^)]{1,40})\))?(!)?:\s+(.+)$/i.exec(s);
  if (cc && /^(feat|feature|fix|hotfix|bugfix|docs?|style|refactor|perf|test|tests|build|ci|chore|revert|ui|content|copy|design|auth|add)$/i.test(cc[1])) {
    type = cc[1].toLowerCase();
    area = cc[2] ? SCOPES[cc[2].toLowerCase()] || titleCase(cc[2]) : "";
    s = cc[4];
  } else if (!first) {
    // "Portal: complete the link-preview tags" → area "Portal". Short prefixes only (a first
    // commit's "Scaffold X: …" stays whole).
    const pre = /^([A-Z][\w .&'/-]{1,32}?):\s+(.+)$/.exec(s);
    if (pre && pre[1].split(/\s+/).length <= 3 && !VERB.test(pre[1])) {
      area = pre[1];
      s = pre[2];
    }
  }
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
  return { text, area, type, kind: kind || DEFAULT_KIND, said };
}

/* ── GitHub (public API) ─────────────────────────────────────────────────────────────────── */
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
export async function publicRepos(cfg) {
  const api = "https://api.github.com";
  const list =
    cfg.ownerType === "user"
      ? `${api}/users/${cfg.owner}/repos?type=owner&per_page=100`
      : `${api}/orgs/${cfg.owner}/repos?type=public&per_page=100`;
  const repos = await pages(list, cfg.token, cfg.timeoutMs ?? 10000, 1000);
  const deny = new Set(cfg.deny ?? []);
  return repos
    .filter((r) => r && r.private === false && r.visibility === "public") // public only, always
    .filter((r) => cfg.forks || !r.fork)
    .filter((r) => !deny.has(r.name))
    .filter((r) => (cfg.include ? (cfg.include instanceof RegExp ? cfg.include.test(r.name) : cfg.include(r.name)) : true));
}

/* ── the whole ledger ─────────────────────────────────────────────────────────────────────── */
export async function buildLedger(cfg) {
  const timeoutMs = cfg.timeoutMs ?? 10000;
  const tz = cfg.timeZone ?? "UTC";
  const kinds = cfg.kinds ?? DEFAULT_KINDS;
  const repos = await publicRepos(cfg);
  const raw = [];
  for (const r of repos) {
    const commits = await pages(
      `https://api.github.com/repos/${cfg.owner}/${r.name}/commits?per_page=100${cfg.since ? `&since=${cfg.since}T00:00:00Z` : ""}`,
      cfg.token,
      timeoutMs,
      cfg.maxPerRepo ?? 400
    );
    for (const c of commits) raw.push({ repo: r.name, c });
  }
  return shape(raw, repos, cfg, { tz, kinds });
}

function personFor(c, cfg) {
  const login = (c.author?.login || "").toLowerCase();
  const name = c.commit?.author?.name || "";
  const people = cfg.people ?? [];
  const hit =
    people.find((p) => login && [p.github, ...(p.logins ?? [])].filter(Boolean).some((l) => l.toLowerCase() === login)) ||
    people.find((p) => [p.name, ...(p.names ?? [])].some((n) => n && n.toLowerCase() === name.toLowerCase()));
  if (hit) return { name: hit.name, github: hit.github ?? null, known: true };
  return { name: nameAs(name || login || "A contributor", cfg.nameStyle), github: cfg.unknownAvatars && login ? c.author.login : null, known: false };
}
function coAuthors(message, allow = []) {
  if (!allow.length) return [];
  const found = [];
  for (const m of String(message).matchAll(/^co-authored-by:\s*([^<·\n]+)/gim)) {
    const who = m[1].trim();
    const ok = allow.find((a) => who.toLowerCase().startsWith(a.toLowerCase()));
    if (ok && !found.includes(ok)) found.push(ok);
  }
  return found;
}

export function shape(raw, repos, cfg, { tz = cfg.timeZone ?? "UTC", kinds = cfg.kinds ?? DEFAULT_KINDS } = {}) {
  const labels = cfg.repoLabels ?? {};
  const label = (name) => labels[name]?.label ?? name;
  const filtered = { merges: 0, mirrors: 0, bots: 0, undone: 0 };
  const keep = [];
  for (const { repo, c } of raw) {
    const msg = c.commit?.message || "";
    const subject = msg.split("\n")[0].trim();
    const login = c.author?.login || "";
    const authorName = c.commit?.author?.name || "";
    if ((c.parents?.length ?? 1) > 1 || /^merge (pull request|branch|remote-tracking|tag)\b/i.test(subject)) filtered.merges++;
    else if (MIRROR.some((re) => re.test(subject))) filtered.mirrors++;
    else if (BOT_NAMES.test(login) || BOT_NAMES.test(authorName) || BUMP.some((re) => re.test(subject))) filtered.bots++;
    else keep.push({ repo, c, subject });
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

  const items = keep
    .filter((k) => !gone.has(k))
    .map(({ repo, c, subject }) => {
      const first = !c.parents?.length;
      const sum = summarize(subject, kinds, { first });
      const authored = c.commit?.author?.date || c.commit?.committer?.date;
      const landed = c.commit?.committer?.date || authored;
      const who = personFor(c, cfg);
      return {
        id: c.sha.slice(0, 12),
        sha: c.sha,
        short: c.sha.slice(0, 7),
        repo,
        repoLabel: label(repo),
        url: c.html_url || `https://github.com/${cfg.owner}/${repo}/commit/${c.sha}`,
        d: dayOf(authored, tz),
        time: timeOf(authored, tz),
        ts: landed,
        text: first && (!sum.said || /^(first|initial) commit$/i.test(subject)) ? `Started ${label(repo)}` : sum.text,
        area: sum.area,
        kind: { id: sum.kind.id, name: sum.kind.name, icon: sum.kind.icon },
        who,
        with: coAuthors(c.commit?.message || "", cfg.coAuthors ?? []),
      };
    })
    .sort((a, b) => b.ts.localeCompare(a.ts) || b.d.localeCompare(a.d));

  // Month → day → repo.
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
      g = { repo: it.repo, label: it.repoLabel, items: [] };
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
  return {
    version: LEDGER_VERSION,
    owner: cfg.owner,
    generated: new Date().toISOString(),
    timeZone: tz,
    total: raw.length,
    shown: items.length,
    filtered,
    repos: repos
      .map((r) => ({ name: r.name, label: label(r.name), blurb: labels[r.name]?.blurb ?? "", url: r.html_url, count: byRepo.get(r.name) ?? 0 }))
      .filter((r) => r.count > 0)
      .sort((a, b) => b.count - a.count),
    kinds: allKinds.map((k) => ({ id: k.id, name: k.name, icon: k.icon, count: byKind.get(k.id) ?? 0 })).filter((k) => k.count > 0),
    people: [...byWho.entries()]
      .map(([name, n]) => ({ name, github: items.find((it) => it.who.name === name)?.who.github ?? null, count: n }))
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
    const token = cfg.token ?? process.env.LEDGER_TOKEN ?? process.env.GITHUB_TOKEN ?? process.env.GH_TOKEN ?? "";
    if (!cfg.offline && process.env.LEDGER_OFFLINE !== "1") {
      try {
        const live = await buildLedger({ ...cfg, token });
        console.log(`[ledger] ${live.shown} public commits from ${live.repos.length} repositories (live, ${token ? "token" : "no token"})`);
        return { ...live, from: "live" };
      } catch (e) {
        console.warn(`[ledger] live fetch failed (${e.message}); using the snapshot`);
      }
    }
    try {
      const snap = JSON.parse(fs.readFileSync(cfg.snapshot, "utf8"));
      return { ...snap, from: "snapshot" };
    } catch {
      console.warn("[ledger] no snapshot either; the ledger page will say so");
      return { version: LEDGER_VERSION, owner: cfg.owner, generated: null, total: 0, shown: 0, filtered: { merges: 0, mirrors: 0, bots: 0, undone: 0 }, repos: [], kinds: [], people: [], months: [], items: [], from: "none" };
    }
  })();
  return cached;
}

// For latest.json: the newest ledger items in the kit's item shape (type "ledger", exact `ts`).
export function ledgerNewsItems(ledger, { days = 45, max = 60, kicker = "ledger" } = {}) {
  const from = Date.now() - days * 86400000;
  return ledger.items
    .filter((it) => Date.parse(it.ts) >= from)
    .slice(0, max)
    .map((it) => ({ type: "ledger", t: it.text, k: `${kicker} · ${it.repoLabel}`, i: it.kind.icon, h: it.url, d: it.d, ts: it.ts, who: it.who.name }));
}
