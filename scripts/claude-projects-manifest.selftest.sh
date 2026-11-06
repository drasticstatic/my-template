#!/bin/sh
# claude-projects-manifest.selftest.sh: proves claude-projects-manifest.py, the claude-session-start.sh hook and the zsh
# guard in its header, in a throwaway folder with a fake home. It never reads your real ~/.claude.
#
#   sh scripts/claude-projects-manifest.selftest.sh
#
# Exit codes: 0 every case as expected · 1 a case failed.
set -u
here="$(cd "$(dirname "$0")" && pwd)"
M="python3 -I $here/claude-projects-manifest.py"
HOOK="$here/claude-session-start.sh"
R="$(mktemp -d "${TMPDIR:-/tmp}/cpm-selftest.XXXXXX")" || exit 1
R="$(cd "$R" && pwd -P)"
H="$R/home"; P="$H/.claude/projects"; mkdir -p "$P"
export HOME="$H"; unset CLAUDE_CONFIG_DIR
enc() { printf '%s' "$1" | sed 's/[^A-Za-z0-9]/-/g'; }
pass=0; fail=0; ok() { if [ "$1" = "$2" ]; then pass=$((pass+1)); else fail=$((fail+1)); echo "FAIL $3: got [$1] want [$2]"; fi; }
SENT="CPMSENTINEL""41c"      # assembled, so this file does not hold the text it hunts for
proj() { d="$P/$(enc "$1")"; mkdir -p "$d/memory"; [ -n "$2" ] && printf '{"cwd":"%s","timestamp":"2026-10-0%sT10:00:00Z","message":"%s"}\n' "$2" "${3:-1}" "$SENT" > "$d/s$3.jsonl"; }
row() { grep -F "| \`$(enc "$1")\` |" "$P/MANIFEST-LOG.md" | head -1; }

# fixture: a live repo, a moved one, a gone one, a parent, an archived one, a private one
mkdir -p "$H/code/live1/.git" "$H/code/newname/.git" "$H/code/sealed-matter-x" "$H/someorg/repoA/.git" "$H/plain"
proj "$H/code/live1" "$H/code/live1" 1
proj "$H/code/newname" "$H/code/oldname" 2
proj "$H/code/gone" "" ""; echo note > "$P/$(enc "$H/code/gone")/memory/MEMORY.md"
proj "$H" "" ""; echo note > "$P/$(enc "$H")/memory/MEMORY.md"
mkdir -p "$P/_archived-pre-move-sessions/$(enc "$H/old")"; printf '{"cwd":"%s"}\n' "$H/old" > "$P/_archived-pre-move-sessions/$(enc "$H/old")/a.jsonl"
proj "$H/code/sealed-matter-x" "/elsewhere" 3
printf '# words whose project folders stay closed\nsealed-matter\n' > "$P/MANIFEST-PRIVATE.txt"
before="$(cat "$P"/*/*.jsonl | shasum)"

$M --projects "$P" --cleanup-days 30 >/dev/null; ok $? 0 "first run writes"
ok "$(row "$H/code/live1" | grep -c '\*\*live\*\*')" 1 "a repo whose sessions ran there is live"
ok "$(row "$H/code/newname" | grep -c '\*\*moved-here\*\*.*recorded cwd ~/code/oldname')" 1 "an older cwd reads moved-here"
ok "$(row "$H/code/gone" | grep -c '\*\*orphan\*\*')" 1 "a gone folder with memory is an orphan"
ok "$(row "$H" | grep -c '\*\*memory-only\*\*.*a parent folder')" 1 "home is memory-only and a parent folder"
ok "$(grep -c '\*\*archived\*\*' "$P/MANIFEST-LOG.md")" 1 "the archive is listed"
ok "$(row "$H/code/sealed-matter-x" | grep -c 'live.*private: transcripts not opened')" 1 "a private project is counted, not opened"
ok "$(grep -c "$SENT" "$P/MANIFEST-LOG.md")" 0 "no message content reaches the manifest"
ok "$(cat "$P"/*/*.jsonl | shasum)" "$before" "transcripts are untouched"

$M --projects "$P" --check >/dev/null; ok $? 1 "check fails on an orphan and an unlisted move"
ok "$($M --projects "$P" --check | grep -c '^not in Moves')" 1 "check names the unlisted move"
# a person writes the move into Moves; the orphan's memory is set aside by hand (here: copied away, then the copy is the test)
sed "s|^<!-- moves:end|- **test**: \`$(enc "$H/code/newname")\` came from oldname\\
&|" "$P/MANIFEST-LOG.md" > "$R/m.md" && cat "$R/m.md" > "$P/MANIFEST-LOG.md"
ok "$($M --projects "$P" --check | grep -c '^not in Moves')" 0 "a listed move passes"
ok "$($M --projects "$P" --check | grep -c '^orphan')" 1 "the orphan still fails"
$M --projects "$P" --cleanup-days 30 >/dev/null
ok "$(grep -c 'came from oldname' "$P/MANIFEST-LOG.md")" 1 "a rerun keeps the Moves section"
ok "$(grep -c 'generated:begin' "$P/MANIFEST-LOG.md")" 1 "a rerun replaces the table, not adds one"

touch -t 202001010000 "$P/$(enc "$H/code/live1")/s1.jsonl"
ok "$($M --projects "$P" --print --cleanup-days 5 | grep -c 'Ages out within a week')" 1 "an old session file is flagged before retention takes it"

sed 's/generated:end/gone/' "$P/MANIFEST-LOG.md" > "$R/b.md"; mkdir -p "$R/p2"; cp "$R/b.md" "$R/p2/MANIFEST-LOG.md"
$M --projects "$R/p2" >/dev/null; ok $? 2 "a manifest without its markers is refused, not rewritten"

# the hook: a log row every time, context only in a parent folder
out="$(printf '{"session_id":"s-parent","cwd":"%s","source":"startup"}' "$H/code" | sh "$HOOK")"; ok $? 0 "hook exits 0"
ok "$(printf '%s' "$out" | python3 -I -c 'import json,sys; o=json.load(sys.stdin)["hookSpecificOutput"]; print(o["hookEventName"], "parent folder" in o["additionalContext"], "live1" in o["additionalContext"])')" "SessionStart True True" "parent folder gets additionalContext naming its repos"
ok "$(printf '{"session_id":"s-repo","cwd":"%s","source":"resume"}' "$H/code/live1" | sh "$HOOK")" "" "inside a repo it says nothing"
ok "$(printf '{"session_id":"s-org","cwd":"%s","source":"startup"}' "$H/someorg" | sh "$HOOK" | grep -c repoA)" 1 "an organisation folder in ~ counts as a parent"
ok "$(printf '{"session_id":"s-plain","cwd":"%s","source":"startup"}' "$H/plain" | sh "$HOOK")" "" "a plain folder with no repos is not a parent"
ok "$(printf 'not json' | sh "$HOOK"; echo "rc=$?")" "rc=0" "bad input: no output, exit 0"
ok "$(sed -n 1p "$P/SESSIONS-LOG.tsv")" "$(printf 'date\tsession_id\tsource\tcwd')" "the log has its header"
ok "$(grep -c '^20' "$P/SESSIONS-LOG.tsv")" 4 "one row per start"
ok "$($M --projects "$P" --print | grep -c '4 starts logged; 2 of the latest started in a parent folder')" 1 "the manifest reads the log"

# the zsh guard from the hook's header
if command -v zsh >/dev/null 2>&1; then
  sed -n '/^# >>> claude-parent-guard/,/^# <<< claude-parent-guard/p' "$HOOK" | sed -e '1d' -e '$d' -e 's/^# //' > "$R/guard.zsh"
  mkdir -p "$R/bin"; printf '#!/bin/sh\necho "STARTED $*"\n' > "$R/bin/claude"; chmod +x "$R/bin/claude"
  z() { (cd "$1" && shift && PATH="$R/bin:$PATH" zsh -f -c ". '$R/guard.zsh'; claude $*" 2>&1); }
  ok "$(z "$H/code" | grep -c 'cd ~/code/live1 && claude')" 1 "guard lists the repos in a parent folder"
  ok "$(z "$H/code"; echo "rc=$?")" "$(z "$H/code" | cat; echo rc=1)" "guard refuses in a parent folder"
  ok "$(z "$H/code" --here --model x)" "STARTED --model x" "--here starts anyway, without passing --here on"
  ok "$(z "$H/code/live1" -c)" "STARTED -c" "inside a repo it starts as usual"
  ok "$(z "$H/code" --version)" "STARTED --version" "--version passes straight through"
  ok "$(z "$H/someorg" | grep -c 'cd ~/someorg/repoA && claude')" 1 "an organisation folder is guarded too"
else
  echo "skip: zsh not found, guard not tested"
fi
echo "claude-projects-manifest: $pass passed, $fail failed"; exit $fail
