#!/bin/sh
# keep-scratch.selftest.sh: proves keep-scratch.sh against a fake home in a throwaway folder. It never reads or writes
# your real iCloud Drive or ~/AI-Archive_Fleet: HOME points at the fake one, and the KEEP_SCRATCH_* overrides are unset.
#
#   sh scripts/keep-scratch.selftest.sh
#   KEEP_SCRATCH_SELFTEST_DIR=/some/scratch sh scripts/keep-scratch.selftest.sh   # where the fake home goes
#
# Exit codes: 0 every case as expected · 1 a case failed.
set -u
here="$(cd "$(dirname "$0")" && pwd -P)"
K="$here/keep-scratch.sh"
base="${KEEP_SCRATCH_SELFTEST_DIR:-${TMPDIR:-/tmp}}"
R="$(mktemp -d "$base/ks-selftest.XXXXXX")" || exit 1
R="$(cd "$R" && pwd -P)"
H="$R/home"; mkdir -p "$H"
export HOME="$H"
unset KEEP_SCRATCH_SYNCED KEEP_SCRATCH_LOCAL KEEP_SCRATCH_LIMIT_KB
SYN="$H/Library/Mobile Documents/com~apple~CloudDocs/__Scratchpad-4-Claude__"
LOC="$H/AI-Archive_Fleet/claude-scratch"
pass=0; fail=0
ok() { if [ "$1" = "$2" ]; then pass=$((pass + 1)); else fail=$((fail + 1)); echo "FAIL $3: got [$1] want [$2]"; fi; }
run() { sh "$K" "$@" > "$R/out" 2>&1; echo $?; }
SENT="KSSENTINEL""41z"              # assembled, so this file does not hold the text it hunts for
opened() { find "$1/open" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' '; }

# fixtures: plain drafts; a folder with a secret-looking name; one whose text holds a key's shape; a single file
mkdir -p "$R/plain" "$R/named" "$R/shaped"
printf 'draft\n' > "$R/plain/a.md"
printf 'X=%s\n' "$SENT" > "$R/named/.env"
printf '%s %s\n%s\n' '-----BEGIN' 'RSA PRIVATE KEY-----' "$SENT" > "$R/shaped/notes.txt"
printf 'one\n' > "$R/single.txt"

# 1. the roads
ok "$(run save "$R/plain" repo topic waiting on review)" 0 "save plain drafts"
ok "$(opened "$SYN")" 1 "plain drafts take the synced road"
ok "$(grep -c "^$SYN/open/" "$R/out")" 1 "and the new folder is printed"
P1="$(cat "$R/out")"
ok "$(test -f "$P1/plain/a.md" && echo yes || echo no)" yes "the folder is copied in whole"
ok "$(test -f "$R/plain/a.md" && echo yes || echo no)" yes "and the source is left where it was"
ok "$(grep -c '^- Waiting on: waiting on review$' "$P1/NOTE.md")" 1 "NOTE.md says what it waits on"
ok "$(run save "$R/named" repo env)" 0 "save a folder with a .env in it"
ok "$(opened "$LOC")" 1 "it takes the local road, in ~/AI-Archive_Fleet/claude-scratch"
P2="$(cat "$R/out")"
ok "$(grep -c 'looks like it holds secrets' "$P2/NOTE.md")" 1 "NOTE.md says why"
ok "$(grep -c '\.env$' "$P2/NOTE.md")" 1 "and names the file"
ok "$(grep -c "$SENT" "$P2/NOTE.md")" 0 "never its content"
ok "$(run save "$R/shaped" repo shaped)" 0 "save a folder whose text holds a key's shape"
ok "$(opened "$LOC")" 2 "it takes the local road too"
ok "$(grep -c "$SENT" "$(cat "$R/out")/NOTE.md")" 0 "and NOTE.md does not quote the text"
ok "$(run save "$R/single.txt" repo single --local)" 0 "save one file with --local"
ok "$(opened "$LOC")" 3 "--local takes the local road whatever it holds"
ok "$(test -d "$H/Archive" && echo made || echo absent)" absent "the old ~/Archive name is not made"

# 2. never overwrite: the same save twice makes a second folder
ok "$(run save "$R/plain" repo topic)" 0 "the same save again"
ok "$(opened "$SYN")" 2 "makes a second folder, not an overwrite"

# 3. status and done
ok "$(run status)" 0 "status"
ok "$(grep -c '2 synced, 3 local' "$R/out")" 1 "counts both roads"
ok "$(run done "$P1")" 0 "done moves a folder"
ok "$(test -d "$P1" && echo there || echo moved)" moved "out of open/"
ok "$(find "$SYN/done/$(date +%Y)/$(date +%m)" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')" 1 "into done/YYYY/MM/"
ok "$(run done "$R/plain")" 1 "done refuses a folder outside open/"
ok "$(test -f "$R/plain/a.md" && echo yes || echo no)" yes "and leaves it alone"

# 4. the overrides still win
mkdir -p "$R/elsewhere"
ok "$(KEEP_SCRATCH_LOCAL="$R/elsewhere" run save "$R/named" repo override)" 0 "KEEP_SCRATCH_LOCAL moves the local road"
ok "$(opened "$R/elsewhere")" 1 "the save lands there"
ok "$(run status --hook)" 0 "status --hook with open folders"
ok "$(grep -c 'Scratch kept' "$R/out")" 1 "speaks when something is open"

# 5. usage
ok "$(run)" 2 "no command prints usage and exits 2"
ok "$(run save "$R/missing" repo t)" 1 "a missing source is refused"

echo "keep-scratch selftest: $pass passed, $fail failed  (scratch: $R)"
[ "$fail" -eq 0 ]
