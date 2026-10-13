// One share card per site page (kit 1.2): /og/page/<slug>.jpg, built once. They're the pages' own
// og:image and the map's thumbnails. The list and the words are in src/og/pages.ts.
import { PAGE_CARDS, pageCard } from "../../../og/pages";

export function getStaticPaths() {
  return PAGE_CARDS.map((c) => ({ params: { slug: c.slug } }));
}

export const GET = ({ params }: { params: { slug: string } }) => pageCard(params.slug);
