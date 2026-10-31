#!/bin/sh
# render-pdfs.sh — the SOP renderer, runnable locally (.github/workflows/pdf.yml does the same on push to main).
#   sh scripts/render-pdfs.sh            # every <DEPT>/SOP-*.md → pdf/<DEPT>/SOP-*.pdf
#   sh scripts/render-pdfs.sh OPS        # one department only
# GitHub callouts become bold labels; <details> open; md-to-pdf@5 (Puppeteer, your installed Chrome) renders Letter.
# Tone: the four shades from my-template/proposals-template/TONES.md. The template ships brass on slate (the lab);
# set the defaults below to your organisation's shades (keep them equal to pdf.yml), or override per run:
#   TONE_PRIMARY=d97706 TONE_DEEP=6b4f1d TONE_MID=b45309 TONE_TINT=fef3c7 sh scripts/render-pdfs.sh   # THEF amber
# If npx stalls on the npm registry (the resolver, SOP-IT-001), point MD2PDF at an installed copy:
#   MD2PDF=~/.npm/_npx/<hash>/node_modules/.bin/md-to-pdf sh scripts/render-pdfs.sh
set -eu
MD2PDF="${MD2PDF:-npx -y md-to-pdf@5}"
TONE_PRIMARY="${TONE_PRIMARY:-d9a441}"; TONE_DEEP="${TONE_DEEP:-334155}"; TONE_MID="${TONE_MID:-8a6a2a}"; TONE_TINT="${TONE_TINT:-f1f5f9}"
TONE_ACCENT="${TONE_ACCENT:-$TONE_PRIMARY}"
CSS="body{font-family:Helvetica,Arial,sans-serif} img{display:inline-block !important;vertical-align:-3px;margin:0 3px} h1{color:#$TONE_DEEP} h2{color:#$TONE_DEEP;border-bottom:2px solid #$TONE_PRIMARY;padding-bottom:4px} h3,h4{color:#$TONE_MID} a{color:#$TONE_ACCENT} blockquote{border-left:4px solid #$TONE_ACCENT;background:#$TONE_TINT;padding:6px 14px;margin-left:0} th{background:#$TONE_TINT;color:#$TONE_DEEP} details>summary{font-weight:600;color:#$TONE_MID} hr{border:0;border-top:1px solid #$TONE_PRIMARY;opacity:.45} pre{background:#f8fafc;border:1px solid #e2e8f0;padding:8px 10px;white-space:pre-wrap} code{font-size:.92em}"
cd "$(dirname "$0")/.."
render () { # $1 = DEPT/SOP-…md
  dept="$(dirname "$1")"; base="$(basename "$1" .md)"; out="pdf/$dept/$base.pdf"; mkdir -p "pdf/$dept"
  sed -e 's/<details>/<details open>/g' \
      -e 's/^> \[!TIP\]/> **Tip.**/' -e 's/^> \[!NOTE\]/> **Note.**/' -e 's/^> \[!IMPORTANT\]/> **Important.**/' -e 's/^> \[!WARNING\]/> **Warning.**/' \
      "$1" > "$dept/_print.md"
  PUPPETEER_SKIP_DOWNLOAD=1 PUPPETEER_EXECUTABLE_PATH="${PUPPETEER_EXECUTABLE_PATH:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}" $MD2PDF "$dept/_print.md" --basedir . \
    --css "$CSS" \
    --launch-options '{"args":["--no-sandbox"]}' \
    --pdf-options '{"format":"Letter","margin":{"top":"18mm","bottom":"18mm","left":"16mm","right":"16mm"},"printBackground":true}'
  mv "$dept/_print.pdf" "$out"; rm "$dept/_print.md"; echo "$out"
}
for f in ${1:-*}/SOP-*.md; do
  [ -f "$f" ] || continue
  case "$f" in _template/*|pdf/*) continue;; esac
  render "$f"
done
