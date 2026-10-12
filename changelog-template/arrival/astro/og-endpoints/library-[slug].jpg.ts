// One social card per library write-up: /og/library/<slug>.jpg (static, built once).
import { getCollection } from "astro:content";
import { entrySlug } from "../../../data/areas";
import { docCard } from "../../../og/cards";

export async function getStaticPaths() {
  const docs = await getCollection("library");
  return docs.map((doc) => ({ params: { slug: entrySlug(doc.id) }, props: { doc } }));
}

export const GET = ({ props }: { props: { doc: Parameters<typeof docCard>[0] } }) => docCard(props.doc);
