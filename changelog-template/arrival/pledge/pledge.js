/*! Arrival kit v1.4 · a pledge of support · https://github.com/drasticstatic/my-template (changelog-template/arrival/pledge)
 *
 * The same file in every org, beside arrival.js (served as /arrival/pledge/pledge.js). Tailor it
 * through org.js (window.ARRIVAL.pledge), never by editing this file:
 *
 *   pledge: {
 *     enabled: true,                 // false: <arrival-pledge> draws nothing
 *     text: "I support …",           // the pledge, in plain words (what the wallet signs)
 *     note: "…",                     // the org's own words, after the fine print
 *     href: "https://<org>.github.io/pledge/",   // the page it lives on (so "/" search finds it)
 *     reownProjectId: "…",           // default: give.reownProjectId (one shared project today)
 *     tokens: false | { title, text, href, label },   // the "Gratitude tokens (coming)" card
 *     bots: false | { title, points: ["…"] },          // "How you'll know these aren't bots"
 *     verify: false,                 // hides the "verify a signature" tool
 *     words: { … },                  // any string below, or arrival.js's PW strings
 *   }
 *
 * What it does (arrival.js draws everything first; this file loads when the pledge nears the screen,
 * and talks to nobody until the visitor clicks):
 *   Connect a wallet   give/give.js's wallet layer: the Reown project's allowlist is checked for this
 *                      site, then AppKit loads and opens (browser wallets, phone wallets by QR code,
 *                      email sign-in). Not on the allowlist, or no project: the browser's own wallet
 *                      if there is one, else a calm "isn't switched on for this site yet" and the guide.
 *   Sign the pledge    an EIP-191 message signature (personal_sign): no gas, no contract, no money.
 *                      It's checked here against the connected wallet, then forgotten. Nothing is
 *                      sent, nothing is saved, and the page never shows the wallet's address. The
 *                      visitor can copy their signed pledge (message, address, signature) to keep.
 *   Verify a signature paste an address, a message and a signature: the signer is recovered here
 *                      (secp256k1 + keccak-256 from @noble, pinned, loaded on first use) and compared.
 *                      Plain wallets only: a smart-contract wallet (a Safe) signs differently.
 *   No counts, ever    until pledges are published as records anyone can verify (see the page).
 */
const CURVES = "https://cdn.jsdelivr.net/npm/@noble/curves@1.9.7/secp256k1/+esm"; // MIT, audited, 2025-08-15
const HASHES = "https://cdn.jsdelivr.net/npm/@noble/hashes@1.8.0/sha3/+esm"; // MIT, audited, 2025-04-21
const V = new URL(import.meta.url).search; // "?v=<kit version>": give.js is imported the same way arrival.js loads it

const doc = document;
const C = window.ARRIVAL || {};
const P = C.pledge || {};
const ORG = C.org || {};
const WHO = ORG.name || ORG.short || "this organization";
const KIT = window.Arrival || {};

const W = Object.assign(
  {
    title: "A pledge of support",
    connect: "Connect a wallet",
    manage: "Manage the connection",
    linked: "Wallet connected",
    checking: "Checking that wallet connect is switched on for this site…",
    opening: "Opening the wallet window…",
    asking: "Asking the wallet in your browser…",
    connected: "A wallet is connected{wallet}. Its address stays in your wallet: this page doesn't show it or keep it.",
    connectedLive: "Connected{wallet}. You can sign the pledge now.",
    injectedNote: "This used the wallet in your browser. To disconnect, use your wallet's list of connected sites.",
    disconnected: "Disconnected.",
    declinedConnect: "You declined in your wallet. Nothing was shared.",
    walletFailed: "Your browser wallet didn't answer. Try again, or use a phone wallet.",
    offTitle: "Wallet connect isn't set up for this site yet",
    offText: "There's no wallet-connect project for this page yet, so signing from here won't work today. Nothing is wrong with your wallet or your browser.",
    originTitle: "Wallet connect isn't switched on for this site yet",
    originText: "Nothing is wrong with your wallet or your browser. Connecting wallets goes through a service that only works on sites its owner has listed, and {host} isn't on that list yet. It's a setting on our side.",
    loadTitle: "The wallet window couldn't open",
    loadText: "Something stopped it loading: a content blocker, a strict privacy setting or a weak connection. Nothing was sent.",
    tryAgain: "Try again",
    howWallets: "How wallets work",
    signApprove: "Waiting for you to sign in your wallet…",
    signedTitle: "Signed, and checked. Thank you.",
    signedText: "The signature matches your wallet. It stayed in this tab: nothing was sent anywhere, and nothing was recorded.",
    copy: "Copy my signed pledge",
    copied: "Copied. It includes your wallet's public address, so share it only if you'd like to.",
    selectIt: "Your browser wouldn't copy it. Nothing was shared.",
    again: "Start over",
    mismatch: "Your wallet returned a signature this page couldn't match to it. Smart-contract wallets (a Safe, for example) sign differently. Nothing was recorded.",
    declined: "You chose not to sign. Nothing happened, and nothing was recorded.",
    signFailed: "The wallet couldn't sign just now. Nothing was recorded, and you can try again.",
    checkFailed: "The signature couldn't be checked here just now (the checker didn't load). Nothing was recorded.",
    // the verify tool
    badAddress: "That doesn't look like a wallet address: 0x and 40 more letters and numbers.",
    badChecksum: "That address's capital letters don't match its built-in checksum, so a character may be mistyped. Checking it anyway, ignoring case.",
    badSig: "That doesn't look like a signature: 0x and 130 more letters and numbers.",
    noMessage: "Paste the message, exactly as it was signed.",
    verifying: "Checking…",
    valid: "Valid. The wallet at that address signed this exact message.",
    validTrim: "Valid, once the blank space at the start or end of the message is taken off. The wallet at that address signed it.",
    invalid: "Doesn't match. That address didn't sign this exact message with this signature. Check every line, space and character. (Smart-contract wallets sign differently and can't be checked here.)",
    verifyFailed: "The checker couldn't load. Check your connection, then try again.",
    eyebrow: "A pledge of support",
  },
  P.words || {}
);

/* ── helpers ─────────────────────────────────────────────────────────────────────────────── */
const esc = (s) => String(s == null ? "" : s).replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c]);
const icon = (n) => '<i class="ph ph-' + esc(n) + '" aria-hidden="true"></i>';
const fill = (s, o) => String(s).replace(/\{(\w+)\}/g, (m, k) => (o && o[k] != null ? o[k] : m));
const toast = (t) => (KIT.toast ? KIT.toast(t) : null);
const rejected = (e) => !!e && (e.code === 4001 || e.name === "UserRejectedRequestError" || /reject|denied|declined|cancel/i.test(String(e.shortMessage || e.message || "")));
const enc = (s) => new TextEncoder().encode(s);
const hex = (b) => Array.from(b, (x) => x.toString(16).padStart(2, "0")).join("");
function unhex(s) {
  s = String(s || "").trim().replace(/^0x/i, "");
  if (!s || s.length % 2 || /[^0-9a-f]/i.test(s)) return null;
  const out = new Uint8Array(s.length / 2);
  for (let i = 0; i < out.length; i++) out[i] = parseInt(s.substr(i * 2, 2), 16);
  return out;
}
function concat(a, b) {
  const out = new Uint8Array(a.length + b.length);
  out.set(a, 0);
  out.set(b, a.length);
  return out;
}

/* ── signatures, checked here (EIP-191 personal_sign, recovered with @noble) ──────────────── */
let nobleP = null;
function noble() {
  if (!nobleP) {
    nobleP = Promise.all([import(CURVES), import(HASHES)]).then(([c, h]) => ({ secp: c.secp256k1, keccak: h.keccak_256 }));
    nobleP.catch(() => (nobleP = null));
  }
  return nobleP;
}
// The address that signed `message` (as personal_sign hashes it), from a 65-byte signature (r, s,
// v as 27/28 or 0/1) or a 64-byte EIP-2098 compact one. Throws on a malformed signature.
async function recover(message, signature) {
  const { secp, keccak } = await noble();
  const sig = unhex(signature);
  if (!sig || (sig.length !== 65 && sig.length !== 64)) throw new Error("shape");
  let rs = sig.slice(0, 64);
  let v;
  if (sig.length === 65) {
    v = sig[64];
    if (v >= 27) v -= 27;
  } else {
    v = rs[32] >> 7;
    rs[32] &= 0x7f;
  }
  if (v !== 0 && v !== 1) throw new Error("v");
  const m = enc(message);
  const digest = keccak(concat(enc("\x19Ethereum Signed Message:\n" + m.length), m));
  const pub = secp.Signature.fromCompact(rs).addRecoveryBit(v).recoverPublicKey(digest).toRawBytes(false);
  return "0x" + hex(keccak(pub.slice(1)).slice(-20));
}
// EIP-55: a mixed-case address carries a checksum in its capitals.
async function checksumOk(addr) {
  const body = addr.slice(2);
  if (body === body.toLowerCase() || body === body.toUpperCase()) return true;
  const { keccak } = await noble();
  const h = hex(keccak(enc(body.toLowerCase())));
  for (let i = 0; i < 40; i++) {
    const c = body[i];
    if (/[a-f]/i.test(c) && (parseInt(h[i], 16) >= 8) !== (c === c.toUpperCase())) return false;
  }
  return true;
}

/* ── the wallet layer: give/give.js's (one AppKit per page) ──────────────────────────────── */
let walletP = null;
function wallet() {
  if (window.ArrivalGive && window.ArrivalGive.wallet) return Promise.resolve(window.ArrivalGive.wallet);
  if (!walletP) {
    walletP = import(new URL("../give/give.js" + V, import.meta.url).href).then(() => {
      const w = window.ArrivalGive && window.ArrivalGive.wallet;
      if (!w) throw new Error("give.js has no wallet layer");
      return w;
    });
    walletP.catch(() => (walletP = null));
  }
  return walletP;
}
const projectId = () => String(P.reownProjectId || (C.give && C.give.reownProjectId) || "").trim();

/* ── state ───────────────────────────────────────────────────────────────────────────────── */
const S = { root: null, sec: null, w: null, account: null, via: "", wallet: "", state: null, note: "", signed: null, result: "" };
const $ = (sel) => S.root && S.root.querySelector(sel);
function live(t) {
  const el = $("[data-pledge-live]");
  if (el) el.textContent = t || "";
}
function busy(el, on) {
  if (el) el.setAttribute("aria-busy", on ? "true" : "false");
}
async function ready() {
  if (S.w) return S.w;
  const w = await wallet();
  if (!S.w) {
    S.w = w;
    w.on(onWallet);
    onWallet(w.state());
  }
  return w;
}
function onWallet(st) {
  const was = S.account;
  S.account = st.account || null;
  S.via = st.via || "";
  S.wallet = st.wallet || "";
  if (S.account) S.state = null;
  else if (st.blocked && S.state !== "origin" && S.via !== "injected") S.state = "origin";
  if (S.account !== was) {
    S.signed = null;
    S.result = "";
    if (S.account) live(fill(W.connectedLive, { wallet: S.wallet ? " to " + S.wallet : "" }));
    else if (was) live(W.disconnected);
  }
  render();
}

/* ── connecting ──────────────────────────────────────────────────────────────────────────── */
async function connect() {
  const btn = $('[data-pledge="connect"]');
  let w;
  try {
    w = await ready();
  } catch (e) {
    return show("load");
  }
  if (S.account) {
    if (S.via === "appkit") {
      try {
        (await w.load(projectId())).open();
      } catch (e) {}
    }
    return;
  }
  busy(btn, true);
  try {
    const pid = projectId();
    if (!pid) return await unavailable(w, "off");
    live(W.checking);
    const ok = await w.allowed(pid);
    if (ok === false) return await unavailable(w, "origin");
    live(W.opening);
    let kit;
    try {
      kit = await w.load(pid, { description: "Sign a pledge of support for " + WHO });
    } catch (e) {
      return await unavailable(w, "load");
    }
    if (w.state().blocked) return await unavailable(w, "origin");
    live("");
    if (!w.state().account) await kit.open();
  } finally {
    busy(btn, false);
  }
}
async function unavailable(w, kind) {
  live("");
  if (w.injected()) {
    try {
      live(W.asking);
      await w.connectBrowser();
      S.note = W.injectedNote;
      render();
      return;
    } catch (err) {
      S.state = kind;
      render();
      return live(rejected(err) ? W.declinedConnect : W.walletFailed);
    }
  }
  show(kind);
}
function show(kind) {
  S.state = kind;
  render();
  learn(kind);
}
async function learn(kind) {
  try {
    const w = await ready();
    w.learn(S.account ? null : kind || S.state, { eyebrow: W.eyebrow, onConnect: () => connect() });
  } catch (e) {
    live(W.loadText);
  }
}

/* ── signing ─────────────────────────────────────────────────────────────────────────────── */
function pledgeText() {
  const el = $("[data-pledge-text]");
  return (el ? el.textContent : P.text || "").trim();
}
function pledgeMessage() {
  return [
    WHO + ": a pledge of support",
    "",
    pledgeText(),
    "",
    "Signed on " + location.host + ", " + new Date().toISOString().slice(0, 10) + ".",
    "Signing this is free. It sends nothing and approves nothing, and for now nothing is recorded.",
  ].join("\n");
}
async function sign() {
  const btn = $('[data-pledge="sign"]');
  if (!S.account || !S.w) return;
  const message = pledgeMessage();
  busy(btn, true);
  btn.disabled = true;
  S.signed = null;
  S.result = "";
  try {
    live(W.signApprove);
    const signature = await S.w.sign(message);
    const address = S.account;
    let got = "";
    try {
      got = await recover(message, signature);
    } catch (e) {
      S.result = "unchecked";
    }
    if (got) S.result = got.toLowerCase() === String(address).toLowerCase() ? "ok" : "mismatch";
    // Kept only in this tab, only for "Copy my signed pledge", and gone on Start over or reload.
    if (S.result === "ok") S.signed = { message, address, signature };
    live(S.result === "ok" ? W.signedTitle : S.result === "mismatch" ? W.mismatch : W.checkFailed);
  } catch (err) {
    S.result = rejected(err) ? "declined" : "failed";
    live(S.result === "declined" ? W.declined : W.signFailed);
  } finally {
    busy(btn, false);
    render();
  }
}
function copySigned() {
  if (!S.signed) return;
  const note = JSON.stringify(
    {
      pledge: S.signed.message,
      address: S.signed.address,
      signature: S.signed.signature,
      standard: "EIP-191 personal_sign",
      verify: location.origin + location.pathname + "#verify-signature",
    },
    null,
    2
  );
  try {
    navigator.clipboard.writeText(note).then(() => toast(W.copied), () => toast(W.selectIt));
  } catch (e) {
    toast(W.selectIt);
  }
}
function startOver() {
  S.signed = null;
  S.result = "";
  live("");
  render();
  const b = $('[data-pledge="sign"]');
  if (b && !b.disabled) b.focus();
}

/* ── the page: steps, the panel under them ───────────────────────────────────────────────── */
function stateHTML(kind) {
  const t = { off: [W.offTitle, W.offText], origin: [W.originTitle, fill(W.originText, { host: location.host })], load: [W.loadTitle, W.loadText] }[kind] || [W.loadTitle, W.loadText];
  return (
    '<div class="arr-give-state">' + icon(kind === "load" ? "plug" : "info") + "<div><h3>" + esc(t[0]) + "</h3><p>" + esc(t[1]) + "</p>" +
    '<div class="arr-give-actions">' +
    (kind === "load" ? '<button type="button" class="arr-btn arr-btn-quiet arr-shape" data-pledge="retry">' + icon("arrow-clockwise") + esc(W.tryAgain) + "</button>" : "") +
    '<button type="button" class="arr-btn arr-btn-quiet arr-shape" data-pledge="learn">' + icon("question") + esc(W.howWallets) + "</button></div></div></div>"
  );
}
function doneStep(k, on) {
  const li = $('[data-pledge-step="' + k + '"]');
  if (!li) return;
  li.classList.toggle("is-done", !!on);
  const sr = li.querySelector("[data-pledge-done]");
  if (sr) sr.hidden = !on;
}
function render() {
  if (!S.root) return;
  const connected = !!S.account;
  doneStep("connect", connected);
  doneStep("sign", S.result === "ok");
  const cbtn = $('[data-pledge="connect"]');
  if (cbtn) {
    const label = cbtn.querySelector("span");
    if (label) label.textContent = connected ? (S.via === "appkit" ? W.manage : W.linked) : W.connect;
    cbtn.classList.toggle("arr-btn-primary", !connected);
    cbtn.classList.toggle("arr-btn-quiet", connected);
  }
  const ctext = $('[data-pledge-step="connect"] .arr-pledge-body > p');
  if (ctext) {
    if (!ctext._orig) ctext._orig = ctext.textContent;
    ctext.textContent = connected ? fill(W.connected, { wallet: S.wallet ? " (" + S.wallet + ")" : "" }) + (S.via === "injected" && S.note ? " " + S.note : "") : ctext._orig;
  }
  const sbtn = $('[data-pledge="sign"]');
  if (sbtn) sbtn.disabled = !connected;
  const panel = $("[data-pledge-panel]");
  if (!panel) return;
  if (S.result === "ok") {
    panel.innerHTML =
      '<div class="arr-pledge-done"><h3>' + icon("seal-check") + esc(W.signedTitle) + "</h3><p>" + esc(W.signedText) + "</p>" +
      '<div class="arr-give-actions"><button type="button" class="arr-btn arr-btn-quiet arr-shape" data-pledge="copy">' + icon("copy") + esc(W.copy) + "</button>" +
      '<button type="button" class="arr-btn arr-btn-quiet arr-shape" data-pledge="again">' + icon("arrow-counter-clockwise") + esc(W.again) + "</button></div></div>";
    panel.hidden = false;
  } else if (!connected && S.state) {
    panel.innerHTML = stateHTML(S.state);
    panel.hidden = false;
  } else {
    panel.innerHTML = "";
    panel.hidden = true;
  }
}

/* ── the verify tool ─────────────────────────────────────────────────────────────────────── */
function result(form, state, text) {
  const out = form.querySelector("[data-pledge-result]");
  if (!out) return;
  out.setAttribute("data-state", state);
  out.innerHTML = icon(state === "ok" ? "check-circle" : state === "bad" ? "x-circle" : state === "warn" ? "warning-circle" : "hourglass-medium") + "<span>" + esc(text) + "</span>";
}
function invalid(form, input, text) {
  if (input) {
    input.setAttribute("aria-invalid", "true");
    input.focus();
  }
  result(form, "warn", text);
}
async function verify(form) {
  if (!form) return;
  const f = form.elements;
  ["address", "signature", "message"].forEach((k) => f[k] && f[k].removeAttribute("aria-invalid"));
  const addr = String(f.address.value || "").trim();
  const sig = String(f.signature.value || "").trim();
  const msg = String(f.message.value || "").replace(/\r\n?/g, "\n");
  if (!/^0x[0-9a-fA-F]{40}$/.test(addr)) return invalid(form, f.address, W.badAddress);
  const s = unhex(sig);
  if (!/^0x/i.test(sig) || !s || (s.length !== 65 && s.length !== 64)) return invalid(form, f.signature, W.badSig);
  if (!msg.trim()) return invalid(form, f.message, W.noMessage);
  result(form, "busy", W.verifying);
  try {
    const caseOk = await checksumOk(addr);
    const want = addr.toLowerCase();
    let got = "";
    try {
      got = await recover(msg, sig);
    } catch (e) {
      return invalid(form, f.signature, W.badSig);
    }
    let state = got === want ? "ok" : "bad";
    let text = got === want ? W.valid : W.invalid;
    if (state === "bad" && msg.trim() !== msg) {
      let got2 = "";
      try {
        got2 = await recover(msg.trim(), sig);
      } catch (e) {}
      if (got2 === want) {
        state = "ok";
        text = W.validTrim;
      }
    }
    result(form, state, (caseOk ? "" : W.badChecksum + " ") + text);
  } catch (e) {
    result(form, "warn", W.verifyFailed);
  }
}

/* ── the kit calls these ─────────────────────────────────────────────────────────────────── */
function init(root) {
  if (!root || root._pledge) return;
  root._pledge = true;
  S.root = S.root || root;
  S.sec = root.querySelector("[data-arr-pledge]");
}
async function act(name, el, root) {
  init(root);
  if (name === "connect") return connect();
  if (name === "retry") {
    S.state = null;
    render();
    return connect();
  }
  if (name === "learn") return learn(S.state);
  if (name === "sign") return sign();
  if (name === "copy") return copySigned();
  if (name === "again") return startOver();
  if (name === "verify") return verify(el && el.closest ? el.closest("form") || el : null);
}

window.ArrivalPledge = { init, act, recover, version: "1.4.0" };
