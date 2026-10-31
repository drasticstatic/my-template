#!/bin/sh
# lay-pending-archive.sh — lay an EMPTY archive beside each repository's pending-tasks file.
#
#     sh scripts/lay-pending-archive.sh [--dry-run | --apply] [--list FILE] [--scan ROOT]... [REPO]...
#
#   --dry-run    (default) say what would be created or changed; write nothing
#   --apply      write the files
#   --list FILE  read repository paths from FILE, one per line (# comments and blanks ignored, ~ expanded)
#   --scan ROOT  find repositories under ROOT (up to 3 levels) that have a pending-tasks file
#   REPO         a repository path
#
# For each repository whose ROOT holds pending-tasks.md or PENDING-TASKS.md (matched by exact
# case, which matters on macOS's case-insensitive disk):
#
#   1. creates the sibling archive, matching the case:
#        pending-tasks.md  ->  pending-tasks_archive.md
#        PENDING-TASKS.md  ->  PENDING-TASKS_ARCHIVE.md
#      with a header, the rule, and an empty "Archived" section. An existing archive is never touched.
#   2. adds ONE pointer line near the top of the pending file (after its "# " title), only if the
#      file doesn't already mention its archive.
#
# Nothing is moved: which items go to the archive is Christopher's call, per repository.
# Idempotent: a second --apply changes nothing. It never commits; review with git diff and commit
# in each repository the usual way.
#
# The repository list is deliberately NOT written into this script: my-template is public, and
# the fleet's repository names are not all meant for visitors. Keep the list in a private file
# and pass it with --list, or use --scan.

MODE=dry-run
REPOS=""
NL='
'

add_repo() { REPOS="$REPOS$1$NL"; }

expand() {
  case "$1" in
    "~") printf '%s' "$HOME" ;;
    "~/"*) printf '%s/%s' "$HOME" "${1#\~/}" ;;
    *) printf '%s' "$1" ;;
  esac
}

usage() { sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) MODE=dry-run ;;
    --apply) MODE=apply ;;
    --list)
      [ -f "$2" ] || { echo "✗ --list: no such file: $2" >&2; exit 2; }
      while IFS= read -r line || [ -n "$line" ]; do
        line=$(printf '%s' "$line" | sed 's/#.*//; s/^[[:space:]]*//; s/[[:space:]]*$//')
        [ -n "$line" ] && add_repo "$(expand "$line")"
      done < "$2"
      shift ;;
    --scan)
      [ -d "$2" ] || { echo "✗ --scan: no such directory: $2" >&2; exit 2; }
      oldifs=$IFS; IFS=$NL   # split find's output on newlines only, so a path with a space stays whole
      for d in $(find "$2" -maxdepth 3 \( -name pending-tasks.md -o -name PENDING-TASKS.md \) \
                   -not -path '*/node_modules/*' 2>/dev/null | sed 's|/[^/]*$||' | sort -u); do
        [ -e "$d/.git" ] && add_repo "$d"
      done
      IFS=$oldifs
      shift ;;
    -h|--help) usage 0 ;;
    -*) echo "✗ unknown option: $1" >&2; usage 2 ;;
    *) add_repo "$(expand "$1")" ;;
  esac
  shift
done

[ -n "$REPOS" ] || { echo "✗ no repositories given (paths, --list FILE or --scan ROOT)" >&2; usage 2; }

TODAY=$(date +%Y-%m-%d)
CREATED=0; POINTED=0; UNCHANGED=0; SKIPPED=0
TMPF=$(mktemp "${TMPDIR:-/tmp}/lay-pending.XXXXXX") || exit 1
TMPL=$(mktemp "${TMPDIR:-/tmp}/lay-pending-list.XXXXXX") || exit 1
trap 'rm -f "$TMPF" "$TMPL"' EXIT
printf '%s' "$REPOS" | sort -u > "$TMPL"

archive_text() { # $1 repo name, $2 pending file name
  cat <<EOF
# $1 — pending tasks archive

Items that have left [\`$2\`](./$2). Laid empty on $TODAY by
\`my-template/scripts/lay-pending-archive.sh\`.

**The rule.** An item moves here when it has been **done for 30 days**, or when it has been
**superseded**. It keeps its date and its commit, so the history stays findable:

\`\`\`text
- [x] The item, as it was written. Done 2026-10-01 in abc1234; moved 2026-11-01.
- [~] The item, as it was written. Superseded 2026-10-12 by <what replaced it>; moved 2026-11-12.
\`\`\`

**Christopher decides what moves.** Nothing moves automatically. Newest moves go at the top of
the section below.

## Archived

<!-- Nothing archived yet. -->
EOF
}

while IFS= read -r repo; do
  [ -n "$repo" ] || continue
  repo=${repo%/}
  if [ ! -d "$repo" ]; then
    echo "  skip     $repo  (not a directory)"; SKIPPED=$((SKIPPED+1)); continue
  fi
  name=$(basename "$repo")
  listing=$(ls -1A "$repo")
  found=0
  for pending in pending-tasks.md PENDING-TASKS.md; do
    printf '%s\n' "$listing" | grep -qx "$pending" || continue
    found=1
    case "$pending" in
      pending-tasks.md) archive=pending-tasks_archive.md ;;
      *) archive=PENDING-TASKS_ARCHIVE.md ;;
    esac

    # 1. the archive file
    existing=$(printf '%s\n' "$listing" | grep -ix "$archive" | head -1)
    if [ -n "$existing" ]; then
      [ "$existing" = "$archive" ] && msg="exists" || msg="exists as $existing (case differs; left alone)"
      echo "  ok       $repo/$archive  ($msg)"
      UNCHANGED=$((UNCHANGED+1))
    elif [ "$MODE" = apply ]; then
      archive_text "$name" "$pending" > "$repo/$archive"
      echo "  created  $repo/$archive"
      CREATED=$((CREATED+1))
    else
      echo "  would create  $repo/$archive"
      CREATED=$((CREATED+1))
    fi

    # 2. the pointer line
    pointer="> Done and superseded items move to [\`$archive\`](./$archive): done for 30 days, or superseded; Christopher decides what moves."
    if grep -qiF "$archive" "$repo/$pending"; then
      echo "  ok       $repo/$pending  (already points to its archive)"
      UNCHANGED=$((UNCHANGED+1))
      continue
    fi
    title=$(grep -n -m1 '^# ' "$repo/$pending" | cut -d: -f1)
    if [ -n "$title" ] && [ "$title" -le 15 ]; then
      where="after line $title (the title)"
    else
      title=0; where="at the top (no '# ' title in the first 15 lines)"
    fi
    awk -v at="$title" -v ptr="$pointer" '
      at == 0 && NR == 1 { print ptr; print "" }
      { if (gap) { if ($0 !~ /^[[:space:]]*$/) print ""; gap = 0 } print }
      at > 0 && NR == at { print ""; print ptr; gap = 1 }
    ' "$repo/$pending" > "$TMPF"
    if [ "$MODE" = apply ]; then
      cat "$TMPF" > "$repo/$pending"
      echo "  pointed  $repo/$pending  ($where)"
    else
      echo "  would point   $repo/$pending  ($where):"
      echo "                $pointer"
    fi
    POINTED=$((POINTED+1))
  done
  if [ $found = 0 ]; then
    echo "  skip     $repo  (no pending-tasks.md or PENDING-TASKS.md at its root)"
    SKIPPED=$((SKIPPED+1))
  fi
done < "$TMPL"

echo ""
if [ "$MODE" = apply ]; then
  echo "applied: $CREATED archive(s) created, $POINTED pointer(s) added, $UNCHANGED already in place, $SKIPPED skipped. Nothing committed."
else
  echo "dry run: $CREATED archive(s) to create, $POINTED pointer(s) to add, $UNCHANGED already in place, $SKIPPED skipped. Run with --apply to write."
fi
