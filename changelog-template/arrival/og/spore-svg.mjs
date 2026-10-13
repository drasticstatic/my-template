// A spore print as an SVG string, seeded by a key (an entry's slug), so every card gets a print of
// its own that stays the same from build to build. Same anatomy as the hero print on the portal and
// SporePrint.astro: long gills from near the stem, shorter gills filling the outer cap, spore dust
// at the rim, and a stem ring in the org's accent.

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

/**
 * key: any string (the same key always draws the same print)
 * o: { spore, accent, width, height, cx, cy, r, ring? (stem ring radius as a share of r) }
 */
export function sporePrintSvg(key, o) {
  const rand = mulberry(fnv(String(key)));
  const k = o.r / 90; // the hero print is drawn at a radius of about 90 units
  const steps = 60 + Math.floor(rand() * 12);
  const turn = rand() * Math.PI * 2;
  let gills = "";
  const line = (a, r0, r1, w, op) => {
    gills +=
      `<line x1="${f(o.cx + r0 * Math.cos(a))}" y1="${f(o.cy + r0 * Math.sin(a))}" ` +
      `x2="${f(o.cx + r1 * Math.cos(a))}" y2="${f(o.cy + r1 * Math.sin(a))}" stroke-width="${f(w)}" opacity="${f(op)}"/>`;
  };
  for (let i = 0; i < steps; i++) {
    const a = turn + (i / steps) * Math.PI * 2 + (rand() - 0.5) * 0.02;
    line(a, o.r * (0.12 + rand() * 0.05), o.r * (0.9 + rand() * 0.08), 0.6 * k, 0.45 + rand() * 0.5);
    for (let j = 1; j <= 3; j++) {
      const b = a + (j / 4) * ((Math.PI * 2) / steps) + (rand() - 0.5) * 0.012;
      const r0 = o.r * (j === 2 ? 0.6 + rand() * 0.12 : 0.76 + rand() * 0.1);
      line(b, r0, o.r * (0.88 + rand() * 0.09), 0.42 * k, 0.28 + rand() * 0.42);
    }
  }
  let dust = "";
  for (let i = 0; i < 300; i++) {
    const a = rand() * Math.PI * 2;
    const rr = o.r * (0.86 + Math.pow(rand(), 1.6) * 0.26);
    dust += `<circle cx="${f(o.cx + rr * Math.cos(a))}" cy="${f(o.cy + rr * Math.sin(a))}" r="${f((0.3 + rand() * 0.55) * k)}" opacity="${f(0.12 + rand() * 0.45)}"/>`;
  }
  const ring = o.r * (o.ring ?? 0.125);
  return (
    `<svg xmlns="http://www.w3.org/2000/svg" width="${o.width}" height="${o.height}" viewBox="0 0 ${o.width} ${o.height}">` +
    `<g stroke="${o.spore}" stroke-linecap="round">${gills}</g>` +
    `<g fill="${o.spore}">${dust}</g>` +
    `<circle cx="${f(o.cx)}" cy="${f(o.cy)}" r="${f(ring)}" fill="${o.background ?? "none"}" stroke="${o.accent}" stroke-width="${f(1.25 * k)}"/>` +
    `</svg>`
  );
}
