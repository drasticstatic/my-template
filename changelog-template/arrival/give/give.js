/*! Arrival kit v1.4 · give with crypto · https://github.com/drasticstatic/my-template (changelog-template/arrival/give)
 *
 * The same file in every org, beside arrival.js (served as /arrival/give/give.js). Tailor it through
 * org.js (window.ARRIVAL.give), never by editing this file:
 *
 *   give: {
 *     enabled: true,                       // false: no module, the donate page keeps its empty slot
 *     reownProjectId: "…",                 // a Reown (WalletConnect) project ID: a public client ID
 *     chains: ["mainnet"],                 // EVM networks the ETH address can receive on (mainnet,
 *                                          // base, arbitrum, optimism; sepolia for tests). List one
 *                                          // only if the address really receives there.
 *     addresses: { eth: null, btc: null, sol: null },   // null until the org publishes one
 *     note: "…",                           // the org's own words, after the safety line
 *     social: true,                        // false hides email and social sign-in
 *     claim: { to: "name@org" },           // where "add your name" notes go (default: the first
 *                                          // email in contact.paths)
 *     words: { … },                        // any string below
 *   }
 *
 * What it does (arrival.js draws the section; this file loads when it nears the screen, and talks
 * to nobody until the visitor clicks):
 *   Connect a wallet   checks the Reown project's public allowlist for this site, then loads Reown
 *                      AppKit (pinned below, from jsDelivr) and opens it: browser wallets, phone
 *                      wallets by QR code or deep link (so Safari and phones work), and email/social
 *                      sign-in where the project allows it. If the site isn't on the allowlist, or
 *                      AppKit can't load, it says so calmly, uses a browser wallet if there is one,
 *                      and otherwise opens the guide.
 *   New to wallets?    a plain-language guide in a kit dialog: what a wallet is, why Safari can't
 *                      use extensions, how to use a phone wallet instead, staying safe.
 *   No address         nothing to send to, so connecting is a labelled preview. Nothing is sent and
 *                      no address is ever shown or made up.
 *   An address         Copy (the kit's), a QR code (drawn here, dark on white), "Open in a wallet
 *                      app" for BTC/SOL, and for ETH "Send with your wallet": an amount, then a
 *                      transfer the visitor approves in their own wallet. After that, optionally,
 *                      "Add your name to the contributors list": the visitor signs a plain message
 *                      (free, no gas) naming the transaction and the name to show, and gets a ready
 *                      JSON note (copy, or a prefilled email) for the org to check and add to
 *                      donate/contributors.json by hand. The page stores nothing and sends nothing.
 *   The allowlist      AppKit logs "origin … not in your allow list" as a console error. The check
 *                      above means it normally never loads on a site that isn't listed; if it does
 *                      (a stale answer), this catches that message, shows the calm state instead,
 *                      and logs one plain console.info line.
 *
 * v1.4: the wallet layer is shared. window.ArrivalGive.wallet = { allowed(pid), load(pid, { description }),
 * injected(), connectBrowser(), sign(message), disconnect(), state(), on(fn), learn(kind, { eyebrow,
 * onConnect }) } is what pledge/pledge.js uses, so a page has one AppKit, one allowlist check and
 * one "New to wallets?" guide, whichever module asks first. It needs no give section on the page.
 */
const APPKIT_VERSION = "1.8.24"; // @reown/appkit-cdn, published 2026-09-16
const APPKIT = "https://cdn.jsdelivr.net/npm/@reown/appkit-cdn@" + APPKIT_VERSION + "/dist/appkit.js";
const UQR = "https://cdn.jsdelivr.net/npm/uqr@0.1.3/dist/index.mjs"; // QR encoder, MIT, no dependencies
const ORIGINS = "https://api.web3modal.org/projects/v1/origins"; // AppKit's own allowlist lookup (public)
// AppKit always lets these in, whatever the project lists (its DEFAULT_ALLOWED_ANCESTORS).
const ALWAYS = ["http://localhost:*", "https://localhost:*", "http://127.0.0.1:*", "https://127.0.0.1:*", "https://*.pages.dev", "https://*.vercel.app", "https://*.ngrok-free.app"];
// Networks whose own coin is ETH, so "Send ETH" means ETH on each of them.
const NETS = {
  mainnet: { key: "mainnet", id: 1, name: "Ethereum", scan: "https://etherscan.io" },
  base: { key: "base", id: 8453, name: "Base", scan: "https://basescan.org" },
  arbitrum: { key: "arbitrum", id: 42161, name: "Arbitrum One", scan: "https://arbiscan.io" },
  optimism: { key: "optimism", id: 10, name: "OP Mainnet", scan: "https://optimistic.etherscan.io" },
  sepolia: { key: "sepolia", id: 11155111, name: "Sepolia (a test network)", scan: "https://sepolia.etherscan.io" },
};
NETS.ethereum = NETS.mainnet;
const COINS = {
  eth: { name: "Ethereum", sym: "ETH", ok: /^0x[0-9a-fA-F]{40}$/ },
  btc: { name: "Bitcoin", sym: "BTC", ok: /^(bc1[02-9ac-hj-np-z]{8,87}|[13][1-9A-HJ-NP-Za-km-z]{25,34})$/ },
  sol: { name: "Solana", sym: "SOL", ok: /^[1-9A-HJ-NP-Za-km-z]{32,44}$/ },
};

const doc = document;
const C = window.ARRIVAL || {};
const G = C.give || {};
const ORG = C.org || {};
const WHO = ORG.short || ORG.name || "us";
const KIT = window.Arrival || {};

const W = Object.assign(
  {
    connect: "Connect a wallet",
    manage: "Manage your wallet",
    linked: "Wallet connected",
    checking: "Checking that wallet connect is switched on for this site…",
    opening: "Opening the wallet window…",
    asking: "Asking the wallet in your browser…",
    connectedLive: "Connected{wallet}.",
    disconnected: "Disconnected.",
    connected: "Connected",
    disconnect: "Disconnect",
    browserWallet: "Browser wallet",
    emailWallet: "Email wallet",
    on: "on",
    offTitle: "Wallet connect isn't set up for this site yet",
    offText: "There's no wallet-connect project for this page yet, so connecting from here won't work. Nothing is wrong with your wallet or your browser.",
    originTitle: "Wallet connect isn't switched on for this site yet",
    originText: "Nothing is wrong with your wallet or your browser. Connecting wallets goes through a service that only works on sites its owner has listed, and {host} isn't on that list yet. It's a setting on our side.",
    loadTitle: "The wallet window couldn't open",
    loadText: "Something stopped it loading: a content blocker, a strict privacy setting or a weak connection. Nothing was sent.",
    tryAgain: "Try again",
    howWallets: "How wallets work",
    injectedOrigin: "Phone wallets (by QR code) and email sign-in aren't switched on for this site yet, so this used the wallet in your browser.",
    injectedLoad: "The full wallet window couldn't load, so this used the wallet in your browser.",
    injectedOff: "To remove this site completely, use your wallet's list of connected sites.",
    declinedConnect: "You declined in your wallet. Nothing was shared.",
    walletFailed: "Your browser wallet didn't answer. Try again, or use a phone wallet.",
    previewTitle: "How giving will work",
    previewText: "No treasury address is published yet, so there's nothing to send to, and nothing has been sent. When there is one, this is where you'll choose an amount, approve it in your wallet, and, if you like, add your name to the thanks list.",
    previewOther: "For {coins}, use the address and QR code above.",
    sendTitle: "Send ETH to {org}",
    amount: "Amount",
    network: "Network",
    sendOn: "On {net}.",
    sendBtn: "Review in your wallet",
    sendNote: "Your wallet shows the address, the amount and the network fee before anything is sent. Check that the address's first and last characters match the ones on this page.",
    badAmount: "Enter an amount, like 0.01.",
    badChecksum: "The address on this page doesn't pass its own checksum, so this page won't send to it. Please tell {org}.",
    approve: "Waiting for you to approve in your wallet…",
    switching: "Asking your wallet to switch to {net}…",
    declined: "You declined in your wallet. Nothing was sent.",
    declinedSign: "You declined in your wallet. Nothing was signed.",
    sendFailed: "The transfer didn't go through, and nothing was sent.",
    sentTitle: "Sent. Thank you.",
    sentText: "Your gift is on its way. Transaction:",
    viewTx: "View it on {scan}",
    sentLive: "Sent. Thank you.",
    claim: "Add your name to the contributors list",
    claimText: "Optional. Sign a short message with the wallet that sent the gift: signing is free and sends nothing. You'll get a ready-made note to send us, and we add your name by hand. Giving without a name is just as welcome.",
    name: "Name to show",
    nameHint: "First name and last initial is plenty, like Sam T.",
    badName: "Enter the name you'd like shown.",
    tx: "Transaction ID",
    txHint: "Starts with 0x; your wallet's activity list shows it.",
    badTx: "That doesn't look like a transaction ID (0x and 64 more characters).",
    signBtn: "Sign with your wallet (free)",
    signApprove: "Waiting for you to sign in your wallet…",
    signFailed: "The message wasn't signed, and nothing was sent.",
    signedTitle: "Signed. Here's your note",
    signedText: "Send it to {org}. They check the gift and add your name to the list by hand. This page hasn't saved or sent anything.",
    yourNote: "Your note",
    copyNote: "Copy the note",
    noteCopied: "Note copied.",
    selectNote: "Select the note and copy it.",
    emailNote: "Email it to {org}",
    emailSubject: "Please add my name to the contributors list",
    showQr: "Show QR code",
    hideQr: "Hide QR code",
    qrLabel: "QR code for the {coin} address",
    qrCaption: "Scan it with your wallet app's own scanner. Check the first and last characters before you send.",
    qrFailed: "The QR code couldn't be drawn. Copy the address instead.",
    learnTitle: "Wallets, in plain words",
    learnEyebrow: "Give with crypto",
    close: "Close",
  },
  G.words || {}
);

/* ── helpers ─────────────────────────────────────────────────────────────────────────────── */
const esc = (s) => String(s == null ? "" : s).replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c]);
const icon = (n) => '<i class="ph ph-' + esc(n) + '" aria-hidden="true"></i>';
const fill = (s, o) => String(s).replace(/\{(\w+)\}/g, (m, k) => (o && o[k] != null ? o[k] : m));
const short = (a) => (a ? a.slice(0, 6) + "…" + a.slice(-4) : "");
const toast = (t) => (KIT.toast ? KIT.toast(t) : null);
function address(id) {
  const v = ((G.addresses || {})[id] || "").toString().trim();
  return v && COINS[id] && COINS[id].ok.test(v) ? v : null;
}
function nets() {
  const list = (G.chains && G.chains.length ? G.chains : ["mainnet"]).map((k) => NETS[k]).filter(Boolean);
  return list.length ? list.filter((n, i) => list.indexOf(n) === i) : [NETS.mainnet];
}
const netById = (id) => Object.values(NETS).find((n) => n.id === Number(id)) || null;
const netName = (id) => (netById(id) ? netById(id).name : id ? "network " + id : "");
function toWei(s) {
  s = String(s || "").trim().replace(",", ".");
  if (!/^\d*(\.\d{0,18})?$/.test(s) || !/\d/.test(s)) return null;
  const [i, f = ""] = s.split(".");
  const wei = BigInt(i || "0") * 10n ** 18n + BigInt((f + "0".repeat(18)).slice(0, 18));
  return wei > 0n ? wei : null;
}
const utf8Hex = (s) => "0x" + Array.from(new TextEncoder().encode(s), (b) => b.toString(16).padStart(2, "0")).join("");
const rejected = (e) => !!e && (e.code === 4001 || e.name === "UserRejectedRequestError" || /reject|denied|declined|cancel/i.test(String(e.shortMessage || e.message || "")));
const reason = (e) => String((e && (e.shortMessage || e.message)) || "").split("\n")[0].slice(0, 160);
function claimTo() {
  if (G.claim && G.claim.to) return String(G.claim.to).replace(/^mailto:/i, "");
  const p = ((C.contact && C.contact.paths) || []).find((x) => x && /^mailto:/i.test(x.href || "") && !x.placeholder);
  return p ? decodeURIComponent(p.href.replace(/^mailto:/i, "").split("?")[0]) : "";
}
function injected() {
  const e = window.ethereum;
  return e && typeof e.request === "function" ? e : null;
}
function dark() {
  const id = doc.documentElement.getAttribute("data-theme");
  const m = (C.modes || []).find((x) => x.id === id);
  if (m) return !!m.dark;
  try {
    return matchMedia("(prefers-color-scheme: dark)").matches;
  } catch (e) {
    return false;
  }
}
function cssColor(v) {
  const s = doc.createElement("span");
  s.style.cssText = "display:none;color:var(" + v + ")";
  doc.body.appendChild(s);
  const c = getComputedStyle(s).color;
  s.remove();
  return c;
}
function themeVars() {
  return { "--w3m-accent": cssColor("--accent"), "--w3m-font-family": getComputedStyle(doc.body).fontFamily, "--w3m-z-index": 10000 };
}
function iconUrl() {
  const src = (ORG.mark && ORG.mark.src) || (doc.querySelector('link[rel~="icon"][href$=".png"]') || doc.querySelector('link[rel~="icon"]') || {}).href || "/favicon.png";
  return new URL(src, location.href).href;
}

/* ── state ───────────────────────────────────────────────────────────────────────────────── */
const S = {
  sec: null,
  allowed: undefined, // true | false | null (unknown)
  kitP: null,
  M: null, // the AppKit module
  adapter: null,
  appkit: null,
  account: null,
  via: "", // "appkit" | "injected"
  wallet: "",
  chainId: null,
  state: null, // off | origin | load: a calm "not available" state
  note: "",
  blocked: false,
  wantSend: false,
  lastTx: null,
  lastNet: null,
  learn: null,
  learnKind: null,
  learnConnect: null,
  n: 0,
};
const $ = (sel) => S.sec && S.sec.querySelector(sel);
// v1.4: anyone sharing the wallet layer (pledge.js) hears about every change of account.
const subs = [];
function walletState() {
  return { account: S.account, via: S.via, wallet: S.wallet, chainId: S.chainId, blocked: S.blocked };
}
function notify() {
  const st = walletState();
  subs.forEach((fn) => {
    try {
      fn(st);
    } catch (e) {}
  });
}
function live(t) {
  const el = $("[data-give-live]");
  if (el) el.textContent = t || "";
}
function busy(el, on) {
  if (el) el.setAttribute("aria-busy", on ? "true" : "false");
}

/* ── is wallet connect switched on for this site? (the project's public allowlist) ──────── */
function matches(here, p) {
  p = String(p || "").trim();
  if (!p) return false;
  let u;
  try {
    u = new URL(here);
  } catch (e) {
    return false;
  }
  let scheme = null;
  let rest = p;
  const i = rest.indexOf("://");
  if (i >= 0) {
    scheme = rest.slice(0, i);
    rest = rest.slice(i + 3);
  }
  rest = rest.split("/")[0];
  let host = rest;
  let port;
  const c = rest.lastIndexOf(":");
  if (c >= 0) {
    host = rest.slice(0, c);
    port = rest.slice(c + 1);
  }
  if (scheme && scheme + ":" !== u.protocol) return false;
  if (port !== undefined && port !== "*" && port !== u.port) return false;
  if (port === undefined && scheme && u.port) return false;
  const want = host.toLowerCase().split(".");
  const have = u.hostname.toLowerCase().split(".");
  if (want.length !== have.length) return false;
  return want.every((l, k) => l === "*" || l === have[k]);
}
async function originAllowed(pid) {
  if (S.allowed !== undefined) return S.allowed;
  const here = location.origin;
  if (ALWAYS.slice(0, 4).some((p) => matches(here, p))) return (S.allowed = true);
  try {
    const ctl = new AbortController();
    const t = setTimeout(() => ctl.abort(), 7000);
    const r = await fetch(ORIGINS + "?projectId=" + encodeURIComponent(pid) + "&st=appkit&sv=html-wagmi-" + APPKIT_VERSION, { signal: ctl.signal, credentials: "omit" });
    clearTimeout(t);
    if (!r.ok) return (S.allowed = null);
    const list = ((await r.json()) || {}).allowedOrigins || [];
    // An empty list lets every site in (AppKit's own rule).
    return (S.allowed = !list.length || list.concat(ALWAYS).some((p) => matches(here, p)));
  } catch (e) {
    return (S.allowed = null);
  }
}

/* ── AppKit's allowlist message, caught: a calm state, not a red console ─────────────────── */
const BLOCK = /not in your allow ?list|not found on allowlist|origin not allowed|APKT00[278]\b/i;
function guard() {
  if (guard.on) return;
  guard.on = true;
  const text = (args) => args.map((a) => (a && typeof a === "object" ? [a.message, a.code, a.debugMessage].filter(Boolean).join(" ") : String(a))).join(" ");
  ["error", "warn"].forEach((lvl) => {
    const orig = console[lvl];
    console[lvl] = function (...args) {
      if (BLOCK.test(text(args))) return blocked();
      return orig.apply(console, args);
    };
  });
  window.addEventListener("unhandledrejection", (e) => {
    const r = e.reason;
    if (BLOCK.test(String((r && (r.message || r.code)) || r))) {
      e.preventDefault();
      blocked();
    }
  });
}
function blocked() {
  if (!S.blocked) console.info("[give] Wallet connect isn't switched on for " + location.origin + " yet: add it to the Reown project's allowlist (see the portal's SUSTAINABILITY.md).");
  S.blocked = true;
  S.allowed = false;
  try {
    if (S.appkit && !S.account) S.appkit.close();
  } catch (e) {}
  if (!S.account) {
    S.state = "origin";
    render();
  }
  notify();
}

/* ── loading AppKit (only on a click) ────────────────────────────────────────────────────── */
function appkit(pid, opts) {
  if (S.kitP) return S.kitP;
  S.kitP = (async () => {
    guard();
    const M = await import(APPKIT);
    const list = nets();
    const networks = list.map((n) => M.networks[n.key]).filter(Boolean);
    if (!networks.length) networks.push(M.networks.mainnet);
    const adapter = new M.WagmiAdapter({ projectId: pid, networks });
    // Remote settings in the Reown dashboard win where they're set. Locally: no analytics, no
    // swaps or on-ramp inside the window, plain accounts (signatures anyone can check).
    const features = { analytics: false, swaps: false, onramp: false, send: false, receive: false };
    if (G.social === false) Object.assign(features, { email: false, socials: false });
    const kit = M.createAppKit({
      adapters: [adapter],
      networks,
      defaultNetwork: networks[0],
      projectId: pid,
      metadata: {
        name: ORG.name || ORG.short || doc.title,
        description: (opts && opts.description) || "Give to " + WHO + " with a crypto wallet",
        url: location.origin,
        icons: [iconUrl()],
      },
      features,
      defaultAccountTypes: { eip155: "eoa" },
      themeMode: dark() ? "dark" : "light",
      themeVariables: themeVars(),
    });
    S.M = M;
    S.adapter = adapter;
    S.appkit = kit;
    kit.subscribeAccount((a) => onAccount(a));
    if (kit.subscribeNetwork) kit.subscribeNetwork((n) => n && n.chainId != null && setChain(n.chainId));
    if (kit.subscribeWalletInfo) kit.subscribeWalletInfo((w) => w && w.name && S.via === "appkit" && ((S.wallet = w.name), updateWho()));
    window.addEventListener("arrival:change", () => {
      try {
        kit.setThemeMode(dark() ? "dark" : "light");
        kit.setThemeVariables(themeVars());
      } catch (e) {}
    });
    try {
      if (kit.ready) await kit.ready();
    } catch (e) {}
    return kit;
  })();
  S.kitP.catch(() => {
    S.kitP = null;
  });
  return S.kitP;
}
function onAccount(a) {
  if (a && a.isConnected && a.address) {
    const fresh = S.account !== a.address || S.via !== "appkit";
    S.account = a.address;
    S.via = "appkit";
    S.state = null;
    S.note = "";
    const info = (S.appkit.getWalletInfo && S.appkit.getWalletInfo()) || {};
    S.wallet = info.name || (a.embeddedWalletInfo ? W.emailWallet : S.wallet || "");
    const cid = S.appkit.getChainId && S.appkit.getChainId();
    if (cid != null) S.chainId = Number(cid);
    if (fresh) {
      render();
      live(fill(W.connectedLive, { wallet: S.wallet ? " to " + S.wallet : "" }));
      notify();
    }
  } else if (S.via === "appkit" && S.account) {
    S.account = null;
    S.via = "";
    render();
    live(W.disconnected);
    notify();
  }
}
function setChain(id) {
  const n = Number(id);
  if (!n || n === S.chainId) return;
  S.chainId = n;
  updateWho();
  notify();
}

/* ── connecting ──────────────────────────────────────────────────────────────────────────── */
async function connect() {
  const btn = $('[data-give="connect"]');
  if (S.account) {
    if (S.via === "appkit") S.appkit.open();
    else $("[data-give-panel]").scrollIntoView({ block: "nearest" });
    return;
  }
  busy(btn, true);
  try {
    const pid = String(G.reownProjectId || "").trim();
    if (!pid) return await unavailable("off");
    live(W.checking);
    const ok = await originAllowed(pid);
    if (ok === false) return await unavailable("origin");
    live(W.opening);
    let kit;
    try {
      kit = await appkit(pid);
    } catch (e) {
      return await unavailable("load");
    }
    if (S.blocked) return await unavailable("origin");
    live("");
    if (!S.account) await kit.open();
  } finally {
    busy(btn, false);
  }
}
async function unavailable(kind) {
  live("");
  if (injected()) return connectInjected(kind);
  S.state = kind;
  render();
  learn(kind); // nothing available here: the guide, with what happened on top
}
// The browser's own wallet (window.ethereum), with no UI of its own: the give section and the
// pledge both call this when wallet connect isn't available for the site.
async function connectBrowser() {
  const eth = injected();
  if (!eth) throw new Error("No browser wallet");
  const accs = await eth.request({ method: "eth_requestAccounts" });
  if (!accs || !accs[0]) throw new Error("No account");
  S.account = accs[0];
  S.via = "injected";
  S.state = null;
  S.chainId = parseInt(await eth.request({ method: "eth_chainId" }), 16) || null;
  S.wallet = eth.isRabby ? "Rabby" : eth.isBraveWallet ? "Brave Wallet" : eth.isCoinbaseWallet ? "Coinbase Wallet" : eth.isMetaMask ? "MetaMask" : W.browserWallet;
  if (!connectBrowser.on && eth.on) {
    connectBrowser.on = true;
    eth.on("accountsChanged", (a) => {
      if (S.via !== "injected") return;
      S.account = (a && a[0]) || null;
      if (!S.account) S.via = "";
      render();
      notify();
    });
    eth.on("chainChanged", (c) => S.via === "injected" && setChain(parseInt(c, 16)));
  }
  notify();
  return S.account;
}
async function connectInjected(kind) {
  try {
    live(W.asking);
    await connectBrowser();
    S.note = kind === "load" ? W.injectedLoad : W.injectedOrigin;
    render();
    live(fill(W.connectedLive, { wallet: " to " + S.wallet }));
  } catch (err) {
    S.state = kind;
    render();
    live(rejected(err) ? W.declinedConnect : W.walletFailed);
  }
}
async function disconnect() {
  const was = S.via;
  if (was === "appkit") {
    try {
      await S.appkit.disconnect();
    } catch (e) {}
  }
  S.account = null;
  S.via = "";
  S.note = "";
  render();
  notify();
  live(W.disconnected + (was === "injected" ? " " + W.injectedOff : ""));
  const b = $('[data-give="connect"]');
  if (b) b.focus();
}

/* ── the wallet itself: send and sign ───────────────────────────────────────────────────── */
async function switchTo(net) {
  if (S.chainId === net.id) return;
  live(fill(W.switching, { net: net.name }));
  if (S.via === "appkit") {
    await S.appkit.switchNetwork(S.M.networks[net.key]);
  } else {
    await injected().request({ method: "wallet_switchEthereumChain", params: [{ chainId: "0x" + net.id.toString(16) }] });
  }
  S.chainId = net.id;
}
async function walletSend(to, wei, net) {
  await switchTo(net);
  live(W.approve);
  if (S.via === "appkit") return S.M.WagmiCore.sendTransaction(S.adapter.wagmiConfig, { to, value: wei, chainId: net.id });
  return injected().request({ method: "eth_sendTransaction", params: [{ from: S.account, to, value: "0x" + wei.toString(16) }] });
}
async function walletSign(message) {
  live(W.signApprove);
  if (S.via === "appkit") return S.M.WagmiCore.signMessage(S.adapter.wagmiConfig, { message });
  return injected().request({ method: "personal_sign", params: [utf8Hex(message), S.account] });
}

/* ── the panel under the buttons ─────────────────────────────────────────────────────────── */
function whoHTML() {
  return (
    icon("check-circle") +
    "<span><strong>" + esc(W.connected) + "</strong>" +
    (S.wallet ? "<span>· " + esc(S.wallet) + "</span>" : "") +
    (S.chainId ? "<span>· " + esc(W.on) + " " + esc(netName(S.chainId)) + "</span>" : "") +
    '<code translate="no">' + esc(short(S.account)) + "</code></span>" +
    '<button type="button" class="arr-btn arr-btn-quiet arr-shape" data-give="disconnect">' + icon("sign-out") + esc(W.disconnect) + "</button>"
  );
}
function updateWho() {
  const el = $("[data-give-who]");
  if (el && S.account) el.innerHTML = whoHTML();
}
function netField(id, selected) {
  const list = nets();
  if (list.length === 1) return '<p class="arr-fine">' + esc(fill(W.sendOn, { net: list[0].name })) + "</p>";
  return (
    '<label class="arr-give-field" for="' + id + '">' + esc(W.network) +
    '<select class="arr-input" id="' + id + '" name="chain">' +
    list.map((n) => '<option value="' + n.key + '"' + (n.id === selected ? " selected" : "") + ">" + esc(n.name) + "</option>").join("") +
    "</select></label>"
  );
}
function claimHTML(open) {
  const k = ++S.n;
  return (
    '<div class="arr-give-block" data-give-claim>' +
    '<button type="button" class="arr-btn arr-btn-quiet arr-shape" data-give="claim" aria-expanded="' + (open ? "true" : "false") + '" aria-controls="arr-give-claim-' + k + '">' + icon("signature") + esc(W.claim) + "</button>" +
    '<form class="arr-give-claim" id="arr-give-claim-' + k + '" data-give-form="claim"' + (open ? "" : " hidden") + ' novalidate>' +
    '<p class="arr-fine">' + esc(W.claimText) + "</p>" +
    '<div class="arr-give-fields">' +
    '<label class="arr-give-field" for="arr-give-name-' + k + '">' + esc(W.name) + '<input class="arr-input" id="arr-give-name-' + k + '" name="name" maxlength="60" autocomplete="off" required><small>' + esc(W.nameHint) + "</small></label>" +
    '<label class="arr-give-field" for="arr-give-tx-' + k + '">' + esc(W.tx) + '<input class="arr-input" id="arr-give-tx-' + k + '" name="tx" spellcheck="false" autocomplete="off" required value="' + esc(S.lastTx || "") + '"><small>' + esc(W.txHint) + "</small></label>" +
    "</div>" +
    netField("arr-give-cnet-" + k, (S.lastNet && S.lastNet.id) || S.chainId) +
    '<button type="submit" class="arr-btn arr-btn-primary arr-shape">' + icon("signature") + esc(W.signBtn) + "</button>" +
    "</form><div data-give-out></div></div>"
  );
}
function bodyHTML() {
  const eth = address("eth");
  if (!eth) {
    const others = ["btc", "sol"].filter(address).map((c) => COINS[c].name);
    return (
      '<div class="arr-give-block"><h3>' + icon("eye") + '<span class="arr-soon">Preview</span> ' + esc(W.previewTitle) + "</h3>" +
      "<p>" + esc(W.previewText) + (others.length ? " " + esc(fill(W.previewOther, { coins: others.join(" or ") })) : "") + "</p></div>"
    );
  }
  const k = ++S.n;
  return (
    '<form class="arr-give-send" data-give-form="send" novalidate><h3>' + icon("paper-plane-tilt") + esc(fill(W.sendTitle, { org: WHO })) + "</h3>" +
    '<div class="arr-give-fields"><label class="arr-give-field" for="arr-give-amt-' + k + '">' + esc(W.amount) +
    '<span class="arr-input-unit"><input class="arr-input" id="arr-give-amt-' + k + '" name="amount" inputmode="decimal" autocomplete="off" placeholder="0.01" required><span>ETH</span></span></label>' +
    (nets().length > 1 ? netField("arr-give-net-" + k, S.chainId) : "") +
    "</div>" + (nets().length > 1 ? "" : netField("", null)) +
    '<p class="arr-fine">' + esc(W.sendNote) + "</p>" +
    '<button type="submit" class="arr-btn arr-btn-primary arr-shape">' + icon("wallet") + esc(W.sendBtn) + "</button></form>" +
    '<div data-give-sent></div>' + claimHTML(false)
  );
}
function stateHTML(kind) {
  const t = { off: [W.offTitle, W.offText], origin: [W.originTitle, fill(W.originText, { host: location.host })], load: [W.loadTitle, W.loadText] }[kind] || [W.loadTitle, W.loadText];
  return (
    '<div class="arr-give-state">' + icon(kind === "load" ? "plug" : "info") + "<div><h3>" + esc(t[0]) + "</h3><p>" + esc(t[1]) + "</p>" +
    '<div class="arr-give-actions">' +
    (kind === "load" ? '<button type="button" class="arr-btn arr-btn-quiet arr-shape" data-give="retry">' + icon("arrow-clockwise") + esc(W.tryAgain) + "</button>" : "") +
    '<button type="button" class="arr-btn arr-btn-quiet arr-shape" data-give="learn">' + icon("question") + esc(W.howWallets) + "</button></div></div></div>"
  );
}
function render() {
  const sec = S.sec;
  if (!sec) return;
  const panel = $("[data-give-panel]");
  const label = $('[data-give="connect"] span');
  if (label) label.textContent = S.account ? (S.via === "appkit" ? W.manage : W.linked) : W.connect;
  sec.setAttribute("data-give-state", S.account ? "connected" : S.state || "idle");
  if (S.account) {
    panel.innerHTML = '<div class="arr-give-who" data-give-who>' + whoHTML() + "</div>" + (S.note ? '<p class="arr-fine">' + esc(S.note) + "</p>" : "") + bodyHTML();
    panel.hidden = false;
    if (S.wantSend) {
      S.wantSend = false;
      const amt = panel.querySelector('input[name="amount"]');
      if (amt) amt.focus();
    }
  } else if (S.state) {
    panel.innerHTML = stateHTML(S.state);
    panel.hidden = false;
  } else {
    panel.innerHTML = "";
    panel.hidden = true;
  }
}

/* ── sending, and the optional thank-you note ───────────────────────────────────────────── */
function fieldError(input, text) {
  live(text);
  if (input) {
    input.setAttribute("aria-invalid", "true");
    input.focus();
  }
}
async function doSend(f) {
  const to = address("eth");
  if (!to || !S.account) return;
  const wei = toWei(f.amount.value);
  if (!wei) return fieldError(f.amount, W.badAmount);
  f.amount.removeAttribute("aria-invalid");
  const net = (f.chain && NETS[f.chain.value]) || nets()[0];
  if (S.M && S.M.Viem && S.M.Viem.isAddress && !S.M.Viem.isAddress(to, { strict: true })) return live(fill(W.badChecksum, { org: WHO }));
  const btn = f.querySelector('[type="submit"]');
  busy(btn, true);
  btn.disabled = true;
  try {
    const hash = await walletSend(to, wei, net);
    S.lastTx = hash;
    S.lastNet = net;
    live(W.sentLive);
    const box = S.sec.querySelector("[data-give-sent]");
    const url = net.scan + "/tx/" + hash;
    box.innerHTML =
      '<div class="arr-give-block"><h3>' + icon("seal-check") + esc(W.sentTitle) + "</h3><p>" + esc(W.sentText) + ' <a href="' + esc(url) + '" rel="noopener"><code translate="no">' + esc(short(hash)) + "</code> " +
      esc(fill(W.viewTx, { scan: new URL(net.scan).host })) + "</a></p></div>";
    const claim = S.sec.querySelector("[data-give-claim]");
    if (claim) {
      claim.outerHTML = claimHTML(true);
      const nm = S.sec.querySelector('[data-give-claim] input[name="name"]');
      if (nm) nm.focus();
    }
  } catch (err) {
    live(rejected(err) ? W.declined : W.sendFailed + (reason(err) ? " (" + reason(err) + ")" : ""));
  } finally {
    busy(btn, false);
    btn.disabled = false;
  }
}
function cleanName(s) {
  return String(s || "").replace(/[\u0000-\u001f\u007f<>]/g, "").replace(/\s+/g, " ").trim().slice(0, 60);
}
function claimMessage(name, tx, net) {
  return [
    "Please thank me by name on " + location.host + location.pathname + ".",
    "",
    "Name to show: " + name,
    "My gift: transaction " + tx + " on " + net.name + " (eip155:" + net.id + ")",
    "Date: " + new Date().toISOString().slice(0, 10),
    "",
    "Signing this message is free. It sends nothing and approves nothing.",
  ].join("\n");
}
async function doClaim(f) {
  if (!S.account) return;
  const name = cleanName(f.name.value);
  if (!name) return fieldError(f.name, W.badName);
  f.name.removeAttribute("aria-invalid");
  const tx = f.tx.value.trim();
  if (!/^0x[0-9a-fA-F]{64}$/.test(tx)) return fieldError(f.tx, W.badTx);
  f.tx.removeAttribute("aria-invalid");
  const net = (f.chain && NETS[f.chain.value]) || S.lastNet || nets()[0];
  const message = claimMessage(name, tx, net);
  const btn = f.querySelector('[type="submit"]');
  busy(btn, true);
  btn.disabled = true;
  try {
    const signature = await walletSign(message);
    live("");
    const json = JSON.stringify(
      {
        entry: { name, kind: "gift", since: new Date().toISOString().slice(0, 7) },
        proof: { chain: "eip155:" + net.id, tx, address: S.account, message, signature },
        _note: "For the keepers of donate/contributors.json: check that the signature recovers to the address, and that the transaction came from it to the published address; then add only \"entry\" to the list. Keep \"proof\" private: it links a name to a wallet.",
      },
      null,
      2
    );
    const to = claimTo();
    const k = ++S.n;
    f.parentNode.querySelector("[data-give-out]").innerHTML =
      '<div class="arr-give-block"><h3>' + icon("seal-check") + esc(W.signedTitle) + "</h3><p>" + esc(fill(W.signedText, { org: WHO })) + "</p>" +
      '<label class="arr-give-field" for="arr-give-note-' + k + '">' + esc(W.yourNote) + "</label>" +
      '<textarea class="arr-snippet" id="arr-give-note-' + k + '" readonly rows="12" spellcheck="false" data-give-note>' + esc(json) + "</textarea>" +
      '<div class="arr-give-actions"><button type="button" class="arr-btn arr-btn-primary arr-shape" data-give="copy-note">' + icon("copy") + esc(W.copyNote) + "</button>" +
      (to ? '<a class="arr-btn arr-btn-quiet arr-shape" data-arr-direct href="mailto:' + esc(to) + "?subject=" + encodeURIComponent(W.emailSubject) + "&amp;body=" + encodeURIComponent(json) + '">' + icon("envelope-simple") + esc(fill(W.emailNote, { org: WHO })) + "</a>" : "") +
      "</div></div>";
    f.hidden = true;
    const tb = f.parentNode.querySelector('[data-give="claim"]');
    if (tb) tb.setAttribute("aria-expanded", "false");
    f.parentNode.querySelector("[data-give-note]").focus();
  } catch (err) {
    live(rejected(err) ? W.declinedSign : W.signFailed + (reason(err) ? " (" + reason(err) + ")" : ""));
  } finally {
    busy(btn, false);
    btn.disabled = false;
  }
}
function copyNote(btn) {
  const ta = btn.closest(".arr-give-block").querySelector("[data-give-note]");
  if (!ta) return;
  const fallback = () => {
    ta.focus();
    ta.select();
    toast(W.selectNote);
  };
  try {
    navigator.clipboard.writeText(ta.value).then(() => toast(W.noteCopied), fallback);
  } catch (e) {
    fallback();
  }
}
function toggleClaim(btn) {
  const f = doc.getElementById(btn.getAttribute("aria-controls"));
  if (!f) return;
  const open = btn.getAttribute("aria-expanded") !== "true";
  btn.setAttribute("aria-expanded", open ? "true" : "false");
  f.hidden = !open;
  if (open) f.querySelector("input").focus();
}

/* ── QR codes (only when an org has an address) ─────────────────────────────────────────── */
async function qr(btn) {
  const coin = btn.getAttribute("data-coin");
  const addr = address(coin);
  const box = doc.getElementById(btn.getAttribute("aria-controls"));
  if (!addr || !box) return;
  const label = btn.querySelector("span") || btn;
  if (btn.getAttribute("aria-expanded") === "true") {
    box.hidden = true;
    btn.setAttribute("aria-expanded", "false");
    label.textContent = W.showQr;
    return;
  }
  if (!box.firstChild) {
    busy(btn, true);
    try {
      const { encode } = await import(UQR);
      const q = encode(addr, { ecc: "M", border: 2 });
      const n = q.size;
      let d = "";
      for (let y = 0; y < n; y++) for (let x = 0; x < n; x++) if (q.data[y][x]) d += "M" + x + " " + y + "h1v1h-1z";
      box.innerHTML =
        '<figure class="arr-qr arr-shape"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ' + n + " " + n + '" shape-rendering="crispEdges" role="img" aria-label="' + esc(fill(W.qrLabel, { coin: COINS[coin].name })) + '">' +
        '<rect width="' + n + '" height="' + n + '" fill="#fff"/><path fill="#111" d="' + d + '"/></svg><figcaption>' + esc(W.qrCaption) + "</figcaption></figure>";
    } catch (e) {
      live(W.qrFailed);
      return;
    } finally {
      busy(btn, false);
    }
  }
  box.hidden = false;
  btn.setAttribute("aria-expanded", "true");
  label.textContent = W.hideQr;
}

/* ── "New to wallets?": the guide ───────────────────────────────────────────────────────── */
const WALLETS = [
  ["MetaMask", "https://metamask.io/download/"],
  ["Rainbow", "https://rainbow.me/"],
  ["Trust Wallet", "https://trustwallet.com/"],
  ["Rabby", "https://rabby.io/"],
  ["Brave Wallet", "https://brave.com/wallet/"],
];
function learnHTML() {
  const part = (ic, h, p) => "<section><h3>" + icon(ic) + esc(h) + "</h3><p>" + p + "</p></section>";
  return (
    '<div data-give-notice hidden></div>' +
    part("wallet", "What a wallet is", "A crypto wallet is an app that holds the keys to your coins. A website never gets those keys. When a page like this one asks for something (to see your address, or to send a gift), your wallet shows you exactly what's being asked and waits for you to approve or decline.") +
    part("browser", "Browser wallets and phone wallets", "Some wallets live in your browser as an extension (MetaMask, Rabby, Brave's built-in wallet) and work in Chrome, Firefox, Brave and Edge. Others are apps on your phone (MetaMask, Rainbow, Trust Wallet and many more). Either kind works here.") +
    part("compass", "Why Safari can't use a browser wallet", "A wallet extension works by adding a small connector to every page you open, which the page then talks to. Safari doesn't let extensions add that connector, on a Mac or on an iPhone, so a browser wallet can't reach a page there. That's Apple's choice, not a fault in your wallet or in this page.") +
    part("device-mobile", "Use your phone wallet instead", "On a computer, choose <strong>Connect a wallet</strong>, then WalletConnect or your wallet's name: a QR code appears. Scan it with your phone wallet's own scanner (not the camera app) and approve on your phone. On a phone, pick your wallet from the list and it opens for you, or open this page inside your wallet app's own browser.") +
    part("shield-check", "Staying safe", "Connecting only shows this page your public address. Nothing moves until you approve it in your wallet, which shows the amount and the network fee first. No one from " + esc(WHO) + " will ever ask for your recovery phrase (the 12 or 24 words); anyone who does isn't us.") +
    "<section><h3>" + icon("arrow-square-out") + "Getting a wallet</h3><p>From their makers' own sites:</p>" +
    '<ul class="arr-learn-links">' + WALLETS.map((w) => '<li><a class="arr-btn arr-btn-quiet arr-shape" href="' + w[1] + '" rel="noopener">' + esc(w[0]) + "</a></li>").join("") + "</ul></section>" +
    '<div class="arr-give-actions">' +
    // Handled here, not by the kit's [data-give] router, so the guide works on any page (the pledge's too).
    '<button type="button" class="arr-btn arr-btn-primary arr-shape" data-give-learn="connect">' + icon("plugs-connected") + esc(W.connect) + "</button>" +
    '<button type="button" class="arr-btn arr-btn-quiet arr-shape" data-arr-close>' + esc(W.close) + "</button></div>"
  );
}
// opts (v1.4, for modules sharing the guide): eyebrow (its small heading), onConnect (what its
// Connect button does; default: the give section's connect).
function learn(kind, opts) {
  if (!KIT.dialog) return;
  opts = opts || {};
  if (!S.learn) {
    S.learn = KIT.dialog({ cls: "arr-learn", title: W.learnTitle, eyebrow: W.learnEyebrow, html: learnHTML() });
    S.learn.el.addEventListener("click", (e) => {
      const b = e.target.closest && e.target.closest('[data-give-learn="connect"]');
      if (!b) return;
      e.preventDefault();
      S.learn.hide();
      (S.learnConnect || connect)();
    });
  }
  S.learnKind = kind || null;
  S.learnConnect = opts.onConnect || null;
  const el = S.learn.el;
  const eb = el.querySelector(".arr-eyebrow");
  if (eb) eb.textContent = (ORG.short ? ORG.short + " · " : "") + (opts.eyebrow || W.learnEyebrow);
  const box = el.querySelector("[data-give-notice]");
  const t = { off: [W.offTitle, W.offText], origin: [W.originTitle, fill(W.originText, { host: location.host })], load: [W.loadTitle, W.loadText] }[kind];
  box.hidden = !t;
  box.innerHTML = t ? '<p class="arr-notice">' + icon("info") + "<span><strong>" + esc(t[0]) + ".</strong> " + esc(t[1]) + "</span></p>" : "";
  // Connecting from the guide only when it could work.
  el.querySelector('[data-give-learn="connect"]').hidden = kind === "off" || kind === "origin";
  S.learn.show();
}

/* ── the kit calls these ─────────────────────────────────────────────────────────────────── */
function init(sec) {
  if (!sec || sec._give) return;
  sec._give = true;
  S.sec = S.sec || sec;
  sec.addEventListener("submit", (e) => {
    const f = e.target.closest && e.target.closest("form[data-give-form]");
    if (!f) return;
    e.preventDefault();
    if (f.getAttribute("data-give-form") === "send") doSend(f);
    else doClaim(f);
  });
}
async function act(name, el, sec) {
  init(sec);
  if (el && el.closest("dialog") && S.learn) S.learn.hide();
  if (name === "connect") return connect();
  if (name === "retry") {
    S.state = null;
    S.allowed = undefined;
    render();
    return connect();
  }
  if (name === "learn") return learn(S.account ? null : S.state);
  if (name === "disconnect") return disconnect();
  if (name === "qr") return qr(el);
  if (name === "send") {
    if (S.account) {
      const amt = S.sec.querySelector('input[name="amount"]');
      if (amt) amt.focus();
      return;
    }
    S.wantSend = true;
    return connect();
  }
  if (name === "claim") return toggleClaim(el);
  if (name === "copy-note") return copyNote(el);
}

// v1.4: the wallet layer, for modules beside this one (pledge/pledge.js). One AppKit per page.
const wallet = {
  allowed: originAllowed, // (projectId) → true | false | null (couldn't tell)
  load: appkit, // (projectId, { description }) → the page's AppKit (created once, by whoever asks first)
  injected, // → window.ethereum, or null
  connectBrowser, // → the account, from the browser's own wallet
  sign: walletSign, // (message) → an EIP-191 signature from the connected wallet
  disconnect,
  state: walletState, // → { account, via: "appkit" | "injected" | "", wallet, chainId, blocked }
  on: (fn) => subs.push(fn), // fn(state) on every change of account
  learn, // (kind?, { eyebrow, onConnect }) the "New to wallets?" guide
};

window.ArrivalGive = { init, act, wallet, version: "1.4.0", appkit: APPKIT_VERSION };
