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
 *   window.Arrival        { get, set, open, close, index, initials, version }
 *   <html data-cursor="on|off">: cursor effects (the kit's trail; sites key their own pointer effects
 *                        on it). Off when the visitor turns them off or motion is still.
 *   window "arrival:change" event whenever a choice changes
 */
(function () {
  "use strict";
  if (window.Arrival) return;

  var VERSION = "1.0.0";
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
      chosen: false,
    };
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
    if (!tentative) state.chosen = true;
    apply();
    store.set(KEY, JSON.stringify(state));
    sync();
    emit("arrival:change", get());
  }
  function get() {
    return { light: state.light, theme: themeOf(state.light), motion: state.motion, contrast: state.contrast, cursor: state.cursor, chosen: !!state.chosen };
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
      '<button type="button" class="arr-chip arr-shape arr-chip-search" data-arrival-open="search" aria-label="' + esc(W.search) + ' (press /)" title="' + esc(W.search) + ' (/)">' +
      icon("magnifying-glass") + '<span class="arr-chip-label">' + esc(W.search) + "</span><kbd>/</kbd></button>" +
      '<span class="arr-swatches" role="group" aria-label="' + esc(W.light) + '">' + swatches + "</span>" +
      '<button type="button" class="arr-chip arr-shape arr-chip-icon" data-arr-motion-toggle></button>' +
      (hasCursor ? '<button type="button" class="arr-chip arr-shape arr-chip-icon arr-cursor-btn" data-arr-cursor-toggle>' + icon("cursor-click") + "</button>" : "") +
      '<span class="arr-drawer-wrap">' +
      '<button type="button" class="arr-chip arr-shape" data-arr-drawer aria-label="' + esc(W.drawer) + '" aria-expanded="false" aria-controls="arr-drawer-' + n + '">' +
      icon("sliders-horizontal") + '<span class="arr-chip-label">' + esc(W.drawer) + "</span>" + '<i class="ph ph-caret-down arr-caret" aria-hidden="true"></i></button>' +
      '<div class="arr-drawer arr-lift" id="arr-drawer-' + n + '" hidden><div class="arr-frame arr-shape"><div class="arr-in arr-shape">' +
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
  function closeDrawers(refocus) {
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
          return (
            para(rec.intro) +
            '<div class="arr-two">' +
            '<div class="arr-box arr-shape"><h3>' + icon("clock-counter-clockwise") + esc(ch.name || "The changelog") + "</h3>" +
            para(ch.text || "What changed, when, and who did it. Short dated entries, newest first, each with a one-line summary and the full story folded underneath.") +
            link(ch.href, ch.label || "Read the changelog", "arrow-right") + "</div>" +
            '<div class="arr-box arr-shape"><h3>' + icon("books") + esc(li.name || "The library") + "</h3>" +
            para(li.text || "How things work. Longer write-ups that stay true over time, rather than news of one change.") +
            (li.href ? link(li.href, li.label || "Open the library", "arrow-right") : li.missing ? placeholder(li.missing) : "") + "</div>" +
            "</div>" +
            (rec.share ? '<p class="arr-notice">' + icon("share-network") + "<span>" + rec.share + "</span></p>" : "")
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
            '<div class="arr-split">' +
            '<fieldset class="arr-field"><legend>' + esc(W.motion) + '</legend><div class="arr-seg">' + motionRadios("arr-gm") + "</div>" +
            '<p class="arr-note" data-arr-motion-note aria-live="polite"></p>' + cursorSwitch() + "</fieldset>" +
            (hasContrast ? '<fieldset class="arr-field"><legend>' + esc(W.contrast) + "</legend>" + contrastSwitch() + "</fieldset>" : "") +
            "</div>" +
            '<p class="arr-fine">In the header, the pause button switches motion off and on in one click, and the pointer button does the same for cursor effects.</p>'
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
    var meta = [it.from, it.k].filter(Boolean).join(" · ");
    return (
      '<li role="option" class="arr-opt-row" id="arr-opt-' + i + '" data-i="' + i + '" aria-selected="false">' +
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
      groups.push(["Try", actions().filter(function (a) { return a.k === "guide" || a.k === "contrast"; })]);
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
    hide(pal, !!it.h);
    if (it.run) {
      it.run();
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
          var name = p.github ? '<a href="https://github.com/' + esc(p.github) + '">' + esc(p.name) + "</a>" : esc(p.name);
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
  });
  doc.addEventListener("click", function (e) {
    var t = e.target && e.target.closest ? e.target : null;
    if (!t) return;
    var b;
    if ((b = t.closest("[data-arr-swatch]"))) {
      set({ light: b.getAttribute("data-arr-swatch") });
    } else if ((b = t.closest("[data-arr-cursor-toggle]"))) {
      set({ cursor: state.cursor === "on" ? "off" : "on" });
    } else if ((b = t.closest("[data-arr-motion-toggle]"))) {
      set({ motion: state.motion === STILL ? state.moving || movingDefault() : STILL });
    } else if ((b = t.closest("[data-arr-drawer]"))) {
      if (b.getAttribute("aria-expanded") === "true") closeDrawers(true);
      else openDrawer(b);
      return;
    } else if ((b = t.closest("[data-arrival-open]"))) {
      e.preventDefault();
      var what = b.getAttribute("data-arrival-open");
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
    if (!t.closest(".arr-drawer-wrap")) closeDrawers(false);
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
      var openD = doc.querySelector('[data-arr-drawer][aria-expanded="true"]');
      if (openD) {
        e.preventDefault();
        closeDrawers(true);
      }
      return;
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
  });

  function open(what, at) {
    if (what === "search") openPalette();
    else if (what === "guide") openGuide(at || undefined);
    else if (what === "splash") openSplash();
    else if (what === "copy") copyLink();
  }
  function close() {
    stack.slice().forEach(function (d) { hide(d); });
  }

  function boot() {
    sync();
    if (location.hash === "#welcome") openGuide();
    else if (splashWanted()) openSplash();
    if (doc.querySelector("arrival-people, arrival-latest")) index();
    else idle(index);
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
    config: C,
    site: site,
  };
})();
