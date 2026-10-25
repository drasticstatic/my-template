# 🌳 Version lineage: keep every copy up, and say which one this is

**TL;DR:** when a site moves or rehearses, **don't hide the other copies from search (`noindex`) and don't
take them down.**
- **Every copy that isn't live** greets visitors once with a short note: *"You're on a rehearsal stage"* or
  *"You're looking at an earlier version"*. It links to **every newer version**.
- **The live site shows nothing** and never links back.
- **A canonical link** tells search engines which copy is the real one.

Anyone can compare versions side by side, and nobody is ever confused about where they are.

*First built for I Am One Self (The Holy Earth Foundation), 2026-10-25. It's the same idea as keeping old
test publishes up beside the live site, made visitor-friendly.*

---

## 🧭 The rules

| Rule | Why |
|---|---|
| **The live site has no note and no links back** | Visitors on the real site are never distracted by its history |
| **Each other copy lists only the stops newer than itself** | An earlier version points forward; a rehearsal points to live. Nobody is sent backwards |
| **The note stays until the visitor confirms**, then never again **in that browser, for that copy** | Honest without nagging. Remembered per copy, so confirming the rehearsal doesn't silence the old version |
| **A small ribbon in the corner** reopens it | The truth is always one tap away |
| **`<link rel="canonical">` points to live** on every other copy | Search engines credit the live site, while the copies stay findable and useful |
| **No `noindex`** | Old versions are part of the story. They teach, and they prove where the work came from |
| **Stops that don't exist yet are listed but closed** (`open: false`) | The list is ready in advance; a move only flips switches |

## 🗂️ The list (one file, oldest first)

```ts
// src/data/lineage.ts
export type LineageKind = "earlier" | "rehearsal" | "live";

export interface LineageStop {
  id: string;      // what each deploy lane names itself
  label: string;   // "The Genesis rehearsal"
  note: string;    // one line under the label
  url: string;
  kind: LineageKind;
  open: boolean;   // false = not built yet; flip it when it is
}

export const LINEAGE: LineageStop[] = [
  { id: "lab-original",   kind: "earlier",   open: false, /* opens at the move */ label: "The first lab version", ... },
  { id: "lab-genesis",    kind: "rehearsal", open: true,  label: "The Genesis rehearsal", ... },
  { id: "thef-rehearsal", kind: "rehearsal", open: false, label: "The foundation's rehearsal stage", ... },
  { id: "live",           kind: "live",      open: true,  label: "The live site", ... },
];

export const LINEAGE_SELF = process.env.NEXT_PUBLIC_LINEAGE_SELF ?? "";

/** This build's stop, unless it is the live site (or no lane set it). */
export const lineageSelf = () => LINEAGE.find((s) => s.id === LINEAGE_SELF && s.kind !== "live");

/** Every stop newer than this one that exists today. */
export function newerStops() {
  const i = LINEAGE.findIndex((s) => s.id === LINEAGE_SELF);
  return i < 0 ? [] : LINEAGE.slice(i + 1).filter((s) => s.open);
}
```

**Local builds and the live site set no `LINEAGE_SELF`, so they render nothing.** Only a lane that names
itself shows the note.

## 🪟 The note (the parts that matter)

- **A native `<dialog>` opened with `showModal()`.** You get focus trapping, a backdrop and screen-reader
  semantics for free.
- **Remember the confirmation in `localStorage`,** keyed to *this copy's* id, inside `try/catch`. In
  private mode it simply greets them again next time. That's fine.
- **Decide after hydration** (`setTimeout(…, 0)`). `localStorage` isn't readable during static rendering.
- **The Escape gotcha:** Chrome lets Escape close a dialog that opened without a click, even if you
  `preventDefault()` the `cancel` event. So in `onClose`, if the visitor hasn't confirmed, call
  `showModal()` again on the next tick. The note can be dismissed only by choosing.
- **Two choices, both honest:** *"Take me to the live site"* and *"I understand, let me look around"*.
- **Keep it out of search results** (`data-pagefind-ignore`).
- **Let other welcomes wait for it.** On I Am One Self, the arrival splash listens for a `lineage:ack`
  event, so two dialogs never stack.
- **Both languages:** every label and note goes through the site's translation table.

## 🚦 Wiring it into the deploy lanes

Each lane names its stop and its canonical target at build time:

```yaml
# .github/workflows/lanes.yml (build step env)
NEXT_PUBLIC_LINEAGE_SELF: ${{ github.ref_name == 'main' && 'live' || vars.REHEARSAL_LINEAGE }}
NEXT_PUBLIC_CANONICAL_URL: ${{ github.ref_name != 'main' && format('{0}{1}', vars.LIVE_SITE_URL, vars.LIVE_BASE_PATH) || '' }}
```

- **Live builds** are `live`, with no canonical override. They render nothing.
- **The rehearsal** sets the repository variable `REHEARSAL_LINEAGE` (e.g. `lab-genesis`, later
  `thef-rehearsal`).
- **An old copy** that keeps building from its own workflow sets its own id (`lab-original`) the same way.

The page's metadata adds `<link rel="canonical" href={NEXT_PUBLIC_CANONICAL_URL}>` whenever it's set.

## 🔁 At a move (how the list changes)

| Moment | Flip |
|---|---|
| **Before:** testing the new home in a lab | `lab-genesis` open; the old site is still live, so it shows nothing |
| **At the move:** the domain points to the new home | Open the new rehearsal stop. Open the old copy as `earlier`, and give its build `LINEAGE_SELF=lab-original` so it greets visitors and points forward |
| **After** | Nothing to maintain. New rehearsals are added as new stops, and old ones stay as history |

## 🧩 Using it elsewhere

- **Next.js sites:** copy `lineage.ts`, `LineageModal.tsx` and `lineage.css` from I Am One Self, mount the
  modal in the root layout, and add the two env lines to your lanes.
- **Kit sites (AstroLog, portals):** the same rules suit a small plain-JavaScript version that reads its
  id from a `<meta>` tag. It's on the kit 1.5 wish list.
- **dApps with demo deployments:** the same note replaces "this is a demo" banners. List the production
  app as `live`.

*Part of the [walkthroughs](README.md).*
