#!/bin/sh
# claude-projects-archive.selftest.sh: proves claude-projects-archive.sh against a fake home in a throwaway folder,
# with a fake projects tree and a fake passphrase. It never reads your real ~/.claude, never writes to iCloud Drive and
# never calls launchctl (the plist is rendered and linted only).
#
#   sh scripts/claude-projects-archive.selftest.sh
#   CLAUDE_ARCHIVE_SELFTEST_DIR=/some/scratch sh scripts/claude-projects-archive.selftest.sh   # where the fake home goes
#
# Exit codes: 0 every case as expected · 1 a case failed.
set -u
here="$(cd "$(dirname "$0")" && pwd -P)"
A="$here/claude-projects-archive.sh"
base="${CLAUDE_ARCHIVE_SELFTEST_DIR:-${TMPDIR:-/tmp}}"
R="$(mktemp -d "$base/cpa-selftest.XXXXXX")" || exit 1
R="$(cd "$R" && pwd -P)"
H="$R/home"; P="$H/.claude/projects"; D="$R/dest"
mkdir -p "$P/-Users-x-code-repo1/memory" "$P/-Users-x-code-repo2/sub" "$D"
export HOME="$H"
unset CLAUDE_ARCHIVE_DEST CLAUDE_ARCHIVE_PASSFILE CLAUDE_ARCHIVE_CONFIG CLAUDE_ARCHIVE_OPENSSL
export CLAUDE_ARCHIVE_NO_LAUNCHCTL=1
export CLAUDE_ARCHIVE_NO_BANNER=1
pass=0; fail=0
ok() { if [ "$1" = "$2" ]; then pass=$((pass + 1)); else fail=$((fail + 1)); echo "FAIL $3: got [$1] want [$2]"; fi; }
run() { sh "$A" "$@" > "$R/out" 2>&1; echo $?; }
SENT="CPASENTINEL""77q"            # assembled, so this file does not hold the text it hunts for
CFG="$H/.config/claude-archive"
mode() { stat -f %Lp "$1" 2>/dev/null || stat -c %a "$1"; }
count() { find "$1" -type f -name "$2" | wc -l | tr -d ' '; }
statedir() { for s in "$CFG"/state/*/; do [ "$(cat "$s/dest")" = "$1" ] && printf '%s\n' "${s%/}"; done; }

# fixture: two projects, a big-ish transcript, memory, a name with a space, CLAUDE.md
i=0; while [ $i -lt 2000 ]; do printf '{"type":"user","message":"%s line %d"}\n' "$SENT" $i; i=$((i + 1)); done > "$P/-Users-x-code-repo1/a.jsonl"
printf '{"cwd":"/x"}\n' > "$P/-Users-x-code-repo2/b.jsonl"
printf '# memory\n' > "$P/-Users-x-code-repo1/memory/MEMORY.md"
printf 'spaced\n' > "$P/-Users-x-code-repo2/sub/with space.txt"
printf '# user claude\n' > "$H/.claude/CLAUDE.md"
printf 'not archived\n' > "$H/.claude/settings.json"

# 1. init
ok "$(run --init)" 0 "init succeeds"
ok "$(mode "$CFG")" 700 "config folder is 700"
ok "$(mode "$CFG/passphrase")" 600 "passphrase file is 600"
ok "$(grep -cF "$(cat "$CFG/passphrase")" "$R/out")" 0 "init never prints the passphrase"
ok "$(grep -c "pbcopy < '$CFG/passphrase'" "$R/out")" 1 "init prints the pbcopy line"
before="$(shasum < "$CFG/passphrase")"
ok "$(run --init)" 0 "a second init succeeds"
ok "$(grep -c 'already exists' "$R/out")" 1 "a second init leaves the file"
ok "$(shasum < "$CFG/passphrase")" "$before" "the passphrase is unchanged"

# 2. refusals before anything is written
ok "$(run --run)" 2 "default dest refused when there is no iCloud Drive"
ok "$(run --run --dest "$R/nope")" 2 "a --dest that does not exist is refused"
ok "$(test -e "$R/nope" && echo made || echo absent)" absent "and is not created"
ok "$(run --run --dest "$H/.claude/backup-here")" 2 "dest inside ~/.claude refused"
mkdir -p "$H/.claude/inner"; ln -s "$H/.claude/inner" "$R/sneaky"
ok "$(run --run --dest "$R/sneaky")" 2 "dest that is a symlink into ~/.claude refused"
ok "$(run --run --dest "$H")" 2 "dest that holds ~/.claude refused"
chmod 644 "$CFG/passphrase"
ok "$(run --run --dest "$D")" 2 "a 644 passphrase is refused"
ok "$(grep -c 'mode 644' "$R/out")" 1 "and the reason names the mode"
chmod 600 "$CFG/passphrase"
ok "$(CLAUDE_ARCHIVE_PASSFILE="$R/missing" run --run --dest "$D")" 2 "a missing passphrase file is refused"
ok "$(count "$D" '*')" 0 "no refusal wrote anything at the destination"

# 3. full
ok "$(run --run --dest "$D")" 0 "first run succeeds"
ok "$(grep -c '^full archive (first run' "$R/out")" 1 "first run is full"
ok "$(count "$D" '*_full.tar.gz.enc')" 1 "one full archive"
ok "$(count "$D" '*_full.tar.gz.enc.sha256')" 1 "its .sha256 beside it"
ok "$(count "$D" '*.partial')" 0 "no .partial left on success"
F1="$(find "$D" -name '*_full.tar.gz.enc')"
ok "$(dirname "$F1")" "$D/$(date +%Y)" "written into the year folder"
ok "$(mode "$F1")" 600 "archive is mode 600"
ok "$(grep -c "$SENT" "$F1")" 0 "the archive is ciphertext: the sentinel is not readable in it"
ok "$(head -c 8 "$F1")" "Salted__" "openssl salted header"
ok "$(run --verify "$F1")" 0 "verify the full"
ok "$(grep -c 'ok .*: 5 entries, sha256 matches' "$R/out")" 1 "full holds the 4 project files and CLAUDE.md"
O3=/opt/homebrew/bin/openssl; [ -x "$O3" ] || O3=/usr/bin/openssl     # OpenSSL 3 when installed, to prove the format travels
ok "$("$O3" enc -d -aes-256-cbc -pbkdf2 -iter 600000 -md sha256 -pass "file:$CFG/passphrase" -in "$F1" | tar -tzf - | grep -c 'CLAUDE.md$')" 1 "$("$O3" version | cut -d' ' -f1-2) opens it and finds CLAUDE.md"
ok "$(/usr/bin/openssl enc -d -aes-256-cbc -pbkdf2 -iter 600000 -md sha256 -pass "file:$CFG/passphrase" -in "$F1" | tar -tzf - | grep -c 'settings.json')" 0 "settings.json is not in it"

# 4. --if-due right after: skip
ok "$(run --if-due --dest "$D")" 0 "if-due exits 0"
ok "$(grep -c '^not due' "$R/out")" 1 "if-due skips within 20 hours"
ok "$(count "$D" '*.enc')" 1 "and writes nothing"

# 5. nothing changed: no archive
ok "$(run --run --dest "$D")" 0 "an incremental with nothing changed succeeds"
ok "$(grep -c 'Nothing changed' "$R/out")" 1 "and says so"
ok "$(count "$D" '*.enc')" 1 "and writes nothing"

# 6. incremental
printf '{"type":"user","message":"appended"}\n' >> "$P/-Users-x-code-repo1/a.jsonl"
mkdir -p "$P/-Users-x-code-repo3"; printf '{"new":1}\n' > "$P/-Users-x-code-repo3/c.jsonl"
ok "$(run --run --dest "$D")" 0 "incremental run succeeds"
ok "$(grep -c '^incr archive' "$R/out")" 1 "second run is incremental"
I1="$(find "$D" -name '*_incr.tar.gz.enc')"
ok "$(echo "$I1" | grep -c .)" 1 "one incremental archive"
ok "$(run --verify "$I1")" 0 "verify the incremental"
ok "$(grep -c ': 2 entries' "$R/out")" 1 "incremental holds only the 2 changed files"
ok "$(count "$D" '*.partial')" 0 "no .partial after the incremental"

# 7. if-due when the last success is old
S="$(statedir "$D")"
echo $(( $(date +%s) - 21 * 3600 )) > "$S/last-success"
printf 'x\n' >> "$P/-Users-x-code-repo2/b.jsonl"
ok "$(run --if-due --dest "$D")" 0 "if-due runs after 20 hours"
ok "$(grep -c '^incr archive' "$R/out")" 1 "and makes an incremental"
ok "$(count "$D" '*_incr.tar.gz.enc')" 2 "two incrementals now"

# 8. verify refuses damage and a wrong passphrase
cp "$F1" "$R/damaged.tar.gz.enc"; cp "$F1.sha256" "$R/damaged.tar.gz.enc.sha256"
printf 'X' | dd of="$R/damaged.tar.gz.enc" bs=1 seek=4000 conv=notrunc 2>/dev/null
ok "$(run --verify "$R/damaged.tar.gz.enc")" 1 "verify fails on a damaged copy"
printf 'wrong-passphrase\n' > "$R/wrong.pass"; chmod 600 "$R/wrong.pass"
ok "$(CLAUDE_ARCHIVE_PASSFILE="$R/wrong.pass" run --verify "$F1")" 1 "verify fails with the wrong passphrase"
files_before="$(find "$R" ! -name out | wc -l)"
run --verify "$F1" >/dev/null
ok "$(find "$R" ! -name out | wc -l)" "$files_before" "verify writes nothing"

# 9. restore
ALL="$(find "$D" -name '*.tar.gz.enc' | awk '{ n = $0; sub(/.*\//, "", n); print n "\t" $0 }' | sort | cut -f2-)"
# shellcheck disable=SC2086
ok "$(set -f; IFS='
'; run --restore $ALL "$R/restored")" 0 "restore full then incrementals into a new folder"
ok "$(diff -r "$P" "$R/restored/.claude/projects" >/dev/null && echo same || echo differ)" same "restored projects match the live tree"
ok "$(cmp -s "$H/.claude/CLAUDE.md" "$R/restored/.claude/CLAUDE.md" && echo same || echo differ)" same "restored CLAUDE.md matches"
ok "$(test -e "$R/restored/.claude/settings.json" && echo yes || echo no)" no "nothing else came back"
ok "$(run --restore-latest --dest "$D" "$R/restored2")" 0 "restore-latest succeeds"
ok "$(diff -r "$P" "$R/restored2/.claude/projects" >/dev/null && echo same || echo differ)" same "restore-latest matches the live tree"
ok "$(run --restore "$F1" "$R/restored")" 2 "restore into a non-empty folder is refused"
mkdir "$R/empty"
ok "$(run --restore "$F1" "$R/empty")" 0 "restore into an existing empty folder works"
ok "$(run --restore "$F1" "$H/.claude/restore-here")" 2 "restore into ~/.claude is refused"
ok "$(test -e "$H/.claude/restore-here" && echo made || echo absent)" absent "and nothing was made there"
ok "$(run --restore "$I1" "$R/r3")" 2 "restore must start with a full"
ok "$(run --restore "$F1" "$F1" "$R/r4")" 2 "a full cannot follow a full"
I2="$(find "$D" -name '*_incr.tar.gz.enc' | sort | tail -n 1)"
ok "$(run --restore "$F1" "$I2" "$I1" "$R/r5")" 2 "incrementals out of order are refused"
ok "$(test -e "$R/r5" && echo made || echo absent)" absent "a refused restore makes no folder"

# 10. a failed write leaves no .partial and does not move the stamp
stamp_before="$(stat -f %Fm "$S/stamp" 2>/dev/null || stat -c %Y "$S/stamp")"
printf 'y\n' >> "$P/-Users-x-code-repo2/b.jsonl"
chmod 500 "$D/$(date +%Y)"
ok "$(run --run --dest "$D")" 1 "a run that cannot write fails"
chmod 700 "$D/$(date +%Y)"
ok "$(count "$D" '*.partial')" 0 "no .partial left by the failed run"
ok "$(stat -f %Fm "$S/stamp" 2>/dev/null || stat -c %Y "$S/stamp")" "$stamp_before" "the stamp did not move"
ok "$(run --run --dest "$D")" 0 "the next run succeeds"
ok "$(count "$D" '*_incr.tar.gz.enc')" 3 "and catches up"
FAKE="$R/fake-openssl"     # decrypts like the real one; encrypting writes half a file, then fails
cat > "$FAKE" <<'EOS'
#!/bin/sh
case " $* " in *" -d "*) exec /usr/bin/openssl "$@" ;; esac
prev=""; for a in "$@"; do [ "$prev" = -out ] && head -c 100 > "$a"; prev="$a"; done
echo broken >&2; exit 1
EOS
chmod 755 "$FAKE"
printf 'z\n' >> "$P/-Users-x-code-repo2/b.jsonl"
ok "$(CLAUDE_ARCHIVE_OPENSSL="$FAKE" run --run --dest "$D")" 1 "a run whose encryption fails, fails"
ok "$(count "$D" '*.partial')" 0 "and leaves no .partial"
ok "$(count "$D" '*_incr.tar.gz.enc')" 3 "and no archive"

# 11. a second full, --list, --prune-plan
ok "$(run --run --full --dest "$D")" 0 "--full forces a full"
ok "$(count "$D" '*_full.tar.gz.enc')" 2 "two fulls now"
ok "$(run --list --dest "$D")" 0 "list succeeds"
ok "$(grep -c ' full$' "$R/out")" 2 "list shows both fulls"
ok "$(grep -c ' incremental$' "$R/out")" 3 "list shows three incrementals"
ok "$(grep -c 'destination total' "$R/out")" 1 "list prints the total"
n_before="$(count "$D" '*')"
ok "$(run --prune-plan 1 --dest "$D")" 0 "prune-plan succeeds"
ok "$(grep -c '_full.tar.gz.enc$' "$R/out")" 1 "prune-plan would move the older full"
ok "$(grep -c '_incr.tar.gz.enc$' "$R/out")" 3 "and the incrementals before the newest full"
ok "$(count "$D" '*')" "$n_before" "prune-plan changed nothing"
ok "$(run --prune-plan 5 --dest "$D")" 0 "prune-plan with room to spare"
ok "$(grep -c 'moves nothing' "$R/out")" 1 "says it moves nothing"
ok "$(run --prune-plan 0 --dest "$D")" 2 "prune-plan 0 is refused"

# 12. the default destination, inside a fake iCloud Drive in the fake home
mkdir -p "$H/Library/Mobile Documents/com~apple~CloudDocs"
ok "$(run --run)" 0 "default destination works when iCloud Drive exists"
ok "$(count "$H/Library/Mobile Documents/com~apple~CloudDocs/Backups/claude-projects/$(date +%Y)" '*_full.tar.gz.enc')" 1 "a new destination starts with a full"
ok "$(run --list)" 0 "list the default destination (a path with spaces)"
ok "$(grep -c ' full$' "$R/out")" 1 "and finds its full"

# 12b. a renamed project folder keeps its files' old times; the listing check still picks it up (Nov 6 verifier finding)
mv "$P/-Users-x-code-repo2" "$P/-Users-x-code-repo2-lab"
ok "$(run --run --dest "$D")" 0 "the run after a rename succeeds"
ok "$(grep -c '^incr archive' "$R/out")" 1 "it writes an incremental, not 'nothing changed'"
ok "$(grep -c ': 2 files,' "$R/out")" 1 "holding the two files of the renamed folder"
ok "$(run --restore-latest --dest "$D" "$R/restored-rename")" 0 "restore-latest after a rename succeeds"
ok "$(diff -r "$P/-Users-x-code-repo2-lab" "$R/restored-rename/.claude/projects/-Users-x-code-repo2-lab" >/dev/null && echo same || echo differ)" same "the renamed folder comes back under its new name"
ok "$(run --run --dest "$D")" 0 "the next run succeeds"
ok "$(grep -c '^Nothing changed' "$R/out")" 1 "and finds nothing new (the listing advanced)"

# 12c. --move-old: older chains leave the destination for another folder, checked, nothing deleted
M="$R/drive"; mkdir -p "$M"
ok "$(run --run --full --dest "$D")" 0 "a second full"
before_n="$(count "$D" '*.enc')"
ok "$(run --move-old 1 "$R/no-drive" --dest "$D")" 2 "move-old to a missing folder is refused"
ok "$(run --move-old 1 "$D/$(date +%Y)" --dest "$D")" 2 "move-old into the destination itself is refused"
ok "$(run --move-old 1 "$M" --dest "$D")" 0 "move-old keeping the newest full succeeds"
moved="$(count "$M" '*.enc')"
ok "$(( $(count "$D" '*.enc') + moved ))" "$before_n" "every archive is either still there or moved: none lost"
ok "$(count "$D" '*_full.tar.gz.enc')" 1 "one full stays at the destination"
ok "$(count "$M" '*.enc.sha256')" "$moved" "each moved archive brought its .sha256"
ok "$(run --restore-latest --dest "$D" "$R/restored-after-move")" 0 "the destination still restores on its own"
ok "$(diff -r "$P" "$R/restored-after-move/.claude/projects" >/dev/null && echo same || echo differ)" same "and matches the live tree"
ok "$(run --move-old 1 "$M" --dest "$D")" 0 "a second move-old with one full"
ok "$(grep -c 'moves nothing' "$R/out")" 1 "moves nothing"

# 12d. a failed run is never silent: recorded, passed to the notify hook, and --status says STALE (Nov 6 finding)
printf '#!/bin/sh\nprintf "%%s\\n" "$1" >> "%s/notified.txt"\n' "$R" > "$CFG/notify"; chmod 700 "$CFG/notify"
ok "$(run --status)" 0 "status is ok after the successes above"
ok "$(run --run --dest "$R/unplugged-drive")" 2 "a run to a missing drive fails"
ok "$(test -s "$CFG/state/last-failure" && echo yes || echo no)" yes "the failure is recorded"
ok "$(grep -c 'unplugged-drive' "$R/notified.txt" 2>/dev/null)" 1 "the notify hook got one message naming the problem"
ok "$(run --status)" 1 "status says STALE when a failure came after the last success"
ok "$(grep -c '^STALE: the last run failed' "$R/out")" 1 "and says why"
ok "$(run --list --dest "$R/also-missing")" 2 "a failed --list is refused"
ok "$(grep -c . "$R/notified.txt")" 1 "but only --run and --if-due notify"
sleep 1
ok "$(run --run --dest "$D")" 0 "the next good run succeeds"
ok "$(run --status)" 0 "and status is ok again"
sleep 1
ok "$(CLAUDE_ARCHIVE_STALE_HOURS=0 run --status)" 1 "status says STALE once the newest success is older than the limit"

# 12e. optional phone notes through ntfy.env, against a stubbed curl that records what it was given (no network)
mkdir -p "$R/bin"
cat > "$R/bin/curl" <<'EOS'
#!/bin/sh
printf '%s\n' "$*" >> "$CURL_STUB_DIR/curl.args"
{ cat; echo '----'; } >> "$CURL_STUB_DIR/curl.cfg"
exit "${CURL_STUB_EXIT:-0}"
EOS
chmod 755 "$R/bin/curl"
export CURL_STUB_DIR="$R"
nrun() { PATH="$R/bin:$PATH" run "$@"; }
calls() { cat "$R/curl.args" 2>/dev/null | grep -c .; }
NE="$CFG/ntfy.env"; TOPIC="cpa-topic-""Zq81"; TOKEN="tk_cpa""selftestTOKEN0000000000000"
ok "$(nrun --notify-test)" 2 "notify-test without ntfy.env is refused"
ok "$(calls)" 0 "and curl is not called"
printf '# phone notes\nNTFY_URL=https://ntfy.example.invalid/\nNTFY_TOPIC=%s\nNTFY_TOKEN="%s"\n' "$TOPIC" "$TOKEN" > "$NE"; chmod 644 "$NE"
ok "$(nrun --notify-test)" 2 "a 644 ntfy.env is refused"
ok "$(grep -c 'mode 644' "$R/out")" 1 "and the reason names the mode"
ok "$(grep -c "$TOPIC" "$R/out")" 0 "the refusal does not print the topic"
printf 'n1\n' >> "$P/-Users-x-code-repo1/a.jsonl"
ok "$(nrun --run --full --dest "$D")" 0 "a full run with a 644 ntfy.env still succeeds"
ok "$(calls)" 0 "and nothing is sent"
chmod 600 "$NE"
ok "$(nrun --notify-test)" 0 "notify-test with a 600 ntfy.env sends"
ok "$(calls)" 1 "curl called once"
ok "$(grep -c "^url = \"https://ntfy.example.invalid/$TOPIC\"$" "$R/curl.cfg")" 1 "to NTFY_URL/NTFY_TOPIC, trailing slash trimmed"
ok "$(grep -c "^header = \"Authorization: Bearer $TOKEN\"$" "$R/curl.cfg")" 1 "with the token as a Bearer header (quotes stripped)"
ok "$(grep -c -e "$TOPIC" -e "$TOKEN" "$R/curl.args")" 0 "neither topic nor token is on curl's command line"
ok "$(grep -c -e "$TOPIC" -e "$TOKEN" "$R/out")" 0 "and neither is printed"
ok "$(nrun --status)" 0 "status still ok"
ok "$(grep -c '^phone notes (ntfy): on, with a token' "$R/out")" 1 "status says phone notes are on"
: > "$R/curl.args"; : > "$R/curl.cfg"
printf 'n2\n' >> "$P/-Users-x-code-repo1/a.jsonl"
ok "$(nrun --run --dest "$D")" 0 "an incremental succeeds"
ok "$(grep -c '^incr archive' "$R/out")" 1 "(it is an incremental)"
ok "$(calls)" 0 "and sends nothing"
ok "$(nrun --run --dest "$D")" 0 "a nothing-changed run succeeds"
ok "$(calls)" 0 "and sends nothing"
ok "$(nrun --run --full --dest "$D")" 0 "a full run succeeds"
ok "$(calls)" 1 "and sends one note"
ok "$(grep -c '^header = "Title: Claude archive: full copy sealed"$' "$R/curl.cfg")" 1 "titled as a full copy"
NEWF="$(find "$D" -name '*_full.tar.gz.enc' | sort | tail -n 1)"
ok "$(grep '^data-raw' "$R/curl.cfg" | grep -c "$(basename "$NEWF")")" 1 "naming the archive"
ok "$(grep '^data-raw' "$R/curl.cfg" | grep -c '/')" 0 "and no path"
: > "$R/curl.args"; : > "$R/curl.cfg"
ok "$(nrun --run --dest "$R/unplugged-again")" 2 "a failed run keeps its exit code with ntfy on"
ok "$(calls)" 1 "and sends one note"
ok "$(grep -c '^header = "Title: Claude archive failed"$' "$R/curl.cfg")" 1 "titled as a failure"
ok "$(grep -c '^header = "Priority: high"$' "$R/curl.cfg")" 1 "at high priority"
ok "$(grep '^data-raw' "$R/curl.cfg" | grep -c -e "$R" -e 'unplugged-again' -e '/')" 0 "the reason carries no path or folder name"
ok "$(grep '^data-raw' "$R/curl.cfg" | grep -c '<path>')" 1 "the path is shown as <path>"
: > "$R/curl.args"; : > "$R/curl.cfg"
printf 'n3\n' >> "$P/-Users-x-code-repo1/a.jsonl"
ok "$(CURL_STUB_EXIT=7 nrun --run --full --dest "$D")" 0 "an unreachable ntfy does not fail a good run"
ok "$(grep -c 'did not take the note' "$R/out")" 1 "it says so once, quietly"
ok "$(CURL_STUB_EXIT=7 nrun --run --dest "$R/unplugged-again")" 2 "nor change a failed run's exit code"
ok "$(CURL_STUB_EXIT=7 nrun --notify-test)" 1 "notify-test reports an unreachable server"
: > "$R/curl.args"; : > "$R/curl.cfg"
printf 'NTFY_TOPIC=%s\n' "$TOPIC" > "$NE"
ok "$(nrun --notify-test)" 0 "a topic alone works (default URL, no token)"
ok "$(grep -c '^url = "https://ntfy.sh/' "$R/curl.cfg")" 1 "the default URL is https://ntfy.sh"
ok "$(grep -c 'Authorization' "$R/curl.cfg")" 0 "and no Authorization header without a token"
printf 'NTFY_URL=http://ntfy.example.invalid\nNTFY_TOPIC=%s\n' "$TOPIC" > "$NE"
ok "$(nrun --notify-test)" 2 "a plain http NTFY_URL is refused"
printf 'NTFY_TOPIC=has/slash\n' > "$NE"
ok "$(nrun --notify-test)" 2 "a topic with a slash is refused"
printf 'NTFY_TOPIC=%s\nNTFY_TOKEN=tk_x;touch %s/sourced\n' "$TOPIC" "$R" > "$NE"
ok "$(nrun --notify-test)" 2 "a token with stray characters is refused"
ok "$(test -e "$R/sourced" && echo ran || echo read)" read "ntfy.env is read as data, never run"
printf 'NTFY_TOPIC=%s\n' "$TOPIC" > "$R/elsewhere.env"; chmod 600 "$R/elsewhere.env"; mv "$NE" "$R/ntfy.env.retired"; ln -s "$R/elsewhere.env" "$NE"
ok "$(nrun --notify-test)" 2 "a symlinked ntfy.env is refused"
mv "$NE" "$R/ntfy.env.link.retired"; mv "$R/elsewhere.env" "$NE"
: > "$R/curl.args"
ok "$(CLAUDE_ARCHIVE_NO_NTFY=1 nrun --run --dest "$R/unplugged-again")" 2 "CLAUDE_ARCHIVE_NO_NTFY=1 on a failed run"
ok "$(calls)" 0 "sends nothing"
mv "$NE" "$R/ntfy.env.done"
sleep 1
ok "$(run --run --dest "$D")" 0 "a good run after the failures above, so status is ok again"

dec() { /usr/bin/openssl enc -d -aes-256-cbc -pbkdf2 -iter 600000 -md sha256 -pass "file:$CFG/passphrase" -in "$1"; }
entries() { dec "$1" | tar -tzf - | sort | tr '\n' '|'; }
mtime() { stat -f %Fm "$1" 2>/dev/null || stat -c %Y "$1"; }

# 12f. history.jsonl, plans/ and file-history/ join the archive. A chain begun before they were archived (made here
# while they are absent) carries on: the next run is an ordinary incremental that holds them, and it restores whole.
D2="$R/dest-inputs"; mkdir -p "$D2"
n_proj="$(cd "$H" && find .claude/projects \( -type f -o -type l \) | wc -l | tr -d ' ')"
ok "$(run --run --dest "$D2")" 0 "a chain begun before the new inputs: its first full"
F2="$(find "$D2" -name '*_full.tar.gz.enc')"
ok "$(run --verify "$F2")" 0 "verify that full"
ok "$(grep -c "ok .*: $((n_proj + 1)) entries, sha256 matches" "$R/out")" 1 "it holds the projects and CLAUDE.md, nothing more"
mkdir -p "$H/.claude/plans" "$H/.claude/file-history/sess-1"
printf '# a plan\n' > "$H/.claude/plans/quiet-plan.md"
printf 'snapshot\n' > "$H/.claude/file-history/sess-1/abc123@v1"
printf '{"display":"%s prompt","timestamp":1,"project":"/x"}\n' "$SENT" > "$H/.claude/history.jsonl"
mkdir -p "$H/.claude/debug"; printf 'not archived\n' > "$H/.claude/debug/log.txt"
# old modification times, so only the listing can find them: the stamp test alone would pass them by
touch -t 202001010000 "$H/.claude/plans/quiet-plan.md" "$H/.claude/file-history/sess-1/abc123@v1" "$H/.claude/history.jsonl"
ok "$(run --run --dest "$D2")" 0 "the first run after the change succeeds"
ok "$(grep -c '^incr archive' "$R/out")" 1 "it is an ordinary incremental"
ok "$(grep -c ': 3 files,' "$R/out")" 1 "holding the three new files, though their times are older than the stamp"
I2b="$(find "$D2" -name '*_incr.tar.gz.enc')"
ok "$(run --verify "$I2b")" 0 "verify that incremental"
ok "$(grep -c ': 3 entries, sha256 matches' "$R/out")" 1 "its count matches"
ok "$(entries "$I2b")" ".claude/file-history/sess-1/abc123@v1|.claude/history.jsonl|.claude/plans/quiet-plan.md|" "paths relative to home, as before"
ok "$(grep -c "$SENT" "$I2b")" 0 "history.jsonl is sealed like the rest"
ok "$(run --restore-latest --dest "$D2" "$R/restored-inputs")" 0 "restore-latest across the change"
ok "$(diff -r "$P" "$R/restored-inputs/.claude/projects" >/dev/null && echo same || echo differ)" same "projects come back"
ok "$(cmp -s "$H/.claude/history.jsonl" "$R/restored-inputs/.claude/history.jsonl" && echo same || echo differ)" same "history.jsonl comes back"
ok "$(diff -r "$H/.claude/plans" "$R/restored-inputs/.claude/plans" >/dev/null && echo same || echo differ)" same "plans/ comes back"
ok "$(diff -r "$H/.claude/file-history" "$R/restored-inputs/.claude/file-history" >/dev/null && echo same || echo differ)" same "file-history/ comes back"
ok "$(test -e "$R/restored-inputs/.claude/debug" -o -e "$R/restored-inputs/.claude/settings.json" && echo yes || echo no)" no "and nothing else of ~/.claude"
ok "$(run --run --dest "$D2")" 0 "the run after that"
ok "$(grep -c '^Nothing changed' "$R/out")" 1 "finds nothing new (the listing now holds them)"
printf '{"display":"one more","timestamp":2}\n' >> "$H/.claude/history.jsonl"
ok "$(run --run --dest "$D2")" 0 "a new prompt in history.jsonl"
ok "$(grep -c ': 1 files,' "$R/out")" 1 "travels in the next incremental, whole"
ok "$(run --run --full --dest "$D2")" 0 "a full after the change"
F2b="$(find "$D2" -name '*_full.tar.gz.enc' | sort | tail -n 1)"
ok "$(run --verify "$F2b")" 0 "verify it"
ok "$(grep -c "ok .*: $((n_proj + 4)) entries" "$R/out")" 1 "it holds the projects, CLAUDE.md and the three new inputs"
ok "$(run --restore-latest --dest "$D2" "$R/restored-inputs2")" 0 "restore-latest from the new full"
ok "$(cmp -s "$H/.claude/history.jsonl" "$R/restored-inputs2/.claude/history.jsonl" && echo same || echo differ)" same "history.jsonl with its new line"

# 12g. --source DIR --name NAME: another folder, its own chain, into the same destination as the Claude chain
N="$R/src/My Notes"; mkdir -p "$N/sub"
printf '%s note\n' "$SENT" > "$N/a.md"; printf 'b\n' > "$N/sub/b.md"; printf 's\n' > "$N/with space.md"
SC="$(statedir "$D")"; c_stamp="$(mtime "$SC/stamp")"; c_n="$(count "$D" 'claude-projects_*.enc')"
srun() { run "$@" --source "$N" --name notes --dest "$D"; }
ok "$(srun --run)" 0 "a --source run succeeds"
ok "$(grep -c '^full archive (first run' "$R/out")" 1 "its first run is full"
NF="$(find "$D/notes" -name 'notes_*_full.tar.gz.enc')"
ok "$(echo "$NF" | grep -c .)" 1 "one full, named notes_..._full.tar.gz.enc"
ok "$(dirname "$NF")" "$D/notes/$(date +%Y)" "written into <dest>/notes/YYYY"
ok "$(mode "$NF")" 600 "mode 600"
ok "$(test -f "$NF.sha256" && echo yes || echo no)" yes "with its .sha256"
ok "$(grep -c "$SENT" "$NF")" 0 "ciphertext: the sentinel is not readable in it"
ok "$(srun --verify "$NF")" 0 "--verify with --source"
ok "$(grep -c ': 3 entries, sha256 matches' "$R/out")" 1 "three entries"
ok "$(entries "$NF")" "My Notes/a.md|My Notes/sub/b.md|My Notes/with space.md|" "paths relative to DIR's parent"
printf 'more\n' >> "$N/a.md"; mkdir -p "$N/new"; printf 'n\n' > "$N/new/c.md"
ok "$(srun --run)" 0 "a --source incremental"
ok "$(grep -c '^incr archive' "$R/out")" 1 "is incremental"
ok "$(grep -c ': 2 files,' "$R/out")" 1 "holding the two changed files"
mv "$N/sub" "$N/sub-renamed"
ok "$(srun --run)" 0 "after a rename inside DIR"
ok "$(grep -c ': 1 files,' "$R/out")" 1 "the renamed folder's file travels"
ok "$(srun --if-due)" 0 "--if-due with --source"
ok "$(grep -c '^not due' "$R/out")" 1 "is not due"
ok "$(srun --list)" 0 "--list with --source"
ok "$(grep -c ' full$' "$R/out")/$(grep -c ' incremental$' "$R/out")" 1/2 "lists its own full and two incrementals"
ok "$(grep -c 'claude-projects_' "$R/out")" 0 "and none of the Claude chain's"
ok "$(srun --restore-latest "$R/notes-restored")" 0 "--restore-latest with --source"
ok "$(diff -r -x sub "$N" "$R/notes-restored/My Notes" >/dev/null && echo same || echo differ)" same "the folder comes back as it is now"
ok "$(test -d "$R/notes-restored/My Notes/sub" && echo yes || echo no)" yes "with the renamed folder's old name too (archives remember)"
ok "$(srun --status)" 0 "--status with --source is ok"
ok "$(srun --run --full)" 0 "--run --full with --source"
ok "$(count "$D/notes" 'notes_*_full.tar.gz.enc')" 2 "two fulls in the notes chain"
ok "$(srun --prune-plan 1)" 0 "--prune-plan with --source"
ok "$(grep -c '_full.tar.gz.enc$' "$R/out")/$(grep -c '_incr.tar.gz.enc$' "$R/out")" 1/2 "would move the older full and its incrementals"
ok "$(grep -c 'claude-projects_' "$R/out")" 0 "and nothing of the Claude chain"
M2="$R/drive2"; mkdir -p "$M2"; s_before="$(count "$D/notes" '*.enc')"
ok "$(srun --move-old 1 "$M2")" 0 "--move-old with --source"
ok "$(count "$M2/notes/$(date +%Y)" 'notes_*.enc')" 3 "moves the older chain into DRIVE/notes/YYYY"
ok "$(( $(count "$D/notes" '*.enc') + $(count "$M2" '*.enc') ))" "$s_before" "none lost"
ok "$(run --restore-latest --dest "$M2" --source "$N" --name notes "$R/notes-from-drive")" 0 "the moved chain restores from the drive"
ok "$(diff -r -x sub "$N" "$R/notes-from-drive/My Notes" >/dev/null && echo same || echo differ)" same "and matches (the old name aside)"
ok "$(run --restore-latest --dest "$D" --source "$R/notes-gone" --name notes "$R/notes-without-dir")" 0 "a restore needs only the name when DIR is gone"
ok "$(diff -r "$N" "$R/notes-without-dir/My Notes" >/dev/null && echo same || echo differ)" same "and matches"

# 12h. the two chains leave each other alone
ok "$(count "$D" 'claude-projects_*.enc')" "$c_n" "the Claude chain's archives are untouched by the notes chain"
ok "$(mtime "$SC/stamp")" "$c_stamp" "and its stamp did not move"
ok "$(test -d "$CFG/sources/notes" && echo yes || echo no)" yes "the notes chain keeps its state in sources/notes"
ok "$(run --list --dest "$D")" 0 "the Claude --list"
ok "$(grep -c 'notes_' "$R/out")" 0 "shows nothing of the notes chain"
ok "$(run --restore-latest --dest "$D" "$R/claude-after-notes")" 0 "the Claude chain still restores"
ok "$(diff -r "$P" "$R/claude-after-notes/.claude/projects" >/dev/null && echo same || echo differ)" same "and matches"
ok "$(test -e "$R/claude-after-notes/My Notes" && echo yes || echo no)" no "with nothing of the notes folder in it"
ok "$(run --run --dest "$D")" 0 "a Claude run after the notes runs"
ok "$(entries "$(find "$D/$(date +%Y)" -name 'claude-projects_*.enc' | sort | tail -n 1)" | grep -c 'My Notes')" 0 "holds nothing of the notes folder"
c_lf="$(cat "$CFG/state/last-failure")"
sleep 1
ok "$(run --run --source "$N" --name notes --dest "$R/unplugged-notes")" 2 "a notes run to a missing drive fails"
ok "$(test -s "$CFG/sources/notes/last-failure" && echo yes || echo no)" yes "recorded in the notes chain's own state"
ok "$(cat "$CFG/state/last-failure")" "$c_lf" "not in the Claude chain's"
ok "$(srun --status)" 1 "the notes --status says STALE"
ok "$(run --status)" 0 "the Claude --status stays ok"
sleep 1
ok "$(srun --run)" 0 "a good notes run"
ok "$(srun --status)" 0 "and the notes status is ok again"
ok "$(run --run --dest "$R/unplugged-claude")" 2 "a Claude run to a missing drive fails"
ok "$(srun --status)" 0 "the notes --status stays ok"
sleep 1
ok "$(run --run --dest "$D")" 0 "a good Claude run, so its status is ok again"

# 12i. what --source and --name refuse, before anything is written
nD="$(count "$D" '*')"; c_lf="$(cat "$CFG/state/last-failure")"
ok "$(run --run --source "$N" --dest "$D")" 2 "--source without --name is refused"
ok "$(grep -c 'go together' "$R/out")" 1 "and says why"
ok "$(run --run --name notes --dest "$D")" 2 "--name without --source is refused"
for bad in 'bad/name' 'has space' 'dot.name' '-lead' '2026' 'claude-projects' 'claude-projects_x' \
           "$(printf 'n%.0s' 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65)"; do
  ok "$(run --run --source "$N" --name "$bad" --dest "$D")" 2 "--name '$(printf '%s' "$bad" | cut -c1-20)' is refused"
done
ok "$(test -e "$CFG/sources/bad" && echo made || echo absent)" absent "a refused name makes no state folder"
ok "$(run --run --source "$R/no-such-folder" --name nope --dest "$D")" 2 "a --source that does not exist is refused"
mkdir -p "$H/.claude/somewhere"; ln -s "$H/.claude/somewhere" "$R/sneaky-src"
ok "$(run --run --source "$H/.claude/somewhere" --name inner --dest "$D")" 2 "a --source inside ~/.claude is refused"
ok "$(run --run --source "$R/sneaky-src" --name inner --dest "$D")" 2 "a --source that is a symlink into ~/.claude is refused"
ok "$(run --run --source "$H" --name home --dest "$D")" 2 "a --source that holds ~/.claude is refused"
ok "$(run --run --source "$CFG" --name config --dest "$D")" 2 "a --source that holds the passphrase is refused"
ok "$(run --run --source "$D" --name dest --dest "$D")" 2 "a --source that is the destination is refused"
mkdir -p "$R/outer/dest-in"
ok "$(run --run --source "$R/outer" --name outer --dest "$R/outer/dest-in")" 2 "a --source that holds the destination is refused"
ok "$(count "$R/outer/dest-in" '*')" 0 "and writes nothing there"
mkdir -p "$D/inner"
ok "$(run --run --source "$D/inner" --name inner --dest "$D")" 2 "a --source inside the destination is refused"
ok "$(run --install --source "$N" --name notes)" 2 "--install with --source is refused (the Claude chain only)"
ok "$(grep -c 'LaunchAgent of your own' "$R/out")" 1 "and points to the walkthrough's own-LaunchAgent line"
ok "$(run --uninstall --source "$N" --name notes)" 2 "--uninstall with --source is refused"
ok "$(run --init --source "$N" --name notes)" 2 "--init with --source is refused"
ok "$(run --restore "$F1" --source "$N" --name notes "$R/wrong-chain")" 2 "a Claude archive is not restored as a notes archive"
NF2="$(find "$D/notes" -name 'notes_*_full.tar.gz.enc' | sort | tail -n 1)"
ok "$(run --restore "$NF2" "$R/wrong-chain2")" 2 "nor a notes archive as a Claude archive"
ok "$(srun --restore "$NF2" "$N/restore-here")" 2 "a restore into DIR itself is refused"
ok "$(test -e "$N/restore-here" && echo made || echo absent)" absent "and makes nothing there"
ok "$(count "$D" '*')" "$nD" "no refusal wrote anything at the destination"
ok "$(cat "$CFG/state/last-failure")" "$c_lf" "no refusal of a --source command marked the Claude chain as failed"
ok "$(run --status)" 0 "the Claude status is still ok"

# 13. install and uninstall render only (no launchctl in the self-test)
ok "$(run --install)" 0 "install renders the plist"
PL="$H/Library/LaunchAgents/com.drasticstatic.claude-projects-archive.plist"
ok "$(plutil -lint "$PL" >/dev/null 2>&1 && echo ok || echo bad)" ok "the plist lints"
ok "$(plutil -extract StartCalendarInterval.Hour raw "$PL")" 0 "at hour 0"
ok "$(plutil -extract StartCalendarInterval.Minute raw "$PL")" 40 "minute 40"
ok "$(basename "$(plutil -extract ProgramArguments.0 raw "$PL")")" claude-projects-archive "run by its named launcher, so Login Items does not show sh"
ok "$(plutil -extract ProgramArguments.1 raw "$PL")" --if-due "with --if-due"
ok "$(plutil -extract StandardOutPath raw "$PL")" "$H/Library/Logs/claude-projects-archive/archive.log" "logs in ~/Library/Logs/claude-projects-archive/"
ok "$(run --install)" 0 "installing the same again succeeds"
ok "$(ls "$CFG/retired" 2>/dev/null | grep -c '\.plist$')" 0 "an identical plist is not moved aside"
ok "$(run --install --dest "$D")" 0 "install with a --dest"
PLD="$(ls "$H"/Library/LaunchAgents/com.drasticstatic.claude-projects-archive.dest-*.plist 2>/dev/null | head -n 1)"
ok "$(test -n "$PLD" && test -e "$PL" && echo both || echo one)" both "a --dest gets its own plist beside the default one"
ok "$(plutil -extract ProgramArguments.3 raw "$PLD")" "$D" "the --dest is carried into its plist"
ok "$(plutil -extract StandardOutPath raw "$PLD" | grep -c 'dest-.*\.log$')" 1 "and its own log file"
ok "$(run --uninstall --dest "$D")" 0 "uninstall the --dest schedule"
ok "$(test -e "$PLD" && echo there || echo gone)/$(test -e "$PL" && echo there || echo gone)" gone/there "only that plist left LaunchAgents"
ok "$(run --uninstall)" 0 "uninstall the default"
ok "$(test -e "$PL" && echo there || echo gone)" gone "the plist left LaunchAgents"
ok "$(ls "$CFG/retired" | grep -c '\.plist$')" 2 "both were moved aside, not deleted"

# 14. usage
ok "$(run)" 2 "no mode prints usage and exits 2"
ok "$(run --verify)" 2 "verify without a file is refused"
ok "$(run --bogus)" 2 "an unknown option is refused"

echo "claude-projects-archive selftest: $pass passed, $fail failed  (scratch: $R)"
[ "$fail" -eq 0 ]
