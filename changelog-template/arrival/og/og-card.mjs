// Arrival kit · social card generator (build time, static output).
// Canonical copy: drasticstatic/my-template changelog-template/arrival/og/og-card.mjs.
//
// Renders a 1200×630 JPEG for og:image / twitter:image from a small spec, with Satori (layout and
// text → SVG) and sharp (SVG → JPEG). No browser, no network: fonts and images are read from disk.
//
//   import { renderCard } from "./og-card.mjs";
//   const jpeg = await renderCard(
//     { eyebrow: "ORG AstroLog · Changelog", kicker: "orgspirituality.org", title: "…", summary: "…",
//       meta: "Oct 12, 2026 · By Renan Teixeira", footer: "octagon-religious-research-group-org.github.io",
//       lit: 1 },                       // which glyph wedge to light (null = all)
//     theme                             // the org's look: see THEME_EXAMPLE below
//   );
//
// In Astro, call it from a static endpoint (src/pages/og/[...slug].jpg.ts with getStaticPaths) and
// point the page's og:image at the output. Dependencies: satori, sharp (sharp ships with Astro and
// Next, but list it in package.json anyway). Fonts must be TTF/OTF/WOFF (not WOFF2).
import satori from "satori";
import sharp from "sharp";
import fs from "node:fs";

export const W = 1200;
export const H = 630;

// What an org passes in. ORG's values; copy and change for another org.
export const THEME_EXAMPLE = {
  background: "#100e1c",
  glows: ["rgba(155, 109, 255, 0.42)", "rgba(233, 190, 114, 0.30)", "rgba(111, 227, 214, 0.16)"],
  heading: "#f4effc",
  text: "#eee8f6",
  muted: "#b4abc9",
  accent: "#e9be72",
  ink: ["#b39bff", "#f08ccf", "#6fe3d6", "#f2c97f"],
  wedges: ["#5a43f0", "#9a4dff", "#d04ce8", "#e65aa8", "#f29a3a", "#e4d548", "#6fd84a", "#3ccfe0"],
  sides: 8, // the glyph's shape: ORG's octagon
  frame: "perforated", // "perforated" (ORG's blotter sheet) | "line" | "none"
  perf: "rgba(238, 232, 246, 0.30)",
  mark: null, // optional path to an official PNG/JPEG mark, drawn unmodified
  fonts: {
    heading: { name: "Fraunces", files: { 400: "fonts/Fraunces-400.ttf", 600: "fonts/Fraunces-600.ttf" } },
    body: { name: "Manrope", files: { 500: "fonts/Manrope-500.ttf", 700: "fonts/Manrope-700.ttf" } },
  },
};

const h = (type, style, children) => ({ type, props: { style, children } });
const clip = (s, n) => (s && s.length > n ? s.slice(0, n - 1).replace(/[\s,.;:]+\S*$/, "") + "…" : s || "");

function glyph(theme, lit, size) {
  const n = theme.sides || 8;
  const a0 = -90 - 180 / n;
  const pt = (r, k) => {
    const a = ((a0 + (360 / n) * k) * Math.PI) / 180;
    return `${(50 + r * Math.cos(a)).toFixed(2)},${(50 + r * Math.sin(a)).toFixed(2)}`;
  };
  let s = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" width="${size}" height="${size}">`;
  for (let k = 0; k < n; k++) {
    const c = theme.wedges[k % theme.wedges.length];
    const on = lit == null || lit === k;
    s += `<polygon points="50,50 ${pt(46, k)} ${pt(46, k + 1)}" fill="${c}" fill-opacity="${on ? 1 : 0.3}"/>`;
  }
  s += `<polygon points="${Array.from({ length: n }, (_, k) => pt(46, k)).join(" ")}" fill="none" stroke="${theme.heading}" stroke-opacity="0.55" stroke-width="3" stroke-linejoin="round"/></svg>`;
  return `data:image/svg+xml;base64,${Buffer.from(s).toString("base64")}`;
}

const fontCache = new Map();
function fonts(theme, base) {
  const key = JSON.stringify(theme.fonts) + base;
  if (fontCache.has(key)) return fontCache.get(key);
  const out = [];
  for (const role of ["heading", "body"]) {
    const f = theme.fonts[role];
    for (const [weight, file] of Object.entries(f.files)) {
      out.push({ name: f.name, data: fs.readFileSync(new URL(file, base)), weight: Number(weight), style: "normal" });
    }
  }
  fontCache.set(key, out);
  return out;
}

async function imageData(path, size) {
  const png = await sharp(fs.readFileSync(path)).resize(size, size, { fit: "cover" }).png().toBuffer();
  return `data:image/png;base64,${png.toString("base64")}`;
}

/**
 * spec: { eyebrow, kicker?, title, summary?, meta?, footer?, lit?, art? (path to a square image),
 *         figure? ({ svg, width, height }: an SVG drawn on the right, e.g. a miniature map) }
 * theme: see THEME_EXAMPLE. base: a file: URL that font/mark/art paths resolve against.
 */
export async function renderCard(spec, theme = THEME_EXAMPLE, base = new URL(".", import.meta.url)) {
  const T = theme;
  const title = clip(spec.title, 120);
  const titleSize = title.length > 90 ? 50 : title.length > 60 ? 58 : title.length > 34 ? 66 : 76;
  const head = T.fonts.heading.name;
  const body = T.fonts.body.name;
  const glow = T.glows || [];
  const bg = [
    glow[0] && `radial-gradient(circle at 88% 8%, ${glow[0]} 0%, transparent 46%)`,
    glow[1] && `radial-gradient(circle at 6% 104%, ${glow[1]} 0%, transparent 52%)`,
    glow[2] && `radial-gradient(circle at 62% 120%, ${glow[2]} 0%, transparent 40%)`,
  ]
    .filter(Boolean)
    .join(", ");
  const mark = T.mark ? await imageData(new URL(T.mark, base), 128) : null;
  const art = spec.art ? await imageData(new URL(spec.art, base), 500) : null;
  // figure: { svg, width, height } drawn on the right at that size, e.g. a miniature diagram.
  const figure = spec.figure
    ? { src: `data:image/svg+xml;base64,${Buffer.from(spec.figure.svg).toString("base64")}`, width: spec.figure.width, height: spec.figure.height }
    : null;

  const frame =
    T.frame === "perforated"
      ? { border: `4px dashed ${T.perf}` }
      : T.frame === "line"
      ? { border: `2px solid ${T.perf}` }
      : {};

  const tree = h(
    "div",
    {
      width: W,
      height: H,
      display: "flex",
      backgroundColor: T.background,
      backgroundImage: bg || "none",
      padding: 30,
      fontFamily: body,
    },
    [
      h(
        "div",
        { display: "flex", flexDirection: "column", flex: 1, padding: "46px 56px 40px", ...frame },
        [
          // top row: mark or glyph, eyebrow, kicker
          h("div", { display: "flex", alignItems: "center" }, [
            mark
              ? { type: "img", props: { src: mark, width: 64, height: 64, style: { marginRight: 22 } } }
              : { type: "img", props: { src: glyph(T, spec.lit ?? null, 64), width: 64, height: 64, style: { marginRight: 22 } } },
            h("div", { display: "flex", flexDirection: "column" }, [
              h("div", { fontSize: 21, fontWeight: 700, letterSpacing: 3.4, textTransform: "uppercase", color: T.muted }, spec.eyebrow || ""),
              spec.kicker ? h("div", { fontSize: 25, fontWeight: 700, color: T.accent, marginTop: 4 }, spec.kicker) : null,
            ].filter(Boolean)),
          ]),
          // middle: title, ink bar, summary (+ optional art)
          h("div", { display: "flex", flex: 1, alignItems: "center", marginTop: 18 }, [
            h("div", { display: "flex", flexDirection: "column", flex: 1, paddingRight: art || figure ? 40 : 0 }, [
              h("div", { fontFamily: head, fontSize: titleSize, lineHeight: 1.08, color: T.heading, letterSpacing: -0.5 }, title),
              h("div", { width: 190, height: 7, marginTop: 26, marginBottom: 22, backgroundImage: `linear-gradient(90deg, ${T.ink.join(", ")})` }, ""),
              spec.summary ? h("div", { fontSize: 27, lineHeight: 1.42, color: T.text, opacity: 0.9 }, clip(spec.summary, title.length > 60 ? 130 : 175)) : null,
            ].filter(Boolean)),
            figure
              ? h("div", { display: "flex", padding: 16, backgroundColor: "rgba(255, 255, 255, 0.035)", border: `2px solid ${T.perf}` }, [
                  { type: "img", props: { src: figure.src, width: figure.width, height: figure.height } },
                ])
              : null,
            // Art is shown whole and unmodified (an org's mark may be among it), on a mat that keeps
            // clear space around it, the way ORG's brand guidelines ask.
            art
              ? h("div", { display: "flex", padding: 22, border: `2px solid ${T.accent}` }, [
                  { type: "img", props: { src: art, width: 250, height: 250 } },
                ])
              : null,
          ].filter(Boolean)),
          // footer
          h("div", { display: "flex", justifyContent: "space-between", alignItems: "center", fontSize: 22, color: T.muted }, [
            h("div", { display: "flex" }, spec.meta || ""),
            h("div", { display: "flex", color: T.accent, fontWeight: 700 }, spec.footer || ""),
          ]),
        ]
      ),
    ]
  );

  const svg = await satori(tree, { width: W, height: H, fonts: fonts(T, base) });
  return sharp(Buffer.from(svg)).jpeg({ quality: 86, mozjpeg: true }).toBuffer();
}
