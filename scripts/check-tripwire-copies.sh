#!/bin/sh
# check-tripwire-copies.sh — every copy of the public-lane tripwire on this machine whose bytes differ from the master.
#
#     sh scripts/check-tripwire-copies.sh [--all] [--refs] [ROOT ...]
#
#   (no flag)   one line per copy that DIFFERS from the master (the scanner, its self-test, or both), then a count
#   --all       one line per copy, current ones too
#   --refs      also read each clone's origin/main and origin/preview, as of the last fetch (`git show`, no fetch), so a
#               copy that waits in an open pull request still shows as drift on the branch GitHub's lane runs from
#   ROOT ...    where to look (default: ~/code ~/drasticstaticLabs ~/dappu ~/littlebirds-git-home and every organisation
#               folder: ~/theholyearthfoundation ~/psychedelicsinrecovery ~/Octagon-Religious-Research-Group-ORG
#               ~/psanctuary ~/psanctuarychurch ~/taylordwraps)
#
# A copy is any scripts/scan-public-lane.sh under a root, up to eight folders deep (node_modules and .git skipped). Each
# line: state, where, the copy's md5 (first 8) and, when the md5 is one the fleet has carried, the master it came from:
#   current          both files are byte-identical to this repository's scripts/ pair
#   DRIFT            the scanner, the self-test or both differ (which one is named)
#   NO-SELFTEST      the scanner sits there without its self-test
# Read-only, by construction: GIT_OPTIONAL_LOCKS=0; it never fetches, copies, commits or deletes. To refresh a copy, copy
# the master pair over it and run its self-test there (sop-template/TRIPWIRE-COPIES.md: copy, do not fork).
#
# Exit code: 0 every copy is current · 1 at least one copy differs · 2 usage.
set -u
export GIT_OPTIONAL_LOCKS=0

here=$(cd "$(dirname "$0")" && pwd)
MS="$here/scan-public-lane.sh"; MT="$here/scan-public-lane.selftest.sh"
[ -f "$MS" ] && [ -f "$MT" ] || { echo "check-tripwire-copies: the master pair is not beside this script" >&2; exit 2; }
ms=$(md5 -q "$MS" 2>/dev/null || md5sum "$MS" | cut -d' ' -f1)
mt=$(md5 -q "$MT" 2>/dev/null || md5sum "$MT" | cut -d' ' -f1)
sum() { if command -v md5 >/dev/null 2>&1; then md5 -q; else md5sum | cut -d' ' -f1; fi; }

ALL=0; REFS=0; ROOTS=""
while [ $# -gt 0 ]; do
  case "$1" in
    --all) ALL=1 ;;
    --refs) REFS=1 ;;
    -h|--help) sed -n '2,22p' "$0"; exit 0 ;;
    -*) echo "check-tripwire-copies: unknown option $1" >&2; exit 2 ;;
    *) ROOTS="$ROOTS $1" ;;
  esac
  shift
done
[ -n "$ROOTS" ] || for d in code drasticstaticLabs dappu littlebirds-git-home theholyearthfoundation psychedelicsinrecovery \
  Octagon-Religious-Research-Group-ORG psanctuary psanctuarychurch taylordwraps; do [ -d "$HOME/$d" ] && ROOTS="$ROOTS $HOME/$d"; done

# md5s the fleet has carried (scanner), newest first; a copy whose md5 is not here was edited by hand (a fork)
label() {
  case "$1" in
    "$ms") echo "master" ;;
    f3f44d83*) echo "v5 37424c7" ;;
    e0a8a277*) echo "v4 3d1a6c7" ;;
    fc54aa60*) echo "v3 06ac002" ;;
    a9d35d6d*) echo "8002408" ;;
    *) echo "unknown: a fork, or older than 8002408" ;;
  esac
}

seen=0; drift=0
report() { # where scanner-md5 selftest-md5-or-"-"
  seen=$((seen + 1)); w="$1"; s="$2"; t="$3"
  if [ "$t" = "-" ]; then state="NO-SELFTEST"
  elif [ "$s" = "$ms" ] && [ "$t" = "$mt" ]; then state="current"
  elif [ "$s" != "$ms" ] && [ "$t" != "$mt" ]; then state="DRIFT scanner+selftest"
  elif [ "$s" != "$ms" ]; then state="DRIFT scanner"
  else state="DRIFT selftest"; fi
  [ "$state" = current ] || drift=$((drift + 1))
  [ "$state" = current ] && [ "$ALL" = 0 ] && return
  printf '%-24s %s  %s (%s)\n' "$state" "$w" "$(printf %s "$s" | cut -c1-8)" "$(label "$s")"
}

list=$(for r in $ROOTS; do
  find "$r" -maxdepth 8 \( -name node_modules -o -name .git \) -prune -o -path '*/scripts/scan-public-lane.sh' -print 2>/dev/null
done | sort -u)

while IFS= read -r f; do
  [ -n "$f" ] || continue
  d=$(dirname "$f"); t="$d/scan-public-lane.selftest.sh"
  s=$(sum < "$f"); if [ -f "$t" ]; then tt=$(sum < "$t"); else tt=-; fi
  report "$(printf %s "$(dirname "$d")" | sed "s#^$HOME#~#")" "$s" "$tt"
  if [ "$REFS" = 1 ]; then
    top=$(git -C "$d" rev-parse --show-toplevel 2>/dev/null) || continue
    rel=$(printf %s "$d" | sed "s#^$top/##; s#^$top\$##")
    case "$rel" in scripts) ;; *) continue ;; esac   # a nested copy inside another repository's tree: its own row says enough
    for ref in origin/main origin/preview; do
      git -C "$top" rev-parse -q --verify "$ref" >/dev/null || continue
      git -C "$top" cat-file -e "$ref:scripts/scan-public-lane.sh" 2>/dev/null || continue
      s=$(git -C "$top" show "$ref:scripts/scan-public-lane.sh" | sum)
      if git -C "$top" cat-file -e "$ref:scripts/scan-public-lane.selftest.sh" 2>/dev/null; then
        tt=$(git -C "$top" show "$ref:scripts/scan-public-lane.selftest.sh" | sum); else tt=-; fi
      report "$(printf %s "$top" | sed "s#^$HOME#~#") @ $ref" "$s" "$tt"
    done
  fi
done <<EOF
$list
EOF

echo "check-tripwire-copies: $seen cop$( [ "$seen" = 1 ] && echo y || echo ies) read, $drift differ from the master ($(printf %s "$ms" | cut -c1-8) / $(printf %s "$mt" | cut -c1-8))"
[ "$drift" = 0 ]
