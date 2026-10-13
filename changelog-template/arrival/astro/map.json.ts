// The map, published for anything else that draws it (the entry portal's /map/ uses the kit's
// <arrival-map> on this file). Version 2: groups and nodes, each node with its share image (`og`).
// One canonical copy: src/data/map.ts.
import { SITE_MAP } from "../data/map";

export function GET() {
  return new Response(JSON.stringify(SITE_MAP), { headers: { "Content-Type": "application/json" } });
}
