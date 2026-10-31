#!/bin/sh
# sync-claude-section.sh — put the fleet's "Pull requests and Promotes" section into CLAUDE.md files,
# as a marker-delimited block, so a later sync replaces it instead of adding a second copy.
#
#     sh scripts/sync-claude-section.sh [--dry-run | --apply] [--quiet] [--source FILE]
#                                       [--list FILE] [--scan ROOT]... [CLAUDE.md]...
#
#   --dry-run    (default) print what would change, with a diff; write nothing
#   --apply      write the files
#   --quiet      no diffs, one line per file
#   --source F   where the block comes from (default: this repository's CLAUDE.md)
#   --list FILE  read CLAUDE.md paths from FILE, one per line (# comments and blanks ignored, ~ expanded);
#                a directory in the list means <dir>/CLAUDE.md
#   --scan ROOT  every CLAUDE.md under ROOT, up to 3 levels deep (node_modules skipped)
#
# The block is everything from the start marker to the end marker in the source, inclusive:
#
#     <!-- fleet:pull-requests-and-promotes:start ... -->
#     ## Pull requests and Promotes (October 2026)
#     ...
#     <!-- fleet:pull-requests-and-promotes:end -->
#
# For each target, in this order:
#   1. it already has the markers        -> the block between them is replaced
#   2. it has the "## Pull requests and Promotes" heading without markers
#                                        -> that section (to the next "#"/"##" heading, "---" rule or
#                                           fleet marker) is replaced by the marked block
#   3. it has "## Commit Convention"     -> the block is inserted just before that heading
#   4. otherwise                         -> the block is appended at the end
# Headings inside ``` fences are ignored. Idempotent: a second --apply changes nothing.
# It never commits. Review with git diff and commit in each repository the usual way.
#
# The file list is deliberately NOT written into this script: my-template is public, and the
# fleet's repository names are not all meant for visitors. Keep the list privately; use --list or --scan.

START='<!-- fleet:pull-requests-and-promotes:start'
END='<!-- fleet:pull-requests-and-promotes:end'

MODE=dry-run
QUIET=""
HERE=$(cd "$(dirname "$0")/.." && pwd)
SOURCE="$HERE/CLAUDE.md"
TARGETS=""
NL='
'

expand() {
  case "$1" in
    "~") printf '%s' "$HOME" ;;
    "~/"*) printf '%s/%s' "$HOME" "${1#\~/}" ;;
    *) printf '%s' "$1" ;;
  esac
}
add() {
  t=$(expand "$1"); t=${t%/}
  [ -d "$t" ] && t="$t/CLAUDE.md"
  TARGETS="$TARGETS$t$NL"
}
usage() { sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) MODE=dry-run ;;
    --apply) MODE=apply ;;
    --quiet) QUIET=1 ;;
    --source) SOURCE=$(expand "$2"); shift ;;
    --list)
      [ -f "$2" ] || { echo "✗ --list: no such file: $2" >&2; exit 2; }
      while IFS= read -r line || [ -n "$line" ]; do
        line=$(printf '%s' "$line" | sed 's/#.*//; s/^[[:space:]]*//; s/[[:space:]]*$//')
        [ -n "$line" ] && add "$line"
      done < "$2"
      shift ;;
    --scan)
      [ -d "$2" ] || { echo "✗ --scan: no such directory: $2" >&2; exit 2; }
      for f in $(find "$2" -maxdepth 3 -name CLAUDE.md -not -path '*/node_modules/*' 2>/dev/null | sort); do
        add "$f"
      done
      shift ;;
    -h|--help) usage 0 ;;
    -*) echo "✗ unknown option: $1" >&2; usage 2 ;;
    *) add "$1" ;;
  esac
  shift
done

[ -n "$TARGETS" ] || { echo "✗ no CLAUDE.md files given (paths, --list FILE or --scan ROOT)" >&2; usage 2; }
[ -f "$SOURCE" ] || { echo "✗ source not found: $SOURCE" >&2; exit 2; }

TMPD=$(mktemp -d "${TMPDIR:-/tmp}/sync-claude.XXXXXX") || exit 1
trap 'rm -f "$TMPD"/*; rmdir "$TMPD"' EXIT
BLOCK="$TMPD/block"
LIST="$TMPD/list"
OUT="$TMPD/out"

awk -v s="$START" -v e="$END" '
  index($0, s) == 1 { on = 1 }
  on { print }
  on && index($0, e) == 1 { exit }
' "$SOURCE" > "$BLOCK"
if ! grep -q "^$END" "$BLOCK" || [ "$(grep -c "^$START" "$BLOCK")" -ne 1 ]; then
  echo "✗ no complete marked block in $SOURCE (need a '$START' line and a '$END' line)" >&2
  exit 2
fi

# Pass 1: where things are. Prints: marker-start marker-end heading-start heading-end commit-conv lines
locate() {
  awk -v s="$START" -v e="$END" '
    { isfence = ($0 ~ /^(```|~~~)/) }
    insec && !fence && !isfence && ($0 ~ /^##? / || $0 ~ /^---+[[:space:]]*$/ || index($0, "<!-- fleet:") == 1) {
      insec = 0; he = lastnb
    }
    insec && $0 ~ /[^[:space:]]/ { lastnb = NR }
    isfence { fence = !fence; next }
    fence { next }
    index($0, s) == 1 && !ms { ms = NR; next }
    index($0, e) == 1 && ms && !me { me = NR; next }
    /^## Pull requests and Promotes/ && !hs && !(ms && !me) { hs = NR; insec = 1; lastnb = NR; next }
    /^## Commit Convention/ && !cc { cc = NR }
    END { if (insec) he = lastnb; print ms + 0, me + 0, hs + 0, he + 0, cc + 0, NR + 0 }
  ' "$1"
}

# Pass 2: replace lines a..b with the block (b = a - 1 inserts before line a; gap=1 adds a blank after).
splice() { # file a b gap
  awk -v a="$2" -v b="$3" -v gap="$4" -v blk="$BLOCK" '
    function emit(  l) { while ((getline l < blk) > 0) print l; close(blk); if (gap) print "" }
    NR == a { emit() }
    NR >= a && NR <= b { next }
    { print }
  ' "$1"
}

CHANGED=0; SAME=0; SKIPPED=0
printf '%s' "$TARGETS" | awk 'NF && !seen[$0]++' > "$LIST"

while IFS= read -r f; do
  if [ ! -f "$f" ]; then
    echo "  skip       $f  (no such file)"; SKIPPED=$((SKIPPED+1)); continue
  fi
  set -- $(locate "$f")
  ms=$1 me=$2 hs=$3 he=$4 cc=$5 n=$6
  if [ "$ms" -gt 0 ] && [ "$me" -eq 0 ]; then
    echo "  skip       $f  (start marker on line $ms but no end marker; fix by hand)"
    SKIPPED=$((SKIPPED+1)); continue
  fi
  if [ "$ms" -gt 0 ]; then
    how="replace marked block (lines $ms-$me)"
    splice "$f" "$ms" "$me" 0 > "$OUT"
    if [ "$hs" -gt 0 ] && { [ "$hs" -lt "$ms" ] || [ "$hs" -gt "$me" ]; }; then
      how="$how; NOTE: a second unmarked copy of the heading is on line $hs, left for a human"
    fi
  elif [ "$hs" -gt 0 ]; then
    how="replace unmarked section (lines $hs-$he) with the marked block"
    splice "$f" "$hs" "$he" 0 > "$OUT"
  elif [ "$cc" -gt 0 ]; then
    how="insert before '## Commit Convention' (line $cc)"
    splice "$f" "$cc" $((cc - 1)) 1 > "$OUT"
  else
    how="append at the end (no '## Commit Convention' heading)"
    { cat "$f"
      [ -n "$(tail -c 1 "$f")" ] && echo ""
      [ -n "$(tail -n 1 "$f" | tr -d '[:space:]')" ] && echo ""
      cat "$BLOCK"
    } > "$OUT"
  fi

  if cmp -s "$f" "$OUT"; then
    echo "  unchanged  $f"
    SAME=$((SAME+1)); continue
  fi
  CHANGED=$((CHANGED+1))
  if [ "$MODE" = apply ]; then
    cat "$OUT" > "$f"
    echo "  updated    $f  ($how)"
  else
    echo "  would      $f  ($how)"
    [ -n "$QUIET" ] || { diff -u "$f" "$OUT" | sed '1,2d; s/^/      /'; echo ""; }
  fi
done < "$LIST"

echo ""
if [ "$MODE" = apply ]; then
  echo "applied: $CHANGED updated, $SAME unchanged, $SKIPPED skipped. Nothing committed."
else
  echo "dry run: $CHANGED to change, $SAME unchanged, $SKIPPED skipped. Run with --apply to write."
fi
