#!/bin/sh
# test-gitmoji.sh — parser tests for .githooks/gitmoji-check.sh, plus a check
# that wiring it into .githooks/commit-msg changed nothing about what that hook
# accepts or rejects.
#
#     sh scripts/test-gitmoji.sh
#
# Each case writes a commit message to a temp file, runs the check, and asserts
# (a) the exit status is 0 (it is warn-only) and (b) a hint was or was not
# printed, and when one was, that it contains an expected phrase.
# Exits non-zero if any case fails.

cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)" || exit 1
CHECK=.githooks/gitmoji-check.sh
HOOK=.githooks/commit-msg
TMP=$(mktemp -d "${TMPDIR:-/tmp}/gitmoji-test.XXXXXX") || exit 1
trap 'rm -f "$TMP"/msg "$TMP"/err; rmdir "$TMP" 2>/dev/null' EXIT

TRAILERS='
Body line.

Co-Authored-By: Alfred · ClaudeCodeCLI · Anthropic [Opus-5.5]
Claude-Session: https://claude.ai/chat/00000000-0000-0000-0000-000000000000'

PASS=0; FAIL=0

# case NAME EXPECT(silent|hint) PHRASE SUBJECT
case_() {
  name=$1; expect=$2; phrase=$3; subject=$4
  printf '%s\n%s\n' "$subject" "$TRAILERS" > "$TMP/msg"
  sh "$CHECK" "$TMP/msg" 2> "$TMP/err"; rc=$?
  out=$(cat "$TMP/err")
  lines=$(grep -c . "$TMP/err")
  ok=1
  [ "$rc" -eq 0 ] || ok=0
  if [ "$expect" = silent ]; then
    [ -z "$out" ] || ok=0
  else
    [ "$lines" -eq 1 ] || ok=0
    printf '%s' "$out" | grep -qF -- "$phrase" || ok=0
  fi
  if [ $ok = 1 ]; then
    PASS=$((PASS+1)); printf '  ok    %-34s %s\n' "$name" "${out:-(silent)}"
  else
    FAIL=$((FAIL+1)); printf '  FAIL  %-34s rc=%s expected %s [%s], got: %s\n' "$name" "$rc" "$expect" "$phrase" "${out:-(silent)}"
  fi
}

echo "gitmoji-check.sh"
case_ "valid feat with scope"        silent "" ':sparkles: feat(sop): the SOP rails'
case_ "valid fix without scope"      silent "" ':bug: fix: events keep their time zone'
case_ "valid test (long alias)"      silent "" ':white_check_mark: test(hooks): gitmoji parser cases'
case_ "valid breaking change"        silent "" ':sparkles: feat(api)!: new route shape'
case_ "valid priority after type"    silent "" ':bug: fix(calendar): [P2] events keep their time zone'
case_ "valid move"                   silent "" ':truck: move(assets): banners under assets/banners/'
case_ "missing gitmoji"              hint   "has no gitmoji"      'feat(sop): the SOP rails'
case_ "plain sentence"               hint   "has no gitmoji"      'README: banner and badges'
case_ "unknown alias"                hint   "not one of the twelve" ':tada: feat: first release'
case_ "unknown glyph"                hint   "not one of the twelve" '🎉 feat: first release'
case_ "priority glyph as type"       hint   "ledger priority glyph" ':fire: fix: hot path'
case_ "wrong type for gitmoji"       hint   "goes with 'fix'"      ':bug: feat: new thing'
case_ "gitmoji but no type"          hint   "write the type"       ':memo: the SOP index'
case_ "priority marker first"        hint   "goes after the type"  '[P1] fix(nav): menu opens'
case_ "merge (exempt)"               silent "" "Merge pull request #12 from drasticstatic/preview"
case_ "merge branch (exempt)"        silent "" "Merge branch 'preview'"
case_ "git revert (exempt)"          silent "" 'Revert ":sparkles: feat(sop): the SOP rails"'
case_ "fixup (exempt)"               silent "" 'fixup! :sparkles: feat(sop): the SOP rails'
case_ "squash (exempt)"              silent "" 'squash! :bug: fix: typo'
case_ "amend (exempt)"               silent "" 'amend! :bug: fix: typo'
case_ "glyph form accepted"          hint   "glyph form accepted"  '✨ feat(sop): the SOP rails'
case_ "glyph with variation sel."    hint   "':recycle:'"          '♻️ refactor(ledger): one parser'
case_ "glyph, wrong type"            hint   "goes with 'docs'"     '📝 fix: typo'
case_ "hand-written revert"          silent "" ':rewind: revert(edge): undo the census change'

# A leading comment block (git's template) is skipped.
printf '# Please enter the commit message\n\n:memo: docs: comment lines skipped\n%s\n' "$TRAILERS" > "$TMP/msg"
if [ -z "$(sh "$CHECK" "$TMP/msg" 2>&1)" ]; then PASS=$((PASS+1)); echo "  ok    comment lines skipped              (silent)"
else FAIL=$((FAIL+1)); echo "  FAIL  comment lines skipped"; fi

echo ""
echo "commit-msg (attribution behaviour unchanged, hint added on pass only)"
hook_() {
  name=$1; want_rc=$2; want=$3; msg=$4
  printf '%s\n' "$msg" > "$TMP/msg"
  sh "$HOOK" "$TMP/msg" > /dev/null 2> "$TMP/err"; rc=$?
  ok=1
  [ "$rc" -eq "$want_rc" ] || ok=0
  case "$want" in
    "") ;;
    NOHINT) ! grep -q 'gitmoji:' "$TMP/err" || ok=0 ;;
    *) grep -qF -- "$want" "$TMP/err" || ok=0 ;;
  esac
  if [ $ok = 1 ]; then
    PASS=$((PASS+1)); printf '  ok    %-34s rc=%s\n' "$name" "$rc"
  else
    FAIL=$((FAIL+1)); printf '  FAIL  %-34s rc=%s (wanted %s, %s)\n' "$name" "$rc" "$want_rc" "$want"
  fi
}
hook_ "good footer, good subject"   0 NOHINT        ":sparkles: feat: x$TRAILERS"
hook_ "good footer, no gitmoji"     0 "gitmoji:"    "feat: x$TRAILERS"
hook_ "no footer still rejected"    1 "commit rejected" ":sparkles: feat: x"
hook_ "bad footer, no gitmoji hint" 1 "commit rejected" "feat: x

Co-Authored-By: Alfred - ClaudeCodeCLI - Anthropic"
hook_ "merge still exempt"          0 NOHINT        "Merge branch 'preview'"
hook_ "Littlebird line, hint runs"  0 "gitmoji:"    "update notes

Co-Authored-By: LittlebirdAI · Desktop Oracle Observer & Fleet Shepherd"

# On a rejection the gitmoji hint must not appear (it runs only after a pass).
printf ':sparkles: feat: x\n' > "$TMP/msg"
if sh "$HOOK" "$TMP/msg" 2>&1 | grep -q 'gitmoji:'; then
  FAIL=$((FAIL+1)); echo "  FAIL  no hint on a rejected commit"
else
  PASS=$((PASS+1)); echo "  ok    no hint on a rejected commit"
fi

echo ""
echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
