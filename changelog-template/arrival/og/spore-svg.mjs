// A spore print as an SVG string, seeded by a key (an entry's slug), so every card gets a print of
// its own that stays the same from build to build. Same anatomy as the hero print on the portal and
// SporePrint.astro: long gills from near the stem, shorter gills filling the outer cap, spore dust
// at the rim, and a stem ring in the org's accent.
//
// Looks (kit 1.2), chosen by the theme:
//   classic (default)  every gill in the spore color: calm and even
//   quiet: true        fewer, finer gills, less dust and a second, inner ring: the formal card
//                      (psanctuarychurch, the church's professional face)
//   prism: [colors]    the gills sweep through the given colors around the cap, the dust glints in
//                      them too, and faint ripple rings spread from the stem, like oil on a cap after
//                      rain (psanctuary, the playful side)

function fnv(s) {
  let h = 2166136261;
  for (let i = 0; i < s.length; i++) h = Math.imul(h ^ s.charCodeAt(i), 16777619);
  return h >>> 0;
}

function mulberry(seed) {
  return () => {
    seed = (seed + 0x6d2b79f5) | 0;
    let t = Math.imul(seed ^ (seed >>> 15), 1 | seed);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

const f = (n) => n.toFixed(2);

// "#rrggbb" → [r, g, b]; mix two colors by t.
const rgb = (hex) => [1, 3, 5].map((i) => parseInt(hex.slice(i, i + 2), 16));
const mix = (a, b, t) => {
  const A = rgb(a);
  const B = rgb(b);
  return "#" + A.map((v, i) => Math.round(v + (B[i] - v) * t).toString(16).padStart(2, "0")).join("");
};
// The color at position u (0..1) around a closed loop of colors.
export const sweep = (cols, u) => {
  const n = cols.length;
  const x = (((u % 1) + 1) % 1) * n;
  const i = Math.floor(x);
  return mix(cols[i % n], cols[(i + 1) % n], x - i);
};

/**
 * key: any string (the same key always draws the same print)
 * o: { spore, accent, width, height, cx, cy, r, ring? (stem ring radius as a share of r),
 *      prism?: ["#hex", …], quiet?: boolean, background? }
 */
export function sporePrintSvg(key, o) {
  const rand = mulberry(fnv(String(key)));
  const k = o.r / 90; // the hero print is drawn at a radius of about 90 units
  const quiet = !!o.quiet;
  const prism = Array.isArray(o.prism) && o.prism.length > 1 ? o.prism : null;
  const steps = (quiet ? 52 : 60) + Math.floor(rand() * 12);
  const turn = rand() * Math.PI * 2;
  const hueTurn = rand();
  let gills = "";
  const line = (a, r0, r1, w, op) => {
    const c = prism ? ` stroke="${sweep(prism, hueTurn + a / (Math.PI * 2))}"` : "";
    gills +=
      `<line x1="${f(o.cx + r0 * Math.cos(a))}" y1="${f(o.cy + r0 * Math.sin(a))}" ` +
      `x2="${f(o.cx + r1 * Math.cos(a))}" y2="${f(o.cy + r1 * Math.sin(a))}" stroke-width="${f(w)}" opacity="${f(op)}"${c}/>`;
  };
  const between = quiet ? 2 : 3;
  for (let i = 0; i < steps; i++) {
    const a = turn + (i / steps) * Math.PI * 2 + (rand() - 0.5) * 0.02;
    line(a, o.r * (0.12 + rand() * 0.05), o.r * (0.9 + rand() * 0.08), (quiet ? 0.5 : 0.6) * k, 0.45 + rand() * 0.5);
    for (let j = 1; j <= between; j++) {
      const b = a + (j / (between + 1)) * ((Math.PI * 2) / steps) + (rand() - 0.5) * 0.012;
      const r0 = o.r * (j === 2 ? 0.6 + rand() * 0.12 : 0.76 + rand() * 0.1);
      line(b, r0, o.r * (0.88 + rand() * 0.09), (quiet ? 0.36 : 0.42) * k, 0.28 + rand() * 0.42);
    }
  }
  let dust = "";
  const dustN = quiet ? 140 : prism ? 360 : 300;
  for (let i = 0; i < dustN; i++) {
    const a = rand() * Math.PI * 2;
    const rr = o.r * (0.86 + Math.pow(rand(), 1.6) * 0.26);
    const c = prism ? ` fill="${sweep(prism, hueTurn + a / (Math.PI * 2) + (rand() - 0.5) * 0.08)}"` : "";
    dust += `<circle cx="${f(o.cx + rr * Math.cos(a))}" cy="${f(o.cy + rr * Math.sin(a))}" r="${f((0.3 + rand() * 0.55) * k)}" opacity="${f(0.12 + rand() * 0.45)}"${c}/>`;
  }
  // Prism: three faint ripples spreading from the stem, each a dashed ring in its own color.
  let ripples = "";
  if (prism) {
    [0.3, 0.46, 0.64].forEach((s, i) => {
      const rr = o.r * (s + rand() * 0.04);
      const dash = (2 + rand() * 3) * k;
      ripples +=
        `<circle cx="${f(o.cx)}" cy="${f(o.cy)}" r="${f(rr)}" fill="none" stroke="${prism[(i * 2 + 1) % prism.length]}" ` +
        `stroke-width="${f(0.5 * k)}" stroke-dasharray="${f(dash)} ${f(dash * 1.7)}" opacity="${f(0.42 - i * 0.08)}"/>`;
    });
  }
  const ring = o.r * (o.ring ?? 0.125);
  return (
    `<svg xmlns="http://www.w3.org/2000/svg" width="${o.width}" height="${o.height}" viewBox="0 0 ${o.width} ${o.height}">` +
    `<g stroke="${o.spore}" stroke-linecap="round">${gills}</g>` +
    `<g fill="${o.spore}">${dust}</g>` +
    ripples +
    `<circle cx="${f(o.cx)}" cy="${f(o.cy)}" r="${f(ring)}" fill="${o.background ?? "none"}" stroke="${o.accent}" stroke-width="${f(1.25 * k)}"/>` +
    (quiet ? `<circle cx="${f(o.cx)}" cy="${f(o.cy)}" r="${f(ring * 0.55)}" fill="none" stroke="${o.accent}" stroke-width="${f(0.5 * k)}" opacity="0.6"/>` : "") +
    `</svg>`
  );
}
