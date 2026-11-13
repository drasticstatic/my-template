#!/bin/sh
# runbook-tray.selftest.sh: proves the runbook tray's helper, its build, and (when asked) the applet itself.
#
#   sh runbook-tray.selftest.sh                 the helper, the stamp, and on macOS a compile and a build into a temporary folder
#   sh runbook-tray.selftest.sh --with-applet   also start the built applet in its self-test mode: an item appears in the
#                                               menu bar for about a second. It starts no helper and opens nothing.
#   RUNBOOK_TRAY_KEEP=DIR sh ... --with-applet  also copy the applet's report and its pictures of each menu into DIR
#
# Everything happens in a temporary folder with a made-up home; the status command, the entries and the opener are
# small scripts written there. It never reads your config, your jobs or ~/Applications. The folder is removed afterwards.
#
# Exit codes: 0 every case as expected · 1 a case failed.
set -u
here="$(cd "$(dirname "$0")" && pwd -P)"
tool="$here/runbook-tray.py"
[ -f "$tool" ] || { echo "selftest: $tool not found" >&2; exit 1; }
WITH_APPLET=0
[ "${1:-}" = "--with-applet" ] && WITH_APPLET=1

PY="$(command -v python3 || true)"
if [ "$(uname)" = Darwin ] && { [ -z "$PY" ] || [ "$PY" = /usr/bin/python3 ]; }; then
  PY=""
  for p in /opt/homebrew/bin/python3 /usr/local/bin/python3; do [ -x "$p" ] && PY="$p" && break; done
fi
[ -n "$PY" ] || { echo "selftest: no python3 found" >&2; exit 1; }

work="$(mktemp -d "${TMPDIR:-/tmp}/runbook-tray-selftest.XXXXXX")" || exit 1
work="$(cd "$work" && pwd -P)"
trap '"$PY" -I -c "import shutil,sys; shutil.rmtree(sys.argv[1], ignore_errors=True)" "$work"' EXIT INT TERM
export HOME="$work/home"
mkdir -p "$HOME/bin" "$work/cfg" "$work/state" "$HOME/pages"
chmod 700 "$work/cfg"
export PLANTED_IN_THE_CALLER="tray-selftest-token-5417"

fails=0; passes=0
ok()    { passes=$((passes+1)); echo "ok    $1"; }
bad()   { fails=$((fails+1)); echo "FAIL  $1"; [ -n "${2:-}" ] && printf '%s\n' "$2" | sed 's/^/      /'; }
check() { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1" "expected [$3]
got      [$2]"; fi; }
has()   { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1" "expected to find [$3]
in       [$2]" ;; esac; }
hasnt() { case "$2" in *"$3"*) bad "$1" "did not expect [$3]
in       [$2]" ;; *) ok "$1" ;; esac; }

# ---- the made-up status command, entry and opener ----
cat > "$HOME/bin/status.sh" <<'EOF'
#!/bin/sh
d="$(dirname "$0")"
[ -f "$d/status.sleep" ] && sleep "$(cat "$d/status.sleep")"
cat "$d/status.out"
[ -f "$d/status.err" ] && cat "$d/status.err" >&2
exit "$(cat "$d/status.code" 2>/dev/null || echo 0)"
EOF
cat > "$HOME/bin/job.sh" <<'EOF'
#!/bin/sh
d="$(dirname "$0")"
echo run >> "$d/job.runs"
echo "# first line of the job"
echo "PATH=$PATH"
echo "planted=${PLANTED_IN_THE_CALLER:-none}"
echo "arg=${1:-}"
[ -f "$d/job.sleep" ] && sleep "$(cat "$d/job.sleep")"
echo "last line of the job"
exit "$(cat "$d/job.code" 2>/dev/null || echo 0)"
EOF
cat > "$HOME/bin/opener.sh" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >> "$(dirname "$0")/opened.txt"
EOF
chmod 755 "$HOME/bin/status.sh" "$HOME/bin/job.sh" "$HOME/bin/opener.sh"
echo "the runbook" > "$HOME/pages/RUNBOOK.md"

good_status='{"when": "2026-01-31 08:30:00", "result": "ignored", "ok": true, "rows": [
 {"name": "nightly-backup", "state": "good", "detail": "waiting for its time", "group": "Scheduled jobs"},
 {"name": "watcher", "state": "good", "detail": "running, pid 41", "group": "Scheduled jobs"},
 {"name": "disk", "state": "good", "detail": "35% used", "group": "Checks"}]}'
printf '%s\n' "$good_status" > "$HOME/bin/status.out"

# mkcfg FILE JSON: write a config, with WORK and HOMEDIR filled in, readable and writable by the owner only
mkcfg() { printf '%s\n' "$2" | sed "s|HOMEDIR|$HOME|g" > "$1"; chmod 600 "$1"; }
cfg="$work/cfg/tray.json"
base_cfg='{"name": "Runbook", "path": "/usr/bin:/bin",
 "status": {"command": ["~/bin/status.sh"], "timeout_seconds": 5},
 "open_with": ["HOMEDIR/bin/opener.sh"],
 "entries": [
  {"id": "job", "title": "Run the job", "command": ["HOMEDIR/bin/job.sh", "$(touch HOMEDIR/pwned); touch HOMEDIR/pwned"], "timeout_seconds": 20},
  {"id": "first", "title": "Run the job, first line", "command": ["~/bin/job.sh"], "summary": "first-line", "ok_exit_codes": [0, 1]},
  {"separator": true},
  {"id": "runbook", "title": "Open the runbook", "open": "~/pages/RUNBOOK.md"},
  {"id": "today", "title": "Open today", "open": "HOMEDIR/pages/{date}.md"},
  {"id": "site", "title": "Open the site", "open": "https://example.org/runbook"}
 ]}'
mkcfg "$cfg" "$base_cfg"

run() { "$PY" -I "$tool" "$@"; }
# q EXPRESSION: evaluate against the menu the helper wrote (m), the status (s) and a helper for entries
q() { "$PY" -I -c '
import json, sys
m = json.load(open(sys.argv[1] + "/menu.json"))
items = m["items"]
def item(title):
    return next(i for i in items if i.get("title") == title)
def act(ident):
    return next(i for i in items if i.get("id") == ident)
print(eval(sys.argv[2]))' "$work/state" "$1" 2>&1; }
rec() { "$PY" -I -c 'import json,sys; r=json.load(open(sys.argv[1])); print(eval(sys.argv[2]))' "$work/state/actions/$1.json" "$2" 2>&1; }

# ---- doctor ----
out="$(run doctor --config "$cfg" 2>&1)"; check "doctor: a good config passes" "$?" 0
has "doctor: says the config is usable" "$out" "the config is usable"
has "doctor: shows what the status command is" "$out" "$HOME/bin/status.sh"
has "doctor: a dated page is named as one" "$out" "a dated page"
out="$(run doctor --config "$work/cfg/none.json" 2>&1)"; check "doctor: no config is exit 2" "$?" 2
chmod 620 "$cfg"; out="$(run doctor --config "$cfg" 2>&1)"; check "doctor: a config others can write is refused" "$?" 2
has "doctor: and says how to fix it" "$out" "chmod go-w"
chmod 600 "$cfg"; chmod 770 "$work/cfg"; out="$(run doctor --config "$cfg" 2>&1)"
check "doctor: a config in a folder others can write is refused" "$?" 2
chmod 700 "$work/cfg"
badcfg="$work/cfg/bad.json"
tryc() { mkcfg "$badcfg" "$2"; out="$(run doctor --config "$badcfg" 2>&1)"; check "doctor: $1 is exit 2" "$?" 2; has "doctor: $1, in words" "$out" "$3"; }
tryc "a command that is not a full path" '{"status": {"command": ["status.sh"]}}' "full path"
tryc "a command written as one string" '{"status": {"command": "HOMEDIR/bin/status.sh --x"}}' "list of words"
tryc "an entry with both command and open" '{"status": {"command": ["HOMEDIR/bin/status.sh"]}, "entries": [{"id": "a", "title": "A", "command": ["/bin/ls"], "open": "/tmp"}]}' "exactly one"
tryc "an id used twice" '{"status": {"command": ["HOMEDIR/bin/status.sh"]}, "entries": [{"id": "a", "title": "A", "open": "/tmp"}, {"id": "a", "title": "B", "open": "/tmp"}]}' "used twice"
tryc "an id with a space" '{"status": {"command": ["HOMEDIR/bin/status.sh"]}, "entries": [{"id": "Full Check", "title": "A", "open": "/tmp"}]}' "lower-case"
tryc "a name the tray does not know" '{"status": {"command": ["HOMEDIR/bin/status.sh"]}, "colour": "red"}' "does not know"
tryc "a fold that is not a list of names" '{"status": {"command": ["HOMEDIR/bin/status.sh"], "fold": "Side list"}}' "list of group names"
tryc "no status command" '{"entries": []}' "needs a status command"
tryc "a status command whose script is not there" '{"status": {"command": ["/bin/sh", "HOMEDIR/bin/gone.sh"]}}' "its script is NOT FOUND"
tryc "a status command that is not there" '{"status": {"command": ["HOMEDIR/bin/gone.sh"]}}' "cannot be run"
printf 'not json\n' > "$badcfg"; chmod 600 "$badcfg"
out="$(run doctor --config "$badcfg" 2>&1)"; check "doctor: a config that is not JSON is exit 2" "$?" 2

# ---- render ----
out="$(run render --config "$cfg" --state "$work/state" --print 2>&1)"; check "render: all good is exit 0" "$?" 0
check "render: the bar has no count when all is good" "$(q 'repr(m["bar"]["text"])')" "''"
check "render: and is drawn in the menu bar's own colour" "$(q 'm["bar"]["tint"]')" "none"
check "render: the first line says all good" "$(q 'items[0]["title"] + "|" + items[0]["state"] + "|" + items[0]["symbol"]')" "All good|good|checkmark.circle.fill"
check "render: the status command's own result line is not trusted" "$(q '"ignored" in json.dumps(m)')" "False"
check "render: one header per group, in order" "$(q '[i["title"] for i in items if i["kind"] == "header"]')" "['Scheduled jobs', 'Checks']"
check "render: a row carries its detail" "$(q 'item("watcher")["subtitle"]')" "running, pid 41"
check "render: the entries follow, in order" "$(q '[i["id"] for i in items if i["kind"] == "action"]')" "['job', 'first', 'runbook', 'today', 'site']"
check "render: an entry never run has no note and can be chosen" "$(q 'repr(act("job")["subtitle"]) + str(act("job")["enabled"])')" "''True"
check "render: a command and a page each get their own picture" "$(q 'act("job")["symbol"] + " " + act("runbook")["symbol"]')" "play.circle arrow.up.right.square"
has "render: --print shows the menu as text" "$out" "✓ All good"
has "render: --print shows a header" "$out" "SCHEDULED JOBS"
check "render: status.json is written" "$([ -f "$work/state/status.json" ] && echo yes)" "yes"
check "render: no half-written file is left" "$(ls "$work/state" | grep -c tmp)" "0"

printf '%s\n' '{"rows": [
 {"name": "a", "state": "good", "detail": "fine"},
 {"name": "b", "state": "look", "detail": "slow"},
 {"name": "c", "state": "bad", "detail": "stopped"},
 {"name": "d", "state": "off", "detail": "not set up"},
 {"name": "e", "state": "purple", "detail": "odd"},
 {"state": "bad", "detail": "a row with no name"},
 {"name": "f", "state": "good", "detail": "one\ntwo\tthree\u0007four"},
 {"name": "g", "state": "good", "detail": "'"$("$PY" -I -c 'print("x" * 400)')"'"}]}' > "$HOME/bin/status.out"
run render --config "$cfg" --state "$work/state" >/dev/null 2>&1; check "render: something needs a look is exit 1" "$?" 1
check "render: the count is bad plus look" "$(q 'm["bar"]["text"]')" "3"
check "render: red when anything is bad" "$(q 'm["bar"]["tint"]')" "red"
check "render: the first line names what needs a look" "$(q 'items[0]["title"]')" "3 need a look: b, c, e"
check "render: an off row is shown in grey and not counted" "$(q 'item("d")["tint"] + "|" + item("d")["symbol"]')" "grey|minus.circle"
has "render: a state the tray does not know becomes a look" "$(q 'item("e")["state"] + " " + item("e")["subtitle"]')" "look state 'purple' is not one the tray knows"
check "render: a row with no name is dropped" "$(q 'len([i for i in items if i["kind"] == "info"])')" "8"
check "render: a detail is made one printable line" "$(q 'item("f")["subtitle"]')" "one two three four"
check "render: a long detail is cut" "$(q 'str(len(item("g")["subtitle"])) + item("g")["subtitle"][-1]')" "300…"
check "render: rows with no group get a rule, not a header" "$(q 'items[1]["kind"] + str(sum(1 for i in items if i["kind"] == "header"))')" "separator0"
foldcfg="$work/cfg/fold.json"
mkcfg "$foldcfg" '{"name": "Runbook", "path": "/usr/bin:/bin", "status": {"command": ["~/bin/status.sh"], "timeout_seconds": 5, "fold": ["Side list", "Never seen"]}}'
side_status='{"rows": [
 {"name": "a", "state": "good", "detail": "fine", "group": "Jobs"},
 {"name": "s1", "state": "good", "detail": "ready", "group": "Side list", "counted": false},
 {"name": "s2", "state": "off", "detail": "not started", "group": "Side list", "counted": false},
 {"name": "s3", "state": "look", "detail": "its file is gone", "group": "Side list", "counted": false},
 {"name": "s4", "state": "unknown", "detail": "cannot be told from here", "group": "Side list", "counted": false},
 {"name": "b", "state": "good", "detail": "fine", "group": "Jobs"}]}'
printf '%s\n' "$side_status" > "$HOME/bin/status.out"
out="$(run render --config "$foldcfg" --state "$work/state" --print 2>&1)"; check "fold: rows that are not counted leave the check good" "$?" 0
check "fold: and the menu bar has no count and its own colour" "$(q 'repr(m["bar"]["text"]) + m["bar"]["tint"]')" "''none"
check "fold: the first line still says all good" "$(q 'items[0]["title"]')" "All good"
check "fold: the group is one row after a rule, and its rows are not in the main menu" "$(q '[i["kind"] for i in items]')" "['info', 'header', 'info', 'info', 'separator', 'group']"
check "fold: the row counts each state" "$(q 'item("Side list")["subtitle"]')" "1 good · 1 off · 1 to look at · 1 not checked"
check "fold: and carries the worst state as its mark" "$(q 'item("Side list")["state"] + "|" + item("Side list")["symbol"] + "|" + item("Side list")["tint"]')" "look|exclamationmark.triangle.fill|amber"
check "fold: its rows sit under it, in order, each with its own mark" "$(q '[(i["title"], i["mark"]) for i in item("Side list")["items"]]')" "[('s1', '✓'), ('s2', '–'), ('s3', '!'), ('s4', '?')]"
check "fold: a row the check cannot judge is a grey question mark, and is no fault" "$(q 'item("Side list")["items"][3]["symbol"] + "|" + item("Side list")["items"][3]["tint"] + "|" + item("Side list")["items"][3]["subtitle"]')" "questionmark.circle|grey|cannot be told from here"
check "fold: a group the config names and the check does not print adds nothing" "$(q 'sum(1 for i in items if i["kind"] == "group")')" "1"
has "fold: --print shows the group with its mark and its count" "$out" "▾ ! Side list  ·  1 good · 1 off · 1 to look at · 1 not checked"
has "fold: --print shows its rows under it" "$out" "    – s2  ·  not started"
printf '%s\n' '{"rows": [{"name": "s1", "state": "bad", "detail": "down", "group": "Side list"}, {"name": "s2", "state": "look", "detail": "slow", "group": "Side list", "counted": false}]}' > "$HOME/bin/status.out"
run render --config "$foldcfg" --state "$work/state" >/dev/null 2>&1; check "fold: a folded row is counted unless it says otherwise" "$?" 1
check "fold: the count leaves out the row that is not counted" "$(q 'm["bar"]["text"] + m["bar"]["tint"] + "|" + items[0]["title"]')" "1red|1 needs a look: s1"
check "fold: the group's mark is its worst row, counted or not" "$(q 'item("Side list")["state"] + "|" + item("Side list")["subtitle"]')" "bad|1 to look at · 1 failing"
check "fold: with only folded rows the menu is the first line, a rule and the group" "$(q '[i["kind"] for i in items]')" "['info', 'separator', 'group']"
printf '%s\n' "$side_status" > "$HOME/bin/status.out"
run render --config "$cfg" --state "$work/state" >/dev/null 2>&1
check "fold: without fold in the config the same rows stay in the main menu, under their header" "$(q '[i["title"] for i in items if i["kind"] == "header"]')" "['Jobs', 'Side list', 'Jobs']"
check "fold: and a row that is not counted is still not counted there" "$(q 'repr(m["bar"]["text"])')" "''"

printf '%s\n' '{"rows": [{"name": "x", "state": "look", "detail": "slow"}]}' > "$HOME/bin/status.out"
run render --config "$cfg" --state "$work/state" >/dev/null 2>&1
check "render: amber when the worst is a look" "$(q 'm["bar"]["tint"] + m["bar"]["text"] + "|" + items[0]["title"]')" "amber1|1 needs a look: x"

before="$(cat "$work/state/status.json")"
printf 'Traceback: it broke\n' > "$HOME/bin/status.out"; echo 3 > "$HOME/bin/status.code"
run render --config "$cfg" --state "$work/state" >/dev/null 2>&1; check "render: a status that is not JSON is exit 1" "$?" 1
check "render: the bar shows a question mark" "$(q 'm["bar"]["text"] + m["bar"]["tint"]')" "?none"
has "render: the menu says the check did not run, and why" "$(q 'items[0]["title"] + ": " + items[0]["subtitle"]')" "The check did not run: the status command did not print JSON (exit 3)"
check "render: the last good status is left as it was" "$(cat "$work/state/status.json")" "$before"
check "render: the entries are still there" "$(q 'len([i for i in items if i["kind"] == "action"])')" "5"
echo 0 > "$HOME/bin/status.code"
printf '%s\n' '{"result": "no rows here"}' > "$HOME/bin/status.out"
run render --config "$cfg" --state "$work/state" >/dev/null 2>&1
has "render: JSON without rows is said so" "$(q 'items[0]["subtitle"]')" 'without a "rows" list'

printf '%s\n' "$good_status" > "$HOME/bin/status.out"; echo 30 > "$HOME/bin/status.sleep"
slowcfg="$work/cfg/slow.json"
mkcfg "$slowcfg" '{"status": {"command": ["HOMEDIR/bin/status.sh"], "timeout_seconds": 1}}'
t0="$(date +%s)"; run render --config "$slowcfg" --state "$work/state" >/dev/null 2>&1; t1="$(date +%s)"
has "render: a status command that hangs is stopped" "$(q 'items[0]["subtitle"]')" "stopped after 1 s"
check "render: and the helper comes back promptly" "$([ $((t1 - t0)) -le 10 ] && echo yes || echo "no: $((t1 - t0)) s")" "yes"
mv "$HOME/bin/status.sleep" "$HOME/bin/status.sleep.off"

mkcfg "$badcfg" '{"status": {"command": ["HOMEDIR/bin/gone.sh"]}}'
run render --config "$badcfg" --state "$work/state" >/dev/null 2>&1
has "render: a status command that is not there is said so" "$(q 'items[0]["subtitle"]')" "could not start"
mkcfg "$badcfg" '{"status": {"command": ["relative.sh"]}}'
run render --config "$badcfg" --state "$work/state" >/dev/null 2>&1; check "render: a config problem is exit 2" "$?" 2
has "render: and the menu says so instead of going quiet" "$(q 'items[0]["title"] + ": " + items[0]["subtitle"]')" "The tray's config has a problem: status.command: the first word must be a full path"
check "render: the state folder is the owner's alone" "$("$PY" -I -c 'import os,sys; print(oct(os.stat(sys.argv[1]).st_mode & 0o777))' "$work/state")" "0o700"

# ---- act: commands ----
out="$(run act job --config "$cfg" --state "$work/state" 2>&1)"; check "act: a command that ends well is exit 0" "$?" 0
check "act: its record says so" "$(rec job 'str(r["ok"]) + str(r["exit"]) + str(r["running"])')" "True0False"
check "act: the summary is the last line" "$(rec job 'r["summary"]')" "last line of the job"
log="$(cat "$work/state/actions/job.log")"
has "act: the output is kept in its log" "$log" "first line of the job"
has "act: the command is given the config's PATH, not the caller's" "$log" "PATH=/usr/bin:/bin"
has "act: nothing of the caller's environment is passed on" "$log" "planted=none"
hasnt "act: so a secret in the caller's environment cannot reach the log" "$log" "tray-selftest-token-5417"
has "act: a word of the command is passed as written" "$log" 'arg=$(touch'
check "act: and is never run by a shell" "$([ -e "$HOME/pwned" ] && echo ran || echo "not run")" "not run"
run render --config "$cfg" --state "$work/state" >/dev/null 2>&1
has "act: the menu then shows when it ran and how it ended" "$(q 'act("job")["subtitle"]')" " · last line of the job"

echo 1 > "$HOME/bin/job.code"
run act first --config "$cfg" --state "$work/state" >/dev/null 2>&1; check "act: an exit code the config calls fine is exit 0" "$?" 0
check "act: summary first-line drops the heading mark" "$(rec first 'r["summary"]')" "first line of the job"
check "act: ~ in a command is the home folder" "$(rec first 'r["ok"]')" "True"
echo 3 > "$HOME/bin/job.code"
run act job --config "$cfg" --state "$work/state" >/dev/null 2>&1; check "act: any other exit code is exit 1" "$?" 1
run render --config "$cfg" --state "$work/state" >/dev/null 2>&1
has "act: and the menu shows the exit code" "$(q 'act("job")["subtitle"]')" "exit 3"
echo 0 > "$HOME/bin/job.code"

: > "$HOME/bin/job.runs"; echo 3 > "$HOME/bin/job.sleep"
run act job --config "$cfg" --state "$work/state" >/dev/null 2>&1 &
bg=$!
n=0; while [ ! -s "$HOME/bin/job.runs" ] && [ $n -lt 50 ]; do n=$((n+1)); "$PY" -I -c 'import time; time.sleep(0.1)'; done
run render --config "$cfg" --state "$work/state" >/dev/null 2>&1
has "act: while it runs, the menu says since when" "$(q 'act("job")["subtitle"]')" "running since"
check "act: and the entry cannot be chosen again" "$(q 'str(act("job")["enabled"]) + " " + act("job")["symbol"]')" "False hourglass"
out="$(run act job --config "$cfg" --state "$work/state" 2>&1)"; check "act: choosing it again anyway is harmless" "$?" 0
has "act: it says it is already running" "$out" "already running"
wait "$bg"
check "act: so the command ran once, not twice" "$(wc -l < "$HOME/bin/job.runs" | tr -d ' ')" "1"
run render --config "$cfg" --state "$work/state" >/dev/null 2>&1
check "act: afterwards it can be chosen again" "$(q 'act("job")["enabled"]')" "True"

echo 30 > "$HOME/bin/job.sleep"
mkcfg "$slowcfg" '{"status": {"command": ["HOMEDIR/bin/status.sh"]}, "entries": [{"id": "job", "title": "J", "command": ["HOMEDIR/bin/job.sh"], "timeout_seconds": 1}]}'
run act job --config "$slowcfg" --state "$work/state" >/dev/null 2>&1; check "act: a command that hangs is exit 1" "$?" 1
has "act: and is recorded as stopped" "$(rec job 'r["note"]')" "stopped after 1 s"
mv "$HOME/bin/job.sleep" "$HOME/bin/job.sleep.off"
run act nothing --config "$cfg" --state "$work/state" >/dev/null 2>&1; check "act: an entry the config does not have is exit 2" "$?" 2

# ---- act: pages ----
run act runbook --config "$cfg" --state "$work/state" >/dev/null 2>&1; check "open: a page that is there is exit 0" "$?" 0
check "open: the opener is given the page, with ~ as the home folder" "$(tail -1 "$HOME/bin/opened.txt")" "$HOME/pages/RUNBOOK.md"
run render --config "$cfg" --state "$work/state" >/dev/null 2>&1
has "open: the menu says when it was opened" "$(q 'act("runbook")["subtitle"]')" "opened "
lines="$(wc -l < "$HOME/bin/opened.txt" | tr -d ' ')"
run act today --config "$cfg" --state "$work/state" >/dev/null 2>&1; check "open: a page that is not there yet is exit 1" "$?" 1
check "open: and the opener is not called" "$(wc -l < "$HOME/bin/opened.txt" | tr -d ' ')" "$lines"
run render --config "$cfg" --state "$work/state" >/dev/null 2>&1
has "open: the menu says it is not there yet" "$(q 'act("today")["subtitle"]')" "not there yet"
today="$(date +%Y-%m-%d)"; echo note > "$HOME/pages/$today.md"
run act today --config "$cfg" --state "$work/state" >/dev/null 2>&1
check "open: {date} is today's date" "$(tail -1 "$HOME/bin/opened.txt")" "$HOME/pages/$today.md"
run act site --config "$cfg" --state "$work/state" >/dev/null 2>&1
check "open: an address is passed to the opener as it is" "$(tail -1 "$HOME/bin/opened.txt")" "https://example.org/runbook"

# ---- stamp ----
printf 'property a : "@@ONE@@"\nproperty b : "@@TWO@@"\n' > "$work/src.txt"
out="$(run stamp --source "$work/src.txt" 'ONE=/a b/c' 'TWO=say "hi" \ there' 2>&1)"; check "stamp: fills every mark" "$?" 0
check "stamp: a quote and a backslash are written as AppleScript needs them" "$out" 'property a : "/a b/c"
property b : "say \"hi\" \\ there"'
out="$(run stamp --source "$work/src.txt" ONE=x 2>&1)"; check "stamp: a mark with no value is exit 2" "$?" 2
has "stamp: and is named" "$out" "TWO"
out="$(run stamp --source "$work/src.txt" ONE=x "TWO=two
lines" 2>&1)"; check "stamp: a value on two lines is refused" "$?" 2
stamped="$work/tray.stamped.applescript"
run stamp --source "$here/tray.applescript" "PYTHON=$PY" "HELPER=$tool" "CONFIG=$cfg" "STATE=$work/state" \
  "NAME=Runbook Tray Test" EVERY=60 > "$stamped" 2>"$work/stamp.err"
check "stamp: the real applet source is filled with these six values" "$?" 0
check "stamp: and no mark is left in it" "$(grep -c '@@[A-Z_]*@@' "$stamped")" "0"

# ---- the two files to start from ----
excfg="$work/cfg/example.json"; cp "$here/config.example.json" "$excfg"; chmod 600 "$excfg"
out="$(run doctor --config "$excfg" 2>&1)"
has "example config: it is a config the tray understands" "$out" 'entry    daily-check: "Run the daily check"'
has "example config: only its made-up paths stop it" "$out" "cannot be run as written"
exout="$("$PY" -I "$here/status.example.py" "local.selftest.not-a-job=Made-up job" 2>&1)"; check "example status: it runs" "$?" 0
exrow="$(printf '%s' "$exout" | "$PY" -I -c 'import json,sys; d=json.load(sys.stdin); r=d["rows"][0]; print(r["name"], "|", r["group"], "|", r["state"] in ("bad", "look"))' 2>&1)"
check "example status: a job launchd does not list is reported, by the name given" "$exrow" "Made-up job | Scheduled jobs | True"
mkcfg "$badcfg" "{\"status\": {\"command\": [\"$PY\", \"-I\", \"$here/status.example.py\", \"local.selftest.not-a-job=Made-up job\"]}}"
run render --config "$badcfg" --state "$work/state" >/dev/null 2>&1; check "example status: the tray reads it, and one row needs a look" "$?" 1
check "example status: the row reaches the menu" "$(q 'item("Made-up job")["state"] in ("bad", "look")')" "True"

# ---- this Mac's section: the parsers and the sums, on made-up tool output (so this part runs on any system) ----
cat > "$work/unit.py" <<'UNIT_EOF'
import importlib.util, json, sys
spec = importlib.util.spec_from_file_location("tray", sys.argv[1]); t = importlib.util.module_from_spec(spec); spec.loader.exec_module(t)
G = t.GIB
def say(name, got, want):
    print(f"{'ok' if got == want else 'FAIL'}|{name}|{got!r}|{want!r}")
sysctl = """hw.memsize: 34359738368
hw.logicalcpu: 10
vm.loadavg: { 2.50 2.00 1.50 }
vm.swapusage: total = 4096.00M  used = 2048.00M  free = 2048.00M  (encrypted)
kern.memorystatus_vm_pressure_level: 2
kern.memorystatus_level: 40
"""
vm = """Mach Virtual Memory Statistics: (page size of 16384 bytes)
Pages free:                               16384.
Pages active:                            400000.
Pages speculative:                        16384.
Pages wired down:                        131072.
Pages purgeable:                          65536.
"Translation faults":                2294384523.
File-backed pages:                       196608.
Anonymous pages:                         589824.
Pages stored in compressor:             1310720.
Pages occupied by compressor:            262144.
"""
m = t.memory_facts(sysctl, vm)
say("memory: the whole is hw.memsize", m["total"], 32 * G)
say("memory: wired is its pages times the page size", m["wired"], 2 * G)
say("memory: app memory leaves out what can be purged", m["app"], 8 * G)
say("memory: used is app + wired + compressed", m["used"], 14 * G)
say("memory: swap in use, from megabytes", m["swap_used"], 2 * G)
say("memory: cached is file-backed pages and what can be purged", m["cached"], 4 * G)
say("memory: free is the free and the speculative pages", m["free"], G // 2)
say("memory: what the compressor holds, at its full size", m["stored"], 20 * G)
say("memory: the kernel's count of memory available", m["headroom"], 40)
say("memory: a count over a hundred per cent is not believed", t.memory_facts(sysctl.replace("level: 40", "level: 400"), vm)["headroom"], None)
g = t.memory_parts(m)
say("parts: five parts, in one fixed order", [x["name"] for x in g["parts"]], ["App memory", "Wired", "Compressed", "Cached files", "Free"])
say("parts: each is its share of the whole", [x["value"] for x in g["parts"]], [0.25, 0.0625, 0.125, 0.125, 0.0156])
say("parts: the colours are the three checked hues, then two greys, each with its dark step",
    [(x["light"], x["dark"]) for x in g["parts"]],
    [("#2a78d6", "#3987e5"), ("#e87ba4", "#d55181"), ("#6250d6", "#9085e9"), ("#9a9aa0", "#7d7d83"), ("#d4d4d8", "#4a4a4e")])
say("parts: the submenu is the bar, a line for each part, a rule, and the kernel's reading",
    [x["kind"] for x in g["items"]], ["parts", "swatch", "swatch", "swatch", "swatch", "swatch", "separator", "info"])
say("parts: a line gives the amount and what the part is", g["items"][1]["subtitle"], "8.0 GB · what apps hold and are using")
say("parts: compressed says how much it is holding", g["items"][3]["subtitle"], "4.0 GB · holding 20.0 GB of app data, squeezed")
say("parts: the kernel's reading has its mark and its words", (g["items"][-1]["title"], g["items"][-1]["state"], g["items"][-1]["subtitle"]),
    ("Pressure: warning", "look", "the kernel counts 40% of memory as available"))
say("parts: the row in the main menu gives the four sizes", g["subtitle"], "app 8.0 · wired 2.0 · compressed 4.0 · cached 4.0 GB")
say("parts: with no count of what the compressor holds, none is claimed", t.memory_parts(dict(m, stored=0))["items"][3]["subtitle"], "4.0 GB · squeezed to make room")
say("memory: the kernel's pressure level", m["pressure"], 2)
say("memory: cores and the one-minute load", (m["cores"], m["load"]), (10, 2.5))
say("memory: tool output that is not what was asked for gives nothing", t.memory_facts("nonsense", "more nonsense"), None)
say("memory: a pressure level the kernel does not define is not guessed", t.memory_facts(sysctl.replace("level: 2", "level: 3"), vm)["pressure"], 0)
say("processor: the busy share between two counts", t.busy_between([100, 50, 800, 0], [160, 90, 1700, 0]), 0.1)
say("processor: a counter that wrapped round is still right", t.busy_between([2**32 - 10, 0, 0, 0], [40, 0, 50, 0]), 0.5)
say("processor: no earlier count, no figure", t.busy_between(None, [1, 2, 3, 4]), None)
say("processor: no time passed, no figure", t.busy_between([1, 2, 3, 4], [1, 2, 3, 4]), None)
top = """Processes: 5 total
PhysMem: 31G used

PID    MEM
377    2048M
400    512M+
401    1G-
402    256K
403    N/A
"""
held = t.parse_top(top)
say("top: megabytes, gigabytes and kilobytes, with top's change marks dropped", held, {377: 2 * G, 400: G // 2, 401: G, 402: 256 * 1024})
ps = """  377 /System/Library/PrivateFrameworks/SkyLight.framework/Resources/WindowServer
  400 /Applications/Example Browser.app/Contents/Frameworks/Example Framework.framework/Helpers/Example Browser Helper (Renderer).app/Contents/MacOS/Example Browser Helper (Renderer)
  401 /Applications/Example Browser.app/Contents/MacOS/Example Browser
  402 /System/Library/Frameworks/WebKit.framework/Versions/A/XPCServices/com.apple.WebKit.WebContent.xpc/Contents/MacOS/com.apple.WebKit.WebContent
  999 -zsh
"""
names = t.parse_names(ps)
say("names: a helper is counted with its app", (names[400], names[401]), ("Example Browser", "Example Browser"))
say("names: a tool is named by its file, never its folder", names[377], "WindowServer")
say("names: WebKit's page processes get a plain name", names[402], "WebKit web content")
groups = t.group_memory(held, names, 2)
say("groups: summed by app, largest first, cut to the number asked for", groups, [["WindowServer", 1, 2 * G], ["Example Browser", 2, G + G // 2]])
say("groups: a process that ended between the two readings is left out", t.group_memory({5: G}, names, 3), [])
say("disk: used, free and the percentage as df prints them", t.disk_facts("Filesystem 1024-blocks Used Available Capacity iused ifree %iused Mounted on\n/dev/disk3s5 1000 300 500 38% 1 2 0% /System/Volumes/Data\n"),
    {"used": 300 * 1024, "free": 500 * 1024, "fraction": 0.375, "percent": 38})
say("disk: df output that is not a table gives nothing", t.disk_facts("df: no such file"), None)
import datetime
say("day: the header names every column of a line", len(t.DAY_HEADER.split(",")), len(t.day_line(m, 0.15, 1_000_000).split(",")))
say("day: a line is the time, then memory in GB, the kernel's words, and the processor",
    t.day_line(m, 0.15, 1_000_000).split(",")[1:], ["14.00", "32.00", "warning", "40", "2.00", "8.00", "2.00", "4.00", "20.00", "4.00", "0.50", "15", "2.50"])
say("day: the time is the local time of the sample", t.day_line(m, None, 1_000_000).split(",")[0], f"{datetime.datetime.fromtimestamp(1_000_000):%Y-%m-%d %H:%M:%S}")
say("day: what was not read is left empty, not written as nought", t.day_line(dict(m, swap_used=None, load=None, headroom=None), None, 1_000_000).split(",")[4:6] + t.day_line(dict(m, load=None), None, 1_000_000).split(",")[-2:], ["", "", "", ""])
say("trend: under a twentieth of a gigabyte is steady", t.moved(10 * G + 1000, 10 * G), "steady")
say("trend: up and down, in gigabytes", (t.moved(11.5 * G, 10 * G), t.moved(9 * G, 10 * G)), ("up 1.5 GB", "down 1.0 GB"))
now = 1_000_000
hour = [{"t": now - 3600 + 60 * i, "mem": (20 + i / 30) * G, "total": 32 * G, "swap": (1 + i / 60) * G, "cpu": [10 * i, 5 * i, 85 * i, 0]} for i in range(61)]
say("trend: the comparison is about an hour back", t.earlier(hour, now)[1], "in the last hour")
say("trend: a short record says how short", t.earlier(hour[-16:], now)[1], "in the last 15 min")
say("trend: a record under ten minutes compares with nothing", t.earlier(hour[-5:], now), (None, ""))
line = t.last_hour(hour, now)
say("line: one step a minute over the hour", (len(line), line[0], line[-1]), (61, 0.625, 0.6875))
items, bar = t.machine_section(m, {"used": 3 * G, "free": 5 * G, "fraction": 0.375, "percent": 38}, [700, 350, 5950, 0], hour, groups, now - 120, now)
kinds = [i["kind"] for i in items]
say("section: a header, memory and its parts, three more meters, the hour's line, and the apps", kinds, ["header", "meter", "group", "meter", "meter", "meter", "spark", "group"])
by = {i["title"]: i for i in items if "title" in i}
say("section: memory's bar is its share of the whole", by["Memory"]["value"], 0.4375)
say("section: memory says what it is in words, state included", by["Memory"]["subtitle"], "14.0 of 32 GB used · pressure warning")
say("section: and its colour follows the kernel's pressure level", by["Memory"]["tint"], "amber")
say("section: swap is measured against the size of memory, with its change", (by["Swap"]["value"], by["Swap"]["subtitle"]), (0.0625, "2.0 GB in use · up 1.0 GB in the last hour"))
say("section: the processor is the busy share since the last sample", (by["Processor"]["value"], by["Processor"]["subtitle"]), (0.15, "15% busy since the last check · load 2.5 on 10 cores"))
say("section: the disk says what df says", by["Disk"]["subtitle"], "38% used · 5 GiB free")
say("section: only memory changes colour; the rest have no rule to change by", sorted({i["tint"] for i in items if i["kind"] == "meter" and i["title"] != "Memory"}), ["blue"])
say("section: the hour's line carries its range and its change", by["Memory, last hour"]["subtitle"], "between 62% and 69% · down 6.0 GB in the last hour")
say("section: the apps are ranked against the largest, in grey", [(r["title"], r["subtitle"], r["value"], r["tint"]) for r in by["What is holding the most memory"]["items"]],
    [("WindowServer", "2.0 GB", 1.0, "grey"), ("Example Browser × 2", "1.5 GB", 0.75, "grey")])
say("section: the menu bar gets the gauge, the colour and the words", bar, {"gauge": 0.4375, "tint": "amber", "tooltip": "memory 44% used, pressure warning"})
calm = dict(m, pressure=1, load=None, swap_used=None)
items2, bar2 = t.machine_section(calm, None, None, [], [], now, now)
say("section: normal pressure is blue, and the menu bar keeps its own colour", (items2[1]["tint"], bar2["tint"]), ("blue", "none"))
say("section: what cannot be read is left out, not guessed", [i.get("title") for i in items2], ["This Mac", "Memory", "Memory, part by part"])
items3, _ = t.machine_section(dict(m, pressure=4), None, None, [], [], now, now)
say("section: critical pressure is red", items3[1]["tint"], "red")
items4, _ = t.machine_section(m, None, None, hour[-1:], [], now, now)
cpu4 = next(i for i in items4 if i.get("title") == "Processor")
say("section: with no earlier count the processor shows its load instead", (cpu4["subtitle"], cpu4["value"]), ("load 2.5 on 10 cores", 0.25))
# the fixture the applet draws in its own self-test: made-up status rows plus this made-up Mac
cfg = {"name": "Runbook", "entries": [], "stale_after": 300, "machine": None}
status = {"when": "", "result": "all good", "rows": [{"name": "nightly-backup", "state": "good", "detail": "waiting for its time", "group": "Scheduled jobs"}]}
model = t.build_model(cfg, status, "", sys.argv[2], now, machine=(items, bar))
say("model: the gauge and the memory words reach the menu bar", (model["bar"]["gauge"], model["bar"]["tint"], model["bar"]["tooltip"].split(" · ")[-1]), (0.4375, "amber", "memory 44% used, pressure warning"))
say("model: pressure raises the menu bar's colour without adding to the count", model["bar"]["text"], "")
json.dump(model, open(sys.argv[2] + "/machine-fixture.json", "w"))
quiet = t.machine_section(dict(m, pressure=1), None, None, hour, groups, now - 120, now)
json.dump(t.build_model(cfg, status, "", sys.argv[2], now, machine=quiet), open(sys.argv[2] + "/machine-calm-fixture.json", "w"))
text = t.as_text(model)
say("text: a meter prints as ten cells", "▰▰▰▰▱▱▱▱▱▱ Memory" in text, True)
say("text: the parts print under their heading", "▾ Memory, part by part" in text and "    ■ Compressed  ·  4.0 GB" in text, True)
say("text: the apps are listed under their heading", "▾ What is holding the most memory" in text and "    ▰▰▰▰▰▰▰▰▰▰ WindowServer" in text, True)
UNIT_EOF
unit="$("$PY" -I -B "$work/unit.py" "$tool" "$work" 2>&1)"   # -B: leave no bytecode beside the tool
[ -n "$unit" ] || bad "machine: the unit checks ran" "no output"
printf '%s\n' "$unit" | while IFS='|' read -r verdict name got want; do
  if [ "$verdict" = ok ]; then echo "ok    $name"; else echo "FAIL  ${name:-$verdict}"; echo "      expected [$want]"; echo "      got      [$got]"; fi
done
passes=$((passes + $(printf '%s\n' "$unit" | grep -c '^ok|')))
fails=$((fails + $(printf '%s\n' "$unit" | grep -c -v '^ok|')))

mkcfg "$badcfg" '{"status": {"command": ["HOMEDIR/bin/status.sh"]}, "machine": {"processes": 99}}'
out="$(run doctor --config "$badcfg" 2>&1)"; check "machine: more than 20 apps is refused" "$?" 2
mkcfg "$badcfg" '{"status": {"command": ["HOMEDIR/bin/status.sh"]}, "machine": {"colour": "red"}}'
out="$(run doctor --config "$badcfg" 2>&1)"; check "machine: a name the tray does not know is refused" "$?" 2
printf '%s\n' "$good_status" > "$HOME/bin/status.out"
run render --config "$cfg" --state "$work/state" >/dev/null 2>&1
check "machine: not asked for, not shown" "$(q 'any(i.get("title") == "This Mac" for i in items) or "gauge" in m["bar"]')" "False"
if [ "$(uname)" = Darwin ]; then
  livecfg="$work/cfg/live.json"; live="$work/live-state"
  mkcfg "$livecfg" '{"status": {"command": ["HOMEDIR/bin/status.sh"]}, "machine": {"processes": 5}}'
  ql() { "$PY" -I -c 'import json,sys; m=json.load(open(sys.argv[1] + "/menu.json")); items=m["items"]; print(eval(sys.argv[2]))' "$live" "$1" 2>&1; }
  run render --config "$livecfg" --state "$live" >/dev/null 2>&1; rc=$?
  check "machine, on this Mac: a render with the section runs" "$([ "$rc" -le 1 ] && echo yes || echo "exit $rc")" "yes"
  check "machine, on this Mac: memory is read as a share between nothing and all" "$(ql '0 < next(i for i in items if i.get("title") == "Memory")["value"] <= 1')" "True"
  check "machine, on this Mac: the menu bar gets its gauge" "$(ql '0 < m["bar"]["gauge"] <= 1')" "True"
  check "machine, on this Mac: memory comes part by part, and the parts are no more than the whole" "$(ql '(lambda g: len(g["parts"]) == 5 and 0.5 < sum(x["value"] for x in g["parts"]) <= 1.02)(next(i for i in items if i.get("title") == "Memory, part by part"))')" "True"
  check "machine, on this Mac: the disk is read" "$(ql '"% used" in next(i for i in items if i.get("title") == "Disk")["subtitle"]')" "True"
  check "machine, on this Mac: up to five apps are listed, largest first" "$(ql '(lambda g: 1 <= len(g) <= 5 and g[0]["value"] == 1.0)(next(i for i in items if i.get("title") == "What is holding the most memory")["items"])')" "True"
  check "machine, on this Mac: a sample is kept" "$("$PY" -I -c 'import json,sys; print(len(json.load(open(sys.argv[1]))["samples"]))' "$live/history.json")" "1"
  first="$(cat "$live/processes.json")"
  run render --config "$livecfg" --state "$live" >/dev/null 2>&1
  check "machine, on this Mac: a second sample is added" "$("$PY" -I -c 'import json,sys; print(len(json.load(open(sys.argv[1]))["samples"]))' "$live/history.json")" "2"
  day="$live/days/$(date +%Y-%m-%d).csv"
  check "machine, on this Mac: the day's record has its header and a line for each sample" "$(head -1 "$day" | cut -d, -f1-3) $(wc -l < "$day" | tr -d ' ')" "time,memory_used_gb,memory_total_gb 3"
  check "machine, on this Mac: the apps are not counted again inside five minutes" "$(cat "$live/processes.json")" "$first"
  hasnt "machine, on this Mac: no argument of any process is kept" "$(cat "$live/processes.json" "$live/menu.json")" " --"
else
  echo "skip  the live reading of this machine (it needs macOS)"
fi

# ---- on macOS: the applet compiles, and the build makes a signed app without touching ~/Applications ----
if [ "$(uname)" = Darwin ] && [ -x /usr/bin/osacompile ]; then
  /usr/bin/osacompile -s -o "$work/Compile Check.app" "$stamped" >"$work/compile.out" 2>&1
  rc=$?; check "applet: osacompile accepts the source" "$rc" 0
  [ "$rc" = 0 ] || sed 's/^/      /' "$work/compile.out"
  out="$(sh "$here/build.sh" --config "$cfg" --out "$work/out" --state "$work/tray-state" --name "Runbook Tray Test" --print 2>&1)"
  check "build: --print is exit 0" "$?" 0
  check "build: --print writes nothing" "$([ -e "$work/out" ] || [ -e "$work/tray-state" ] && echo wrote || echo nothing)" "nothing"
  out="$(sh "$here/build.sh" --config "$cfg" --out "$work/out" --state "$work/tray-state" --name "Runbook Tray Test" --python "$PY" 2>&1)"
  check "build: builds" "$?" 0
  app="$work/out/Runbook Tray Test.app"
  check "build: the app is where it was asked for" "$([ -x "$app/Contents/MacOS/applet" ] && echo yes)" "yes"
  check "build: it has no Dock icon" "$(/usr/bin/plutil -extract LSUIElement raw "$app/Contents/Info.plist" 2>&1)" "true"
  check "build: it carries its name" "$(/usr/bin/plutil -extract CFBundleName raw "$app/Contents/Info.plist" 2>&1)" "Runbook Tray Test"
  /usr/bin/codesign --verify "$app" 2>"$work/sign.err"; check "build: its signature for this Mac verifies" "$?" 0
  hasnt "build: it says nothing was added to Login Items" "$out" "added to Login Items"
  has "build: and that opening at login is the owner's choice" "$out" "yours to choose"
  out="$(sh "$here/build.sh" --config "$cfg" --out "$work/out" --state "$work/tray-state" --name "Runbook Tray Test" --python "$PY" 2>&1)"
  check "build: a second build is exit 0" "$?" 0
  check "build: and the first app is kept, moved aside" "$(find "$work/tray-state/previous-builds" -name 'Runbook Tray Test.app' -maxdepth 2 | wc -l | tr -d ' ')" "1"
  out="$(sh "$here/build.sh" --out "$work/out" 2>&1)"; check "build: no config is exit 2" "$?" 2
  out="$(sh "$here/build.sh" --config "$cfg" --every 5 2>&1)"; check "build: checking more often than every 15 s is refused" "$?" 2
  out="$(sh "$here/build.sh" --config "$badcfg" --out "$work/out" 2>&1)"; check "build: a config with a problem is exit 2" "$?" 2

  if [ "$WITH_APPLET" = 1 ]; then
    fx="$work/fixtures"; mkdir -p "$fx"
    printf '%s\n' "$good_status" > "$HOME/bin/status.out"
    run render --config "$cfg" --state "$work/state" >/dev/null 2>&1; cp "$work/state/menu.json" "$fx/01-good.json"
    printf '%s\n' '{"rows": [{"name": "b", "state": "look", "detail": "slow", "group": "Checks"}, {"name": "c", "state": "bad", "detail": "stopped", "group": "Checks"}, {"name": "d", "state": "off", "detail": "not set up", "group": "Checks"}]}' > "$HOME/bin/status.out"
    run render --config "$cfg" --state "$work/state" >/dev/null 2>&1; cp "$work/state/menu.json" "$fx/02-trouble.json"
    printf 'not json\n' > "$fx/03-broken.json"
    cp "$work/machine-fixture.json" "$fx/04-machine.json"
    cp "$work/machine-calm-fixture.json" "$fx/05-machine-calm.json"
    printf '%s\n' "$side_status" > "$HOME/bin/status.out"
    run render --config "$foldcfg" --state "$work/state" >/dev/null 2>&1; cp "$work/state/menu.json" "$fx/06-folded.json"
    report="$work/applet-report.txt"
    "$app/Contents/MacOS/applet" --selftest "$fx" "$report" >"$work/applet.out" 2>&1 &
    ap=$!
    n=0; while kill -0 "$ap" 2>/dev/null && [ $n -lt 150 ]; do n=$((n+1)); "$PY" -I -c 'import time; time.sleep(0.1)'; done
    if kill -0 "$ap" 2>/dev/null; then kill "$ap"; bad "applet: it quits by itself after its self-test"; else ok "applet: it quits by itself after its self-test"; fi
    rep="$(cat "$report" 2>/dev/null)"
    has "applet: the self-test ran to its end" "$rep" "selftest: done"
    hasnt "applet: with no error" "$rep" "SELFTEST ERROR"
    check "applet: nothing was printed as an error by AppleScript" "$(grep -c -i 'error\|\*\*\*' "$work/applet.out")" "0"
    has "applet: all good, the bar is a picture with no count" "$rep" "bar: title=[] image=true tip=[Runbook: all good, checked "
    has "applet: the first line, with its coloured mark" "$rep" "item: [All good] sub=[checked "
    has "applet: a group header is a real section header" "$rep" "item: [Scheduled jobs] sub=[] picture=false enabled=true wired=false header=true"
    has "applet: a row has its detail and its mark, and does nothing when chosen" "$rep" "item: [watcher] sub=[running, pid 41] picture=true enabled=true wired=false header=false id=[]"
    check "applet: an entry has its picture and its last result" "$(printf '%s\n' "$rep" | grep -c -E 'item: \[Run the job, first line\] sub=\[[0-9:]+ · first line of the job\] picture=true' | sed 's/^[1-9][0-9]*$/found/')" "found"
    has "applet: an entry is wired to its id" "$rep" "item: [Open the runbook] sub=[opened "
    has "applet: Refresh now is always there" "$rep" "item: [Refresh now] sub=[] picture=true enabled=true wired=true header=false id=[_refresh]"
    has "applet: Quit is always there" "$rep" "item: [Quit Runbook Tray Test] sub=[] picture=true enabled=true wired=true"
    has "applet: choosing an entry asks the helper to do that entry" "$rep" "would run: -I $tool act runbook --config $cfg --state $work/tray-state"
    has "applet: choosing Refresh now asks the helper to render" "$rep" "would run: -I $tool render --config $cfg --state $work/tray-state"
    has "applet: trouble shows as a count beside the picture" "$rep" "bar: title=[2] image=true tip=[Runbook: 2 need a look: b, c, checked "
    has "applet: a file that is not JSON is not drawn" "$rep" "== 03-broken.json loaded=false"
    has "applet: and the menu says it is waiting, with Quit still there" "$rep" "item: [Waiting for the first check]"
    check "applet: no helper was started and nothing was opened" "$([ -e "$work/tray-state/menu.json" ] && echo started || echo "not started")" "not started"
    has "applet: a meter row has its bar and its words" "$rep" "item: [Memory] sub=[14.0 of 32 GB used · pressure warning] picture=true enabled=true wired=false"
    has "applet: memory's parts are a row with their own small picture" "$rep" "item: [Memory, part by part] sub=[app 8.0 · wired 2.0 · compressed 4.0 · cached 4.0 GB] picture=true"
    has "applet: under it, the bar split into its parts" "$rep" "under it: [] sub=[] picture=true"
    has "applet: and a line for each part, with its colour" "$rep" "under it: [Compressed] sub=[4.0 GB · holding 20.0 GB of app data, squeezed] picture=true"
    has "applet: and the kernel's own reading" "$rep" "under it: [Pressure: warning] sub=[the kernel counts 40% of memory as available] picture=true"
    has "applet: the hour's line is drawn" "$rep" "item: [Memory, last hour] sub=[between 62% and 69% · down 6.0 GB in the last hour] picture=true"
    has "applet: the apps sit in a submenu, each with its bar" "$rep" "under it: [Example Browser × 2] sub=[1.5 GB] picture=true"
    has "applet: a folded group is one row with its mark and its count" "$rep" "item: [Side list] sub=[1 good · 1 off · 1 to look at · 1 not checked] picture=true"
    has "applet: and its rows are under it, each with its mark" "$rep" "under it: [s4] sub=[cannot be told from here] picture=true"
    hasnt "applet: every picture it was asked for could be drawn" "$rep" "SHEET ERROR"
    check "applet: a picture of each menu is saved for a person to look at" "$(ls "$report".*.png 2>/dev/null | wc -l | tr -d ' ')" "6"
    if [ -n "${RUNBOOK_TRAY_KEEP:-}" ]; then
      mkdir -p "$RUNBOOK_TRAY_KEEP" && cp "$report" "$report".*.png "$RUNBOOK_TRAY_KEEP/" && echo "kept  the applet's report and pictures in $RUNBOOK_TRAY_KEEP"
    fi
  else
    echo "skip  the applet's own self-test (run with --with-applet; an item appears in the menu bar for about a second)"
  fi
else
  echo "skip  the compile and the build (they need macOS)"
fi

echo
echo "$passes passed, $fails failed"
[ "$fails" = 0 ]
