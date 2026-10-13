// Psanctuary's look for the spore-print card layout (spore-card.mjs): the Spore Print mode of its
// arrival kit org.css (violet-black, spore violet, bruise blue), Young Serif with Figtree. Write one
// per org; psanctuarychurch differs only in `accent` (#e2b45a) and `glow`. Paths resolve against
// the folder passed to renderCard (src/og/).
export const CARD_THEME = {
  background: "#16111a",
  heading: "#f6efe4",
  text: "#ddd3df",
  muted: "#aba0ae",
  accent: "#74bce0", // the stem ring, the kicker, the rule and the footer
  spore: "#a88bc9", // the gills and spore dust
  glow: "rgba(116, 188, 224, 0.15)", // behind the print
  sporeGlow: "rgba(168, 139, 201, 0.16)", // top-left corner
  mark: "../../public/favicon.png", // optional: the org's square mark, drawn unmodified at 56px
  fonts: {
    heading: { name: "Young Serif", files: { 400: "fonts/YoungSerif-400.ttf" } },
    body: { name: "Figtree", files: { 500: "fonts/Figtree-500.ttf", 700: "fonts/Figtree-700.ttf" } },
  },
};
