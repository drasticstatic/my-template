#!/bin/sh
# set-merge-methods.selftest.sh: proves set-merge-methods.sh against a stub `gh` in a throwaway folder. Offline: no
# real GitHub call is made.
#
#   sh scripts/set-merge-methods.selftest.sh
#
# Exit codes: 0 every case as expected · 1 a case failed.
set -u
here="$(cd "$(dirname "$0")" && pwd)"
D="$(mktemp -d "${TMPDIR:-/tmp}/merge-selftest.XXXXXX")" || exit 1   # left for the system's temp cleanup
pass=0; fail=0
ok() { if [ "$1" = "$2" ]; then pass=$((pass+1)); else fail=$((fail+1)); echo "FAIL $3: got [$1] want [$2]"; fi; }

# The stub answers `repo list OWNER`, `api repos/O/R -q ...` and `api -X PATCH repos/O/R ...` from files in $D.
cat > "$D/gh" <<'EOF'
#!/bin/sh
D="$STUB_DIR"
key() { printf '%s' "$1" | tr '/' '_'; }
if [ "$1" = repo ] && [ "$2" = list ]; then cat "$D/list.$3" 2>/dev/null || exit 1; exit 0; fi
if [ "$1" = api ] && [ "$2" = -X ]; then r=${4#repos/}; echo "$r" >> "$D/patched"
  [ -f "$D/state.$(key "$r")" ] || exit 1; echo "true false false" > "$D/state.$(key "$r")"; cat "$D/state.$(key "$r")"; exit 0; fi
if [ "$1" = api ]; then r=${2#repos/}; cat "$D/state.$(key "$r")" 2>/dev/null || exit 1; exit 0; fi
exit 9
EOF
chmod +x "$D/gh"
export STUB_DIR="$D" GH="$D/gh" MERGE_EXCEPTIONS="$D/exceptions.txt"
S="sh $here/set-merge-methods.sh"
set_state() { printf '%s\n' "$2" > "$D/state.$(printf '%s' "$1" | tr '/' '_')"; }

printf 'clean/a\nclean/b\n' > "$D/list.clean"; set_state clean/a "true false false"; set_state clean/b "true false false"
printf 'messy/squash\nmessy/rebase\nmessy/nomerge\n' > "$D/list.messy"
set_state messy/squash "true true false"; set_state messy/rebase "true false true"; set_state messy/nomerge "false false false"
printf 'kept/old\n' > "$D/list.kept"; set_state kept/old "true true true"
printf 'gone/x\n' > "$D/list.gone"
printf '# comment\nkept/old   # predates us\n' > "$D/exceptions.txt"

$S >/dev/null 2>&1; ok "$?" 2 "no arguments is usage"
$S --audit >/dev/null 2>&1; ok "$?" 2 "--audit with no owner is usage"
$S --audit clean >/dev/null; ok "$?" 0 "clean owner audits clean"
out=$($S --audit messy); ok "$?" 1 "drifted owner exits 1"
ok "$(printf '%s\n' "$out" | grep -c 'DRIFT$')" 3 "squash, rebase and merge-off each flagged"
out=$($S --audit kept); ok "$?" 0 "an exception does not fail the audit"
ok "$(printf '%s\n' "$out" | grep -c 'exception$')" 1 "the exception is reported as such"
$S --audit gone >/dev/null; ok "$?" 1 "an unreadable repository exits 1"
$S --audit clean/a >/dev/null 2>&1; ok "$?" 2 "--audit refuses owner/repo"
$S --fix messy >/dev/null 2>&1; ok "$?" 2 "--fix refuses a bare owner"
$S --fix messy/squash messy/rebase >/dev/null; ok "$?" 0 "--fix succeeds"
$S --audit messy >/dev/null; ok "$?" 1 "messy/nomerge still drifted (not passed to --fix)"
$S --fix messy/nomerge >/dev/null; $S --audit messy >/dev/null; ok "$?" 0 "after fixing all three, the owner is clean"
out=$($S --fix kept/old); ok "$?" 0 "fixing an exception is a skip, not a failure"
ok "$(grep -c 'kept/old' "$D/patched")" 0 "the exception was never patched"
ok "$(cat "$D/state.kept_old")" "true true true" "the exception's settings are untouched"
$S --fix gone/x >/dev/null; ok "$?" 1 "a failed patch exits 1"
$S --list clean >/dev/null 2>&1; ok "$?" 2 "an unknown mode is usage"

echo "set-merge-methods selftest: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
