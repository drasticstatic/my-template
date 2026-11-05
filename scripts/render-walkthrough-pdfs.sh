#!/bin/sh
# render-walkthrough-pdfs.sh: every walkthroughs/*.md becomes walkthroughs/pdf/<NAME>.pdf, so a guide can be sent as a
# file while the markdown stays the source (walkthroughs/MARKDOWN-BESIDE-PDF.md says why both).
# .github/workflows/walkthroughs-pdf.yml runs this same script on a push to main and commits the result by the Actions bot.
#   sh scripts/render-walkthrough-pdfs.sh                            # every guide, then drops PDFs whose source is gone
#   sh scripts/render-walkthrough-pdfs.sh SECURE-TWO-FACTOR          # one guide (NAME or NAME.md)
#   sh scripts/render-walkthrough-pdfs.sh --list                     # say what would be rendered; draws nothing, installs nothing
# Modelled on trading-bot_arbitrage_DAPPUv3_hardhat_UNI-CAKE/scripts/render-ops-pdfs.sh, itself on
# sop-template/repo/scripts/render-pdfs.sh. GitHub callouts become bold labels; <details> open; ```mermaid blocks become
# SVG pictures (sop-template/repo/scripts/mermaid-prerender.sh, @mermaid-js/mermaid-cli, pinned); md-to-pdf@5 renders Letter.
# walkthroughs/README.md is the index of the guides, not a guide, so it is not rendered.
# Tone: brass on slate, the lab's shades (proposals-template/TONES.md), the same as the walkthroughs' badges. Override per run:
#   TONE_ACCENT=d97706 sh scripts/render-walkthrough-pdfs.sh         # links and quote bar in THEF amber, for a copy meant for Kenney
# The renderer runs from the repository root and md-to-pdf serves that folder, so the pages' ../sop-template/repo/assets/icons/
# links resolve exactly as they do on GitHub. If npx stalls on the npm registry, point MD2PDF and MMDC at installed copies
# (~/.npm/_npx/<hash>/node_modules/.bin/...). A Mac short of memory should prefer the workflow, or one guide at a time.
set -eu
MD2PDF="${MD2PDF:-npx -y md-to-pdf@5}"
TONE_PRIMARY="${TONE_PRIMARY:-d9a441}"; TONE_DEEP="${TONE_DEEP:-334155}"; TONE_MID="${TONE_MID:-8a6a2a}"; TONE_TINT="${TONE_TINT:-f1f5f9}"
TONE_ACCENT="${TONE_ACCENT:-$TONE_PRIMARY}"
export TONE_PRIMARY TONE_DEEP TONE_MID TONE_TINT
CSS="body{font-family:Helvetica,Arial,sans-serif} img{display:inline-block !important;vertical-align:-3px;margin:0 3px} h1{color:#$TONE_DEEP} h2{color:#$TONE_DEEP;border-bottom:2px solid #$TONE_PRIMARY;padding-bottom:4px} h3,h4{color:#$TONE_MID} a{color:#$TONE_ACCENT} blockquote{border-left:4px solid #$TONE_ACCENT;background:#$TONE_TINT;padding:6px 14px;margin-left:0} th{background:#$TONE_TINT;color:#$TONE_DEEP} details>summary{font-weight:600;color:#$TONE_MID} hr{border:0;border-top:1px solid #$TONE_PRIMARY;opacity:.45} pre{background:#f8fafc;border:1px solid #e2e8f0;padding:8px 10px;white-space:pre-wrap} code{font-size:.92em} img[src*=_print-]{display:block !important;max-width:100% !important;max-height:190mm !important;width:auto !important;height:auto !important;margin:10px auto !important;page-break-inside:avoid}"
PDF_OPTIONS='{"format":"Letter","margin":{"top":"18mm","bottom":"18mm","left":"16mm","right":"16mm"},"printBackground":true,"displayHeaderFooter":true,"headerTemplate":"<span></span>","footerTemplate":"<div style=\"width:100%;font-size:8px;color:#64748b;text-align:center\"><span class=\"pageNumber\"></span> / <span class=\"totalPages\"></span></div>"}'
# On a Mac use the installed Chrome. On the Actions runner the npx packages fetch their own.
if [ "$(uname)" = Darwin ]; then
  PUPPETEER_SKIP_DOWNLOAD=1; PUPPETEER_EXECUTABLE_PATH="${PUPPETEER_EXECUTABLE_PATH:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
  export PUPPETEER_SKIP_DOWNLOAD PUPPETEER_EXECUTABLE_PATH
fi
cd "$(dirname "$0")/.."   # the repository root: md-to-pdf serves it, so ../sop-template/... resolves from walkthroughs/
PRERENDER="sop-template/repo/scripts/mermaid-prerender.sh"
DIR="walkthroughs"

sources () { # every guide, as a bare NAME (no folder, no .md)
  find "$DIR" -maxdepth 1 -type f -name '*.md' -not -name README.md -not -name '_print*' | sed "s|^$DIR/||; s|\.md\$||" | sort
}
render () { # $1 = NAME, for example SECURE-TWO-FACTOR
  out="$DIR/pdf/$1.pdf"; mkdir -p "$DIR/pdf"
  sed -e 's/<details>/<details open>/g' \
      -e 's/^> \[!TIP\]/> **Tip.**/' -e 's/^> \[!NOTE\]/> **Note.**/' -e 's/^> \[!IMPORTANT\]/> **Important.**/' -e 's/^> \[!WARNING\]/> **Warning.**/' \
      "$DIR/$1.md" > "$DIR/_print.src.md"
  sh "$PRERENDER" "$DIR/_print.src.md" "$DIR/_print.md"
  rm -f "$DIR/_print.src.md"
  $MD2PDF "$DIR/_print.md" --basedir . --css "$CSS" --launch-options '{"args":["--no-sandbox"]}' --pdf-options "$PDF_OPTIONS"
  mv "$DIR/_print.pdf" "$out"; rm -f "$DIR/_print.md" "$DIR"/_print-*.svg; echo "$out"
}

case "${1:-}" in
  --list) sources; exit 0;;
  "") target="";;
  *) target="$(basename "$1" .md)"
     [ -f "$DIR/$target.md" ] || { echo "render-walkthrough-pdfs: no such guide: $DIR/$target.md" >&2; exit 2; };;
esac
if [ -n "$target" ]; then render "$target"; else for f in $(sources); do render "$f"; done; fi
# A full run also drops any PDF whose source was renamed or removed, so a stale copy can't be sent by mistake.
if [ -z "$target" ] && [ -d "$DIR/pdf" ]; then
  find "$DIR/pdf" -type f -name '*.pdf' | while read -r p; do
    base="$(basename "$p" .pdf)"; [ -f "$DIR/$base.md" ] || { rm -f "$p"; echo "removed stale $p"; }
  done
fi
