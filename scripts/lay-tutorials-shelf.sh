#!/bin/sh
# lay-tutorials-shelf.sh — lay a tutorials shelf (a pointer tutorials/README.md) beside every SOP location and reading room.
#
#     sh scripts/lay-tutorials-shelf.sh [--dry-run | --apply] [--list FILE] [--scan ROOT]... [REPO]...
#
#   --dry-run    (default) say what would be created; write nothing
#   --apply      write the files
#   --list FILE  read repository paths from FILE, one per line (# comments and blanks ignored, ~ expanded)
#   --scan ROOT  find SOP locations and reading rooms under ROOT (up to 3 levels)
#   REPO         a repository path
#
# Which folders count (the names this template gives them, matched by exact case):
#
#   SOP location   a git repository named  ops-standard-operating-procedures
#                  or ops-standard-operating-procedures-<desk>   (sop-template/README.md: the organisation's
#                  procedures, and the lab's drafting desk for it)
#   reading room   a git repository named  reading-room           (SOP-IT-002: <org>/reading-room)
#
#   Never a public twin: any name ending in -public (ops-standard-operating-procedures-<org>-public,
#   reading-room-public) is skipped, because a twin receives only allowlisted files from its sync and
#   is never edited by hand. A path from --list or the command line that does not match is skipped too.
#
# For each match it creates tutorials/README.md: a short index that points to
# my-template/tutorials/README.md (the four shelves and how a tutorial is laid out) and holds an empty
# table for the repository's own tutorials. It NEVER overwrites: if tutorials/README.md exists (in any
# case), or a file named tutorials is in the way, the repository is reported and left alone.
# Idempotent: a second --apply changes nothing. It never commits; review with git status in each
# repository and commit there, on its working branch.
#
# Like lay-pending-archive.sh, no repository list is written into this script: my-template is public.
# Keep the list in a private file and pass it with --list, or use --scan.

MODE=dry-run
REPOS=""
SCANNED=no
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

usage() { sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }

# kind NAME -> prints "sop", "reading-room" or nothing
kind() {
  case "$1" in
    *-public) ;;
    ops-standard-operating-procedures|ops-standard-operating-procedures-?*) echo sop ;;
    reading-room) echo reading-room ;;
  esac
}

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
      SCANNED=yes
      oldifs=$IFS; IFS=$NL   # split find's output on newlines only, so a path with a space stays whole
      for d in $(find "$2" -maxdepth 3 -type d \( -name 'ops-standard-operating-procedures*' -o -name 'reading-room*' \) \
                   -not -path '*/node_modules/*' 2>/dev/null | sort -u); do
        [ -e "$d/.git" ] && [ -n "$(kind "$(basename "$d")")" ] && add_repo "$d"
      done
      IFS=$oldifs
      shift ;;
    -h|--help) usage 0 ;;
    -*) echo "✗ unknown option: $1" >&2; usage 2 ;;
    *) add_repo "$(expand "$1")" ;;
  esac
  shift
done

if [ -z "$REPOS" ]; then
  [ "$SCANNED" = yes ] && { echo "nothing to do: no SOP location or reading room found by name under the scanned roots."; exit 0; }
  echo "✗ no repositories given (paths, --list FILE or --scan ROOT)" >&2; usage 2
fi

TODAY=$(date +%Y-%m-%d)
CREATED=0; UNCHANGED=0; SKIPPED=0
TMPL=$(mktemp "${TMPDIR:-/tmp}/lay-tutorials-list.XXXXXX") || exit 1
trap 'rm -f "$TMPL"' EXIT
printf '%s' "$REPOS" | sort -u > "$TMPL"

shelf_text() { # $1 repository name, $2 kind
  if [ "$2" = sop ]; then
    beside="beside this repository's procedures. A procedure says how an approved job is done, every time; a tutorial teaches someone to do it, start to finish"
  else
    beside="in this reading room. Like every page here, a tutorial is a copy: it keeps the name it has in the repository that wrote it"
  fi
  cat <<EOF
# Tutorials — $1

Learn by doing: one task from start to finish, with what you should see at each step. This shelf sits
$beside.

- **The four shelves** (procedure, proposal, walkthrough, tutorial) and how a tutorial is named and laid out:
  [my-template/tutorials/README.md](https://github.com/drasticstatic/my-template/blob/main/tutorials/README.md).
- **Writing one?** Start from
  [my-template/tutorials-template/](https://github.com/drasticstatic/my-template/tree/main/tutorials-template).
- Tutorials are not numbered. Link them by file name.

Laid empty on $TODAY by \`my-template/scripts/lay-tutorials-shelf.sh\`.

## The tutorials

| Tutorial | You will learn to… |
|---|---|

<!-- None yet. Add one row per tutorial. -->
EOF
}

while IFS= read -r repo; do
  [ -n "$repo" ] || continue
  repo=${repo%/}
  if [ ! -d "$repo" ]; then
    echo "  skip     $repo  (not a directory)"; SKIPPED=$((SKIPPED+1)); continue
  fi
  name=$(basename "$repo")
  k=$(kind "$name")
  if [ -z "$k" ]; then
    case "$name" in
      *-public) why="a public twin: it receives files only from its sync" ;;
      *) why="not an SOP location or a reading room by name" ;;
    esac
    echo "  skip     $repo  ($why)"; SKIPPED=$((SKIPPED+1)); continue
  fi
  if [ ! -e "$repo/.git" ]; then
    echo "  skip     $repo  (not a git repository)"; SKIPPED=$((SKIPPED+1)); continue
  fi
  shelf=$(ls -1A "$repo" | grep -ix tutorials | head -1)
  if [ -n "$shelf" ] && [ ! -d "$repo/$shelf" ]; then
    echo "  skip     $repo  (a file named $shelf is in the way; left alone)"; SKIPPED=$((SKIPPED+1)); continue
  fi
  if [ -n "$shelf" ]; then
    readme=$(ls -1A "$repo/$shelf" | grep -ix readme.md | head -1)
    if [ -n "$readme" ]; then
      echo "  ok       $repo/$shelf/$readme  (exists; never overwritten)"; UNCHANGED=$((UNCHANGED+1)); continue
    fi
  else
    shelf=tutorials
  fi
  if [ "$MODE" = apply ]; then
    mkdir -p "$repo/$shelf" && shelf_text "$name" "$k" > "$repo/$shelf/README.md" || { echo "✗ could not write $repo/$shelf/README.md" >&2; exit 1; }
    echo "  created  $repo/$shelf/README.md  ($k)"
  else
    echo "  would create  $repo/$shelf/README.md  ($k)"
  fi
  CREATED=$((CREATED+1))
done < "$TMPL"

echo ""
if [ "$MODE" = apply ]; then
  echo "applied: $CREATED shelf README(s) created, $UNCHANGED already in place, $SKIPPED skipped. Nothing committed."
else
  echo "dry run: $CREATED shelf README(s) to create, $UNCHANGED already in place, $SKIPPED skipped. Run with --apply to write."
fi
