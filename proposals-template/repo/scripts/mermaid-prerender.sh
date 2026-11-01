#!/bin/sh
# mermaid-prerender.sh — turn every ```mermaid block in a markdown file into an SVG picture, so the PDF shows the diagram.
#   sh scripts/mermaid-prerender.sh IN.md OUT.md
# GitHub draws ```mermaid blocks itself; md-to-pdf does not, and would print the diagram's source text. This step runs
# between the print preprocessing (sed) and md-to-pdf, in scripts/render-pdfs.sh and in .github/workflows/pdf.yml (the proposals copy; the SOP template carries the same file):
#   OUT.md is IN.md with each block replaced by ![diagram](./OUT-1.svg), ./OUT-2.svg, …, written beside OUT.md.
# A file with no ```mermaid block is copied unchanged and nothing is installed or run.
#
# The tool is @mermaid-js/mermaid-cli (mmdc), pinned. Provenance checked 2026-11-01 (my-template/LUCID.md, "Mermaid in PDFs"):
#   the mermaid-js organisation's own package (github.com/mermaid-js/mermaid-cli, MIT, since 2020), published by GitHub
#   Actions as a trusted publisher; 12.0.0 has no preinstall/install/postinstall script. Its one peer, puppeteer, has a
#   postinstall that downloads Chrome; PUPPETEER_SKIP_DOWNLOAD=1 skips it when a Chrome is already installed (locally).
# Diagram colours follow the same four tone shades as the PDF (TONE_* variables, bare hex, no #).
# Override the command with MMDC=... (an installed copy, when the npm registry stalls: SOP-IT-001).
set -eu
in="${1:?usage: mermaid-prerender.sh IN.md OUT.md}"; out="${2:?usage: mermaid-prerender.sh IN.md OUT.md}"
if ! grep -q '^```mermaid' "$in"; then
  [ "$in" = "$out" ] || cp "$in" "$out"
  exit 0
fi
MMDC="${MMDC:-npx -y -p @mermaid-js/mermaid-cli@12.0.0 -p puppeteer@25.13.0 mmdc}"
TONE_PRIMARY="${TONE_PRIMARY:-d97706}"; TONE_DEEP="${TONE_DEEP:-6b4f1d}"; TONE_MID="${TONE_MID:-b45309}"; TONE_TINT="${TONE_TINT:-fef3c7}"
cfgdir="$(mktemp -d "${TMPDIR:-/tmp}/mermaid.XXXXXX")"
trap 'rm -rf "$cfgdir"' EXIT
src="$cfgdir/source.md"; cp "$in" "$src"
printf '{"args":["--no-sandbox"]}\n' > "$cfgdir/puppeteer.json"
cat > "$cfgdir/mermaid.json" <<EOF
{"theme":"base","themeVariables":{"fontFamily":"Helvetica, Arial, sans-serif","primaryColor":"#$TONE_TINT","primaryBorderColor":"#$TONE_PRIMARY","primaryTextColor":"#$TONE_DEEP","secondaryColor":"#ffffff","tertiaryColor":"#f8fafc","lineColor":"#$TONE_MID","clusterBkg":"#f8fafc","clusterBorder":"#$TONE_PRIMARY","edgeLabelBackground":"#ffffff","noteBkgColor":"#$TONE_TINT","noteBorderColor":"#$TONE_MID"},"flowchart":{"htmlLabels":false,"useMaxWidth":false},"sequence":{"useMaxWidth":false},"gitGraph":{"useMaxWidth":false},"timeline":{"useMaxWidth":false},"gantt":{"useMaxWidth":false}}
EOF
$MMDC -q -i "$src" -o "$out" -e svg -b white -c "$cfgdir/mermaid.json" -p "$cfgdir/puppeteer.json"
grep -q '^```mermaid' "$out" && { echo "mermaid-prerender: a block was left unrendered in $out" >&2; exit 1; }
exit 0
