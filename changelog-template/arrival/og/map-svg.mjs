// A miniature of the ORG map (the data from src/data/map.ts or map.json) as a standalone SVG with
// inline colors, for the map's social card. Same file in the ORG AstroLog and the drasticstatic lab.
const esc = (s) => String(s).replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" })[c]);

export function mapSvg(map, c, here) {
  let s = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 20 ${map.width} ${map.height - 20}" width="${map.width}" height="${map.height - 20}">`;
  s += `<defs><marker id="a" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="${c.accent}"/></marker>`;
  s += `<marker id="b" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="${c.muted}"/></marker></defs>`;
  for (const col of map.columns) s += `<text x="${col.x}" y="92" font-family="sans-serif" font-size="22" font-weight="700" fill="${c.muted}">${esc(col.label)}</text>`;
  for (const e of map.edges) {
    s += e.soft
      ? `<path d="${e.d}" fill="none" stroke="${c.muted}" stroke-width="2.4" stroke-dasharray="7 6" marker-end="url(#b)"/>`
      : `<path d="${e.d}" fill="none" stroke="${c.accent}" stroke-width="2.6" marker-end="url(#a)"/>`;
  }
  for (const n of map.nodes) {
    const isHere = here && n.self === here;
    s += `<polygon points="${n.points}" fill="${c.node}" stroke="${isHere ? c.accent : c.border}" stroke-width="${isHere ? 4 : 2}"${n.private ? ' stroke-dasharray="8 6"' : ""}/>`;
    s += `<text x="${n.x + 18}" y="${n.y + 42}" font-family="serif" font-size="27" fill="${c.heading}">${esc(n.name)}</text>`;
  }
  return s + "</svg>";
}
