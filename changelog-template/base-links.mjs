// Prefix the site's `base` onto root-relative links and image sources inside Markdown content.
//
// Why: entries link to each other base-less (`/library/some-doc`, `/changelog/wordpress/x`), but
// Astro doesn't add `base` to URLs inside Markdown. On a GitHub Pages project site the base is the
// repo path (e.g. /changelog-astro-public), so those links resolved to the ORG root and 404'd.
//
// What it touches: <a href> and <img src> that start with a single "/". Leaves alone: external URLs,
// protocol-relative "//", "#anchors", relative paths, and anything already under the base.
// trailingSlash is untouched (authors keep writing no trailing slash).
//
// Astro 7's default Markdown processor is Sätteri, which takes hast plugins in this
// { name, element: { filter, visit } } shape — a rehype plugin would only run if you swapped to
// the unified processor. Usage (astro.config.mjs):
//   import { satteri } from "@astrojs/markdown-satteri";
//   import { baseLinks } from "./src/plugins/base-links.mjs";
//   markdown: { processor: satteri({ hastPlugins: [baseLinks(BASE)] }) }
// Copy this file as-is into any changelog-astro instance; only BASE differs per site.
export function baseLinks(base) {
  const b = base.replace(/\/+$/, "");
  const fix = (url) =>
    typeof url === "string" && url.startsWith("/") && !url.startsWith("//") && url !== b && !url.startsWith(b + "/")
      ? b + url
      : null;
  return {
    name: "base-links",
    element: {
      filter: ["a", "img"],
      visit(node, ctx) {
        const key = node.tagName === "a" ? "href" : "src";
        const next = fix(node.properties?.[key]);
        if (next) ctx.setProperty(node, key, next);
      },
    },
  };
}
