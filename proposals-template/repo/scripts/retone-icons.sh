#!/bin/sh
# retone-icons.sh — recolour the Lucide icon set in proposals/assets/icons/ to an organisation's tone.
#   sh proposals/scripts/retone-icons.sh PRIMARY MID        # e.g. sh … ec4899 be185d  (magenta)
# The icons ship amber (d97706 strokes, b45309 the darker fill). Semantic colours are left alone:
# green (ready), red (blocked), purple (from you), grey (idle), white. Register: my-template/proposals-template/TONES.md.
set -eu
P="${1:?primary hex, no #}"; M="${2:-$1}"
cd "$(dirname "$0")/../assets/icons"
for f in *.svg; do
  sed -i '' -e "s/#d97706/#$P/g" -e "s/#b45309/#$M/g" "$f"
done
echo "icons toned #$P / #$M in $(pwd)"
