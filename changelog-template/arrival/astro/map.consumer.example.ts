// The map of ORG's sites is NOT kept here. Its one canonical copy is ORG's AstroLog
// (Octagon-Religious-Research-Group-ORG/changelog-astro, astro/src/data/map.ts), published at
// MAP_SOURCE. This lab fetches it when it builds and draws it with the same OrgMap component, so the
// two maps can't drift. If the fetch fails (offline, ORG's site down), the build uses the committed
// snapshot instead; refresh it with `npm run map:snapshot`. To change the map, change ORG's copy.
import snapshot from "./map.snapshot.json";

export const MAP_SOURCE = "https://octagon-religious-research-group-org.github.io/changelog-astro-public/map.json";

export type OrgMapData = {
  version: 1;
  title: string;
  desc: string;
  width: number;
  height: number;
  nodeW: number;
  nodeH: number;
  columns: { x: number; label: string }[];
  nodes: { id: string; x: number; y: number; name: string; line: string; href?: string; private?: boolean; self?: string; points: string }[];
  edges: { d: string; label: string; lx: number; ly: number; soft?: boolean }[];
};

let cached: Promise<{ map: OrgMapData; from: "live" | "snapshot" }> | null = null;

export function loadMap() {
  cached ??= (async () => {
    try {
      const res = await fetch(MAP_SOURCE, { signal: AbortSignal.timeout(10000) });
      if (res.ok) {
        const map = (await res.json()) as OrgMapData;
        if (map?.version === 1 && Array.isArray(map.nodes) && Array.isArray(map.edges)) {
          console.log(`[map] drawn from ${MAP_SOURCE}`);
          return { map, from: "live" as const };
        }
      }
    } catch {
      // fall through to the snapshot
    }
    console.warn("[map] couldn't fetch ORG's map.json; using src/data/map.snapshot.json");
    return { map: snapshot as OrgMapData, from: "snapshot" as const };
  })();
  return cached;
}
