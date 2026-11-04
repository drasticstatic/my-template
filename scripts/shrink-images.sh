#!/bin/sh
# shrink-images.sh — make the pictures in a repository small enough to commit and publish.
#
#     sh scripts/shrink-images.sh [--check] [--max PX] [--no-quantise] [--quality MIN-MAX] <file or folder>...
#
#   (no flag)        shrink each image in place: resize so the longer side is at most PX (default 2500),
#                    then PNG → pngquant, JPEG → re-saved at quality 80. A file is replaced only when the
#                    result is smaller; otherwise it is left exactly as it was and the line says so.
#   --check          list every image with its size, pixels and verdict; touch nothing. Exit 1 when any
#                    image is over 15 MB (the hook and the scanner would refuse it), else 0.
#   --max PX         longer side after resizing (default 2500; a README banner needs no more than ~1600,
#                    a screenshot for a PDF no more than ~2000)
#   --no-quantise    skip pngquant: resize only. For a photograph saved as PNG that must stay lossless,
#                    or any PNG whose colours must not be reduced (see "what pngquant does", below)
#   --quality MIN-MAX  pngquant's quality window (default 65-80)
#   A folder is searched to any depth (node_modules and .git skipped) for png jpg jpeg gif webp svg heic.
#
# The two limits, and where they come from:
#   15 MB  refused — scripts/scan-public-lane.sh (MAX_BYTES) refuses it at every public lane, and
#          .githooks/pre-commit refuses it before it is ever committed.
#    2 MB  warned  — a banner or screenshot this size is nearly always a resize away from a tenth of it.
#
# What is in the box on this machine (checked 2026-11-04):
#   sips      /usr/bin/sips, part of macOS. Resizes (-Z) and re-encodes JPEG (-s formatOptions N) for
#             png jpg jpeg gif heic; reads webp but cannot write it on every macOS, so a webp that will
#             not re-save is reported and left alone.
#   pngquant  /opt/homebrew/bin/pngquant (3.0.3). Lossy PNG: quantises to a 256-colour palette, which
#             cuts a banner, diagram or screenshot by 60-80 % with no visible change, and turns a
#             photograph's smooth gradients into bands. That is why --no-quantise exists and why the
#             skill (.claude/skills/compress-images.md) says to flag a photograph, not force it.
#   NOT installed: oxipng, jpegoptim, cwebp, magick (ImageMagick). Nothing here calls them; every
#             step falls back to sips. If one arrives later (brew install oxipng jpegoptim webp
#             imagemagick) this script still works unchanged; a lossless PNG pass would be the first
#             thing worth adding.
#   GIF is left alone (sips would flatten an animation to one frame) and SVG is text (no raster to
#   resize): both are listed by --check and reported, never changed.
#
# It never runs git. After shrinking, `git add` the files again: the hook reads the staged blob.
# The exact pngquant line the hook prints, for one file by hand:
#   pngquant --quality=65-80 --speed=1 --skip-if-larger --ext .png --force <file.png>

set -u

MAX_PX=2500
QUALITY="65-80"
CHECK=0
QUANTISE=1
REFUSE=$((15 * 1024 * 1024))
WARN=$((2 * 1024 * 1024))
TARGETS=""
NL='
'

usage() { sed -n '2,19p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }

while [ $# -gt 0 ]; do
  case "$1" in
    --check) CHECK=1 ;;
    --max) MAX_PX="$2"; shift ;;
    --max=*) MAX_PX="${1#--max=}" ;;
    --no-quantise|--no-quantize) QUANTISE=0 ;;
    --quality) QUALITY="$2"; shift ;;
    --quality=*) QUALITY="${1#--quality=}" ;;
    -h|--help) usage 0 ;;
    -*) echo "✗ unknown option: $1" >&2; usage 2 ;;
    *) TARGETS="$TARGETS$1$NL" ;;
  esac
  shift
done
[ -n "$TARGETS" ] || { echo "✗ give at least one image file or folder" >&2; usage 2; }
case "$MAX_PX" in ''|*[!0-9]*) echo "✗ --max wants a whole number of pixels, got '$MAX_PX'" >&2; exit 2 ;; esac

command -v sips >/dev/null 2>&1 || { echo "✗ sips not found: this script is for macOS" >&2; exit 2; }
PNGQUANT=$(command -v pngquant 2>/dev/null || true)
[ -z "$PNGQUANT" ] && [ -x /opt/homebrew/bin/pngquant ] && PNGQUANT=/opt/homebrew/bin/pngquant
if [ "$CHECK" = 0 ] && [ "$QUANTISE" = 1 ] && [ -z "$PNGQUANT" ]; then
  echo "⚠ pngquant not found (brew install pngquant): PNGs will be resized only." >&2
  QUANTISE=0
fi

TMPD=$(mktemp -d "${TMPDIR:-/tmp}/shrink-images.XXXXXX") || exit 1
trap 'rm -f "$TMPD"/*; rmdir "$TMPD"' EXIT

mb() { awk -v b="$1" 'BEGIN { if (b < 1048576) printf "%d KB", (b + 1023) / 1024; else printf "%.1f MB", b / 1048576 }'; }
bytes() { stat -f %z "$1" 2>/dev/null || stat -c %s "$1"; }
ext_of() { printf '%s' "${1##*.}" | tr '[:upper:]' '[:lower:]'; }
# "WxH" for a raster sips can read, "-" otherwise (sips prints "<nil>" for a file it cannot parse,
# and a float for an SVG's viewBox; both are read as whole numbers or not at all).
dims() {
  sips -g pixelWidth -g pixelHeight "$1" 2>/dev/null \
    | awk '/pixelWidth/ && $2 ~ /^[0-9]/ {w=int($2)} /pixelHeight/ && $2 ~ /^[0-9]/ {h=int($2)}
           END { if (w > 0 && h > 0) print w "x" h; else print "-" }'
}
longer() { printf '%s' "$1" | awk -Fx '{ print ($1 > $2) ? $1 : $2 }'; }

# Expand folders. find's output split on newlines only.
LIST="$TMPD/list"
printf '%s' "$TARGETS" | while IFS= read -r t; do
  [ -n "$t" ] || continue
  if [ -d "$t" ]; then
    find "$t" \( -name node_modules -o -name .git \) -prune -o -type f \
      \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.gif' \
         -o -iname '*.webp' -o -iname '*.svg' -o -iname '*.heic' \) -print 2>/dev/null | sort
  elif [ -f "$t" ]; then
    printf '%s\n' "$t"
  else
    echo "  skip       $t  (no such file or folder)" >&2
  fi
done > "$LIST"

[ -s "$LIST" ] || { echo "no images found"; exit 0; }

OVER15=0; OVER2=0; SHRUNK=0; LEFT=0; SAVED=0

if [ "$CHECK" = 1 ]; then
  printf '%-10s %-12s %-8s %s\n' "size" "pixels" "verdict" "path"
  while IFS= read -r f; do
    sz=$(bytes "$f"); px=$(dims "$f")
    if [ "$sz" -gt "$REFUSE" ]; then v="REFUSE"; OVER15=$((OVER15+1))
    elif [ "$sz" -gt "$WARN" ]; then v="shrink"; OVER2=$((OVER2+1))
    else v="ok"; fi
    printf '%-10s %-12s %-8s %s\n' "$(mb "$sz")" "$px" "$v" "$f"
  done < "$LIST"
  echo ""
  n=$(wc -l < "$LIST" | tr -d ' ')
  echo "$n images · over 15 MB (refused by the hook and the scanner): $OVER15 · over 2 MB (shrink before committing): $OVER2"
  if [ "$OVER15" -gt 0 ] || [ "$OVER2" -gt 0 ]; then
    echo "Shrink: sh scripts/shrink-images.sh <those files>   (add --no-quantise for a photograph that must stay lossless)"
  fi
  [ "$OVER15" = 0 ]
  exit $?
fi

while IFS= read -r f; do
  ext=$(ext_of "$f")
  before=$(bytes "$f")
  px=$(dims "$f")
  case "$ext" in
    svg)
      echo "  left       $f  ($(mb "$before"); SVG is text, nothing to resize; if it is large it embeds a raster)"
      LEFT=$((LEFT+1)); continue ;;
    gif)
      echo "  left       $f  ($(mb "$before"); GIF: sips would flatten an animation; convert by hand if it must shrink)"
      LEFT=$((LEFT+1)); continue ;;
  esac
  if [ "$px" = "-" ]; then
    echo "  left       $f  ($(mb "$before"); sips cannot read it)"
    LEFT=$((LEFT+1)); continue
  fi

  tmp="$TMPD/work.$ext"
  cp "$f" "$tmp" || { echo "  left       $f  (could not copy)"; LEFT=$((LEFT+1)); continue; }
  did=""

  # 1. Resize only when the longer side is over the limit: sips -Z would otherwise upscale.
  if [ "$(longer "$px")" -gt "$MAX_PX" ]; then
    if sips -Z "$MAX_PX" "$tmp" >/dev/null 2>&1; then did="${did}resized to $(dims "$tmp"); "
    else echo "  left       $f  ($(mb "$before"); sips could not resize this $ext)"; LEFT=$((LEFT+1)); continue; fi
  fi

  # 2. Per format.
  case "$ext" in
    png)
      if [ "$QUANTISE" = 1 ]; then
        "$PNGQUANT" --quality="$QUALITY" --speed=1 --skip-if-larger --ext .png --force "$tmp" >/dev/null 2>&1
        rc=$?
        case "$rc" in
          0)  did="${did}pngquant $QUALITY; " ;;
          98) did="${did}pngquant skipped (would be larger); " ;;
          99) did="${did}pngquant skipped (cannot meet quality $QUALITY); " ;;
          *)  did="${did}pngquant failed ($rc); " ;;
        esac
      else
        did="${did}not quantised; "
      fi ;;
    jpg|jpeg)
      if sips -s format jpeg -s formatOptions 80 "$tmp" >/dev/null 2>&1; then did="${did}jpeg quality 80; "
      else did="${did}jpeg re-save failed; "; fi ;;
    heic)
      did="${did}heic re-saved by sips; " ;;
    webp)
      # sips reads webp on recent macOS; writing it depends on the OS. If the result is not a
      # webp any more (sips fell back to another container) or is empty, leave the original.
      if [ ! -s "$tmp" ] || ! head -c 12 "$tmp" | grep -q 'WEBP'; then
        echo "  left       $f  ($(mb "$before"); sips cannot write WebP here and cwebp is not installed)"
        LEFT=$((LEFT+1)); continue
      fi ;;
  esac

  after=$(bytes "$tmp")
  if [ "$after" -lt "$before" ]; then
    cp "$tmp" "$f"
    SHRUNK=$((SHRUNK+1)); SAVED=$((SAVED + before - after))
    echo "  shrunk     $f  $(mb "$before") → $(mb "$after")  ($did$(dims "$f"))"
  else
    LEFT=$((LEFT+1))
    echo "  left       $f  ($(mb "$before"); ${did}nothing smaller came out, so it is untouched)"
  fi
  [ "$(bytes "$f")" -gt "$REFUSE" ] && OVER15=$((OVER15+1))
  [ "$(bytes "$f")" -gt "$WARN" ] && OVER2=$((OVER2+1))
done < "$LIST"

echo ""
echo "shrunk: $SHRUNK ($(mb "$SAVED") saved) · left as they were: $LEFT · still over 15 MB: $OVER15 · still over 2 MB: $OVER2"
echo "Nothing was staged. git add the shrunk files again; the pre-commit hook reads the staged blob."
if [ "$OVER15" -gt 0 ]; then
  echo "A file still over 15 MB cannot be committed: lower --max, or ask whether a picture that size belongs in a repository at all."
fi
[ "$OVER15" = 0 ]
