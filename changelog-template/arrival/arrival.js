/*! Arrival kit v1 · core script · https://github.com/drasticstatic/my-template (changelog-template/arrival)
 *
 * The same file in every org. Tailor it through org.js (window.ARRIVAL) and org.css, not by editing
 * this file, so a fix here can be copied to every org unchanged.
 *
 * Load it in <head>, after org.js, so the visitor's choices apply before the first paint:
 *   <link rel="stylesheet" href="https://<org>.github.io/arrival/arrival.css">
 *   <link rel="stylesheet" href="https://<org>.github.io/arrival/org.css">
 *   <script src="https://<org>.github.io/arrival/org.js"></script>
 *   <script src="https://<org>.github.io/arrival/arrival.js"></script>
 * and name the page's site: <html data-arrival-site="portal">  (a key of ARRIVAL.sites).
 *
 * What a page gets:
 *   <html data-light data-theme data-motion data-contrast>, remembered in localStorage. Every read
 *     and write is wrapped in try/catch; with storage blocked, the defaults apply and the splash is
 *     skipped (there would be no way to remember the answer).
 *   <arrival-controls>   search button, minimalist light swatches + motion toggle, and the dropdown
 *                        drawer (light, motion, contrast, a link to the welcome guide)
 *   first-visit splash    "Choose how you arrive". Off for a page with data-arrival-splash="off".
 *   welcome guide         the onboarding panel. Opens from the drawer, "?", #welcome, or any
 *                         [data-arrival-open="guide"] element.
 *   "/" or Ctrl/⌘ K       quick search over ARRIVAL.search.sources (search.json files) plus links
 *                         and actions. [data-arrival-open="search"] opens it too.
 *   [data-arrival-open="copy"]  copies the page's link and says it shares with its own card.
 *   <arrival-avatar name github email size>   GitHub picture, else Gravatar for an org-domain role
 *                         address only, else the org's initials SVG
 *   <arrival-people>, <arrival-latest limit>  rendered from the search.json people and entries
 *   window.Arrival        { get, set, open, close, index, initials, reading(on?), news(), version }
 *   <html data-cursor="on|off">: cursor effects (the kit's trail; sites key their own pointer effects
 *                        on it). Off when the visitor turns them off or motion is still.
 *   window "arrival:change" event whenever a choice changes
 *
 * Wave 5 (v1.1, 2026-10-12), all additive; an org.js written for v1.0 keeps working unchanged:
 *   Reading mode          one tap for the calmest page: ARRIVAL.reading.light (or the first mode
 *                         marked calm: true), still motion, more contrast, cursor effects off. Tap
 *                         again to restore what the visitor had. Persisted; <html data-reading="on|off">.
 *                         Any other change while it's on simply leaves reading mode. ARRIVAL.reading
 *                         = false hides it.
 *   What's new            on a return visit, a quiet count in the header of entries, write-ups and
 *                         ledger items newer than the last visit (ARRIVAL.news.sources, e.g. the
 *                         AstroLog's latest.json; default: the search sources). Matching links on
 *                         the page get data-arr-new (and fill any [data-arr-new-tag] slot inside).
 *                         Opening the count, or the new page itself, clears it. First visits show
 *                         nothing. ARRIVAL.news = false hides it.
 *   record.ledger         a third box in the guide's "Changelog and library" step.
 *
 * Wave 6 (v1.2, 2026-10-13), the interface half; additive again, so a v1.1 org.js keeps working:
 *   <arrival-nav>         the page's navbar, from ARRIVAL.nav: links and dropdown groups, every one
 *                         with an icon. When the bar runs out of room, items fold into a "More"
 *                         dropdown (lowest priority first), so it never wraps; below nav.fold (1100px)
 *                         the whole bar folds into a Menu button and panel. Keyboard: arrows inside
 *                         a dropdown, Esc closes and returns focus. <html data-arr-nav="bar|menu">.
 *   <arrival-footer>      link groups (ARRIVAL.footer.groups, or derived from the nav), icon on every
 *                         link: e.g. Explore, Get involved, About this build (roadmap, sustainability).
 *   Contact modal         one dialog listing every way to reach the org (ARRIVAL.contact.paths: a
 *                         form, a CONTACTS.md, role emails; placeholders say so). Opens from any
 *                         [data-arrival-open="contact"], and any link to one of those paths.
 *   Community modal       every platform the org has (ARRIVAL.community.platforms), each with a public
 *                         link and a sign-up link, "coming soon" for placeholders, plus a sneak-peek
 *                         card for the bespoke network (community.bespoke). [data-arrival-open="community"].
 *   What's new, louder    a filled, counted pill with a gentle halo (none when motion is still or in
 *                         reading mode), a one-time tip under it, a count on the Menu button and a
 *                         row at the top of the Menu.
 *   Reading, round 2      text size steps (ARRIVAL.reading.sizes) and a comfortable line length,
 *                         in the drawer, the guide and "/" search. <html data-text data-measure>.
 *   <arrival-donate>      the donate page body from ARRIVAL.donate: giving paths, a disclaimer slot,
 *                         an opt-in contribution ledger (a JSON file) and an empty "crypto, coming
 *                         soon" slot ([data-arr-wallet-slot]) for a later wallet module.
 *   <arrival-map src>     the site map from a map.json (version 2): every destination as a card with
 *                         its share image as the thumbnail, grouped, "You are here" on this site.
 */
(function () {
  "use strict";
  if (window.Arrival) return;

  var VERSION = "1.2.0";
  var C = window.ARRIVAL || {};
  var doc = document;
  var root = doc.documentElement;
  var siteId = root.getAttribute("data-arrival-site") || "site";
  var site = assign({}, (C.sites || {})[siteId] || {}, window.ARRIVAL_SITE || {});
  var org = C.org || {};

  var W = assign(
    {
      arrive: "Choose how you arrive",
      intro:
        "Pick a light, how much movement you'd like, and how much contrast. Change any of it later from the light and motion controls in the header.",
      enter: "Enter",
      tour: "Take the tour",
      saved: "Saved in this browser only.",
      light: "Light",
      motion: "Motion",
      contrast: "Contrast",
      moreContrast: "More contrast",
      contrastNote: "Stronger text and edges, and a quieter background behind the words.",
      pause: "Pause the motion",
      play: "Let it move",
      search: "Search",
      searchPlaceholder: "Search changes, write-ups, people and pages",
      searchTip: "Anywhere, any time: every change, write-up, person and page.",
      drawer: "Light & motion",
      guide: "Welcome guide",
      openGuide: "Open the welcome guide",
      searchAll: "Search everything",
      reduced: "Your device asks for less motion, so Still is selected. You can still choose more.",
      moreAsked: "Your device asks for more contrast, so it's switched on.",
      nothing: "Nothing matches yet. Try a month, a name, or the word light.",
      followNow: "Right now",
      copied: "Link copied. It shares with its own preview card.",
      cursor: "Cursor effects",
      cursorNote: "A trail of light behind your pointer, and ink that stirs as you move. Off for anyone who'd rather not.",
      cursorOn: "Turn cursor effects off",
      cursorOff: "Turn cursor effects on",
      reading: "Reading mode",
      readingNote: "One tap for the calmest page: the {light} light, nothing moving, more contrast, and no cursor effects. Tap again to go back to how you had it.",
      readingOn: "Leave reading mode",
      readingOff: "Reading mode",
      readEnter: "Just let me read",
      newSince: "New since your last visit",
      newBadge: "new",
      newTag: "New",
      newsGuide: "Coming back? A bright count in the header shows what's new since your last visit, and new things are marked where they appear. Opening it clears it.",
      newsTip: "{n} new since your last visit. Take a look",
      ledger: "The ledger",
      // v1.2
      menu: "Menu",
      menuClose: "Close",
      more: "More",
      menuMain: "Pages",
      nav: "Site",
      footer: "More ways around",
      textSize: "Text size",
      measure: "Comfortable line length",
      measureNote: "Shorter lines of text, with a little more room between them.",
      contact: "Reach out",
      contactIntro: "Every way to reach the people behind these pages. Pick whichever suits you.",
      community: "Where we gather",
      communityIntro: "Every place the community talks. Each one has a public link anyone can open, and a way to sign up.",
      publicLink: "Public link",
      joinLink: "Sign up",
      soon: "Coming soon",
      sneak: "Sneak peek",
      close: "Close",
      copyAddress: "Copy address",
      addressCopied: "Address copied.",
      writeEmail: "Write an email",
      openLink: "Open",
      youAreHere: "You are here",
      mapLoading: "Drawing the map…",
    },
    C.words || {}
  );

  var MODES = C.modes && C.modes.length ? C.modes : [
    { id: "dark", name: "Dark", swatch: ["#111318", "#8ab4ff"], dark: true },
    { id: "light", name: "Light", swatch: ["#ffffff", "#2f5bd3"] },
  ];
  var MOTIONS = C.motions && C.motions.length ? C.motions : [
    { id: "still", name: "Still", note: "Nothing moves." },
    { id: "gentle", name: "Gentle", note: "Slow, soft movement." },
  ];
  var STILL = C.stillMotion || "still";
  var hasContrast = C.contrast !== false;
  var hasCursor = C.cursor !== false; // the cursor-effects switch (trail + anything a site keys on data-cursor)
  var hasReading = C.reading !== false; // the one-tap reading-mode preset
  var RD = C.reading && typeof C.reading === "object" ? C.reading : {};
  // Reading, round 2 (v1.2): text size steps (a scale on the root font size, so every rem grows) and
  // a comfortable line length. Both are settings of their own, kept beside the reading switch.
  var SIZES = RD.sizes && RD.sizes.length ? RD.sizes : [
    { id: "standard", name: "Standard", scale: 1 },
    { id: "large", name: "Large", scale: 1.125 },
    { id: "larger", name: "Larger", scale: 1.25 },
    { id: "largest", name: "Largest", scale: 1.4 },
  ];
  var hasMeasure = hasReading && RD.measure !== false;

  /* ── helpers ───────────────────────────────────────────────────────────────────────────── */
  function assign(t) {
    for (var i = 1; i < arguments.length; i++) {
      var s = arguments[i];
      if (s) for (var k in s) if (Object.prototype.hasOwnProperty.call(s, k)) t[k] = s[k];
    }
    return t;
  }
  function byId(list, id) {
    for (var i = 0; i < list.length; i++) if (list[i].id === id) return list[i];
    return null;
  }
  function esc(s) {
    return String(s == null ? "" : s).replace(/[&<>"']/g, function (c) {
      return { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c];
    });
  }
  function media(q) {
    try {
      return !!(window.matchMedia && window.matchMedia(q).matches);
    } catch (e) {
      return false;
    }
  }
  function icon(name) {
    return '<i class="ph ph-' + esc(name) + '" aria-hidden="true"></i>';
  }
  function fmtDate(d, long) {
    if (!d) return "";
    try {
      return new Date(d + "T12:00:00Z").toLocaleDateString("en-US", { year: "numeric", month: long ? "long" : "short", day: "numeric", timeZone: "UTC" });
    } catch (e) {
      return d;
    }
  }
  function emit(name, detail) {
    try {
      window.dispatchEvent(new CustomEvent(name, { detail: detail }));
    } catch (e) {}
  }
  function idle(fn) {
    if (window.requestIdleCallback) window.requestIdleCallback(fn, { timeout: 2500 });
    else setTimeout(fn, 1200);
  }

  /* ── storage: every access guarded ─────────────────────────────────────────────────────── */
  var S = C.storage || {};
  var KEY = S.key || "arrival";
  var store = {
    ok: (function () {
      try {
        var t = "__arrival__";
        localStorage.setItem(t, "1");
        localStorage.removeItem(t);
        return true;
      } catch (e) {
        return false;
      }
    })(),
    get: function (k) {
      try {
        return localStorage.getItem(k);
      } catch (e) {
        return null;
      }
    },
    set: function (k, v) {
      try {
        localStorage.setItem(k, v);
        return true;
      } catch (e) {
        return false;
      }
    },
  };

  /* ── state ─────────────────────────────────────────────────────────────────────────────── */
  var prefersLess = media("(prefers-reduced-motion: reduce)");
  var prefersMore = media("(prefers-contrast: more)");

  function movingDefault() {
    var d = byId(MOTIONS, C.defaultMotion);
    if (d && d.id !== STILL) return d.id;
    for (var i = 0; i < MOTIONS.length; i++) if (MOTIONS[i].id !== STILL) return MOTIONS[i].id;
    return MOTIONS[0].id;
  }
  function defaults() {
    return {
      light: byId(MODES, C.defaultMode) ? C.defaultMode : MODES[0].id,
      motion: prefersLess && byId(MOTIONS, STILL) ? STILL : movingDefault(),
      contrast: hasContrast && prefersMore ? "more" : "standard",
      cursor: prefersLess || !hasCursor ? "off" : "on",
      reading: "off",
      text: SIZES[0].id,
      measure: "full",
      chosen: false,
    };
  }

  // Reading mode's light: ARRIVAL.reading.light, else the first mode marked calm: true, else the
  // first light (not dark, not time-following) mode, else the first mode.
  function calmLight() {
    if (RD.light && byId(MODES, RD.light)) return RD.light;
    var i;
    for (i = 0; i < MODES.length; i++) if (MODES[i].calm) return MODES[i].id;
    for (i = 0; i < MODES.length; i++) if (!MODES[i].dark && !MODES[i].follows) return MODES[i].id;
    return MODES[0].id;
  }
  function readingPreset() {
    return {
      light: calmLight(),
      motion: byId(MOTIONS, STILL) ? STILL : MOTIONS[0].id,
      contrast: hasContrast ? "more" : "standard",
      cursor: "off",
    };
  }
  function readingMatches(s) {
    var p = readingPreset();
    return s.light === p.light && s.motion === p.motion && s.contrast === p.contrast && s.cursor === p.cursor;
  }
  function read() {
    var s = defaults();
    var raw = store.get(KEY);
    var saved = null;
    if (raw) {
      try {
        saved = JSON.parse(raw);
      } catch (e) {}
    }
    if (saved && typeof saved === "object") {
      s = assign(s, saved);
    } else if (S.legacy) {
      // Keys a site used before the kit, e.g. { light: "org-light", motion: "org-motion" }.
      var l = S.legacy.light && store.get(S.legacy.light);
      var m = S.legacy.motion && store.get(S.legacy.motion);
      if (l) s.light = l;
      if (m) s.motion = m;
      if (l || m) s.chosen = true;
    }
    if (!byId(MODES, s.light)) s.light = defaults().light;
    if (!byId(MOTIONS, s.motion)) s.motion = defaults().motion;
    if (s.contrast !== "more") s.contrast = "standard";
    if (!hasContrast) s.contrast = "standard";
    if (s.cursor !== "off" && s.cursor !== "on") s.cursor = defaults().cursor;
    if (!hasCursor) s.cursor = "off";
    if (s.reading !== "on" || !hasReading || !readingMatches(s)) s.reading = "off";
    if (!s.before || typeof s.before !== "object") s.before = null;
    if (!byId(SIZES, s.text) || !hasReading) s.text = SIZES[0].id;
    if (s.measure !== "comfy" || !hasMeasure) s.measure = "full";
    return s;
  }

  var state = read();

  function themeOf(lightId) {
    var m = byId(MODES, lightId);
    if (m && typeof m.follows === "function") {
      try {
        var t = m.follows(new Date());
        if (byId(MODES, t)) return t;
      } catch (e) {}
    }
    return m ? m.id : MODES[0].id;
  }
  function attr(name, value) {
    if (root.getAttribute(name) !== value) root.setAttribute(name, value);
  }
  function apply() {
    var theme = themeOf(state.light);
    attr("data-light", state.light);
    attr("data-theme", theme);
    attr("data-motion", state.motion);
    attr("data-contrast", state.contrast);
    // "off" whenever the visitor switched cursor effects off or chose a still page. Sites key their
    // own pointer effects on it (ORG's marbled ink stops stirring).
    attr("data-cursor", state.cursor === "on" && state.motion !== STILL ? "on" : "off");
    attr("data-reading", state.reading === "on" ? "on" : "off");
    var sz = byId(SIZES, state.text) || SIZES[0];
    attr("data-text", sz.id);
    attr("data-measure", state.measure === "comfy" ? "comfy" : "full");
    try {
      root.style.setProperty("--arr-text-scale", String(+sz.scale || 1));
    } catch (e) {}
    var m = byId(MODES, theme);
    var bg = m && (m.bg || (m.swatch && m.swatch[0]));
    if (bg && doc.head) {
      var meta = doc.querySelector('meta[name="theme-color"]');
      if (!meta) {
        meta = doc.createElement("meta");
        meta.name = "theme-color";
        doc.head.appendChild(meta);
      }
      meta.content = bg;
    }
  }
  apply(); // before first paint

  // tentative: a choice made inside the splash, which counts as "chosen" only once it closes.
  function set(patch, tentative) {
    state = assign({}, state, patch || {});
    if (state.motion !== STILL) state.moving = state.motion;
    // Reading mode is a preset, not a fifth setting: any change that breaks it leaves it, and the
    // visitor keeps what they just chose (nothing is restored behind their back).
    if (state.reading === "on" && !readingMatches(state)) {
      state.reading = "off";
      state.before = null;
    }
    if (!tentative) state.chosen = true;
    apply();
    store.set(KEY, JSON.stringify(state));
    sync();
    emit("arrival:change", get());
  }
  function get() {
    return {
      light: state.light, theme: themeOf(state.light), motion: state.motion, contrast: state.contrast,
      cursor: state.cursor, reading: state.reading === "on", text: state.text, measure: state.measure, chosen: !!state.chosen,
    };
  }
  // One tap: save what the visitor has, apply the calmest preset; tap again to restore it. The
  // preset also turns on the comfortable line length (and restores it after); text size is left alone.
  function toggleReading(tentative) {
    if (!hasReading) return;
    if (state.reading === "on") {
      var b = state.before || {};
      var d = defaults();
      set({
        reading: "off",
        before: null,
        light: byId(MODES, b.light) ? b.light : d.light,
        motion: byId(MOTIONS, b.motion) ? b.motion : movingDefault(),
        contrast: b.contrast === "more" ? "more" : "standard",
        cursor: b.cursor === "on" ? "on" : "off",
        measure: b.measure === "comfy" ? "comfy" : "full",
      }, tentative);
    } else {
      set(assign({ reading: "on", before: { light: state.light, motion: state.motion, contrast: state.contrast, cursor: state.cursor, measure: state.measure } }, readingPreset(), hasMeasure ? { measure: "comfy" } : {}), tentative);
    }
  }
  function stepText(d) {
    var i = 0;
    for (var k = 0; k < SIZES.length; k++) if (SIZES[k].id === state.text) i = k;
    set({ text: SIZES[Math.max(0, Math.min(SIZES.length - 1, i + d))].id });
  }

  window.addEventListener("storage", function (e) {
    if (e.key !== KEY) return;
    state = read();
    apply();
    sync();
  });
  setInterval(function () {
    var m = byId(MODES, state.light);
    if (m && m.follows) {
      apply();
      sync();
    }
  }, 5 * 60 * 1000);

  /* ── markup builders shared by the drawer, splash and guide ───────────────────────────── */
  var uid = 0;
  function swatchBg(m) {
    if (m.ink) return m.ink; // any CSS background, set per mode in org.js
    if (m.follows && m.shows) {
      var cols = m.shows.map(function (id) {
        var x = byId(MODES, id);
        return x && x.swatch ? x.swatch[0] : "#888";
      });
      var step = 100 / cols.length;
      return "linear-gradient(90deg," + cols.map(function (c, i) {
        return c + " " + (i * step).toFixed(2) + "% " + ((i + 1) * step).toFixed(2) + "%";
      }).join(",") + ")";
    }
    var sw = m.swatch || ["#888", "#ccc"];
    return "linear-gradient(135deg," + sw[0] + " 55%," + (sw[1] || sw[0]) + " 55%)";
  }
  function lightRadios(name, rich) {
    return MODES.map(function (m) {
      return (
        '<label class="arr-opt">' +
        '<input class="arr-sr" type="radio" name="' + name + '" value="' + esc(m.id) + '" data-arr-light>' +
        '<span class="arr-dot arr-shape" style="background:' + swatchBg(m) + '"></span>' +
        '<span class="arr-opt-text"><span class="arr-opt-name">' + esc(m.name) + "</span>" +
        (rich && m.note ? '<span class="arr-opt-note">' + esc(m.note) + "</span>" : "") +
        (m.follows ? '<span class="arr-opt-note" data-arr-now></span>' : "") +
        "</span></label>"
      );
    }).join("");
  }
  function lightCards(name) {
    var sample = esc(org.motto || org.name || "");
    return MODES.map(function (m) {
      var follow = !!m.follows;
      return (
        '<label class="arr-card' + (follow ? " arr-card-follow" : "") + '"' + (follow ? "" : ' data-theme="' + esc(m.id) + '"') + ">" +
        '<input class="arr-sr" type="radio" name="' + name + '" value="' + esc(m.id) + '" data-arr-light>' +
        '<span class="arr-frame arr-shape"><span class="arr-in arr-shape">' +
        '<span class="arr-card-ink arr-shape"' + (follow ? ' style="background:' + swatchBg(m) + '"' : "") + "></span>" +
        '<span class="arr-card-name">' + esc(m.name) + "</span>" +
        (m.note ? '<span class="arr-card-note">' + esc(m.note) + "</span>" : "") +
        (follow ? '<span class="arr-card-note arr-card-now" data-arr-now></span>' : sample ? '<span class="arr-card-sample">' + sample + "</span>" : "") +
        '<span class="arr-card-check" aria-hidden="true">' + icon("check") + "</span>" +
        "</span></span></label>"
      );
    }).join("");
  }
  function motionRadios(name) {
    return MOTIONS.map(function (m) {
      return (
        '<label class="arr-seg-opt">' +
        '<input class="arr-sr" type="radio" name="' + name + '" value="' + esc(m.id) + '" data-arr-motion>' +
        '<span class="arr-shape">' + (m.icon ? icon(m.icon) : "") + esc(m.name) + "</span></label>"
      );
    }).join("");
  }
  function contrastSwitch() {
    if (!hasContrast) return "";
    return (
      '<label class="arr-switch"><input class="arr-sr" type="checkbox" role="switch" data-arr-contrast>' +
      '<span class="arr-switch-track" aria-hidden="true"><span></span></span>' +
      '<span class="arr-switch-label">' + esc(W.moreContrast) + "</span></label>" +
      '<p class="arr-note">' + esc(W.contrastNote) + "</p>"
    );
  }
  function cursorSwitch() {
    if (!hasCursor) return "";
    return (
      '<label class="arr-switch arr-switch-cursor"><input class="arr-sr" type="checkbox" role="switch" data-arr-cursor>' +
      '<span class="arr-switch-track" aria-hidden="true"><span></span></span>' +
      '<span class="arr-switch-label">' + esc(W.cursor) + "</span></label>" +
      '<p class="arr-note">' + esc(W.cursorNote) + "</p>"
    );
  }
  function readingNote() {
    var m = byId(MODES, calmLight());
    return W.readingNote.replace("{light}", m ? m.name : "calmest");
  }
  function readingSwitch() {
    if (!hasReading) return "";
    return (
      '<label class="arr-switch arr-switch-reading"><input class="arr-sr" type="checkbox" role="switch" data-arr-reading>' +
      '<span class="arr-switch-track" aria-hidden="true"><span></span></span>' +
      '<span class="arr-switch-label">' + icon("book-open-text") + esc(W.reading) + "</span></label>" +
      '<p class="arr-note">' + esc(readingNote()) + "</p>" + readingExtras()
    );
  }
  // Text size steps (a segmented row of growing A's) and the line-length switch, under the reading
  // switch wherever it appears. `name` keeps each copy's radio group separate.
  var rxUid = 0;
  function readingExtras() {
    if (!hasReading) return "";
    var n = ++rxUid;
    return (
      '<fieldset class="arr-field arr-field-size"><legend>' + esc(W.textSize) + '</legend><div class="arr-seg arr-seg-size">' +
      SIZES.map(function (s, i) {
        return (
          '<label class="arr-seg-opt" title="' + esc(s.name) + '"><input class="arr-sr" type="radio" name="arr-tx-' + n + '" value="' + esc(s.id) +
          '" data-arr-text aria-label="' + esc(s.name) + '"><span class="arr-shape"><span class="arr-size-a" aria-hidden="true" style="font-size:' +
          (0.78 + i * 0.17).toFixed(2) + 'rem">A</span></span></label>'
        );
      }).join("") +
      "</div></fieldset>" +
      (hasMeasure
        ? '<label class="arr-switch arr-switch-measure"><input class="arr-sr" type="checkbox" role="switch" data-arr-measure>' +
          '<span class="arr-switch-track" aria-hidden="true"><span></span></span>' +
          '<span class="arr-switch-label">' + icon("text-align-left") + esc(W.measure) + "</span></label>" +
          '<p class="arr-note">' + esc(W.measureNote) + "</p>"
        : "")
    );
  }
  function notices() {
    var out = "";
    if (prefersLess) out += '<p class="arr-notice">' + icon("hand-palm") + esc(W.reduced) + "</p>";
    if (prefersMore && hasContrast) out += '<p class="arr-notice">' + icon("circle-half") + esc(W.moreAsked) + "</p>";
    return out;
  }

  /* ── keep every control in step with the state ────────────────────────────────────────── */
  function sync() {
    var theme = themeOf(state.light);
    var all = function (sel, fn) {
      var list = doc.querySelectorAll(sel);
      for (var i = 0; i < list.length; i++) fn(list[i]);
    };
    all("[data-arr-swatch]", function (b) {
      b.setAttribute("aria-pressed", String(b.getAttribute("data-arr-swatch") === state.light));
    });
    all("input[data-arr-light]", function (i) {
      i.checked = i.value === state.light;
    });
    all("input[data-arr-motion]", function (i) {
      i.checked = i.value === state.motion;
    });
    all("input[data-arr-contrast]", function (i) {
      i.checked = state.contrast === "more";
      i.setAttribute("aria-checked", String(i.checked));
    });
    all("input[data-arr-cursor]", function (i) {
      i.checked = state.cursor === "on";
      i.setAttribute("aria-checked", String(i.checked));
    });
    all("[data-arr-cursor-toggle]", function (b) {
      var on = state.cursor === "on";
      var label = on ? W.cursorOn : W.cursorOff;
      b.setAttribute("aria-pressed", String(on));
      b.setAttribute("aria-label", label);
      b.setAttribute("title", label + (state.motion === STILL ? " (resting while motion is still)" : ""));
    });
    var reading = state.reading === "on";
    all("input[data-arr-reading]", function (i) {
      i.checked = reading;
      i.setAttribute("aria-checked", String(reading));
    });
    all("[data-arr-reading-toggle]", function (b) {
      var label = reading ? W.readingOn : W.readingOff;
      b.setAttribute("aria-pressed", String(reading));
      b.setAttribute("aria-label", label);
      b.setAttribute("title", label);
    });
    all("input[data-arr-text]", function (i) {
      i.checked = i.value === state.text;
    });
    all("input[data-arr-measure]", function (i) {
      i.checked = state.measure === "comfy";
      i.setAttribute("aria-checked", String(i.checked));
    });
    syncNews();
    var still = state.motion === STILL;
    all("[data-arr-motion-toggle]", function (b) {
      var label = still ? W.play : W.pause;
      b.setAttribute("aria-pressed", String(still));
      b.setAttribute("aria-label", label);
      b.setAttribute("title", label);
      b.innerHTML = icon(still ? "play" : "pause");
    });
    var mo = byId(MOTIONS, state.motion);
    all("[data-arr-motion-note]", function (p) {
      p.textContent = mo && mo.note ? mo.note : "";
    });
    var tm = byId(MODES, theme);
    all("[data-arr-now]", function (s) {
      s.textContent = W.followNow + ": " + (tm ? tm.name : theme);
    });
    syncTrail();
  }

  /* ── <arrival-controls>: search, minimalist swatches + motion, and the drawer ─────────── */
  function renderControls(host) {
    var n = ++uid;
    var swatches = MODES.map(function (m) {
      return (
        '<button type="button" class="arr-swatch arr-shape" data-arr-swatch="' + esc(m.id) + '" title="' + esc(m.name) +
        '" aria-label="' + esc(W.light + ": " + m.name) + '" style="background:' + swatchBg(m) + '"></button>'
      );
    }).join("");
    host.innerHTML =
      '<div class="arr-controls">' +
      // What's new: hidden until a return visit finds something newer than the last one. Then it's a
      // filled pill with a count, and (once per visit) a small tip underneath pointing at it.
      (hasNews
        ? '<span class="arr-news-wrap"><button type="button" class="arr-chip arr-shape arr-news" data-arr-news hidden>' + icon("sparkle") +
          '<span class="arr-news-n" data-arr-news-n></span><span class="arr-chip-label">' + esc(W.newBadge) + "</span></button>" +
          '<span class="arr-news-tip arr-shape" data-arr-news-tip aria-hidden="true" hidden></span></span>'
        : "") +
      '<button type="button" class="arr-chip arr-shape arr-chip-search" data-arrival-open="search" aria-label="' + esc(W.search) + ' (press /)" title="' + esc(W.search) + ' (/)">' +
      icon("magnifying-glass") + '<span class="arr-chip-label">' + esc(W.search) + "</span><kbd>/</kbd></button>" +
      '<span class="arr-swatches" role="group" aria-label="' + esc(W.light) + '">' + swatches + "</span>" +
      '<button type="button" class="arr-chip arr-shape arr-chip-icon" data-arr-motion-toggle></button>' +
      (hasCursor ? '<button type="button" class="arr-chip arr-shape arr-chip-icon arr-cursor-btn" data-arr-cursor-toggle>' + icon("cursor-click") + "</button>" : "") +
      (hasReading ? '<button type="button" class="arr-chip arr-shape arr-chip-icon arr-reading-btn" data-arr-reading-toggle>' + icon("book-open-text") + "</button>" : "") +
      '<span class="arr-drawer-wrap">' +
      '<button type="button" class="arr-chip arr-shape" data-arr-drawer aria-label="' + esc(W.drawer) + '" aria-expanded="false" aria-controls="arr-drawer-' + n + '">' +
      icon("sliders-horizontal") + '<span class="arr-chip-label">' + esc(W.drawer) + "</span>" + '<i class="ph ph-caret-down arr-caret" aria-hidden="true"></i></button>' +
      '<div class="arr-drawer arr-lift" id="arr-drawer-' + n + '" hidden><div class="arr-frame arr-shape"><div class="arr-in arr-shape">' +
      (hasReading ? '<div class="arr-field arr-field-reading">' + readingSwitch() + "</div>" : "") +
      '<fieldset class="arr-field"><legend>' + esc(W.light) + '</legend><div class="arr-list">' + lightRadios("arr-dl-" + n, false) + "</div></fieldset>" +
      '<fieldset class="arr-field"><legend>' + esc(W.motion) + '</legend><div class="arr-seg">' + motionRadios("arr-dm-" + n) + "</div>" +
      '<p class="arr-note" data-arr-motion-note></p>' + cursorSwitch() + "</fieldset>" +
      (hasContrast ? '<fieldset class="arr-field"><legend>' + esc(W.contrast) + "</legend>" + contrastSwitch() + "</fieldset>" : "") +
      '<div class="arr-rule" role="presentation"></div>' +
      '<a class="arr-link" href="#welcome" data-arrival-open="guide">' + icon("compass") + "<span>" + esc(W.openGuide) + "</span><kbd>?</kbd></a>" +
      '<button type="button" class="arr-link" data-arrival-open="search">' + icon("magnifying-glass") + "<span>" + esc(W.searchAll) + "</span><kbd>/</kbd></button>" +
      '<p class="arr-fine">' + esc(W.saved) + "</p>" +
      "</div></div></div></span></div>";
    sync();
  }

  function drawerOf(btn) {
    return doc.getElementById(btn.getAttribute("aria-controls"));
  }
  // Every popup that hangs off the header (the drawer, the nav's dropdowns and the Menu) closes
  // when another opens, so only one is ever open.
  function closeDrawers(refocus) {
    closeNavs(false);
    var open = doc.querySelectorAll('[data-arr-drawer][aria-expanded="true"]');
    for (var i = 0; i < open.length; i++) {
      open[i].setAttribute("aria-expanded", "false");
      var p = drawerOf(open[i]);
      if (p) p.hidden = true;
      if (refocus) open[i].focus();
    }
  }
  function openDrawer(btn) {
    closeDrawers(false);
    var p = drawerOf(btn);
    if (!p) return;
    btn.setAttribute("aria-expanded", "true");
    p.hidden = false;
    p.style.top = "";
    if (window.innerWidth < 560) {
      var r = btn.getBoundingClientRect();
      p.style.top = Math.round(r.bottom + 8) + "px";
    }
    sync();
    var f = p.querySelector("input:checked") || p.querySelector("input, a, button");
    if (f) f.focus();
  }

  /* ── dialogs (splash, guide, search) ───────────────────────────────────────────────────── */
  var FOCUSABLE = 'a[href], button:not([disabled]), input:not([disabled]), select, textarea, [tabindex]:not([tabindex="-1"])';
  function focusables(box) {
    var list = box.querySelectorAll(FOCUSABLE);
    var out = [];
    for (var i = 0; i < list.length; i++) {
      var el = list[i];
      if (el.type === "radio" && !el.checked) {
        var group = box.querySelectorAll('input[type="radio"][name="' + el.name + '"]');
        var any = false;
        for (var j = 0; j < group.length; j++) if (group[j].checked) any = true;
        if (any) continue;
      }
      if (el.closest("[hidden]")) continue;
      if (!el.getClientRects().length) continue;
      out.push(el);
    }
    return out;
  }
  var stack = [];
  function makeDialog(cls, labelId, onClose) {
    var d = doc.createElement("dialog");
    d.className = "arr-dialog " + cls;
    d.setAttribute("aria-labelledby", labelId);
    d._onClose = onClose;
    d.addEventListener("cancel", function (e) {
      e.preventDefault();
      hide(d);
    });
    d.addEventListener("keydown", function (e) {
      if (e.key === "Escape") {
        e.preventDefault();
        e.stopPropagation();
        hide(d);
        return;
      }
      if (e.key !== "Tab") return;
      var f = focusables(d);
      if (!f.length) {
        e.preventDefault();
        return;
      }
      var first = f[0];
      var last = f[f.length - 1];
      var a = doc.activeElement;
      if (!d.contains(a)) {
        e.preventDefault();
        first.focus();
      } else if (e.shiftKey && a === first) {
        e.preventDefault();
        last.focus();
      } else if (!e.shiftKey && a === last) {
        e.preventDefault();
        first.focus();
      }
    });
    d.addEventListener("mousedown", function (e) {
      d._downOnBackdrop = e.target === d;
    });
    d.addEventListener("click", function (e) {
      if (e.target === d && d._downOnBackdrop) hide(d);
    });
    doc.body.appendChild(d);
    return d;
  }
  function show(d, focusEl) {
    if (d.open) return;
    d._return = doc.activeElement;
    // Opened from inside a dropdown or the Menu, which closes now: return focus to its button.
    var pop = d._return && d._return.closest && d._return.closest(".arr-nav-menu, .arr-menu-panel, .arr-drawer");
    if (pop && pop.id) d._return = doc.querySelector('[aria-controls="' + pop.id + '"]') || d._return;
    hideTip();
    closeDrawers(false);
    try {
      d.showModal();
    } catch (e) {
      d.setAttribute("open", "");
    }
    stack.push(d);
    root.classList.add("arr-locked");
    var f = focusEl || focusables(d)[0];
    if (f) f.focus();
  }
  function hide(d, keepFocus) {
    if (!d || !d.open) return;
    if (d._onClose) d._onClose();
    try {
      d.close();
    } catch (e) {
      d.removeAttribute("open");
    }
    stack = stack.filter(function (x) {
      return x !== d;
    });
    if (!stack.length) root.classList.remove("arr-locked");
    if (!keepFocus && d._return && d._return.focus && doc.contains(d._return)) d._return.focus();
  }
  function panel(inner, extra) {
    return '<div class="arr-lift"><div class="arr-frame arr-shape arr-panel ' + (extra || "") + '"><div class="arr-in arr-shape">' + inner + "</div></div></div>";
  }
  function markHTML() {
    var mk = org.mark;
    return mk && mk.src ? '<img class="arr-mark" src="' + esc(mk.src) + '" alt="" width="40" height="40">' : "";
  }

  /* ── first-visit splash: "Choose how you arrive" ──────────────────────────────────────── */
  var splashEl = null;
  function splashWanted() {
    return store.ok && !state.chosen && C.splash !== false && root.getAttribute("data-arrival-splash") !== "off";
  }
  function openSplash() {
    if (!splashEl) {
      splashEl = makeDialog("arr-splash", "arr-splash-title", function () {
        set({}, false); // closing (Enter, Esc, backdrop, tour, "/") records the choice
      });
      splashEl.innerHTML = panel(
        '<div class="arr-head">' + markHTML() +
        '<span class="arr-eyebrow">' + esc(org.short || "") + (org.name ? '<span class="arr-eyebrow-full"> · ' + esc(org.name) + "</span>" : "") + "</span></div>" +
        '<h2 class="arr-title" id="arr-splash-title">' + esc(W.arrive) + "</h2>" +
        '<p class="arr-intro">' + esc(W.intro) + "</p>" +
        notices() +
        '<fieldset class="arr-field"><legend>' + esc(W.light) + '</legend><div class="arr-cards">' + lightCards("arr-sl") + "</div></fieldset>" +
        '<div class="arr-split">' +
        '<fieldset class="arr-field"><legend>' + esc(W.motion) + '</legend><div class="arr-seg">' + motionRadios("arr-sm") + "</div>" +
        '<p class="arr-note" data-arr-motion-note aria-live="polite"></p>' + cursorSwitch() + "</fieldset>" +
        (hasContrast ? '<fieldset class="arr-field"><legend>' + esc(W.contrast) + "</legend>" + contrastSwitch() + "</fieldset>" : "") +
        "</div>" +
        '<div class="arr-tip arr-shape"><kbd class="arr-kbd-big arr-shape">/</kbd><p><strong>Press / to search.</strong> ' + esc(W.searchTip) +
        ' <span class="arr-hover-only">Try it now: press <kbd>/</kbd>.</span><span class="arr-touch-only">On a phone, tap the magnifier in the header.</span></p></div>' +
        '<div class="arr-actions">' +
        '<button type="button" class="arr-btn arr-btn-primary arr-shape" data-arr-enter>' + esc(W.enter) + icon("arrow-right") + "</button>" +
        '<button type="button" class="arr-btn arr-btn-quiet arr-shape" data-arr-tour>' + icon("compass") + esc(W.tour) + "</button>" +
        (hasReading ? '<button type="button" class="arr-btn arr-btn-quiet arr-shape" data-arr-read-enter title="' + esc(readingNote()) + '">' + icon("book-open-text") + esc(W.readEnter) + "</button>" : "") +
        '<span class="arr-fine">' + esc(W.saved) + "</span></div>"
      );
    }
    sync();
    show(splashEl, splashEl.querySelector("input[data-arr-light]:checked") || splashEl.querySelector("[data-arr-enter]"));
  }

  /* ── the welcome guide (onboarding panel) ─────────────────────────────────────────────── */
  var guideEl = null;
  var step = 0;
  var seen = {};

  function link(href, label, ic, cls) {
    if (!href) return "";
    return '<a class="arr-btn arr-shape ' + (cls || "arr-btn-quiet") + '" href="' + esc(href) + '">' + (ic ? icon(ic) : "") + esc(label) + "</a>";
  }
  function placeholder(text) {
    return '<p class="arr-placeholder arr-shape">' + icon("note-pencil") + "<span><strong>Placeholder.</strong> " + text + "</span></p>";
  }
  function para(text) {
    return text ? "<p>" + text + "</p>" : "";
  }

  // Each step: { id, icon, title, html() }. Text comes from org.js (ARRIVAL.guide.<id> overrides
  // any field; ARRIVAL.guide.order picks and orders the steps). Strings there may hold simple HTML.
  function steps() {
    var G = C.guide || {};
    var rec = site.record || C.record || {};
    var com = site.community || C.community || null;
    var home = org.home || null;
    var defs = {
      welcome: {
        icon: "hand-waving",
        title: "Welcome to " + (site.name || org.short || "the site"),
        html: function () {
          return (
            (site.what ? '<p class="arr-lede">' + site.what + "</p>" : "") +
            para(org.about) +
            (org.welcomeNote ? '<blockquote class="arr-quote">' + org.welcomeNote + "</blockquote>" : org.welcomePlaceholder ? placeholder(org.welcomePlaceholder) : "") +
            para((G.welcome || {}).more)
          );
        },
      },
      record: {
        icon: "clock-counter-clockwise",
        title: "Changelog and library",
        html: function () {
          var ch = rec.changelog || {};
          var li = rec.library || {};
          var lg = rec.ledger || null;
          return (
            para(rec.intro) +
            '<div class="arr-two' + (lg ? " arr-three" : "") + '">' +
            '<div class="arr-box arr-shape"><h3>' + icon("clock-counter-clockwise") + esc(ch.name || "The changelog") + "</h3>" +
            para(ch.text || "What changed, when, and who did it. Short dated entries, newest first, each with a one-line summary and the full story folded underneath.") +
            link(ch.href, ch.label || "Read the changelog", "arrow-right") + "</div>" +
            '<div class="arr-box arr-shape"><h3>' + icon("books") + esc(li.name || "The library") + "</h3>" +
            para(li.text || "How things work. Longer write-ups that stay true over time, rather than news of one change.") +
            (li.href ? link(li.href, li.label || "Open the library", "arrow-right") : li.missing ? placeholder(li.missing) : "") + "</div>" +
            (lg
              ? '<div class="arr-box arr-shape arr-box-ledger"><h3>' + icon(lg.icon || "scroll") + esc(lg.name || W.ledger) + "</h3>" +
                para(lg.text || "Every public change to the code, in plain words, grouped by day and by kind, each one linked to the change itself. For anyone who'd rather not open GitHub.") +
                link(lg.href, lg.label || "Open the ledger", "arrow-right") + "</div>"
              : "") +
            "</div>" +
            (rec.share ? '<p class="arr-notice">' + icon("share-network") + "<span>" + rec.share + "</span></p>" : "") +
            (hasNews ? '<p class="arr-notice">' + icon("sparkle") + "<span>" + esc(W.newsGuide) + "</span></p>" : "")
          );
        },
      },
      search: {
        icon: "magnifying-glass",
        title: "Press / to search",
        html: function () {
          return (
            '<div class="arr-tip arr-shape"><kbd class="arr-kbd-big arr-shape">/</kbd><p>Press <kbd>/</kbd> on any page, or <kbd>Ctrl</kbd> <kbd>K</kbd> (<kbd>⌘</kbd> <kbd>K</kbd> on a Mac). On a phone, tap the magnifier in the header. Like Discord\'s quick switcher: start typing and jump.</p></div>' +
            "<ul class=\"arr-ticks\">" +
            "<li>" + icon("sparkle") + "Every changelog entry, by title, month, area, or who made it.</li>" +
            "<li>" + icon("book-open-text") + "Every library write-up.</li>" +
            "<li>" + icon("signpost") + "Pages and links, like " + esc(home ? home.label : "the main site") + (com ? " or the " + esc(com.name) + " group" : "") + ".</li>" +
            "<li>" + icon("palette") + "Actions: type <em>light</em>, <em>still</em> or <em>contrast</em> to change how the page looks.</li>" +
            "</ul>" +
            para((G.search || {}).more) +
            '<p><button type="button" class="arr-btn arr-btn-primary arr-shape" data-arrival-open="search">' + icon("magnifying-glass") + "Try it now</button></p>"
          );
        },
      },
      light: {
        icon: "palette",
        title: "Pick a light",
        html: function () {
          return para((G.light || {}).text) + '<div class="arr-cards arr-cards-compact">' + lightCards("arr-gl") + "</div>";
        },
      },
      motion: {
        icon: "wind",
        title: "Motion and contrast",
        html: function () {
          return (
            para((G.motion || {}).text) + notices() +
            (hasReading ? '<div class="arr-field arr-field-reading">' + readingSwitch() + "</div>" : "") +
            '<div class="arr-split">' +
            '<fieldset class="arr-field"><legend>' + esc(W.motion) + '</legend><div class="arr-seg">' + motionRadios("arr-gm") + "</div>" +
            '<p class="arr-note" data-arr-motion-note aria-live="polite"></p>' + cursorSwitch() + "</fieldset>" +
            (hasContrast ? '<fieldset class="arr-field"><legend>' + esc(W.contrast) + "</legend>" + contrastSwitch() + "</fieldset>" : "") +
            "</div>" +
            '<p class="arr-fine">In the header, the pause button switches motion off and on in one click, the pointer button does the same for cursor effects' +
            (hasReading ? ", and the book button is reading mode" : "") + ".</p>"
          );
        },
      },
      people: {
        icon: "users-three",
        title: "Who made the changes",
        html: function () {
          return (
            para((G.people || {}).text || "Every entry credits whoever did the work.") +
            "<arrival-people compact></arrival-people>" +
            '<p class="arr-fine">' + ((G.people || {}).fine || "Pictures come from public GitHub profiles. Anyone without one gets their initials instead.") + "</p>"
          );
        },
      },
      community: {
        icon: "chats-circle",
        title: "Where the community talks",
        html: function () {
          if (!com) return placeholder("This org hasn't named its community space here yet.");
          // v1.2: with platforms configured, list them and offer the community modal.
          if (com.platforms && com.platforms.length) {
            return (
              para(com.text) +
              '<ul class="arr-ticks">' +
              com.platforms.map(function (p) {
                var k = PLATFORM[p.kind] || [p.kind || "", "chats-circle"];
                var soon = p.status === "soon" || (!(p.public && p.public.href) && !(p.join && p.join.href));
                return "<li>" + icon(p.icon || k[1]) + "<span><strong>" + esc(p.name || k[0]) + "</strong>" + (soon ? " · " + esc(W.soon) : "") + "</span></li>";
              }).join("") +
              (com.bespoke ? "<li>" + icon(com.bespoke.icon || "graph") + "<span><strong>" + esc(com.bespoke.title || "A network of our own") + "</strong> · " + esc(com.bespoke.tag || W.sneak) + "</span></li>" : "") +
              "</ul>" +
              '<p><button type="button" class="arr-btn arr-btn-primary arr-shape" data-arrival-open="community">' + icon(com.icon || "users-three") + esc(com.label || "See every way in") + "</button></p>" +
              (com.more || []).map(function (x) { return '<p class="arr-fine">' + x + "</p>"; }).join("")
            );
          }
          return (
            para(com.text) +
            (com.href ? link(com.href, com.label || "Open " + com.name, com.icon || "chats-circle", "arr-btn-primary") : placeholder("The " + esc(com.name) + " link still needs to be added.")) +
            (com.more || []).map(function (x) {
              return '<p class="arr-fine">' + x + "</p>";
            }).join("")
          );
        },
      },
      home: {
        icon: "globe-hemisphere-west",
        title: home ? home.label : "The main site",
        html: function () {
          return (
            para(home && home.text) +
            (home ? link(home.href, "Visit " + home.label, "arrow-square-out", "arr-btn-primary") : "") +
            para((G.home || {}).more) +
            '<p class="arr-finale" data-arr-finale hidden>' + icon("seal-check") + "<span></span></p>"
          );
        },
      },
    };
    var order = G.order || ["welcome", "record", "search", "light", "motion", "people", "community", "home"];
    return order
      .map(function (id) {
        var d = defs[id] || (G[id] && G[id].html ? { icon: "info", title: id } : null);
        if (!d) return null;
        var o = G[id] || {};
        return {
          id: id,
          icon: o.icon || d.icon,
          title: o.title || d.title,
          html: typeof o.html === "function" ? o.html : o.html ? function () { return o.html; } : d.html,
        };
      })
      .filter(Boolean);
  }

  function glyph(n, cur, size) {
    var cols = C.wedges && C.wedges.length ? C.wedges : ["var(--accent)"];
    var a0 = -90 - 180 / n;
    var pt = function (r, k) {
      var a = ((a0 + (360 / n) * k) * Math.PI) / 180;
      return (50 + r * Math.cos(a)).toFixed(2) + "," + (50 + r * Math.sin(a)).toFixed(2);
    };
    var s = '<svg class="arr-glyph" viewBox="0 0 100 100" width="' + size + '" height="' + size + '" aria-hidden="true">';
    for (var k = 0; k < n; k++) {
      s +=
        '<polygon class="arr-wedge' + (seen[k] ? " is-lit" : "") + (k === cur ? " is-current" : "") +
        '" points="50,50 ' + pt(46, k) + " " + pt(46, k + 1) + '" fill="' + cols[k % cols.length] + '"/>';
    }
    var ring = [];
    for (var j = 0; j < n; j++) ring.push(pt(46, j));
    return s + '<polygon points="' + ring.join(" ") + '" fill="none" stroke="currentColor" stroke-opacity=".5" stroke-width="3" stroke-linejoin="round"/></svg>';
  }

  var STEPS = null;
  function renderStep() {
    var s = STEPS[step];
    var n = STEPS.length;
    seen[step] = true;
    var g = guideEl;
    g.querySelector("[data-arr-glyph]").innerHTML = glyph(n, step, 56);
    g.querySelector("[data-arr-count]").textContent = step + 1 + " of " + n;
    g.querySelector("#arr-guide-title").innerHTML = icon(s.icon) + esc(s.title);
    var body = g.querySelector("[data-arr-body]");
    body.innerHTML = s.html();
    body.scrollTop = 0;
    var tabs = g.querySelectorAll("[data-arr-step]");
    for (var i = 0; i < tabs.length; i++) {
      if (+tabs[i].getAttribute("data-arr-step") === step) tabs[i].setAttribute("aria-current", "step");
      else tabs[i].removeAttribute("aria-current");
      tabs[i].classList.toggle("is-seen", !!seen[i]);
    }
    g.querySelector("[data-arr-prev]").disabled = step === 0;
    var next = g.querySelector("[data-arr-next]");
    next.innerHTML = step === n - 1 ? "Done" + icon("check") : "Next" + icon("arrow-right");
    var fin = body.querySelector("[data-arr-finale]");
    if (fin) {
      var all = Object.keys(seen).length >= n;
      fin.hidden = false;
      fin.querySelector("span").textContent = all
        ? (C.guideFinale || "You've lit every wedge. Welcome in.")
        : "You can open this guide again any time from the light and motion drawer, or by pressing ?";
      if (all) g.querySelector(".arr-glyph").classList.add("is-whole");
    }
    sync();
  }
  function openGuide(at) {
    if (!guideEl) {
      STEPS = steps();
      var colsN = C.wedges || [];
      guideEl = makeDialog("arr-guide", "arr-guide-title", function () {
        if (!state.chosen) set({}, false); // someone who took the tour has arrived
        if (location.hash === "#welcome") {
          try {
            history.replaceState(null, "", location.pathname + location.search);
          } catch (e) {}
        }
      });
      guideEl.innerHTML = panel(
        '<div class="arr-guide-head">' +
        '<span class="arr-glyph-wrap" data-arr-glyph></span>' +
        '<div class="arr-guide-heading"><p class="arr-eyebrow">' + esc(W.guide) + ' · <span data-arr-count></span></p>' +
        '<h2 class="arr-title" id="arr-guide-title" aria-live="polite"></h2></div>' +
        '<button type="button" class="arr-x arr-shape" data-arr-close aria-label="Close the guide">' + icon("x") + "</button></div>" +
        '<div class="arr-guide-main">' +
        '<nav class="arr-steps" aria-label="Guide steps"><ol>' +
        STEPS.map(function (s, i) {
          return (
            '<li><button type="button" data-arr-step="' + i + '"><span class="arr-step-dot" style="--wedge:' +
            (colsN.length ? colsN[i % colsN.length] : "var(--accent)") + '"></span>' + esc(s.title) + "</button></li>"
          );
        }).join("") +
        "</ol></nav>" +
        '<section class="arr-step" data-arr-body></section></div>' +
        '<div class="arr-guide-foot">' +
        '<button type="button" class="arr-btn arr-btn-quiet arr-shape" data-arr-prev>' + icon("arrow-left") + "Back</button>" +
        '<span class="arr-fine arr-hover-only"><kbd>←</kbd> <kbd>→</kbd> to move</span>' +
        '<button type="button" class="arr-btn arr-btn-primary arr-shape" data-arr-next></button></div>',
        "arr-guide-panel"
      );
    }
    var idx = 0;
    if (typeof at === "string") {
      for (var i = 0; i < STEPS.length; i++) if (STEPS[i].id === at) idx = i;
    } else if (typeof at === "number") idx = at;
    step = Math.max(0, Math.min(STEPS.length - 1, idx));
    renderStep();
    show(guideEl, guideEl.querySelector("[data-arr-next]"));
  }
  function goStep(i) {
    if (!STEPS) return;
    if (i >= STEPS.length) {
      hide(guideEl);
      return;
    }
    step = Math.max(0, i);
    renderStep();
  }

  /* ── "/" quick search ──────────────────────────────────────────────────────────────────── */
  var indexP = null;
  function index() {
    if (indexP) return indexP;
    // Org-wide sources first, then the site's; a site entry with the same url replaces the org's
    // (that's how a site relabels or drops one: { url, label } or { url, skip: true }).
    var byUrl = {};
    var order = [];
    [].concat((C.search && C.search.sources) || [], site.sources || []).forEach(function (src) {
      if (typeof src === "string") src = { url: src };
      if (!src || !src.url) return;
      if (!byUrl[src.url]) order.push(src.url);
      byUrl[src.url] = src;
    });
    var sources = order.map(function (u) { return byUrl[u]; }).filter(function (s) { return !s.skip; });
    indexP = Promise.all(
      sources.map(function (src) {
        if (typeof src === "string") src = { url: src };
        if (!window.fetch) return { items: [], people: [] };
        return fetch(src.url, { credentials: "omit" })
          .then(function (r) {
            return r.ok ? r.json() : null;
          })
          .catch(function () {
            return null;
          })
          .then(function (j) {
            if (!j) return { items: [], people: [] };
            var items = (j.items || []).map(function (it) {
              return src.label ? assign({}, it, { from: src.label }) : it;
            });
            return { items: items, people: src.people === false ? [] : j.people || [] };
          });
      })
    ).then(function (parts) {
      var items = [];
      var people = [];
      var seenH = {};
      var seenP = {};
      parts.forEach(function (p) {
        p.items.forEach(function (it) {
          if (!it || !it.t) return;
          if (it.h && seenH[it.h]) return;
          if (it.h) seenH[it.h] = 1;
          items.push(it);
        });
        p.people.forEach(function (x) {
          if (!x || !x.name || seenP[x.name]) return;
          seenP[x.name] = 1;
          people.push(x);
        });
      });
      return { items: items, people: people };
    });
    return indexP;
  }

  function actions() {
    var out = [];
    MODES.forEach(function (m) {
      out.push({ t: W.light + ": " + m.name, k: "light", i: "palette", x: m.note || "", run: function () { set({ light: m.id }); } });
    });
    MOTIONS.forEach(function (m) {
      out.push({ t: W.motion + ": " + m.name, k: "motion", i: m.icon || "wind", x: (m.note || "") + " pause animation", run: function () { set({ motion: m.id }); } });
    });
    if (hasContrast) {
      out.push({
        t: W.moreContrast + ": on or off", k: "contrast", i: "circle-half", x: "accessibility readable",
        run: function () { set({ contrast: state.contrast === "more" ? "standard" : "more" }); },
      });
    }
    if (hasCursor) {
      out.push({
        t: W.cursor + ": on or off", k: "cursor", i: "cursor-click", x: "trail pointer mouse sparkle effects",
        run: function () { set({ cursor: state.cursor === "on" ? "off" : "on" }); },
      });
    }
    if (hasReading) {
      out.push({
        t: W.reading + ": " + (state.reading === "on" ? "off, back to how I had it" : "on"), k: "reading", i: "book-open-text",
        x: "calm read quiet focus still contrast accessibility dyslexia simple plain", run: function () { toggleReading(); },
      });
    }
    if (hasReading) {
      out.push({ t: W.textSize + ": larger", k: "text", i: "text-aa", x: "bigger zoom font size read accessibility", run: function () { stepText(1); } });
      out.push({ t: W.textSize + ": smaller", k: "text", i: "text-aa", x: "zoom font size read", run: function () { stepText(-1); } });
      if (hasMeasure) {
        out.push({
          t: W.measure + ": on or off", k: "text", i: "text-align-left", x: "line width measure narrow column read accessibility",
          run: function () { set({ measure: state.measure === "comfy" ? "full" : "comfy" }); },
        });
      }
    }
    if (hasContact) out.push({ t: (CONTACT.title || W.contact) + ": every way to reach us", k: "contact", i: "envelope-simple", x: "contact email form message question help reach out", run: openContact });
    if (hasCommunity) out.push({ t: (COMM.title || W.community) + ": the community", k: "community", i: COMM.icon || "users-three", x: "community chat talk join sign up members discord telegram mighty", run: openCommunity });
    out.push({ t: W.openGuide, k: "guide", i: "compass", x: "help onboarding tour welcome how", run: function () { openGuide(); } });
    out.push({ t: "Copy a link to this page", k: "action", i: "link", x: "share url card preview telegram", run: copyLink });
    return out;
  }
  function staticItems() {
    return [].concat((C.search && C.search.items) || [], site.items || []);
  }
  function norm(s) {
    return String(s == null ? "" : s)
      .toLowerCase()
      .normalize("NFD")
      .replace(/[̀-ͯ]/g, "")
      .replace(/[^a-z0-9]+/g, " ")
      .trim();
  }
  function subseq(w, s) {
    var i = 0;
    for (var c = 0; c < s.length && i < w.length; c++) if (s[c] === w[i]) i++;
    return i === w.length;
  }
  function rank(q, items) {
    var words = norm(q).split(" ").filter(Boolean);
    var out = [];
    items.forEach(function (it) {
      var t = norm(it.t);
      var hay = norm([it.t, it.k, it.s, it.x, it.who, it.from, it.d, fmtDate(it.d, true)].join(" "));
      var s = 0;
      for (var i = 0; i < words.length; i++) {
        var w = words[i];
        if (t.indexOf(w) === 0) s += 8;
        else if ((" " + t).indexOf(" " + w) >= 0) s += 6;
        else if (t.indexOf(w) >= 0) s += 4;
        else if ((" " + hay).indexOf(" " + w) >= 0) s += 3;
        else if (hay.indexOf(w) >= 0) s += 2;
        else if (w.length > 2 && subseq(w, t)) s += 1;
        else return;
      }
      out.push({ it: it, s: s });
    });
    out.sort(function (a, b) {
      return b.s - a.s || String(b.it.d || "").localeCompare(String(a.it.d || ""));
    });
    return out.slice(0, 40).map(function (x) {
      return x.it;
    });
  }
  function highlight(text, q) {
    var h = esc(text);
    norm(q).split(" ").filter(function (w) { return w.length > 1; }).forEach(function (w) {
      var re = new RegExp("(" + w.replace(/[.*+?^${}()|[\]\\]/g, "\\$&") + ")", "i");
      h = h.replace(re, "<mark>$1</mark>");
    });
    return h;
  }

  var pal = null;
  var shown = [];
  var sel = 0;
  var loaded = null;

  function openPalette() {
    if (!pal) {
      pal = makeDialog("arr-palette", "arr-pal-label");
      pal.innerHTML = panel(
        '<label class="arr-sr" id="arr-pal-label" for="arr-pal-input">' + esc(W.search) + "</label>" +
        '<div class="arr-pal-bar">' + icon("magnifying-glass") +
        '<input id="arr-pal-input" type="text" role="combobox" aria-expanded="true" aria-controls="arr-pal-list" aria-autocomplete="list" autocomplete="off" spellcheck="false" placeholder="' + esc(W.searchPlaceholder) + '">' +
        '<kbd class="arr-hover-only">esc</kbd><button type="button" class="arr-x arr-shape arr-touch-only" data-arr-close aria-label="Close search">' + icon("x") + "</button></div>" +
        '<ul class="arr-pal-list" id="arr-pal-list" role="listbox" aria-label="Results"></ul>' +
        '<div class="arr-pal-foot arr-hover-only"><span><kbd>↑</kbd><kbd>↓</kbd> move</span><span><kbd>↵</kbd> open</span><span><kbd>esc</kbd> close</span><span><kbd>?</kbd> guide</span><span class="arr-pal-status" aria-live="polite"></span></div>',
        "arr-pal-panel"
      );
      var inp = pal.querySelector("input");
      inp.addEventListener("input", function () {
        sel = 0;
        renderPalette();
      });
      inp.addEventListener("keydown", function (e) {
        if (e.key === "ArrowDown") {
          e.preventDefault();
          move(1);
        } else if (e.key === "ArrowUp") {
          e.preventDefault();
          move(-1);
        } else if (e.key === "Enter") {
          e.preventDefault();
          go(shown[sel], e.metaKey || e.ctrlKey);
        }
      });
      var list = pal.querySelector("ul");
      list.addEventListener("click", function (e) {
        var li = e.target.closest("[data-i]");
        if (li) go(shown[+li.getAttribute("data-i")], e.metaKey || e.ctrlKey);
      });
      list.addEventListener("mousemove", function (e) {
        var li = e.target.closest("[data-i]");
        if (li && +li.getAttribute("data-i") !== sel) {
          sel = +li.getAttribute("data-i");
          paintSel();
        }
      });
    }
    var input = pal.querySelector("input");
    input.value = "";
    sel = 0;
    renderPalette();
    show(pal, input);
    if (!loaded) {
      index().then(function (ix) {
        loaded = ix;
        if (pal.open) renderPalette();
      });
    }
  }
  function move(d) {
    if (!shown.length) return;
    sel = (sel + d + shown.length) % shown.length;
    paintSel();
  }
  function paintSel() {
    var opts = pal.querySelectorAll("[data-i]");
    for (var i = 0; i < opts.length; i++) opts[i].setAttribute("aria-selected", String(+opts[i].getAttribute("data-i") === sel));
    var input = pal.querySelector("input");
    input.setAttribute("aria-activedescendant", shown.length ? "arr-opt-" + sel : "");
    var on = pal.querySelector('[aria-selected="true"]');
    if (on && on.scrollIntoView) on.scrollIntoView({ block: "nearest" });
  }
  function option(it, i, q) {
    var meta = [isFresh(it) ? W.newTag : "", it.from, it.k].filter(Boolean).join(" · ");
    return (
      '<li role="option" class="arr-opt-row' + (isFresh(it) ? " arr-opt-new" : "") + '" id="arr-opt-' + i + '" data-i="' + i + '" aria-selected="false">' +
      '<span class="arr-opt-icon">' + icon(it.i || (it.run ? "lightning" : "arrow-right")) + "</span>" +
      '<span class="arr-opt-main"><span class="arr-opt-title">' + highlight(it.t, q) + "</span>" +
      (it.s ? '<span class="arr-opt-sub">' + esc(it.s) + "</span>" : "") + "</span>" +
      '<span class="arr-opt-meta">' + esc(meta) + (it.d ? "<time>" + esc(fmtDate(it.d)) + "</time>" : "") + "</span></li>"
    );
  }
  function renderPalette() {
    var q = pal.querySelector("input").value;
    var list = pal.querySelector("ul");
    var status = pal.querySelector(".arr-pal-status");
    var content = loaded ? loaded.items : [];
    var html = "";
    if (!norm(q)) {
      var groups = [];
      if (fresh.length) groups.push([W.newSince + (visit && visit.since ? " · " + fmtTime(visit.since) : ""), fresh.slice(0, 12)]);
      var pinH = {};
      var pinned = content.concat(staticItems()).filter(function (x) {
        if (!x.pin || (x.h && pinH[x.h])) return false;
        if (x.h) pinH[x.h] = 1;
        return true;
      });
      if (pinned.length) groups.push(["Jump to", pinned]);
      var latest = content
        .filter(function (x) { return x.type === "entry"; })
        .sort(function (a, b) { return String(b.d || "").localeCompare(String(a.d || "")); })
        .slice(0, 5);
      if (latest.length) groups.push(["Latest changes", latest]);
      groups.push(["Try", actions().filter(function (a) { return a.k === "guide" || a.k === "contrast" || a.k === "reading" || a.k === "contact" || a.k === "community"; })]);
      shown = [];
      groups.forEach(function (g) {
        html += '<li role="presentation" class="arr-pal-group">' + esc(g[0]) + "</li>";
        g[1].forEach(function (it) {
          html += option(it, shown.length, "");
          shown.push(it);
        });
      });
    } else {
      var seenH = {};
      var pool = content.concat(staticItems()).filter(function (it) {
        if (!it.h) return true;
        if (seenH[it.h]) return false;
        seenH[it.h] = 1;
        return true;
      });
      shown = rank(q, pool.concat(actions()));
      html = shown.map(function (it, i) { return option(it, i, q); }).join("");
      if (!shown.length) html = '<li role="presentation" class="arr-pal-empty">' + esc(loaded ? W.nothing : "Loading the index…") + "</li>";
    }
    list.innerHTML = html;
    if (status) status.textContent = norm(q) ? shown.length + (shown.length === 1 ? " result" : " results") : "";
    sel = Math.min(sel, Math.max(0, shown.length - 1));
    paintSel();
  }
  function go(it, newTab) {
    if (!it) return;
    var via = it.open || (it.h && !newTab ? interceptOf(it.h) : null);
    if (via && !canOpen(via)) via = null;
    hide(pal, !!it.h && !via);
    if (it.run) {
      it.run();
      return;
    }
    if (via) {
      open(via);
      return;
    }
    if (!it.h) return;
    if (it.h.charAt(0) === "#") {
      var t = doc.querySelector(it.h);
      if (t) t.scrollIntoView({ behavior: state.motion === STILL ? "auto" : "smooth" });
      return;
    }
    if (newTab) window.open(it.h, "_blank", "noopener");
    else location.href = it.h;
  }
  function copyLink() {
    var url = location.href.replace(/#welcome$/, "");
    var done = function () { toast(W.copied); };
    try {
      navigator.clipboard.writeText(url).then(done, function () { toast(url); });
    } catch (e) {
      toast(url);
    }
  }
  var toastEl = null;
  var toastT = 0;
  function toast(msg) {
    if (!toastEl) {
      toastEl = doc.createElement("div");
      toastEl.className = "arr-toast arr-shape";
      toastEl.setAttribute("role", "status");
      doc.body.appendChild(toastEl);
    }
    toastEl.textContent = msg;
    toastEl.classList.add("is-on");
    clearTimeout(toastT);
    toastT = setTimeout(function () { toastEl.classList.remove("is-on"); }, 2200);
  }

  /* ── avatars ───────────────────────────────────────────────────────────────────────────── */
  function initialsOf(name) {
    var parts = String(name || "?").replace(/[^A-Za-z0-9À-ɏ\s'-]/g, " ").trim().split(/\s+/).filter(Boolean);
    if (!parts.length) return "?";
    var a = parts.length > 1 ? parts[0].charAt(0) + parts[parts.length - 1].charAt(0) : parts[0].slice(0, 2);
    return a.toUpperCase();
  }
  function fnv(s) {
    var h = 2166136261;
    for (var i = 0; i < s.length; i++) h = Math.imul(h ^ s.charCodeAt(i), 16777619);
    return h >>> 0;
  }
  function initials(name) {
    var A = C.avatar || {};
    var cols = A.colors || C.wedges || ["#5b6b8c", "#8c5b7a"];
    var h = fnv(String(name || ""));
    var c1 = cols[h % cols.length];
    var c2 = cols[(h + Math.max(1, Math.floor(cols.length / 3))) % cols.length];
    var ini = initialsOf(name);
    var svg;
    if (typeof A.svg === "function") {
      svg = A.svg(ini, c1, c2, name);
    } else {
      var shape =
        A.shape === "octagon"
          ? '<polygon points="29.3,0 70.7,0 100,29.3 100,70.7 70.7,100 29.3,100 0,70.7 0,29.3" fill="url(#g)"/><polygon points="31,5 69,5 95,31 95,69 69,95 31,95 5,69 5,31" fill="none" stroke="#fff" stroke-opacity=".45" stroke-width="2"/>'
          : A.shape === "square"
          ? '<rect width="100" height="100" rx="20" fill="url(#g)"/>'
          : '<circle cx="50" cy="50" r="50" fill="url(#g)"/>';
      svg =
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><defs><linearGradient id="g" x1="0" y1="0" x2="1" y2="1">' +
        '<stop offset="0" stop-color="' + c1 + '"/><stop offset="1" stop-color="' + c2 + '"/></linearGradient></defs>' + shape +
        '<text x="50" y="50" dy=".35em" text-anchor="middle" font-family="' + esc(A.font || "system-ui, -apple-system, Segoe UI, sans-serif") +
        '" font-size="' + (ini.length > 1 ? 38 : 46) + '" font-weight="700" fill="#fff" stroke="rgba(0,0,0,.28)" stroke-width="3" paint-order="stroke">' +
        esc(ini) + "</text></svg>";
    }
    return "data:image/svg+xml;charset=utf-8," + encodeURIComponent(svg);
  }
  function roleAddress(email) {
    var domains = (C.avatar && C.avatar.roleDomains) || [];
    var at = String(email || "").trim().toLowerCase().split("@");
    if (at.length !== 2) return false;
    var ok = domains.some(function (d) { return at[1] === String(d).toLowerCase(); });
    if (!ok && window.console) console.warn("[arrival] Gravatar is only used for org-domain role addresses; ignoring " + at[1]);
    return ok;
  }
  function gravatar(email, size) {
    if (!window.crypto || !crypto.subtle || !window.TextEncoder) return Promise.resolve(null);
    return crypto.subtle.digest("SHA-256", new TextEncoder().encode(String(email).trim().toLowerCase())).then(function (buf) {
      var hex = Array.prototype.map.call(new Uint8Array(buf), function (b) { return ("0" + b.toString(16)).slice(-2); }).join("");
      return "https://gravatar.com/avatar/" + hex + "?s=" + size * 2 + "&d=404";
    });
  }
  function renderAvatar(el) {
    var name = el.getAttribute("name") || "";
    var gh = el.getAttribute("github");
    var email = el.getAttribute("email");
    var size = +el.getAttribute("size") || 32;
    var img = doc.createElement("img");
    var fallback = initials(name);
    img.className = "arr-avatar-img";
    img.alt = el.hasAttribute("alt") ? el.getAttribute("alt") : "";
    img.width = img.height = size;
    img.decoding = "async";
    img.referrerPolicy = "no-referrer";
    img.onerror = function () {
      img.onerror = null;
      img.src = fallback;
    };
    if (gh) {
      img.src = "https://github.com/" + encodeURIComponent(gh) + ".png?size=" + Math.min(460, size * 2);
    } else {
      img.src = fallback;
      if (email && roleAddress(email)) {
        gravatar(email, size).then(function (u) {
          if (!u) return;
          var probe = new Image();
          probe.referrerPolicy = "no-referrer";
          probe.onload = function () { img.src = u; };
          probe.src = u;
        });
      }
    }
    el.style.setProperty("--arr-avatar", size + "px");
    if (!el.title && name) el.title = name;
    el.textContent = "";
    el.appendChild(img);
  }
  function avatarTag(p, size) {
    return (
      '<arrival-avatar name="' + esc(p.name) + '"' + (p.github ? ' github="' + esc(p.github) + '"' : "") +
      (p.email ? ' email="' + esc(p.email) + '"' : "") + ' size="' + (size || 40) + '"></arrival-avatar>'
    );
  }
  function renderPeople(el) {
    var compact = el.hasAttribute("compact");
    el.innerHTML = '<p class="arr-fine">Gathering who made the changes…</p>';
    index().then(function (ix) {
      if (!ix.people.length) {
        el.innerHTML = "";
        el.hidden = true;
        return;
      }
      el.innerHTML =
        '<ul class="arr-people' + (compact ? " arr-people-compact" : "") + '">' +
        ix.people.map(function (p) {
          // A GitHub handle gives the picture and the link; someone shown with a generated avatar can
          // still have a profile link (search.json: profile), so their name links too.
          var href = p.github ? "https://github.com/" + p.github : /^https:\/\//.test(p.profile || "") ? p.profile : "";
          var name = href ? '<a href="' + esc(href) + '">' + esc(p.name) + "</a>" : esc(p.name);
          return (
            "<li>" + avatarTag(p, compact ? 36 : 48) +
            '<span class="arr-person"><span class="arr-person-name">' + name + "</span>" +
            (p.role ? '<span class="arr-person-role">' + esc(p.role) + "</span>" : "") + "</span>" +
            (p.count != null ? '<span class="arr-person-count">' + p.count + (p.count === 1 ? " entry" : " entries") + "</span>" : "") +
            "</li>"
          );
        }).join("") +
        "</ul>";
    });
  }
  function renderLatest(el) {
    var limit = +el.getAttribute("limit") || 4;
    index().then(function (ix) {
      var list = ix.items
        .filter(function (x) { return x.type === "entry"; })
        .sort(function (a, b) { return String(b.d || "").localeCompare(String(a.d || "")); })
        .slice(0, limit);
      if (!list.length) {
        el.hidden = true;
        return;
      }
      el.innerHTML =
        '<ul class="arr-latest">' +
        list.map(function (it) {
          return (
            '<li><a href="' + esc(it.h) + '"><time datetime="' + esc(it.d) + '">' + esc(fmtDate(it.d)) + "</time>" +
            '<span class="arr-latest-title">' + esc(it.t) + "</span>" +
            '<span class="arr-latest-meta">' + esc([it.k, it.who ? "by " + it.who : ""].filter(Boolean).join(" · ")) + "</span></a></li>"
          );
        }).join("") +
        "</ul>";
      markNew(el);
    });
  }

  /* ── what's new since your last visit ─────────────────────────────────────────────────────
     A visit is a run of page views with no gap longer than news.gapMinutes (30). The visits record
     lives under its own key (<storage key>:visits), every access guarded:
       { since: when the previous visit ended, at: last activity, prev: [keys known at the previous
         visit], seen: [keys known now], ack: when the count was opened, opened: [new pages visited] }
     An item is new when its time is after `since` and the previous visit didn't already know it.
     Items carry `ts` (ISO time, exact: ledger commits) or only `d` (a date, counted as the end of
     that day; the `prev` list stops a same-day entry the visitor already saw from counting twice).
     The first visit records the time and shows nothing; the splash covers first visits. */
  var NEWS_CFG = site.news !== undefined ? site.news : C.news;
  var hasNews = NEWS_CFG !== false && store.ok && !!window.fetch;
  var NC = NEWS_CFG && typeof NEWS_CFG === "object" ? NEWS_CFG : {};
  var VKEY = NC.key || KEY + ":visits";
  var GAP = (NC.gapMinutes || 30) * 60000;
  var NEWS_TYPES = NC.types || ["entry", "doc", "ledger"];
  var DAY = 86400000;
  var visit = null;
  var fresh = [];
  var freshKeys = {};
  var newsP = null;

  function fmtTime(ms) {
    try {
      return new Date(ms).toLocaleDateString("en-US", { month: "short", day: "numeric" });
    } catch (e) {
      return "";
    }
  }
  function normUrl(h) {
    if (!h) return "";
    try {
      var u = new URL(h, location.href);
      return (u.origin + u.pathname).replace(/\/+$/, "").toLowerCase();
    } catch (e) {
      return String(h).replace(/[#?].*$/, "").replace(/\/+$/, "").toLowerCase();
    }
  }
  function keyOf(it) {
    return fnv(normUrl(it.h) || String(it.id || it.t || "")).toString(36);
  }
  function itemTime(it) {
    if (it.ts) {
      var t = Date.parse(it.ts);
      if (!isNaN(t)) return t;
    }
    var m = /^(\d{4})-(\d{2})-(\d{2})/.exec(it.d || "");
    return m ? new Date(+m[1], +m[2] - 1, +m[3], 23, 59, 59, 999).getTime() : NaN;
  }
  function uniqCap(list, n) {
    var seenK = {};
    var out = [];
    for (var i = list.length - 1; i >= 0 && out.length < n; i--) {
      if (seenK[list[i]]) continue;
      seenK[list[i]] = 1;
      out.unshift(list[i]);
    }
    return out;
  }
  function saveVisit() {
    if (visit) store.set(VKEY, JSON.stringify(visit));
  }
  function startVisit() {
    if (!hasNews) return;
    var now = Date.now();
    var v = null;
    try {
      v = JSON.parse(store.get(VKEY) || "null");
    } catch (e) {}
    if (!v || typeof v !== "object" || typeof v.at !== "number") {
      visit = { first: true, since: now, at: now, prev: [], seen: [], ack: 0, opened: [] };
    } else if (now - v.at > GAP || v.at > now) {
      visit = { since: Math.min(v.at, now), at: now, prev: uniqCap([].concat(v.prev || [], v.seen || []), 400), seen: [], ack: 0, opened: [] };
    } else {
      visit = v;
      visit.at = now;
      visit.prev = visit.prev || [];
      visit.seen = visit.seen || [];
      visit.opened = visit.opened || [];
    }
    saveVisit();
  }
  function newsItems() {
    var list = NC.sources;
    if (!list || !list.length) return index().then(function (ix) { return ix.items; });
    return Promise.all(
      list.map(function (src) {
        var url = typeof src === "string" ? src : src && src.url;
        if (!url) return [];
        return fetch(url, { credentials: "omit" })
          .then(function (r) { return r.ok ? r.json() : null; })
          .catch(function () { return null; })
          .then(function (j) {
            var items = (j && j.items) || [];
            return src && src.label ? items.map(function (it) { return assign({}, it, { from: src.label }); }) : items;
          });
      })
    ).then(function (parts) { return [].concat.apply([], parts); });
  }
  function loadNews() {
    if (!hasNews || !visit) return Promise.resolve([]);
    if (newsP) return newsP;
    newsP = newsItems().then(function (items) {
      var now = Date.now();
      var prev = {};
      visit.prev.forEach(function (k) { prev[k] = 1; });
      var dup = {};
      var out = [];
      items.forEach(function (it) {
        if (!it || !it.t || (it.type && NEWS_TYPES.indexOf(it.type) < 0)) return;
        var t = itemTime(it);
        if (isNaN(t)) return;
        var k = keyOf(it);
        if (dup[k]) return;
        dup[k] = 1;
        // What this visit knows, for the next one: recent items up to the end of today (a date-only
        // item counts from the end of its day). Anything stamped later than that can't have been
        // seen yet (a clock behind the server's), so it stays eligible to count as new.
        if (t >= now - 3 * DAY && t <= now + DAY) visit.seen.push(k);
        if (!visit.first && t > visit.since && !prev[k]) out.push(assign({}, it, { _k: k, _t: t }));
      });
      visit.seen = uniqCap(visit.seen, 400);
      out.sort(function (a, b) { return b._t - a._t; });
      fresh = out;
      freshKeys = {};
      fresh.forEach(function (x) { freshKeys[x._k] = x; });
      // Opening one of the new pages counts as seeing it.
      var here = fnv(normUrl(location.href)).toString(36);
      if (freshKeys[here] && visit.opened.indexOf(here) < 0) visit.opened.push(here);
      saveVisit();
      syncNews();
      markNew();
      if (fresh.length) {
        emit("arrival:news", { count: unread(), items: fresh.slice(), since: visit.since });
        setTimeout(showTip, 700);
      }
      return fresh;
    });
    return newsP;
  }
  function isFresh(it) {
    return !!(it && fresh.length && freshKeys[it._k || keyOf(it)]);
  }
  function unread() {
    if (!visit || visit.ack) return 0;
    return fresh.filter(function (x) { return visit.opened.indexOf(x._k) < 0; }).length;
  }
  function syncNews() {
    var n = unread();
    var nn = n > 99 ? "99+" : String(n);
    var list = doc.querySelectorAll("[data-arr-news]");
    for (var i = 0; i < list.length; i++) {
      var b = list[i];
      b.hidden = !n;
      if (!n) continue;
      var label = n + " " + W.newSince.charAt(0).toLowerCase() + W.newSince.slice(1) + (visit.since ? " (" + fmtTime(visit.since) + ")" : "");
      b.setAttribute("aria-label", label);
      b.setAttribute("title", label);
      var c = b.querySelectorAll("[data-arr-news-n]");
      for (var j = 0; j < c.length; j++) c[j].textContent = nn;
    }
    // The Menu button carries the count too, so a folded nav still shows it.
    var dots = doc.querySelectorAll("[data-arr-news-dot]");
    for (var k = 0; k < dots.length; k++) {
      dots[k].hidden = !n;
      dots[k].textContent = n ? nn : "";
    }
    if (!n) hideTip();
  }
  // Once per visit, a small tip under the count, so nobody misses it. It fades on its own.
  var tipT = 0;
  function showTip() {
    if (!visit || visit.tipped || !unread()) return;
    var tips = doc.querySelectorAll("[data-arr-news-tip]");
    var shown = false;
    for (var i = 0; i < tips.length; i++) {
      var b = tips[i].parentNode && tips[i].parentNode.querySelector("[data-arr-news]");
      if (!b || !b.getClientRects().length) continue;
      tips[i].textContent = W.newsTip.replace("{n}", unread() > 99 ? "99+" : String(unread()));
      tips[i].insertAdjacentHTML("beforeend", icon("arrow-right"));
      tips[i].hidden = false;
      // Keep it on screen: shift it right if it would start off the left edge, and move its arrow
      // the other way so it still points at the count.
      tips[i].style.right = "";
      var r = tips[i].getBoundingClientRect();
      var shift = r.left < 12 ? Math.ceil(12 - r.left) : 0;
      if (shift) tips[i].style.right = -shift + "px";
      tips[i].style.setProperty("--arr-tip-arrow", 18 + shift + "px");
      shown = true;
    }
    if (!shown) return;
    visit.tipped = true;
    saveVisit();
    clearTimeout(tipT);
    tipT = setTimeout(hideTip, 9000);
  }
  function hideTip() {
    var tips = doc.querySelectorAll("[data-arr-news-tip]");
    for (var i = 0; i < tips.length; i++) tips[i].hidden = true;
  }
  // Mark links (and [data-arr-key] rows) that point at something new.
  function markNew(scope) {
    if (!fresh.length) return;
    var list = (scope || doc).querySelectorAll("a[href], [data-arr-key]");
    for (var i = 0; i < list.length; i++) {
      var el = list[i];
      if (el.closest(".arr-dialog, arrival-controls, .arr-drawer")) continue;
      var raw = el.getAttribute("data-arr-key") || el.getAttribute("href");
      if (!raw || raw.charAt(0) === "#") continue;
      if (!freshKeys[fnv(normUrl(raw)).toString(36)]) continue;
      el.setAttribute("data-arr-new", "");
      var tag = el.querySelector("[data-arr-new-tag]");
      if (tag && !tag.textContent) {
        tag.textContent = W.newTag;
        tag.hidden = false;
      }
    }
  }
  // The count was opened: it has done its job for this visit (the marks stay until the next one).
  function ackNews() {
    hideTip();
    if (!visit || visit.ack) return;
    visit.ack = Date.now();
    saveVisit();
    syncNews();
  }

  /* ── v1.2 · the navbar: <arrival-nav> ─────────────────────────────────────────────────────
     ARRIVAL.nav = { items: [link | group], fold: 1100, menuLabel? }
       link:  { id, label, icon, href, hrefs?: { <siteId>: href }, open?: "contact" | "community" |
                "guide" | "search", exact?, priority? (lower folds first; default 2), keep?,
                sites?: [siteIds], hideOn?: [siteIds], note? (a line under it in menus) }
       group: { id, label, icon, items: [link…], priority?, keep? }   (a dropdown)
     The bar shows every item it can fit; the rest move into a "More" dropdown, so the bar never
     wraps. Below `fold` px the whole bar becomes a Menu button and panel. `current="<id>"` on the
     element marks the current item; otherwise it's matched from the URL. */
  var NAV = C.nav && C.nav.items && C.nav.items.length ? C.nav : null;
  function visibleOn(it) {
    if (!it) return false;
    if (it.sites && it.sites.indexOf(siteId) < 0) return false;
    if (it.hideOn && it.hideOn.indexOf(siteId) >= 0) return false;
    return true;
  }
  function navItems() {
    if (!NAV) return [];
    return NAV.items
      .filter(visibleOn)
      .map(function (it) {
        return it.items ? assign({}, it, { items: it.items.filter(visibleOn) }) : it;
      })
      .filter(function (it) {
        return !it.items || it.items.length;
      });
  }
  // Every link the nav knows, groups flattened, so the footer can name them by id.
  function navLinks() {
    var out = {};
    ((NAV && NAV.items) || []).forEach(function (it) {
      (it.items || [it]).forEach(function (x) {
        if (x.id) out[x.id] = x;
      });
    });
    return out;
  }
  function hrefOf(it) {
    return (it.hrefs && it.hrefs[siteId]) || it.href || "";
  }
  function isCurrent(it, forced) {
    if (forced) return it.id === forced;
    if (it.open || !hrefOf(it)) return false;
    var here = normUrl(location.href);
    var h = normUrl(hrefOf(it));
    if (here === h) return true;
    if (it.exact) return false;
    try {
      if (new URL(hrefOf(it), location.href).pathname.replace(/\/+$/, "") === "") return false;
    } catch (e) {}
    return here.indexOf(h + "/") === 0;
  }
  function linkTag(it, cls, forced, withNote) {
    var cur = isCurrent(it, forced);
    var href = hrefOf(it) || "#";
    return (
      '<a class="' + cls + (cur ? " is-current" : "") + '" href="' + esc(href) + '"' +
      (it.open ? ' data-arrival-open="' + esc(it.open) + '"' : "") + (cur ? ' aria-current="page"' : "") + ">" +
      icon(it.icon || "arrow-right") +
      '<span class="arr-nav-text"><span class="arr-nav-label">' + esc(it.label) + "</span>" +
      (withNote && it.note ? '<span class="arr-nav-note">' + esc(it.note) + "</span>" : "") +
      "</span></a>"
    );
  }
  var navUid = 0;
  var navHosts = [];
  function renderNav(host) {
    var items = navItems();
    if (!items.length) {
      host.hidden = true;
      return;
    }
    var n = ++navUid;
    var forced = host.getAttribute("current");
    var bar = "";
    var menus = "";
    var more = "";
    var mainLinks = [];
    var groups = [];
    items.forEach(function (it, k) {
      var pri = it.priority == null ? 2 : +it.priority;
      var li = '<li class="arr-nav-li" data-arr-nav-k="' + k + '" data-pri="' + pri + '"' + (it.keep ? " data-keep" : "") + ">";
      if (it.items) {
        var mid = "arr-nav-" + n + "-" + k;
        var cur = it.items.some(function (x) { return isCurrent(x, forced); });
        var rows = it.items.map(function (x) { return "<li>" + linkTag(x, "arr-nav-row", forced, true) + "</li>"; }).join("");
        bar +=
          li + '<button type="button" class="arr-nav-a arr-nav-btn' + (cur ? " is-current" : "") + '" data-arr-nav-toggle aria-expanded="false" aria-controls="' + mid + '">' +
          icon(it.icon || "list") + '<span class="arr-nav-label">' + esc(it.label) + '</span><i class="ph ph-caret-down arr-caret" aria-hidden="true"></i></button></li>';
        menus += '<div class="arr-nav-menu arr-lift" id="' + mid + '" hidden><div class="arr-frame arr-shape"><div class="arr-in arr-shape"><ul class="arr-nav-rows">' + rows + "</ul></div></div></div>";
        more += '<div class="arr-nav-more-group" data-arr-more-k="' + k + '" hidden><p class="arr-nav-more-h">' + icon(it.icon || "list") + esc(it.label) + '</p><ul class="arr-nav-rows">' + rows + "</ul></div>";
        groups.push({ label: it.label, icon: it.icon, rows: rows });
      } else {
        bar += li + linkTag(it, "arr-nav-a", forced) + "</li>";
        more += '<div data-arr-more-k="' + k + '" hidden><ul class="arr-nav-rows"><li>' + linkTag(it, "arr-nav-row", forced, true) + "</li></ul></div>";
        mainLinks.push("<li>" + linkTag(it, "arr-nav-row", forced, true) + "</li>");
      }
    });
    var moreId = "arr-nav-" + n + "-more";
    var menuId = "arr-menu-" + n;
    var sections = (mainLinks.length ? [{ label: NAV.menuMain || W.menuMain, icon: "compass", rows: mainLinks.join("") }] : []).concat(groups);
    host.innerHTML =
      '<nav class="arr-nav" aria-label="' + esc(NAV.label || W.nav) + '">' +
      '<ul class="arr-nav-bar">' + bar +
      '<li class="arr-nav-li arr-nav-more-li" data-arr-nav-more hidden><button type="button" class="arr-nav-a arr-nav-btn" data-arr-nav-toggle aria-expanded="false" aria-controls="' + moreId + '">' +
      icon("dots-three-circle") + '<span class="arr-nav-label">' + esc(NAV.moreLabel || W.more) + '</span><i class="ph ph-caret-down arr-caret" aria-hidden="true"></i></button></li>' +
      "</ul>" + menus +
      '<div class="arr-nav-menu arr-nav-more arr-lift" id="' + moreId + '" hidden><div class="arr-frame arr-shape"><div class="arr-in arr-shape">' + more + "</div></div></div>" +
      // Folded: one Menu button (it carries the what's-new count), and the panel it opens.
      '<button type="button" class="arr-chip arr-shape arr-menu-btn" data-arr-menu aria-expanded="false" aria-controls="' + menuId + '">' +
      '<span class="arr-menu-icon">' + icon("list") + '</span><span class="arr-menu-label">' + esc(NAV.menuLabel || W.menu) + "</span>" +
      '<span class="arr-menu-count" data-arr-news-dot hidden></span></button>' +
      '<div class="arr-menu-panel arr-lift" id="' + menuId + '" hidden><div class="arr-frame arr-shape"><div class="arr-in arr-shape">' +
      (hasNews
        ? '<button type="button" class="arr-menu-news arr-shape" data-arr-news hidden>' + icon("sparkle") + '<span><strong><span data-arr-news-n></span> ' +
          esc(W.newBadge) + "</strong> " + esc(W.newSince.charAt(0).toLowerCase() + W.newSince.slice(1)) + "</span>" + icon("arrow-right") + "</button>"
        : "") +
      '<div class="arr-menu-grid">' +
      sections.map(function (s) {
        return '<section class="arr-menu-sec"><p class="arr-menu-h">' + icon(s.icon || "list") + esc(s.label) + '</p><ul class="arr-nav-rows">' + s.rows + "</ul></section>";
      }).join("") +
      "</div></div></div></div></nav>";
    host.classList.add("arr-nav-host");
    navHosts.push(host);
    layoutNav(host);
    if (window.ResizeObserver) {
      var raf = 0;
      new ResizeObserver(function () {
        cancelAnimationFrame(raf);
        raf = requestAnimationFrame(function () { layoutNav(host); });
      }).observe(host);
    }
    if (doc.fonts && doc.fonts.ready) doc.fonts.ready.then(function () { layoutNav(host); });
    syncNews();
  }
  function foldAt() {
    return (NAV && +NAV.fold) || 1100;
  }
  function setNavMode(host, mode) {
    if (host._mode !== mode) {
      closeNavs(false);
      host._mode = mode;
      host.setAttribute("data-mode", mode);
    }
    attr("data-arr-nav", mode);
  }
  function layoutNav(host) {
    setNavMode(host, window.innerWidth < foldAt() ? "menu" : "bar");
    if (host._mode === "bar") fitNav(host);
  }
  function overflows(el) {
    return el.scrollWidth > el.clientWidth + 1;
  }
  // Priority+: show everything, then fold the lowest-priority items (rightmost first among equals)
  // into "More" until the bar fits. If even that can't fit, fold the whole bar into the Menu.
  function fitNav(host) {
    var bar = host.querySelector(".arr-nav-bar");
    if (!bar) return;
    var lis = [].slice.call(bar.querySelectorAll("[data-arr-nav-k]"));
    var moreLi = bar.querySelector("[data-arr-nav-more]");
    var copies = host.querySelectorAll("[data-arr-more-k]");
    var i;
    for (i = 0; i < lis.length; i++) lis[i].hidden = false;
    for (i = 0; i < copies.length; i++) copies[i].hidden = true;
    moreLi.hidden = true;
    if (!overflows(bar)) return;
    moreLi.hidden = false;
    var order = lis
      .filter(function (li) { return !li.hasAttribute("data-keep"); })
      .sort(function (a, b) {
        return +a.getAttribute("data-pri") - +b.getAttribute("data-pri") || +b.getAttribute("data-arr-nav-k") - +a.getAttribute("data-arr-nav-k");
      });
    for (i = 0; i < order.length && overflows(bar); i++) {
      order[i].hidden = true;
      var c = host.querySelector('[data-arr-more-k="' + order[i].getAttribute("data-arr-nav-k") + '"]');
      if (c) c.hidden = false;
    }
    if (overflows(bar)) setNavMode(host, "menu");
  }
  function panelOf(btn) {
    return btn && doc.getElementById(btn.getAttribute("aria-controls"));
  }
  function closeNavs(refocus) {
    var open = doc.querySelectorAll('[data-arr-nav-toggle][aria-expanded="true"], [data-arr-menu][aria-expanded="true"]');
    for (var i = 0; i < open.length; i++) {
      var b = open[i];
      b.setAttribute("aria-expanded", "false");
      var p = panelOf(b);
      if (p) p.hidden = true;
      if (b.hasAttribute("data-arr-menu")) {
        var lab = b.querySelector(".arr-menu-label");
        if (lab) lab.textContent = (NAV && NAV.menuLabel) || W.menu;
        var ic = b.querySelector(".arr-menu-icon");
        if (ic) ic.innerHTML = icon("list");
      }
      if (refocus) b.focus();
    }
  }
  function placeDropdown(host, btn, p) {
    p.style.left = "0px";
    var hr = host.getBoundingClientRect();
    var br = btn.getBoundingClientRect();
    var w = p.offsetWidth;
    var left = br.left - hr.left;
    var max = window.innerWidth - 12 - w - hr.left;
    p.style.left = Math.round(Math.max(12 - hr.left, Math.min(left, max))) + "px";
  }
  function placeMenu(btn, p) {
    var head = btn.closest("header") || btn.closest("arrival-nav") || btn;
    var top = Math.max(8, Math.round(head.getBoundingClientRect().bottom + 6));
    p.style.top = top + "px";
    p.style.maxHeight = Math.max(160, window.innerHeight - top - 12) + "px";
  }
  function openNav(btn) {
    closeDrawers(false);
    var p = panelOf(btn);
    if (!p) return;
    btn.setAttribute("aria-expanded", "true");
    p.hidden = false;
    var host = btn.closest("arrival-nav");
    if (btn.hasAttribute("data-arr-menu")) {
      var lab = btn.querySelector(".arr-menu-label");
      if (lab) lab.textContent = (NAV && NAV.menuClose) || W.menuClose;
      var ic = btn.querySelector(".arr-menu-icon");
      if (ic) ic.innerHTML = icon("x");
      placeMenu(btn, p);
    } else if (host) {
      placeDropdown(host, btn, p);
    }
    syncNews();
  }
  function navRows(p) {
    var list = p.querySelectorAll("a[href], button:not([hidden])");
    var out = [];
    for (var i = 0; i < list.length; i++) if (list[i].getClientRects().length) out.push(list[i]);
    return out;
  }
  window.addEventListener("resize", function () {
    var b = doc.querySelector('[data-arr-menu][aria-expanded="true"]');
    if (b) placeMenu(b, panelOf(b));
  });
  window.addEventListener(
    "scroll",
    function () {
      var b = doc.querySelector('[data-arr-menu][aria-expanded="true"]');
      if (b) placeMenu(b, panelOf(b));
    },
    { passive: true }
  );

  /* ── v1.2 · the footer: <arrival-footer> ──────────────────────────────────────────────────
     ARRIVAL.footer = { label?, groups: [{ label, icon, items: [navId | link] }], note? }. Without
     groups it repeats the nav: its links as one group, then each dropdown as its own. */
  function renderFooter(host) {
    var F = C.footer || {};
    var byNav = navLinks();
    var groups = F.groups;
    if (!groups) {
      var items = navItems();
      groups = [{ label: (NAV && NAV.menuMain) || W.menuMain, icon: "compass", items: items.filter(function (x) { return !x.items; }) }].concat(
        items.filter(function (x) { return x.items; }).map(function (g) { return { label: g.label, icon: g.icon, items: g.items }; })
      );
    }
    var html = groups
      .map(function (g) {
        var links = (g.items || [])
          .map(function (x) { return typeof x === "string" ? byNav[x] : x; })
          .filter(visibleOn);
        if (!links.length) return "";
        return (
          '<section class="arr-foot-group"><p class="arr-foot-h">' + icon(g.icon || "list") + esc(g.label) + "</p><ul>" +
          links.map(function (x) { return "<li>" + linkTag(x, "arr-foot-a", host.getAttribute("current")) + "</li>"; }).join("") +
          "</ul></section>"
        );
      })
      .join("");
    if (!html) {
      host.hidden = true;
      return;
    }
    host.innerHTML =
      '<nav class="arr-foot" aria-label="' + esc(F.label || W.footer) + '"><div class="arr-foot-groups">' + html + "</div>" +
      (F.note ? '<p class="arr-foot-note">' + F.note + "</p>" : "") + "</nav>";
    if (fresh.length) markNew(host);
  }

  /* ── v1.2 · contact and community modals ──────────────────────────────────────────────────
     ARRIVAL.contact = { title?, intro?, paths: [{ kind: "form" | "email" | "page" | "github" | "chat",
       label, href, note?, action?, icon?, placeholder? (text: shown instead of a link) }], fine?,
       intercept? (default true: a click on a link to one of these paths opens the modal instead) }
     ARRIVAL.community = { …v1.0 keys for the guide…, title?, intro?, platforms: [{ id, kind:
       "discord" | "telegram" | "mighty" | "whatsapp" | "substack" | "bespoke" | …, name, text?,
       status?: "live" | "soon", public?: { href, label, note }, join?: { href, label, note } }],
       bespoke?: { title, tag?, text, points?: [], note? }, fine?, intercept? (default true) }
     Placeholders never get a made-up link: a missing href renders as "coming soon". */
  var CONTACT = site.contact !== undefined ? site.contact : C.contact || null;
  var COMM = site.community !== undefined ? site.community : C.community || null;
  var hasContact = !!(CONTACT && CONTACT.paths && CONTACT.paths.length);
  var hasCommunity = !!(COMM && ((COMM.platforms && COMM.platforms.length) || COMM.bespoke));
  var PLATFORM = {
    discord: ["Discord", "discord-logo"],
    telegram: ["Telegram", "telegram-logo"],
    mighty: ["Mighty Networks", "users-three"],
    whatsapp: ["WhatsApp", "whatsapp-logo"],
    substack: ["Substack", "newspaper-clipping"],
    bespoke: ["Our own network", "graph"],
    forum: ["Forum", "chats-teardrop"],
    email: ["Email list", "envelope-simple"],
  };
  function hostOf(href) {
    try {
      var u = new URL(href, location.href);
      if (u.protocol === "mailto:") return decodeURIComponent(u.pathname);
      return (u.host.replace(/^www\./, "") + u.pathname).replace(/\/+$/, "");
    } catch (e) {
      return href;
    }
  }
  function modalHead(title, eyebrow, id) {
    return (
      '<div class="arr-modal-head"><div class="arr-head">' + markHTML() +
      '<span class="arr-eyebrow">' + esc(org.short || "") + (eyebrow ? " · " + esc(eyebrow) : "") + "</span></div>" +
      '<button type="button" class="arr-x arr-shape" data-arr-close aria-label="' + esc(W.close) + '">' + icon("x") + "</button></div>" +
      '<h2 class="arr-title" id="' + id + '">' + esc(title) + "</h2>"
    );
  }
  function softPlaceholder(text, tag) {
    return '<p class="arr-placeholder arr-shape">' + icon("note-pencil") + "<span><strong>" + esc(tag || "Placeholder.") + "</strong> " + text + "</span></p>";
  }
  function pathRow(p) {
    var ic = p.icon || { form: "note-pencil", email: "envelope-simple", page: "address-book", github: "github-logo", chat: "chat-circle-text", phone: "phone" }[p.kind] || "arrow-square-out";
    var head = '<span class="arr-path-icon arr-shape">' + icon(ic) + '</span><div class="arr-path-main"><h3>' + esc(p.label) + "</h3>";
    if (!p.href || p.placeholder) {
      return '<li class="arr-path arr-shape is-placeholder">' + head + (p.note ? "<p>" + p.note + "</p>" : "") + softPlaceholder(p.placeholder || "This way in isn't set up yet.") + "</div></li>";
    }
    var mail = /^mailto:/i.test(p.href);
    var where = hostOf(p.href);
    return (
      '<li class="arr-path arr-shape">' + head + (p.note ? "<p>" + p.note + "</p>" : "") +
      '<div class="arr-path-actions"><a class="arr-btn arr-btn-primary arr-shape" href="' + esc(p.href) + '"' + (mail ? "" : ' rel="noopener"') + ">" +
      icon(mail ? "paper-plane-tilt" : "arrow-square-out") + esc(p.action || (mail ? W.writeEmail : W.openLink)) + "</a>" +
      (mail ? '<button type="button" class="arr-btn arr-btn-quiet arr-shape" data-arr-copy="' + esc(where) + '">' + icon("copy") + esc(W.copyAddress) + "</button>" : "") +
      '<span class="arr-path-where">' + esc(where) + "</span></div></div></li>"
    );
  }
  var contactEl = null;
  function openContact() {
    if (!hasContact) return;
    if (!contactEl) {
      contactEl = makeDialog("arr-modal arr-contact", "arr-contact-title");
      contactEl.innerHTML = panel(
        modalHead(CONTACT.title || W.contact, W.contact, "arr-contact-title") +
        '<p class="arr-intro">' + (CONTACT.intro || esc(W.contactIntro)) + "</p>" +
        '<ul class="arr-paths">' + CONTACT.paths.map(pathRow).join("") + "</ul>" +
        (CONTACT.fine ? '<p class="arr-fine">' + CONTACT.fine + "</p>" : ""),
        "arr-modal-panel"
      );
    }
    show(contactEl, contactEl.querySelector(".arr-path a, .arr-path button") || contactEl.querySelector("[data-arr-close]"));
  }
  function platLink(l, which) {
    var ic = which === "public" ? "globe-simple" : "sign-in";
    var label = (l && l.label) || (which === "public" ? W.publicLink : W.joinLink);
    var note = l && l.note ? '<span class="arr-plat-note">' + esc(l.note) + "</span>" : "";
    if (!l || !l.href) {
      return '<span class="arr-plat-link is-off"><span class="arr-btn arr-btn-quiet arr-shape" aria-disabled="true">' + icon(ic) + esc(label) + '</span><span class="arr-plat-note">' + esc(W.soon) + "</span></span>";
    }
    return (
      '<span class="arr-plat-link"><a class="arr-btn ' + (which === "join" ? "arr-btn-primary" : "arr-btn-quiet") + ' arr-shape" href="' + esc(l.href) + '" rel="noopener">' +
      icon(ic) + esc(label) + "</a>" + note + "</span>"
    );
  }
  function platCard(p) {
    var k = PLATFORM[p.kind] || [p.kind || "", "chats-circle"];
    var soon = p.status === "soon" || (!(p.public && p.public.href) && !(p.join && p.join.href));
    return (
      '<li class="arr-plat arr-shape' + (soon ? " is-soon" : "") + '"><div class="arr-plat-head"><span class="arr-path-icon arr-shape">' + icon(p.icon || k[1]) + "</span>" +
      '<div class="arr-plat-title"><h3>' + esc(p.name || k[0]) + "</h3>" +
      '<span class="arr-plat-kind">' + esc(k[0]) + (soon ? ' · <span class="arr-soon">' + esc(W.soon) + "</span>" : "") + "</span></div></div>" +
      (p.text ? "<p>" + p.text + "</p>" : "") +
      '<div class="arr-plat-links">' + platLink(p.public, "public") + platLink(p.join, "join") + "</div></li>"
    );
  }
  function bespokeCard(b) {
    if (!b) return "";
    return (
      '<li class="arr-plat arr-plat-bespoke arr-shape"><div class="arr-plat-head"><span class="arr-path-icon arr-shape">' + icon(b.icon || "graph") + "</span>" +
      '<div class="arr-plat-title"><h3>' + esc(b.title || "A network of our own") + '</h3><span class="arr-plat-kind"><span class="arr-soon">' + esc(b.tag || W.sneak) + "</span></span></div></div>" +
      (b.text ? "<p>" + b.text + "</p>" : "") +
      (b.points && b.points.length ? '<ul class="arr-ticks">' + b.points.map(function (x) { return "<li>" + icon("sparkle") + "<span>" + x + "</span></li>"; }).join("") + "</ul>" : "") +
      (b.note ? '<p class="arr-fine">' + b.note + "</p>" : "") + "</li>"
    );
  }
  var communityEl = null;
  function openCommunity() {
    if (!hasCommunity) {
      if (COMM && COMM.href) location.href = COMM.href;
      return;
    }
    if (!communityEl) {
      communityEl = makeDialog("arr-modal arr-community", "arr-community-title");
      communityEl.innerHTML = panel(
        modalHead(COMM.title || W.community, COMM.eyebrow || "Community", "arr-community-title") +
        '<p class="arr-intro">' + (COMM.intro || esc(W.communityIntro)) + "</p>" +
        '<ul class="arr-plats">' + (COMM.platforms || []).map(platCard).join("") + bespokeCard(COMM.bespoke) + "</ul>" +
        (COMM.fine ? '<p class="arr-fine">' + COMM.fine + "</p>" : ""),
        "arr-modal-panel"
      );
    }
    show(communityEl, communityEl.querySelector(".arr-plat a") || communityEl.querySelector("[data-arr-close]"));
  }
  // Links that are really "contact" or "community" access points open the modal instead (a plain
  // click only: modifier and middle clicks still go straight there).
  var interceptMap = null;
  function intercepts() {
    if (interceptMap) return interceptMap;
    interceptMap = {};
    var add = function (href, what) {
      if (!href) return;
      var k = /^mailto:/i.test(href) ? "mailto:" + hostOf(href).toLowerCase() : normUrl(href);
      if (k) interceptMap[k] = what;
    };
    if (hasContact && CONTACT.intercept !== false) CONTACT.paths.forEach(function (p) { if (!p.placeholder) add(p.href, "contact"); });
    if (hasCommunity && COMM.intercept !== false) {
      (COMM.platforms || []).forEach(function (p) {
        add(p.public && p.public.href, "community");
        add(p.join && p.join.href, "community");
      });
    }
    return interceptMap;
  }
  function interceptOf(a) {
    var href = typeof a === "string" ? a : a.getAttribute("href");
    if (!href || href.charAt(0) === "#") return null;
    var k = /^mailto:/i.test(href) ? "mailto:" + hostOf(href).toLowerCase() : normUrl(href);
    return intercepts()[k] || null;
  }

  /* ── v1.2 · the donate page: <arrival-donate> ─────────────────────────────────────────────
     ARRIVAL.donate = { give: [{ label, href, icon?, note?, action? }], disclaimer?: { title?, text,
       placeholder? }, ledger?: { src (a contributors.json), title?, intro?, empty? }, crypto?:
       { title?, text?, note? } }. contributors.json: { updated, contributors: [{ name, github?,
       url?, kind?, since?, note? }] }, people who opted in to be named, nobody else. The crypto
       slot stays empty until a wallet module fills [data-arr-wallet-slot]; it never shows an
       address on its own. */
  var KINDS = { gift: ["Gift", "gift"], sponsor: ["Sponsor", "handshake"], time: ["Time and skills", "hand-heart"], "in-kind": ["In kind", "package"], founding: ["Founding", "plant"] };
  function renderDonate(el) {
    var D = C.donate || {};
    var L = D.ledger || null;
    var X = D.crypto || {};
    var n = ++uid;
    var h = "";
    if (D.give && D.give.length) {
      h +=
        '<section class="arr-give" aria-label="' + esc(D.giveLabel || "Ways to give") + '">' +
        D.give.map(function (g, i) {
          return (
            '<div class="arr-give-card arr-shape' + (i ? "" : " is-primary") + '"><h2>' + icon(g.icon || "heart") + esc(g.label) + "</h2>" +
            (g.note ? "<p>" + g.note + "</p>" : "") +
            (g.href
              ? '<a class="arr-btn ' + (i ? "arr-btn-quiet" : "arr-btn-primary") + ' arr-shape" href="' + esc(g.href) + '" rel="noopener">' + esc(g.action || "Give") + icon("arrow-square-out") + "</a>" +
                '<span class="arr-path-where">' + esc(hostOf(g.href)) + "</span>"
              : softPlaceholder(g.placeholder || "This way to give isn't set up yet.")) +
            "</div>"
          );
        }).join("") +
        "</section>";
    }
    if (D.disclaimer) {
      var dc = D.disclaimer;
      h +=
        '<aside class="arr-disclaimer arr-shape' + (dc.placeholder ? " is-placeholder" : "") + '" aria-label="' + esc(dc.title || "Please note") + '">' +
        '<p class="arr-disclaimer-h">' + icon(dc.placeholder ? "note-pencil" : "info") + esc(dc.title || "Please note") + (dc.placeholder ? ' <span class="arr-soon">Placeholder</span>' : "") + "</p>" +
        "<p>" + dc.text + "</p></aside>";
    }
    if (L) {
      h +=
        '<section class="arr-contrib" aria-labelledby="arr-contrib-' + n + '"><h2 id="arr-contrib-' + n + '">' + icon("hand-heart") + esc(L.title || "Contribution ledger") + "</h2>" +
        (L.intro ? '<p class="arr-intro">' + L.intro + "</p>" : "") + '<div data-arr-contrib><p class="arr-fine">Gathering the names…</p></div></section>';
    }
    h +=
      '<section class="arr-crypto arr-shape" data-arr-wallet-slot aria-labelledby="arr-crypto-' + n + '">' +
      '<h2 id="arr-crypto-' + n + '">' + icon(X.icon || "wallet") + esc(X.title || "Give with crypto") + ' <span class="arr-soon">' + esc(W.soon) + "</span></h2>" +
      "<p>" + (X.text || "A way to give with a crypto wallet is on its way. It isn't open yet.") + "</p>" +
      '<p class="arr-fine">' + (X.note || "No wallet address is published here yet. If you see one anywhere claiming to be ours, please check with us first.") + "</p></section>";
    el.innerHTML = h;
    if (!L) return;
    var box = el.querySelector("[data-arr-contrib]");
    var empty = function () {
      box.innerHTML = '<div class="arr-contrib-empty arr-shape">' + icon("plant") + "<p>" + (L.empty || "No names here yet. People who'd like to be thanked by name are listed here, only with their permission. Giving without a name is just as welcome.") + "</p></div>";
    };
    if (!L.src || !window.fetch) return empty();
    fetch(L.src, { credentials: "omit" })
      .then(function (r) { return r.ok ? r.json() : null; })
      .catch(function () { return null; })
      .then(function (j) {
        var list = (j && j.contributors) || [];
        if (!list.length) return empty();
        box.innerHTML =
          '<ul class="arr-contrib-list">' +
          list.map(function (c) {
            var k = KINDS[c.kind] || (c.kind ? [c.kind, "heart"] : null);
            var name = c.url || c.github ? '<a href="' + esc(c.url || "https://github.com/" + c.github) + '" rel="noopener">' + esc(c.name) + "</a>" : esc(c.name);
            return (
              '<li class="arr-contrib-item arr-shape">' + avatarTag(c, 48) +
              '<span class="arr-person"><span class="arr-person-name">' + name + "</span>" +
              (k ? '<span class="arr-contrib-kind">' + icon(k[1]) + esc(k[0]) + (c.since ? " · since " + esc(fmtMonth(c.since)) : "") + "</span>" : c.since ? '<span class="arr-contrib-kind">Since ' + esc(fmtMonth(c.since)) + "</span>" : "") +
              (c.note ? '<span class="arr-person-role">' + esc(c.note) + "</span>" : "") + "</span></li>"
            );
          }).join("") +
          "</ul>" + (j.updated ? '<p class="arr-fine">Updated ' + esc(fmtDate(j.updated, true)) + ".</p>" : "");
      });
  }
  function fmtMonth(s) {
    var m = /^(\d{4})-(\d{2})/.exec(String(s || ""));
    if (!m) return s;
    try {
      return new Date(Date.UTC(+m[1], +m[2] - 1, 15)).toLocaleDateString("en-US", { month: "long", year: "numeric", timeZone: "UTC" });
    } catch (e) {
      return s;
    }
  }

  /* ── v1.2 · the site map: <arrival-map src here> ──────────────────────────────────────────
     Reads a map.json (version 2), published by the AstroLog:
       { version: 2, title, desc, groups: [{ id, label, icon?, note? }], nodes: [{ id, group, name,
         line?, href?, open?, og? (absolute URL of its share image), icon?, self?, external? }] }
     and draws every destination as a card with its share image as the thumbnail. A node whose
     `self` equals `here` (default: this page's site id) says "You are here". The AstroLog renders
     the same markup at build time (MapGrid.astro), so both maps look alike. */
  function mapCard(nd, here) {
    var isHere = !!(here && nd.self === here);
    var thumb =
      '<span class="arr-map-thumb arr-shape">' +
      (nd.og ? '<img src="' + esc(nd.og) + '" alt="" width="1200" height="630" loading="lazy" decoding="async">' : '<span class="arr-map-noimg">' + icon(nd.icon || "globe-simple") + "</span>") +
      (isHere ? '<span class="arr-map-here">' + icon("map-pin") + esc(W.youAreHere) + "</span>" : "") + "</span>";
    var body =
      '<span class="arr-map-body"><span class="arr-map-name">' + icon(nd.icon || "arrow-right") + "<span>" + esc(nd.name) + "</span>" +
      (nd.external ? '<i class="ph ph-arrow-up-right arr-map-ext" aria-hidden="true"></i>' : "") + "</span>" +
      (nd.line ? '<span class="arr-map-line">' + esc(nd.line) + "</span>" : "") +
      (nd.href ? '<span class="arr-map-url">' + esc(hostOf(nd.href)) + "</span>" : "") + "</span>";
    return (
      '<li class="arr-map-item">' +
      (nd.href
        ? '<a class="arr-map-card arr-shape' + (isHere ? " is-here" : "") + '" href="' + esc(nd.href) + '"' + (nd.open ? ' data-arrival-open="' + esc(nd.open) + '"' : "") + (isHere ? ' aria-current="page"' : "") + ">" + thumb + body + "</a>"
        : '<div class="arr-map-card arr-shape is-static">' + thumb + body + "</div>") +
      "</li>"
    );
  }
  function mapHTML(m, here) {
    var groups = m.groups && m.groups.length ? m.groups : [{ id: "", label: "" }];
    return groups
      .map(function (g) {
        var nodes = (m.nodes || []).filter(function (nd) { return (nd.group || "") === (g.id || ""); });
        if (!nodes.length) return "";
        return (
          '<section class="arr-map-group">' + (g.label ? '<h2 class="arr-map-h">' + icon(g.icon || "map-trifold") + esc(g.label) + "</h2>" : "") +
          (g.note ? '<p class="arr-map-note">' + esc(g.note) + "</p>" : "") +
          '<ul class="arr-map-grid">' + nodes.map(function (nd) { return mapCard(nd, here); }).join("") + "</ul></section>"
        );
      })
      .join("");
  }
  function renderMap(el) {
    var src = el.getAttribute("src") || (C.map && C.map.src);
    var here = el.getAttribute("here") || siteId;
    if (!src || !window.fetch) return;
    el.innerHTML = '<p class="arr-fine">' + esc(W.mapLoading) + "</p>";
    fetch(src, { credentials: "omit" })
      .then(function (r) { return r.ok ? r.json() : null; })
      .catch(function () { return null; })
      .then(function (m) {
        if (!m || !m.nodes) {
          el.innerHTML = softPlaceholder("The map couldn't be drawn just now. Try again in a moment, or use the links in the menu.", "Not this time.");
          return;
        }
        el.innerHTML = '<div class="arr-map">' + mapHTML(m, here) + "</div>";
        if (fresh.length) markNew(el);
      });
  }

  /* ── custom elements (defined here in <head>, so they render as the parser reaches them) ── */
  function define(name, render) {
    if (!window.customElements || customElements.get(name)) return;
    customElements.define(
      name,
      class extends HTMLElement {
        connectedCallback() {
          if (this._arr) return;
          this._arr = true;
          render(this);
        }
      }
    );
  }
  define("arrival-controls", renderControls);
  define("arrival-avatar", renderAvatar);
  define("arrival-people", renderPeople);
  define("arrival-latest", renderLatest);
  define("arrival-nav", renderNav);
  define("arrival-footer", renderFooter);
  define("arrival-donate", renderDonate);
  define("arrival-map", renderMap);

  /* ── cursor effects: a trail behind the pointer, per motion level ────────────────────────
     motions[i].trail = true | { colors: [...], life: ms, width: px, alpha: 0..1, sparks: 0..1,
     sides: n }. No colors = a prism-hue sweep; sparks = the chance per move of shedding a small
     spinning n-sided spark. Runs only with cursor effects on, a moving motion and a fine pointer. */
  var stopTrail = null;
  var trailKey = "";
  function syncTrail() {
    var m = byId(MOTIONS, state.motion);
    var opt = m && m.trail;
    var want = !!opt && state.cursor === "on" && state.motion !== STILL && !media("(pointer: coarse)") && !!doc.body;
    var key = want ? state.motion : "";
    if (key === trailKey) return;
    if (stopTrail) {
      stopTrail();
      stopTrail = null;
    }
    trailKey = key;
    if (want) stopTrail = startTrail(opt === true ? {} : opt);
  }
  function startTrail(o) {
    var colors = o.colors && o.colors.length ? o.colors : null;
    var LIFE = o.life || 520;
    var WIDTH = o.width || 3.2;
    var ALPHA = o.alpha == null ? 0.8 : o.alpha;
    var SPARKS = o.sparks || 0;
    var SIDES = o.sides || 0;
    var canvas = doc.createElement("canvas");
    canvas.className = "arr-trail";
    canvas.setAttribute("aria-hidden", "true");
    doc.body.appendChild(canvas);
    var ctx = canvas.getContext("2d");
    if (!ctx) return function () { canvas.remove(); };
    var dpr = Math.min(2, window.devicePixelRatio || 1);
    var pts = [];
    var dust = [];
    var raf = 0;
    var n = 0;
    var size = function () {
      canvas.width = innerWidth * dpr;
      canvas.height = innerHeight * dpr;
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    };
    var poly = function (x, y, r, rot, sides) {
      ctx.beginPath();
      for (var k = 0; k < sides; k++) {
        var a = rot + (k * Math.PI * 2) / sides;
        if (k) ctx.lineTo(x + r * Math.cos(a), y + r * Math.sin(a));
        else ctx.moveTo(x + r * Math.cos(a), y + r * Math.sin(a));
      }
      ctx.closePath();
    };
    var frame = function () {
      raf = 0;
      var now = performance.now();
      while (pts.length && now - pts[0].t > LIFE) pts.shift();
      dust = dust.filter(function (d) { return now - d.t < d.life; });
      var mode = byId(MODES, themeOf(state.light));
      var dark = !!(mode && mode.dark);
      var a = dark ? ALPHA : ALPHA * 0.72;
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      ctx.globalCompositeOperation = dark ? "lighter" : "source-over";
      ctx.lineCap = "round";
      for (var i = 1; i < pts.length; i++) {
        var life = 1 - (now - pts[i].t) / LIFE;
        ctx.globalAlpha = Math.max(0, life * a);
        ctx.strokeStyle = colors
          ? colors[pts[i].c % colors.length]
          : "hsl(" + ((pts[i].t / 6 + i * 9) % 360) + "," + (dark ? 90 : 75) + "%," + (dark ? 68 : 52) + "%)";
        ctx.lineWidth = 0.5 + life * WIDTH;
        ctx.beginPath();
        ctx.moveTo(pts[i - 1].x, pts[i - 1].y);
        ctx.lineTo(pts[i].x, pts[i].y);
        ctx.stroke();
      }
      dust.forEach(function (d) {
        var age = (now - d.t) / d.life;
        d.vx *= 0.96;
        d.vy = d.vy * 0.96 + 0.025;
        d.x += d.vx;
        d.y += d.vy;
        d.rot += d.spin;
        ctx.globalAlpha = Math.max(0, (1 - age) * a);
        ctx.fillStyle = d.color;
        if (d.sides >= 3) poly(d.x, d.y, d.r * (1 - age * 0.4), d.rot, d.sides);
        else {
          ctx.beginPath();
          ctx.arc(d.x, d.y, d.r * (1 - age * 0.4), 0, Math.PI * 2);
        }
        ctx.fill();
      });
      ctx.globalAlpha = 1;
      if (pts.length || dust.length) raf = requestAnimationFrame(frame);
    };
    var moveFn = function (e) {
      if (e.pointerType === "touch") return;
      var t = performance.now();
      n++;
      pts.push({ x: e.clientX, y: e.clientY, t: t, c: Math.floor(n / 3) });
      if (pts.length > 64) pts.shift();
      if (SPARKS && Math.random() < SPARKS && dust.length < 60) {
        var ang = Math.random() * Math.PI * 2;
        var sp = 0.4 + Math.random() * 1.4;
        dust.push({
          x: e.clientX, y: e.clientY, vx: Math.cos(ang) * sp, vy: Math.sin(ang) * sp - 0.4,
          r: 1.6 + Math.random() * 2.6, rot: Math.random() * 6, spin: (Math.random() - 0.5) * 0.18,
          sides: SIDES, t: t, life: 600 + Math.random() * 500,
          color: colors ? colors[Math.floor(Math.random() * colors.length)] : "hsl(" + Math.floor(Math.random() * 360) + ",90%,70%)",
        });
      }
      if (!raf) raf = requestAnimationFrame(frame);
    };
    size();
    addEventListener("resize", size);
    addEventListener("pointermove", moveFn);
    return function () {
      cancelAnimationFrame(raf);
      removeEventListener("resize", size);
      removeEventListener("pointermove", moveFn);
      canvas.remove();
    };
  }

  /* ── events (delegated, so every copy of every control works) ─────────────────────────── */
  function inSplash(el) {
    return !!(splashEl && splashEl.contains(el));
  }
  doc.addEventListener("change", function (e) {
    var t = e.target;
    if (!t || !t.matches) return;
    var tentative = inSplash(t);
    if (t.matches("[data-arr-light]")) set({ light: t.value }, tentative);
    else if (t.matches("[data-arr-motion]")) set({ motion: t.value }, tentative);
    else if (t.matches("[data-arr-contrast]")) set({ contrast: t.checked ? "more" : "standard" }, tentative);
    else if (t.matches("[data-arr-cursor]")) set({ cursor: t.checked ? "on" : "off" }, tentative);
    else if (t.matches("[data-arr-text]")) set({ text: t.value }, tentative);
    else if (t.matches("[data-arr-measure]")) set({ measure: t.checked ? "comfy" : "full" }, tentative);
    else if (t.matches("[data-arr-reading]")) {
      if (t.checked !== (state.reading === "on")) toggleReading(tentative);
    }
  });
  function canOpen(what) {
    if (what === "contact") return hasContact;
    if (what === "community") return hasCommunity;
    return true;
  }
  doc.addEventListener("click", function (e) {
    var t = e.target && e.target.closest ? e.target : null;
    if (!t) return;
    var b;
    // v1.2: the nav's dropdowns and the Menu
    if ((b = t.closest("[data-arr-nav-toggle], [data-arr-menu]"))) {
      if (b.getAttribute("aria-expanded") === "true") closeNavs(true);
      else openNav(b);
      return;
    }
    if (!t.closest(".arr-nav-menu, .arr-menu-panel")) closeNavs(false);
    if ((b = t.closest("[data-arr-copy]"))) {
      var text = b.getAttribute("data-arr-copy");
      try {
        navigator.clipboard.writeText(text).then(function () { toast(W.addressCopied); }, function () { toast(text); });
      } catch (err) {
        toast(text);
      }
      return;
    }
    if ((b = t.closest("[data-arr-news-tip]"))) {
      ackNews();
      open("search");
      return;
    }
    // A plain click on a link that is really a contact or community access point opens its modal.
    var a = t.closest("a[href]");
    if (a && !e.defaultPrevented && e.button === 0 && !e.metaKey && !e.ctrlKey && !e.shiftKey && !e.altKey && !a.closest(".arr-dialog") && !a.hasAttribute("data-arrival-open") && !a.hasAttribute("data-arr-direct")) {
      var via = interceptOf(a);
      if (via && canOpen(via)) {
        e.preventDefault();
        closeDrawers(false);
        open(via);
        return;
      }
    }
    if ((b = t.closest("[data-arr-swatch]"))) {
      set({ light: b.getAttribute("data-arr-swatch") });
    } else if ((b = t.closest("[data-arr-cursor-toggle]"))) {
      set({ cursor: state.cursor === "on" ? "off" : "on" });
    } else if ((b = t.closest("[data-arr-reading-toggle]"))) {
      toggleReading();
    } else if ((b = t.closest("[data-arr-news]"))) {
      ackNews();
      closeDrawers(false);
      open("search");
    } else if ((b = t.closest("[data-arr-read-enter]"))) {
      if (state.reading !== "on") toggleReading(true);
      hide(splashEl);
    } else if ((b = t.closest("[data-arr-motion-toggle]"))) {
      set({ motion: state.motion === STILL ? state.moving || movingDefault() : STILL });
    } else if ((b = t.closest("[data-arr-drawer]"))) {
      if (b.getAttribute("aria-expanded") === "true") closeDrawers(true);
      else openDrawer(b);
      return;
    } else if ((b = t.closest("[data-arrival-open]"))) {
      var what = b.getAttribute("data-arrival-open");
      // Without a configured modal, a link keeps its own href (the no-JS fallback).
      if (!canOpen(what)) return;
      if (e.button !== 0 || e.metaKey || e.ctrlKey || e.shiftKey) {
        if (b.tagName === "A" && b.getAttribute("href") && b.getAttribute("href").charAt(0) !== "#") return;
      }
      e.preventDefault();
      closeDrawers(false);
      if (splashEl && splashEl.open) hide(splashEl, true);
      open(what, b.getAttribute("data-arrival-step"));
    } else if ((b = t.closest("[data-arr-enter]"))) {
      hide(splashEl);
    } else if ((b = t.closest("[data-arr-tour]"))) {
      hide(splashEl, true);
      openGuide();
    } else if ((b = t.closest("[data-arr-close]"))) {
      hide(b.closest("dialog"));
    } else if ((b = t.closest("[data-arr-step]"))) {
      goStep(+b.getAttribute("data-arr-step"));
    } else if ((b = t.closest("[data-arr-prev]"))) {
      goStep(step - 1);
    } else if ((b = t.closest("[data-arr-next]"))) {
      goStep(step + 1);
    }
    if (!t.closest(".arr-drawer-wrap, .arr-nav-menu, .arr-menu-panel")) closeDrawers(false);
  });
  // Focus leaving an open dropdown or Menu (Tab past its last link) closes it.
  doc.addEventListener("focusin", function (e) {
    var open = doc.querySelectorAll('[data-arr-nav-toggle][aria-expanded="true"], [data-arr-menu][aria-expanded="true"]');
    for (var i = 0; i < open.length; i++) {
      var p = panelOf(open[i]);
      if (e.target === open[i] || (p && p.contains(e.target))) continue;
      closeNavs(false);
      break;
    }
  });
  function typing(el) {
    if (!el) return false;
    if (el.isContentEditable) return true;
    if (el.tagName === "TEXTAREA" || el.tagName === "SELECT") return true;
    return el.tagName === "INPUT" && !/^(radio|checkbox|button|submit|reset|range|color|file)$/i.test(el.type);
  }
  doc.addEventListener("keydown", function (e) {
    if (e.defaultPrevented) return;
    var k = e.key;
    if ((k === "k" || k === "K") && (e.metaKey || e.ctrlKey) && !e.altKey) {
      e.preventDefault();
      if (pal && pal.open) hide(pal);
      else open("search");
      return;
    }
    if (k === "Escape") {
      var openN = doc.querySelector('[data-arr-nav-toggle][aria-expanded="true"], [data-arr-menu][aria-expanded="true"]');
      if (openN) {
        e.preventDefault();
        closeNavs(true);
        return;
      }
      var openD = doc.querySelector('[data-arr-drawer][aria-expanded="true"]');
      if (openD) {
        e.preventDefault();
        closeDrawers(true);
      }
      hideTip();
      return;
    }
    // Arrow keys inside the nav: Down on a dropdown button opens it; Up/Down/Home/End move between
    // its links (Tab works too, and leaving closes it).
    if (k === "ArrowDown" || k === "ArrowUp" || k === "Home" || k === "End") {
      var tg = e.target && e.target.closest ? e.target.closest("[data-arr-nav-toggle], [data-arr-menu]") : null;
      var pnl = e.target && e.target.closest ? e.target.closest(".arr-nav-menu, .arr-menu-panel") : null;
      if (tg && k === "ArrowDown") {
        e.preventDefault();
        if (tg.getAttribute("aria-expanded") !== "true") openNav(tg);
        var first = navRows(panelOf(tg))[0];
        if (first) first.focus();
        return;
      }
      if (pnl && !pnl.hidden) {
        var rows = navRows(pnl);
        var at = rows.indexOf(doc.activeElement);
        if (!rows.length) return;
        e.preventDefault();
        var to = k === "Home" ? 0 : k === "End" ? rows.length - 1 : at + (k === "ArrowDown" ? 1 : -1);
        if (to < 0) {
          var own = doc.querySelector('[aria-controls="' + pnl.id + '"]');
          if (own) own.focus();
          return;
        }
        rows[Math.min(rows.length - 1, to)].focus();
        return;
      }
    }
    if (typing(e.target) || e.metaKey || e.ctrlKey || e.altKey) return;
    if (k === "/") {
      e.preventDefault();
      if (splashEl && splashEl.open) hide(splashEl, true);
      if (guideEl && guideEl.open) hide(guideEl, true);
      open("search");
    } else if (k === "?") {
      if (pal && pal.open) return;
      e.preventDefault();
      if (splashEl && splashEl.open) hide(splashEl, true);
      open("guide");
    } else if (guideEl && guideEl.open && (k === "ArrowRight" || k === "ArrowLeft")) {
      if (e.target && e.target.type === "radio") return;
      e.preventDefault();
      goStep(step + (k === "ArrowRight" ? 1 : -1));
    }
  });
  window.addEventListener("hashchange", function () {
    if (location.hash === "#welcome") open("guide");
    else if ((location.hash === "#contact" || location.hash === "#community") && canOpen(location.hash.slice(1))) open(location.hash.slice(1));
  });

  function open(what, at) {
    if (what === "search") openPalette();
    else if (what === "guide") openGuide(at || undefined);
    else if (what === "splash") openSplash();
    else if (what === "copy") copyLink();
    else if (what === "contact") openContact();
    else if (what === "community") openCommunity();
  }
  function close() {
    stack.slice().forEach(function (d) { hide(d); });
  }

  function boot() {
    startVisit();
    sync();
    if (location.hash === "#welcome") openGuide();
    else if ((location.hash === "#contact" || location.hash === "#community") && canOpen(location.hash.slice(1))) open(location.hash.slice(1));
    else if (splashWanted()) openSplash();
    if (doc.querySelector("arrival-people, arrival-latest")) index();
    else idle(index);
    if (hasNews && visit && !visit.first) setTimeout(loadNews, 250);
    else if (hasNews && visit) idle(loadNews); // the first visit only records what it knows
  }
  if (doc.readyState === "loading") doc.addEventListener("DOMContentLoaded", boot);
  else boot();

  window.Arrival = {
    version: VERSION,
    get: get,
    set: function (patch) { set(patch, false); },
    open: open,
    close: close,
    index: index,
    initials: initials,
    reading: function (on) {
      if (on === undefined || !!on !== (state.reading === "on")) toggleReading();
      return state.reading === "on";
    },
    news: function () {
      return loadNews().then(function () { return { since: visit && visit.since, count: unread(), items: fresh.slice() }; });
    },
    config: C,
    site: site,
  };
})();
