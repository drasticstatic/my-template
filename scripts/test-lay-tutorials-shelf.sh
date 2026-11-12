#!/bin/sh
# test-lay-tutorials-shelf.sh — self-test for scripts/lay-tutorials-shelf.sh, on a small made-up fleet in a temp folder.
#
#     sh scripts/test-lay-tutorials-shelf.sh
#
# Proves: the dry run writes nothing; --apply lays tutorials/README.md in SOP locations and reading rooms
# only; public twins and other repositories are skipped; an existing README is never overwritten (in any
# case); a file named tutorials is left alone; a second --apply changes nothing; --list and REPO work.
# Exits non-zero if any case fails.

cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)" || exit 1
LAY="$(pwd)/scripts/lay-tutorials-shelf.sh"
TMP=$(mktemp -d "${TMPDIR:-/tmp}/lay-tutorials-test.XXXXXX") || exit 1
trap 'rm -rf "$TMP"' EXIT INT TERM   # only the temp fleet this test made

PASS=0; FAIL=0
ok()   { PASS=$((PASS+1)); printf '  ok    %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); printf '  FAIL  %s\n' "$1"; }
check() { if eval "$2"; then ok "$1"; else bad "$1"; fi; }

F="$TMP/fleet"
repo() { mkdir -p "$F/$1/.git"; }
repo org/ops-standard-operating-procedures
repo org/ops-standard-operating-procedures-public
repo lab/ops-standard-operating-procedures-org
repo org/reading-room
repo org/reading-room-public
repo org/proposals
repo other/reading-room                                   # already has a shelf, in another case
mkdir -p "$F/other/reading-room/Tutorials"; echo "keep me" > "$F/other/reading-room/Tutorials/readme.md"
repo blocked/reading-room; echo "a file" > "$F/blocked/reading-room/tutorials"
repo half/ops-standard-operating-procedures; mkdir -p "$F/half/ops-standard-operating-procedures/tutorials"
mkdir -p "$F/notgit/reading-room"                          # right name, not a repository

echo "lay-tutorials-shelf.sh"

out=$(sh "$LAY" --scan "$F" 2>&1)
check "dry run writes nothing" '[ ! -e "$F/org/ops-standard-operating-procedures/tutorials" ] && [ ! -e "$F/org/reading-room/tutorials" ]'
check "dry run names what it would create" 'printf "%s" "$out" | grep -q "would create  $F/org/reading-room/tutorials/README.md"'

out=$(sh "$LAY" --apply --scan "$F" 2>&1)
check "SOP location gets a shelf" '[ -f "$F/org/ops-standard-operating-procedures/tutorials/README.md" ]'
check "lab desk gets a shelf" '[ -f "$F/lab/ops-standard-operating-procedures-org/tutorials/README.md" ]'
check "reading room gets a shelf" '[ -f "$F/org/reading-room/tutorials/README.md" ]'
check "shelf in an existing empty folder" '[ -f "$F/half/ops-standard-operating-procedures/tutorials/README.md" ]'
check "public SOP twin skipped" '[ ! -e "$F/org/ops-standard-operating-procedures-public/tutorials" ]'
check "public reading room skipped" '[ ! -e "$F/org/reading-room-public/tutorials" ]'
check "other repositories skipped" '[ ! -e "$F/org/proposals/tutorials" ]'
check "not a git repository: skipped" '[ ! -e "$F/notgit/reading-room/tutorials" ]'
check "existing README never overwritten" '[ "$(cat "$F/other/reading-room/Tutorials/readme.md")" = "keep me" ] && [ "$(ls "$F/other/reading-room/Tutorials" | wc -l | tr -d " ")" = 1 ]'
check "a file named tutorials left alone" '[ -f "$F/blocked/reading-room/tutorials" ] && [ "$(cat "$F/blocked/reading-room/tutorials")" = "a file" ]'
check "SOP shelf names its kind" 'grep -q "beside this repository.s procedures" "$F/org/ops-standard-operating-procedures/tutorials/README.md"'
check "reading-room shelf names its kind" 'grep -q "in this reading room" "$F/org/reading-room/tutorials/README.md"'
check "shelf points to the four shelves" 'grep -q "my-template/blob/main/tutorials/README.md" "$F/org/reading-room/tutorials/README.md"'
check "summary counts" 'printf "%s" "$out" | grep -q "applied: 4 shelf README(s) created, 1 already in place"'

before=$(cd "$F" && find . -type f -exec cksum {} + | sort)
out=$(sh "$LAY" --apply --scan "$F" 2>&1)
after=$(cd "$F" && find . -type f -exec cksum {} + | sort)
check "second --apply changes nothing" '[ "$before" = "$after" ] && printf "%s" "$out" | grep -q "applied: 0 shelf README(s) created"'

printf '# a private list\n%s\n\n%s  # a twin\n' "$F/org/reading-room" "$F/org/reading-room-public" > "$TMP/list.txt"
out=$(sh "$LAY" --list "$TMP/list.txt" 2>&1)
check "--list: existing shelf reported ok" 'printf "%s" "$out" | grep -q "ok       $F/org/reading-room/tutorials/README.md"'
check "--list: twin reported as skipped" 'printf "%s" "$out" | grep -q "skip     $F/org/reading-room-public  (a public twin"'

out=$(sh "$LAY" "$F/org/proposals" 2>&1)
check "REPO that does not match: skipped" 'printf "%s" "$out" | grep -q "not an SOP location or a reading room by name"'

sh "$LAY" >/dev/null 2>&1; rc=$?
check "no repositories given: exit 2" '[ "$rc" -eq 2 ]'

echo ""
echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
