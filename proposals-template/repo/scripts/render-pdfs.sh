#!/bin/sh
# render-pdfs.sh — the fleet's proposal renderer (origin: the foundation's proposals/.github/workflows/pdf.yml), runnable locally.
#   sh proposals/scripts/render-pdfs.sh            # every NNN-*/README.md → pdf/NNN-*.pdf
# GitHub callouts become bold labels; <details> open; md-to-pdf@5 (Puppeteer/Chromium) renders A4.
# Tone: set per organisation; see TONES.md (my-template/proposals-template/TONES.md). Four shades carry the family through the page
# (deep for H1/H2, mid for H3 and summaries, primary for rules, a tint behind quotes and table heads) and an
# accent colour for links and quote bars that a lab repo may borrow from the organisation a proposal serves.
# Override per run: TONE_PRIMARY=… TONE_DEEP=… TONE_MID=… TONE_TINT=… TONE_ACCENT=… sh … ; TONE=rainbow for David's.
set -eu
TONE="${TONE:-amber}"
TONE_PRIMARY="${TONE_PRIMARY:-d97706}"
TONE_DEEP="${TONE_DEEP:-6b4f1d}"
TONE_MID="${TONE_MID:-b45309}"
TONE_TINT="${TONE_TINT:-fef3c7}"
TONE_ACCENT="${TONE_ACCENT:-$TONE_PRIMARY}"
if [ "$TONE" = "rainbow" ]; then
  TONE_CSS="h1{background:linear-gradient(90deg,#dc2626,#ea580c,#ca8a04,#16a34a,#2563eb,#7c3aed);-webkit-background-clip:text;background-clip:text;color:transparent} h2{border-bottom:2px solid;padding-bottom:4px} h2:nth-of-type(6n+1){color:#dc2626} h2:nth-of-type(6n+2){color:#ea580c} h2:nth-of-type(6n+3){color:#ca8a04} h2:nth-of-type(6n+4){color:#16a34a} h2:nth-of-type(6n+5){color:#2563eb} h2:nth-of-type(6n+6){color:#7c3aed} h3,h4{color:#4338ca} a{color:#2563eb} blockquote{border-left:4px solid;border-image:linear-gradient(#dc2626,#7c3aed) 1;background:#fafafa;padding:6px 14px;margin-left:0} th{background:#f5f3ff;color:#3b1f6e} details>summary{font-weight:600;color:#4338ca} hr{border:0;height:2px;background:linear-gradient(90deg,#dc2626,#ea580c,#ca8a04,#16a34a,#2563eb,#7c3aed)}"
else
  TONE_CSS="h1{color:#$TONE_DEEP} h2{color:#$TONE_DEEP;border-bottom:2px solid #$TONE_PRIMARY;padding-bottom:4px} h3,h4{color:#$TONE_MID} a{color:#$TONE_ACCENT} blockquote{border-left:4px solid #$TONE_ACCENT;background:#$TONE_TINT;padding:6px 14px;margin-left:0} th{background:#$TONE_TINT;color:#$TONE_DEEP} details>summary{font-weight:600;color:#$TONE_MID} hr{border:0;border-top:1px solid #$TONE_PRIMARY;opacity:.45} sub{color:#$TONE_MID}"
fi
cd "$(dirname "$0")/.."
mkdir -p pdf
for dir in [0-9][0-9][0-9]-*/; do
  name="${dir%/}"
  [ -f "$name/README.md" ] || continue
  sed -e 's/<details>/<details open>/g' \
      -e 's/^> \[!TIP\]/> **Tip.**/' -e 's/^> \[!NOTE\]/> **Note.**/' -e 's/^> \[!IMPORTANT\]/> **Important.**/' -e 's/^> \[!WARNING\]/> **Warning.**/' \
      "$name/README.md" > "$name/_print.md"
  PUPPETEER_SKIP_DOWNLOAD=1 PUPPETEER_EXECUTABLE_PATH="${PUPPETEER_EXECUTABLE_PATH:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}" npx -y md-to-pdf@5 "$name/_print.md" --basedir . \
    --css "img{display:inline-block !important;vertical-align:-3px;margin:0 3px} h2 img{vertical-align:-5px} body{font-family:Helvetica,Arial,sans-serif} $TONE_CSS img[src*=screenshots]{display:block !important;max-width:100% !important;height:auto !important;margin:6px 0 !important}" \
    --launch-options '{"args":["--no-sandbox"]}' \
    --pdf-options '{"format":"A4","margin":{"top":"18mm","bottom":"18mm","left":"16mm","right":"16mm"},"printBackground":true}'
  mv "$name/_print.pdf" "pdf/$name.pdf"
  rm "$name/_print.md"
  echo "pdf/$name.pdf"
done
