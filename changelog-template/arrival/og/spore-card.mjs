// Arrival kit · social cards, alternate layout: the spore-print family's card (psanctuary and
// psanctuarychurch). Canonical copy: drasticstatic/my-template changelog-template/arrival/og/
// spore-card.mjs, with spore-svg.mjs beside it; copy both unchanged and write a theme like
// spore-theme.example.mjs.
//
// A 1200×630 JPEG for og:image / twitter:image, rendered at build time like the kit's og-card.mjs
// and with the same spec shape: Satori lays out the card and turns the text into paths, sharp
// writes the JPEG, fonts and images are read from disk, no network. The layout is the family's own:
// the title on violet-black, and a spore print of the entry's own (seeded by `spec.seed`, e.g. its
// slug, so every card differs and stays the same from build to build) rising off the right edge,
// its stem ring in the org's accent.
//
//   const jpeg = await renderCard({ eyebrow, kicker, title, summary, meta, footer, seed, hero? }, THEME, base)
//
// Each org's signature comes from its theme (kit 1.2):
//   theme.frame: true          a double hairline frame in the accent, a quieter print (theme.quiet)
//                              and a plain hairline under the title: formal (psanctuarychurch)
//   theme.prism: [colors]      gills that sweep through those colors, ripple rings, glows and a
//                              gradient rule in the same colors: playful (psanctuary)
//   spec.hero: true            the big-name layout for a site's own card (portal, porch)
// Never put a count on a card ("12 entries"): link previews are cached for weeks, and a count goes
// stale. Say what the page is instead.
//
// Fonts must be TTF/OTF/WOFF (not WOFF2). `base` is a file: URL that font and mark paths resolve
// against; resolve it from the project folder, since Astro bundles the endpoint that calls this.
import satori from "satori";
import sharp from "sharp";
import fs from "node:fs";
import { sporePrintSvg } from "./spore-svg.mjs";

export const W = 1200;
export const H = 630;

const h = (type, style, children) => ({ type, props: { style, children } });
const img = (src, width, height, style = {}) => ({ type: "img", props: { src, width, height, style } });
const clip = (s, n) => (s && s.length > n ? s.slice(0, n - 1).replace(/[\s,.;:]+\S*$/, "") + "…" : s || "");
const svgData = (svg) => `data:image/svg+xml;base64,${Buffer.from(svg).toString("base64")}`;
// "#rrggbb" + alpha → rgba()
const rgba = (hex, a) => `rgba(${[1, 3, 5].map((i) => parseInt(hex.slice(i, i + 2), 16)).join(", ")}, ${a})`;

const fontCache = new Map();
function fonts(T, base) {
  const key = JSON.stringify(T.fonts) + base;
  if (fontCache.has(key)) return fontCache.get(key);
  const out = [];
  for (const role of ["heading", "body"]) {
    const font = T.fonts[role];
    for (const [weight, file] of Object.entries(font.files)) {
      out.push({ name: font.name, data: fs.readFileSync(new URL(file, base)), weight: Number(weight), style: "normal" });
    }
  }
  fontCache.set(key, out);
  return out;
}

const markCache = new Map();
async function mark(T, base) {
  if (!T.mark) return null;
  if (!markCache.has(T.mark)) {
    const png = await sharp(fs.readFileSync(new URL(T.mark, base))).resize(112, 112).png().toBuffer();
    markCache.set(T.mark, `data:image/png;base64,${png.toString("base64")}`);
  }
  return markCache.get(T.mark);
}

/**
 * spec: { eyebrow, kicker?, title, summary?, meta?, footer?, seed?, hero? }
 * theme: { background, heading, text, muted, accent, spore, glow, sporeGlow, mark?, fonts,
 *          frame?, quiet?, prism? }
 */
export async function renderCard(spec, T, base) {
  const prism = Array.isArray(T.prism) && T.prism.length > 1 ? T.prism : null;
  const hero = !!spec.hero;
  const title = clip(spec.title, 110);
  const titleSize = hero ? (title.length > 18 ? 84 : 104) : title.length > 84 ? 48 : title.length > 58 ? 55 : title.length > 32 ? 62 : 72;
  const summary = clip(spec.summary, hero ? 120 : title.length > 58 ? 136 : 172);
  const m = await mark(T, base);
  const print = sporePrintSvg(spec.seed || spec.title, {
    spore: T.spore,
    accent: T.accent,
    background: T.background,
    width: 560,
    height: H,
    cx: 405,
    cy: 315,
    r: T.frame ? 318 : 340,
    prism,
    quiet: !!T.quiet,
  });
  // A few loose spores drifting off the print, toward the words.
  const dot = (x, y, r, c, o) => h("div", { position: "absolute", left: x, top: y, width: r * 2, height: r * 2, borderRadius: r, backgroundColor: c, opacity: o }, "");
  const dc = (i, fallback) => (prism ? prism[i % prism.length] : fallback);
  const glows = prism
    ? `radial-gradient(circle at 86% 46%, ${rgba(prism[1], 0.17)} 0%, transparent 32%), radial-gradient(circle at 70% 96%, ${rgba(prism[3 % prism.length], 0.13)} 0%, transparent 30%), radial-gradient(circle at 0% 0%, ${rgba(prism[0], 0.2)} 0%, transparent 46%)`
    : `radial-gradient(circle at 87% 50%, ${T.glow} 0%, transparent 34%), radial-gradient(circle at 0% 0%, ${T.sporeGlow} 0%, transparent 46%)`;
  const rule = T.frame
    ? h("div", { display: "flex", alignItems: "center", marginTop: 24, marginBottom: 20 }, [
        h("div", { width: 120, height: 2, backgroundColor: T.accent, opacity: 0.85 }, ""),
        h("div", { width: 9, height: 9, marginLeft: 10, borderRadius: 5, border: `1.5px solid ${T.accent}` }, ""),
      ])
    : prism
    ? h("div", { display: "flex", alignItems: "center", marginTop: 24, marginBottom: 20 }, [
        h("div", { width: 132, height: 5, borderRadius: 3, backgroundImage: `linear-gradient(90deg, ${prism.join(", ")})` }, ""),
        ...[0.9, 0.7, 0.55, 0.4].map((o, i) => h("div", { width: 5, height: 5, borderRadius: 3, marginLeft: i ? 9 : 12, backgroundColor: prism[(i + 1) % prism.length], opacity: o }, "")),
      ])
    : h("div", { display: "flex", alignItems: "center", marginTop: 24, marginBottom: 20 }, [
        h("div", { width: 64, height: 4, borderRadius: 2, backgroundColor: T.accent }, ""),
        ...[0.9, 0.7, 0.55, 0.4, 0.28].map((o, i) => h("div", { width: 5, height: 5, borderRadius: 3, marginLeft: i ? 9 : 12, backgroundColor: T.spore, opacity: o }, "")),
      ]);
  const pad = T.frame ? "64px 86px 58px" : "54px 72px 48px";

  const tree = h(
    "div",
    {
      position: "relative",
      width: W,
      height: H,
      display: "flex",
      flexDirection: "column",
      padding: pad,
      backgroundColor: T.background,
      backgroundImage: glows,
      fontFamily: T.fonts.body.name,
    },
    [
      img(svgData(print), 560, H, { position: "absolute", left: 640, top: 0 }),
      dot(702, 118, 2.2, dc(0, T.spore), 0.55),
      dot(688, 452, 1.6, dc(2, T.spore), 0.45),
      dot(716, 236, 3, dc(1, T.accent), 0.7),
      dot(806, 606, 2.6, dc(3, T.accent), 0.5),
      // The formal frame: two hairlines in the accent, inset from the edge.
      T.frame ? h("div", { position: "absolute", left: 24, top: 24, width: W - 48, height: H - 48, border: `1.5px solid ${rgba(T.accent, 0.7)}`, borderRadius: 6 }, "") : null,
      T.frame ? h("div", { position: "absolute", left: 32, top: 32, width: W - 64, height: H - 64, border: `1px solid ${rgba(T.accent, 0.28)}`, borderRadius: 3 }, "") : null,
      // top: the mark, the eyebrow, the kicker
      h("div", { display: "flex", alignItems: "center" }, [
        m ? img(m, 56, 56, { marginRight: 20, borderRadius: 14 }) : null,
        h("div", { display: "flex", flexDirection: "column" }, [
          h("div", { fontSize: 20, fontWeight: 700, letterSpacing: T.frame ? 4.6 : 3.6, textTransform: "uppercase", color: T.muted }, spec.eyebrow || ""),
          spec.kicker ? h("div", { fontSize: 24, fontWeight: 700, color: T.accent, marginTop: 3 }, spec.kicker) : null,
        ].filter(Boolean)),
      ].filter(Boolean)),
      // middle: the title, a rule, the summary
      h("div", { display: "flex", flexDirection: "column", justifyContent: "center", flex: 1, width: T.frame ? 580 : 600 }, [
        h("div", { fontFamily: T.fonts.heading.name, fontSize: titleSize, lineHeight: 1.1, color: T.heading, letterSpacing: hero ? -1 : -0.4 }, title),
        rule,
        summary ? h("div", { fontSize: hero ? 30 : 26, lineHeight: 1.42, color: T.text }, summary) : null,
      ].filter(Boolean)),
      // bottom: when and who, and where
      h("div", { display: "flex", alignItems: "center", fontSize: 20, color: T.muted, width: 760 }, [
        h("div", { display: "flex", flexShrink: 0 }, spec.meta || ""),
        spec.meta && spec.footer ? h("div", { display: "flex", margin: "0 12px", color: dc(4, T.spore) }, "·") : null,
        spec.footer ? h("div", { display: "flex", flexShrink: 0, color: T.accent, fontWeight: 700 }, spec.footer) : null,
      ].filter(Boolean)),
    ].filter(Boolean)
  );

  const svg = await satori(tree, { width: W, height: H, fonts: fonts(T, base) });
  return sharp(Buffer.from(svg)).jpeg({ quality: 86, mozjpeg: true }).toBuffer();
}
