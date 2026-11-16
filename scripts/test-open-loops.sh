#!/bin/sh
# test-open-loops.sh: proves open-loops.py on made-up repositories in a throwaway folder. No network, no real repo.
# (The personal vault keeps a wrapper that calls this script; this is the canonical copy.)
#
#   sh scripts/test-open-loops.sh
#
# Exit codes: 0 every case as expected · 1 a case failed.
set -u
here="$(cd "$(dirname "$0")" && pwd)"
PY=python3; [ "$(command -v python3)" = /usr/bin/python3 ] && PY=/opt/homebrew/bin/python3
R="$(mktemp -d "${TMPDIR:-/tmp}/open-loops-test.XXXXXX")" || exit 1
R="$(cd "$R" && pwd -P)"
pass=0; fail=0
ok() { if [ "$1" = "$2" ]; then pass=$((pass+1)); else fail=$((fail+1)); echo "FAIL $3: got [$1] want [$2]"; fi; }

mkdir -p "$R/desk" "$R/tax-helper" "$R/empty" "$R/extra"
printf -- "- [ ] **From the extra folder**\n" > "$R/extra/PENDING-TASKS.md"
cat > "$R/desk/PENDING-TASKS.md" <<'EOF'
# Tasks
- [ ] **Buy the drive** · Nov 12, 2026
  It waits on a yes. **Owner: Christopher**.
- [ ] **Write the SOP** (2026-11-10) **Alfred (prep)**.
- [ ] plain item with no owner and a | pipe
- [x] **Done already** · Nov 1, 2026 **Owner: Christopher**
EOF
cat > "$R/tax-helper/PENDING-TASKS.md" <<'EOF'
- [ ] **SECRET-TITLE-THAT-MUST-NOT-APPEAR** **Owner: Christopher**
- [ ] **another**
EOF
printf '[{"path":"%s"},{"path":"%s"},{"path":"%s"}]' "$R/desk" "$R/tax-helper" "$R/empty" > "$R/cm.json"
OUT="$R/OPEN-LOOPS.md"
S="$PY -I $here/open-loops.py --clone-map $R/cm.json --out $OUT --extra $R/extra"

msg=$($S 2>&1); ok "$?" 0 "runs"
ok "$(grep -c 'SECRET-TITLE' "$OUT")" 1 "every title is shown by default"
ok "$(grep -c "extra\` | 1 | 0 |" "$OUT")" 1 "an --extra folder is read"
ok "$(grep -c '| 2026-11-12 | Buy the drive | Christopher |' "$OUT")" 1 "owner and date read from the item's lines"
ok "$(grep -c '| 2026-11-10 | Write the SOP | Alfred |' "$OUT")" 1 "the (prep) form"
ok "$(grep -c 'Done already' "$OUT")" 0 "closed items left out"
ok "$(grep -c 'plain item with no owner and a \\\\| pipe' "$OUT")" 0 "no-owner items only in the counts"
ok "$(grep -c "desk\` | 3 | 2 | 2026-11-12 Buy the drive |" "$OUT")" 1 "per-repository row"
ok "$(printf '%s' "$msg" | grep -c 'wrote')" 1 "first run writes"
msg2=$($S 2>&1)
ok "$(printf '%s' "$msg2" | grep -c 'unchanged')" 1 "second run changes nothing"
C="$R/COUNTS.md"
$PY -I "$here/open-loops.py" --clone-map "$R/cm.json" --out "$C" --counts-only 'tax' > /dev/null 2>&1; ok "$?" 0 "--counts-only runs"
ok "$(grep -c 'SECRET-TITLE' "$C")" 0 "--counts-only: matching titles never written"
ok "$(grep -c "tax-helper\` | 2 |" "$C")" 1 "--counts-only: the count is shown"
$PY -I "$here/open-loops.py" --clone-map "$R/cm.json" > /dev/null 2>&1; ok "$?" 2 "--out is required"

echo "open-loops: $pass passed, $fail failed"
[ "$fail" = 0 ]
