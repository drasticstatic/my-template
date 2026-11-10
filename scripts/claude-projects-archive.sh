#!/bin/sh
# claude-projects-archive.sh: a nightly, encrypted snapshot of ~/.claude/projects (and ~/.claude/CLAUDE.md), written as
# finished files into iCloud Drive or any folder you name. The live ~/.claude never lives in iCloud; only sealed
# archives of it do. Walkthrough: walkthroughs/CLAUDE-PROJECTS-ARCHIVE.md
#
#     sh scripts/claude-projects-archive.sh --init              once: make the passphrase file (never shown)
#     sh scripts/claude-projects-archive.sh --run               archive now: full, or incremental since the last success
#     sh scripts/claude-projects-archive.sh --run --full        archive now, a full one whatever the date
#     sh scripts/claude-projects-archive.sh --if-due            --run, but only if the last success is over 20 hours old
#     sh scripts/claude-projects-archive.sh --status            did the last run work? exit 1 if stale (36 h) or it failed
#     sh scripts/claude-projects-archive.sh --list              every archive at the destination, with sizes and the total
#     sh scripts/claude-projects-archive.sh --verify FILE       check its .sha256, decrypt to a pipe, read the tar; write nothing
#     sh scripts/claude-projects-archive.sh --restore FULL [INCR ...] DIR   into a new, empty DIR, in that order
#     sh scripts/claude-projects-archive.sh --restore-latest DIR            the newest full and every incremental after it
#     sh scripts/claude-projects-archive.sh --prune-plan KEEP   what keeping the last KEEP fulls WOULD move aside; changes nothing
#     sh scripts/claude-projects-archive.sh --move-old KEEP DIR the older chains moved (never deleted) to DIR, e.g. a drive
#     sh scripts/claude-projects-archive.sh --install           a LaunchAgent at 00:40 nightly (runs --if-due); you run this
#     sh scripts/claude-projects-archive.sh --uninstall         unload it; the plist is moved aside, not deleted
#     sh scripts/claude-projects-archive.sh --notify-test       send one test phone note through ntfy.env (below)
#     sh scripts/claude-projects-archive.selftest.sh            prove all of it against a fake home in a temporary folder
#
# Any mode takes --dest DIR (or CLAUDE_ARCHIVE_DEST=DIR). The default is iCloud Drive:
#     ~/Library/Mobile Documents/com~apple~CloudDocs/Backups/claude-projects/YYYY/
# A --dest folder must already exist (an unplugged drive must not become a folder on the boot disk); the YYYY folder
# inside it is made as needed. A destination inside ~/.claude is refused, symlinks followed.
#
# How a run works:
#   - Full on the first run for a destination, on the first run of each calendar month (the 1st, or the first night the
#     Mac is on after it), and with --full. Otherwise incremental: every file under ~/.claude/projects, and CLAUDE.md,
#     whose modification time is newer than the stamp of the last successful run, plus every path that was not in the
#     last run's listing (a folder renamed by rename-local-repo.py keeps its files' old times, so the time test alone
#     would miss it; the listing is state/<dest>/paths). A changed transcript travels whole.
#   - tar | gzip | openssl enc -aes-256-cbc -pbkdf2 -iter 600000 -md sha256 -salt, the passphrase passed as a file path
#     (-pass file:), never on the command line or in the environment. /usr/bin/openssl (LibreSSL) by default; the format
#     opens with OpenSSL 3 too (tested both ways, Nov 6, 2026).
#   - Written as NAME.partial at the destination, then decrypted again and its tar listing counted against the file list,
#     then its .sha256 written beside it, then renamed to NAME. The stamp advances only after all of that.
#   - Names sort in the order they were made: claude-projects_YYYYMMDD-HHMMSS_full.tar.gz.enc, ..._incr.tar.gz.enc.
#     (The time is in the name so two runs on one day never collide and a plain sort is the restore order.)
#   - Paths inside the archive are relative to your home: .claude/projects/... and .claude/CLAUDE.md.
#   - Nothing is excluded: the tree is transcripts, memory and the fleet's manifests, and all of it is wanted back.
#   - Keep everything: no archive is ever deleted. --prune-plan only prints a plan.
#   - The only files the script ever removes are ones it made in the same run: a failed run's NAME.partial. The lock is
#     a pid file that is emptied, not removed.
#   - State (the stamp, the last success, the last full's month, a history.tsv) lives in ~/.config/claude-archive/state/,
#     one folder per destination, so switching destinations starts a fresh chain with a full.
#
# Files (CLAUDE_ARCHIVE_CONFIG moves the folder, CLAUDE_ARCHIVE_PASSFILE the passphrase alone):
#   ~/.config/claude-archive/            mode 700
#   ~/.config/claude-archive/passphrase  mode 600 (or 400), written by --init; copy it into your password manager
#   ~/.config/claude-archive/ntfy.env    optional, mode 600 exactly, you write it: phone notes through ntfy (below)
#
# Optional phone notes through ntfy (https://ntfy.sh, or a self-hosted ntfy). Off unless ntfy.env exists. It holds
# plain KEY=value lines, read as data (never sourced):
#     NTFY_URL=https://ntfy.sh        optional; https only; the default is https://ntfy.sh
#     NTFY_TOPIC=<a long random name>  required; letters, digits, - and _, up to 64
#     NTFY_TOKEN=tk_...                optional; an access token, needed once the topic is reserved or the server has auth
# It is not read at all unless it is a plain file you own with mode 600 (a warning is printed instead, and no note is
# sent). One short note is sent when a --run or --if-due fails, and one when a full archive (the monthly one, the first
# for a destination, or --full) is sealed and verified; never for a routine incremental or a "not due". A note carries
# the host, the exit code and the reason with every word that holds a "/" replaced by <path>, or the archive's own name
# and size; never another file name or path. The topic and token travel to curl on its stdin (-K -), never on a command
# line. If ntfy cannot be reached the run's own result and exit code are unchanged. CLAUDE_ARCHIVE_NO_NTFY=1 turns it off.
#
# Optional, opt-in "backup upon commit" (not wired into any hook by this script or the fleet). In a repository of your
# choosing, add this one line to its post-commit hook (.git/hooks/post-commit, or the folder core.hooksPath names):
#     ( sh "$HOME/code/my-template/scripts/claude-projects-archive.sh" --if-due >/dev/null 2>&1 & )
# It is backgrounded, so the commit does not wait, and --if-due makes it a no-op on all but the first commit after 20 hours.
#
# Exit codes: 0 done (or not due) · 1 a run, verify or restore failed · 2 refused (usage, a check that protects you).
# macOS tools only: sh, find, tar (bsdtar), gzip inside tar, openssl, shasum, stat, launchctl, plutil.

set -u
umask 077
if ! (set -o pipefail) 2>/dev/null; then echo "claude-projects-archive: this sh has no 'set -o pipefail'; run it with /bin/sh" >&2; exit 2; fi
set -o pipefail
LC_ALL=C; export LC_ALL
MODE=""

LABEL="com.drasticstatic.claude-projects-archive"
ITER=600000
DUE_HOURS=20
OPENSSL="${CLAUDE_ARCHIVE_OPENSSL:-/usr/bin/openssl}"
[ -x "$OPENSSL" ] || OPENSSL="$(command -v openssl 2>/dev/null || true)"
CONFIG="${CLAUDE_ARCHIVE_CONFIG:-$HOME/.config/claude-archive}"
PASSFILE="${CLAUDE_ARCHIVE_PASSFILE:-$CONFIG/passphrase}"
ICLOUD="$HOME/Library/Mobile Documents/com~apple~CloudDocs"
DEFAULT_DEST="$ICLOUD/Backups/claude-projects"
CLAUDE_DIR="$HOME/.claude"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
LOGDIR="$HOME/Library/Logs/claude-projects-archive"
SELF="$(cd "$(dirname "$0")" && pwd -P)/$(basename "$0")"

say() { printf '%s\n' "$*"; }
LASTERR=""
warn() { LASTERR="$*"; printf 'claude-projects-archive: %s\n' "$*" >&2; }
refuse() { warn "refused: $*"; exit 2; }
fail() { warn "failed: $*"; exit 1; }

if stat -f %z / >/dev/null 2>&1; then BSDSTAT=1; else BSDSTAT=0; fi
mode_of() { if [ "$BSDSTAT" = 1 ]; then stat -f %Lp "$1"; else stat -c %a "$1"; fi; }
size_of() { if [ "$BSDSTAT" = 1 ]; then stat -f %z "$1"; else stat -c %s "$1"; fi; }
human() { awk -v b="$1" 'BEGIN { split("B KB MB GB TB", u, " "); i = 1; while (b >= 1024 && i < 5) { b /= 1024; i++ }
                                 if (i == 1) printf "%d %s", b, u[i]; else printf "%.1f %s", b, u[i] }'; }
dir_bytes() { [ -d "$1" ] || { echo 0; return; }; du -sk "$1" 2>/dev/null | awk '{ print $1 * 1024 }'; }

# The physical path of $1, following symlinks, even when its last parts do not exist yet.
physpath() {
  _p="$1"; _rest=""
  case "$_p" in /*) ;; *) _p="$(pwd -P)/$_p" ;; esac
  while [ ! -d "$_p" ]; do _rest="/$(basename "$_p")$_rest"; _p="$(dirname "$_p")"; done
  _p="$(cd "$_p" && pwd -P)"; [ "$_p" = / ] && _p=""
  printf '%s%s\n' "$_p" "$_rest"
}
# True when name $1 sorts strictly before name $2 (byte order; POSIX test has no string less-than).
before() { [ "$1" != "$2" ] && printf '%s\n%s\n' "$1" "$2" | sort -c 2>/dev/null; }
# True when $1 is $2 or lies inside it (both physical).
inside() { case "$1/" in "$2"/*) return 0 ;; esac; return 1; }

check_passfile() {
  [ -e "$PASSFILE" ] || refuse "no passphrase file at $PASSFILE. Run --init first (you run it yourself, once)."
  [ -f "$PASSFILE" ] && [ ! -L "$PASSFILE" ] || refuse "$PASSFILE is not a plain file."
  [ -O "$PASSFILE" ] || refuse "$PASSFILE is not owned by you."
  _m="$(mode_of "$PASSFILE")"
  case "$_m" in 600|400) ;; *) refuse "$PASSFILE is mode $_m; it must be 600 (chmod 600 '$PASSFILE')." ;; esac
  [ -s "$PASSFILE" ] || refuse "$PASSFILE is empty."
  [ -n "$OPENSSL" ] && [ -x "$OPENSSL" ] || refuse "openssl not found."
}

# Decrypt $1 to stdout.
decrypt() { "$OPENSSL" enc -d -aes-256-cbc -pbkdf2 -iter "$ITER" -md sha256 -pass "file:$PASSFILE" -in "$1"; }

# Resolve the destination. $1 = create (make the folders) or look (change nothing).
resolve_dest() {
  if [ -n "$OPT_DEST" ]; then
    DEST_BASE="$OPT_DEST"
    [ -d "$DEST_BASE" ] || refuse "--dest $DEST_BASE does not exist. Make it yourself (or plug the drive in) first."
  else
    DEST_BASE="$DEFAULT_DEST"
    [ -d "$ICLOUD" ] || refuse "iCloud Drive is not at $ICLOUD. Pass --dest DIR (an external drive, any folder)."
    [ "$1" = create ] && { mkdir -p "$DEST_BASE" || fail "cannot make $DEST_BASE"; }
  fi
  DEST_PHYS="$(physpath "$DEST_BASE")"
  CLAUDE_PHYS="$(physpath "$CLAUDE_DIR")"
  if inside "$DEST_PHYS" "$CLAUDE_PHYS"; then refuse "the destination $DEST_BASE is inside ~/.claude ($CLAUDE_PHYS)."; fi
  if inside "$CLAUDE_PHYS" "$DEST_PHYS"; then refuse "the destination $DEST_BASE contains ~/.claude; an archive would archive itself."; fi
  STATE="$CONFIG/state/$(printf '%s' "$DEST_PHYS" | cksum | awk '{ print $1 }')"
}

state_init() {
  mkdir -p "$CONFIG" && chmod 700 "$CONFIG" || fail "cannot make $CONFIG"
  mkdir -p "$STATE/work" || fail "cannot make $STATE"
  printf '%s\n' "$DEST_PHYS" > "$STATE/dest"
}

LOCKED=0
take_lock() {
  _lk="$STATE/lock"
  if [ -s "$_lk" ]; then
    _pid="$(cat "$_lk")"
    if [ -n "$_pid" ] && kill -0 "$_pid" 2>/dev/null; then say "another run (pid $_pid) is under way; leaving it be."; exit 0; fi
  fi
  printf '%s\n' "$$" > "$_lk"; LOCKED=1
}
PARTIAL=""

# ---------------------------------------------------------------------------------------------------------------- ntfy
NTFY_ENV="$CONFIG/ntfy.env"
ntfy_warn() { printf 'claude-projects-archive: ntfy: %s\n' "$*" >&2; }
# Sets N_URL, N_TOPIC, N_TOKEN from ntfy.env. Returns 1 when it is absent or turned off (silently), 2 when it is present
# but not safe or not valid (with one warning). Never prints the topic or the token.
ntfy_load() {
  N_URL=""; N_TOPIC=""; N_TOKEN=""
  [ "${CLAUDE_ARCHIVE_NO_NTFY:-0}" = 1 ] && return 1
  [ -e "$NTFY_ENV" ] || [ -L "$NTFY_ENV" ] || return 1
  if [ -L "$NTFY_ENV" ] || [ ! -f "$NTFY_ENV" ] || [ ! -O "$NTFY_ENV" ]; then
    ntfy_warn "$NTFY_ENV is not a plain file you own; not read, no phone note."; return 2
  fi
  _nm="$(mode_of "$NTFY_ENV")"
  [ "$_nm" = 600 ] || { ntfy_warn "$NTFY_ENV is mode $_nm; not read until it is 600 (chmod 600 '$NTFY_ENV'), no phone note."; return 2; }
  while IFS= read -r _l || [ -n "$_l" ]; do
    _l="$(printf '%s' "$_l" | tr -d '\r')"
    case "$_l" in ''|'#'*) continue ;; esac
    _l="${_l#export }"; _k="${_l%%=*}"; _v="${_l#*=}"
    [ "$_k" = "$_l" ] && continue
    case "$_v" in \"*\") _v="${_v#\"}"; _v="${_v%\"}" ;; \'*\') _v="${_v#\'}"; _v="${_v%\'}" ;; esac
    case "$_k" in NTFY_URL) N_URL="$_v" ;; NTFY_TOPIC) N_TOPIC="$_v" ;; NTFY_TOKEN) N_TOKEN="$_v" ;; esac
  done < "$NTFY_ENV"
  N_URL="${N_URL:-https://ntfy.sh}"; N_URL="${N_URL%/}"
  case "$N_URL" in https://?*) ;; *) ntfy_warn "NTFY_URL must start with https://; no phone note."; return 2 ;; esac
  case "$N_URL" in *[!A-Za-z0-9._:/~-]*) ntfy_warn "NTFY_URL holds characters it may not; no phone note."; return 2 ;; esac
  case "$N_TOPIC" in ''|*[!A-Za-z0-9_-]*) ntfy_warn "NTFY_TOPIC is missing or holds characters other than letters, digits, - and _; no phone note."; return 2 ;; esac
  [ "${#N_TOPIC}" -le 64 ] || { ntfy_warn "NTFY_TOPIC is longer than 64 characters; no phone note."; return 2; }
  case "$N_TOKEN" in *[!A-Za-z0-9_]*) ntfy_warn "NTFY_TOKEN holds characters a token does not; no phone note."; return 2 ;; esac
  return 0
}
# Every word holding a "/" becomes <path>, so a note never carries a file path.
ntfy_scrub() { printf '%s' "$1" | awk '{ for (i = 1; i <= NF; i++) if ($i ~ /\//) $i = "<path>"; print }'; }
# ntfy_send TITLE PRIORITY TAGS MESSAGE: 0 sent; 1 not set up, not safe, or ntfy unreachable. Never fatal, never loud.
ntfy_send() {
  ntfy_load || return 1
  command -v curl >/dev/null 2>&1 || { ntfy_warn "curl not found; no phone note."; return 1; }
  _nt="$(printf '%s' "$1" | tr -d '"\\\r\n' | cut -c1-120)"
  _nb="$(printf '%s' "$4" | tr '\r\n' '  ' | tr -d '"\\' | cut -c1-600)"
  # The URL (with the topic) and the token go to curl as a config on stdin, so neither shows in a process listing.
  if {
       printf 'url = "%s/%s"\n' "$N_URL" "$N_TOPIC"
       printf 'header = "Title: %s"\nheader = "Priority: %s"\nheader = "Tags: %s"\n' "$_nt" "$2" "$3"
       [ -n "$N_TOKEN" ] && printf 'header = "Authorization: Bearer %s"\n' "$N_TOKEN"
       printf 'data-raw = "%s"\n' "$_nb"
     } | curl -q -fs --max-time 10 -o /dev/null -K - >/dev/null 2>&1
  then return 0
  else ntfy_warn "the ntfy server did not take the note (unreachable, or the token or topic was refused); the run's result is unchanged."; return 1
  fi
}

# A failed --run or --if-due must not be silent (Nov 6 finding: macOS may block a background job from writing into
# iCloud Drive, and nothing would tell you). It is written to state/failures.tsv and last-failure, shown as a macOS
# banner (no prompt; CLAUDE_ARCHIVE_NO_BANNER=1 turns it off), and passed to ~/.config/claude-archive/notify if you made
# that file executable (for example, a one-line push to your phone). --status reads it back.
note_failure() {
  mkdir -p "$CONFIG/state" 2>/dev/null || return 0
  _msg="claude-projects-archive failed (exit $1) on $(hostname -s) at $(date '+%Y-%m-%d %H:%M'): ${LASTERR:-see the log}"
  date +%s > "$CONFIG/state/last-failure" 2>/dev/null
  printf '%s\t%s\t%s\n' "$(date +%Y%m%d-%H%M%S)" "$1" "${LASTERR:-}" >> "$CONFIG/state/failures.tsv" 2>/dev/null
  if [ "${CLAUDE_ARCHIVE_NO_BANNER:-0}" != 1 ] && command -v osascript >/dev/null 2>&1; then
    osascript -e "display notification \"$(printf '%s' "${LASTERR:-see the log}" | tr -d '"\\' | cut -c1-180)\" with title \"Claude archive failed\"" >/dev/null 2>&1 || true
  fi
  [ -x "$CONFIG/notify" ] && "$CONFIG/notify" "$_msg" >/dev/null 2>&1 || true
  ntfy_send "Claude archive failed" high warning \
    "On $(hostname -s), exit $1: $(ntfy_scrub "${LASTERR:-see the log}") Run --status, or read the log, for details." || true
}
on_exit() {
  _rc=$?
  if [ "$_rc" -ne 0 ] && { [ "$MODE" = --run ] || [ "$MODE" = --if-due ]; }; then note_failure "$_rc"; fi
  [ -n "$PARTIAL" ] && [ -e "$PARTIAL" ] && rm -f "$PARTIAL" && warn "removed this run's unfinished $(basename "$PARTIAL")"
  [ "$LOCKED" = 1 ] && : > "$STATE/lock"
}
trap on_exit EXIT
trap 'exit 1' INT TERM HUP

# Move $1 into the retired folder under a name nothing else has; never overwrites. Prints the new path.
retire() {
  mkdir -p "$CONFIG/retired" && chmod 700 "$CONFIG" || return 1
  _r="$CONFIG/retired/$LABEL.$(date +%Y%m%d-%H%M%S).plist"; _j=1
  while [ -e "$_r" ]; do _r="$CONFIG/retired/$LABEL.$(date +%Y%m%d-%H%M%S).$_j.plist"; _j=$((_j + 1)); done
  mv "$1" "$_r" && printf '%s\n' "$_r"
}

last_success() { [ -s "$STATE/last-success" ] && cat "$STATE/last-success" || echo 0; }

# ---------------------------------------------------------------------------------------------------------------- init
do_init() {
  mkdir -p "$CONFIG" && chmod 700 "$CONFIG" || fail "cannot make $CONFIG"
  if [ -e "$PASSFILE" ]; then
    say "$PASSFILE already exists; left as it is, and never shown."
  else
    [ -n "$OPENSSL" ] || fail "openssl not found"
    ( set -C; "$OPENSSL" rand -base64 33 > "$PASSFILE" ) || fail "cannot write $PASSFILE"
    chmod 600 "$PASSFILE"
    say "Wrote $PASSFILE (mode 600, 44 random characters). It is not shown here, on purpose."
  fi
  say ""
  say "Copy it into 1Password now (a Password item, e.g. 'claude-projects archive passphrase'), then clear the clipboard:"
  say ""
  say "    pbcopy < '$PASSFILE'"
  say "    pbcopy < /dev/null"
  say ""
  say "Reminder: without this passphrase the archives cannot be opened, by you or anyone. If this Mac is lost, the"
  say "copy in your password manager is the only key."
}

# ----------------------------------------------------------------------------------------------------------------- run
do_run() {
  check_passfile
  [ -d "$CLAUDE_DIR/projects" ] || refuse "there is no $CLAUDE_DIR/projects to archive."
  resolve_dest create
  state_init
  take_lock

  _t0="$(date +%s)"; _now="$(date +%Y%m%d-%H%M%S)"; _month="$(date +%Y%m)"; _year="$(date +%Y)"
  _kind=incr; _why="files changed since the last success"
  if [ ! -e "$STATE/stamp" ]; then _kind=full; _why="first run for this destination"
  elif [ "$(cat "$STATE/last-full" 2>/dev/null)" != "$_month" ]; then _kind=full; _why="first run of $_month"
  elif [ "$OPT_FULL" = 1 ]; then _kind=full; _why="--full"; fi

  touch "$STATE/stamp.next" || fail "cannot write $STATE/stamp.next"
  # every path now, for the rename check above and for the next run
  (cd "$HOME" && { find .claude/projects \( -type f -o -type l \) -print; [ -f .claude/CLAUDE.md ] && echo .claude/CLAUDE.md; true; } | sort -u) \
    > "$STATE/work/paths.now" || fail "cannot list $CLAUDE_DIR/projects"
  _list="$STATE/work/files.list"
  (
    cd "$HOME" || exit 1
    if [ "$_kind" = full ]; then
      find .claude/projects \( -type f -o -type l \) -print0
      [ -f .claude/CLAUDE.md ] && printf '%s\0' .claude/CLAUDE.md
    else
      {
        find .claude/projects \( -type f -o -type l \) -newer "$STATE/stamp" -print
        [ -f .claude/CLAUDE.md ] && find .claude/CLAUDE.md -newer "$STATE/stamp" -print
        # paths new since the last run's listing (renamed or moved folders keep old modification times)
        [ -f "$STATE/paths" ] && comm -13 "$STATE/paths" "$STATE/work/paths.now"
        true
      } | sort -u | tr '\n' '\000'
    fi
    true
  ) > "$_list" || fail "cannot list $CLAUDE_DIR/projects"
  _count="$(tr -cd '\000' < "$_list" | wc -c | tr -d ' ')"
  _srcbytes="$( (cd "$HOME" && xargs -0 sh -c 'for f; do [ -f "$f" ] && { stat -f %z "$f" 2>/dev/null || stat -c %s "$f"; }; done' sh) < "$_list" | awk '{ s += $1 } END { print s + 0 }')"

  if [ "$_count" = 0 ]; then
    mv "$STATE/stamp.next" "$STATE/stamp"; mv "$STATE/work/paths.now" "$STATE/paths"; date +%s > "$STATE/last-success"
    printf '%s\t%s\t0\t0\t-\n' "$_now" "$_kind" >> "$STATE/history.tsv"
    say "Nothing changed since the last success; no archive written. Destination: $DEST_BASE"
    return 0
  fi

  _outdir="$DEST_BASE/$_year"
  mkdir -p "$_outdir" || fail "cannot make $_outdir"
  # One archive per second at most, so the name order is the order they were made (a full and an incremental in the
  # same second would otherwise sort full first, whichever came first).
  while [ -n "$(find "$_outdir" -maxdepth 1 -name "claude-projects_${_now}_*" 2>/dev/null | head -n 1)" ]; do
    sleep 1; _now="$(date +%Y%m%d-%H%M%S)"
  done
  _name="claude-projects_${_now}_${_kind}.tar.gz.enc"
  _final="$_outdir/$_name"
  [ -e "$_final" ] && refuse "$_final already exists; nothing is ever overwritten."
  say "$_kind archive ($_why): $_count files, $(human "$_srcbytes") before compression"
  say "  -> $_final"

  PARTIAL="$_final.partial"
  (cd "$HOME" && tar -czf - --null -T "$_list") \
    | "$OPENSSL" enc -aes-256-cbc -pbkdf2 -iter "$ITER" -md sha256 -salt -pass "file:$PASSFILE" -out "$PARTIAL" \
    || fail "tar or openssl stopped; nothing kept, the stamp did not move"
  chmod 600 "$PARTIAL"

  _seen="$(decrypt "$PARTIAL" | tar -tzf - | wc -l | tr -d ' ')" || fail "the new archive does not open again; nothing kept"
  [ "$_seen" = "$_count" ] || fail "the new archive lists $_seen entries, not $_count; nothing kept"
  _sum="$(shasum -a 256 < "$PARTIAL" | awk '{ print $1 }')" || fail "shasum"
  printf '%s  %s\n' "$_sum" "$_name" > "$_final.sha256" || fail "cannot write $_final.sha256"
  mv "$PARTIAL" "$_final" || fail "cannot rename the .partial"
  PARTIAL=""

  mv "$STATE/stamp.next" "$STATE/stamp"
  mv "$STATE/work/paths.now" "$STATE/paths"
  date +%s > "$STATE/last-success"
  [ "$_kind" = full ] && printf '%s\n' "$_month" > "$STATE/last-full"
  _bytes="$(size_of "$_final")"
  printf '%s\t%s\t%s\t%s\t%s\n' "$_now" "$_kind" "$_count" "$_bytes" "$_name" >> "$STATE/history.tsv"
  _t1="$(date +%s)"
  say "  done in $((_t1 - _t0)) s: $(human "$_bytes") sealed, verified ($_seen entries), sha256 written"
  say "  destination total: $(human "$(dir_bytes "$DEST_BASE")") in $DEST_BASE"
  if [ "$_kind" = full ]; then
    ntfy_send "Claude archive: full copy sealed" default lock \
      "$_name on $(hostname -s): $_count files, $(human "$_bytes"), verified ($_why)." || true
  fi
  return 0
}

do_if_due() {
  resolve_dest look
  _last="$(last_success)"; _age=$(( $(date +%s) - _last ))
  if [ "$_last" -gt 0 ] && [ "$_age" -lt $((DUE_HOURS * 3600)) ]; then
    say "not due: the last success was $((_age / 3600)) h $(((_age % 3600) / 60)) min ago (runs after ${DUE_HOURS} h)."
    return 0
  fi
  do_run
}

# --------------------------------------------------------------------------------------------------------------- status
# --status: reads only ~/.config/claude-archive/state (never the destination, so it works where iCloud is blocked).
# Exit 0: the newest success is under STALE_HOURS (36) old and no failure came after it. Exit 1 otherwise.
STALE_HOURS="${CLAUDE_ARCHIVE_STALE_HOURS:-36}"
do_status() {
  _best=0; _now="$(date +%s)"
  for _s in "$CONFIG"/state/*/; do
    [ -f "$_s/dest" ] || continue
    _ls="$( [ -s "$_s/last-success" ] && cat "$_s/last-success" || echo 0)"
    [ "$_ls" -gt "$_best" ] && _best="$_ls"
    if [ "$_ls" -gt 0 ]; then say "$(cat "$_s/dest"): last success $(( (_now - _ls) / 3600 )) h ago"; else say "$(cat "$_s/dest"): no success yet"; fi
  done
  _lf="$( [ -s "$CONFIG/state/last-failure" ] && cat "$CONFIG/state/last-failure" || echo 0)"
  [ "$_lf" -gt 0 ] && say "last failure $(( (_now - _lf) / 3600 )) h ago: $(tail -n 1 "$CONFIG/state/failures.tsv" 2>/dev/null | cut -f3)"
  ntfy_load; case $? in
    0) say "phone notes (ntfy): on, $( [ -n "$N_TOKEN" ] && echo with || echo without) a token (failures and full archives)" ;;
    1) say "phone notes (ntfy): off (no ntfy.env)" ;;
    *) say "phone notes (ntfy): ntfy.env present but not used (see the warning above)" ;;
  esac
  if [ "$_best" -eq 0 ]; then say "STALE: no archive has ever succeeded."; return 1; fi
  if [ "$_lf" -gt "$_best" ]; then say "STALE: the last run failed after the last success."; return 1; fi
  if [ $((_now - _best)) -gt $((STALE_HOURS * 3600)) ]; then say "STALE: the newest success is over ${STALE_HOURS} h old."; return 1; fi
  say "ok: the newest success is under ${STALE_HOURS} h old."
}

# ---------------------------------------------------------------------------------------------------------------- list
archives() { # every archive and leftover under the destination, oldest first, one path per line
  find "$DEST_BASE" -type f \( -name 'claude-projects_*.tar.gz.enc' -o -name 'claude-projects_*.partial' \
       -o -name '.claude-projects_*.icloud' \) 2>/dev/null \
    | awk '{ n = $0; sub(/.*\//, "", n); sub(/^\./, "", n); print n "\t" $0 }' | sort | cut -f2-
}
do_list() {
  resolve_dest look
  [ -d "$DEST_BASE" ] || { say "No archives yet: $DEST_BASE does not exist."; return 0; }
  say "Archives in $DEST_BASE (oldest first):"
  _n=0; _all="$(archives)"
  set -f; _ifs="$IFS"; IFS='
'
  for _f in $_all; do
    IFS="$_ifs"; _b="$(basename "$_f")"; _s="$(size_of "$_f")"
    case "$_b" in
      *.partial) _note="  UNFINISHED: a run stopped mid-write; safe to delete by hand" ;;
      *.icloud)  _note="  in iCloud only (not downloaded)" ;;
      *_full.*)  _note="  full" ;;
      *)         _note="  incremental" ;;
    esac
    [ -e "$_f.sha256" ] || case "$_b" in *.enc) _note="$_note, NO .sha256" ;; esac
    printf '  %10s  %s%s\n' "$(human "$_s")" "$_b" "$_note"; _n=$((_n + 1))
  done
  IFS="$_ifs"; set +f
  say "$_n file(s); destination total $(human "$(dir_bytes "$DEST_BASE")")."
  [ -s "$STATE/last-success" ] && say "Last success: $(date -r "$(cat "$STATE/last-success")" '+%Y-%m-%d %H:%M' 2>/dev/null || cat "$STATE/last-success")"
  return 0
}

# -------------------------------------------------------------------------------------------------------------- verify
verify_one() { # $1 = archive; prints one line; returns 0 when sound
  [ -f "$1" ] || { warn "$1: no such file"; return 1; }
  if [ -f "$1.sha256" ]; then
    _want="$(awk '{ print $1; exit }' "$1.sha256")"; _got="$(shasum -a 256 < "$1" | awk '{ print $1 }')"
    [ "$_want" = "$_got" ] || { warn "$(basename "$1"): sha256 does not match its .sha256 (damaged or changed)"; return 1; }
    _shamsg="sha256 matches"
  else
    _shamsg="no .sha256 beside it"
  fi
  _entries="$(decrypt "$1" 2>/dev/null | tar -tzf - 2>/dev/null | wc -l | tr -d ' ')" \
    || { warn "$(basename "$1"): does not decrypt and read as a tar (wrong passphrase, or damaged)"; return 1; }
  say "ok  $(basename "$1"): $_entries entries, $_shamsg"
}
do_verify() { check_passfile; verify_one "$1" || exit 1; }

# ------------------------------------------------------------------------------------------------------------- restore
do_restore() { # args: FILE... DIR
  check_passfile
  [ $# -ge 2 ] || refuse "usage: --restore FULL [INCR ...] DIR"
  _files=""; _dir=""; _i=0; _prev=""
  for _a in "$@"; do _i=$((_i + 1)); [ "$_i" -eq $# ] && _dir="$_a"; done
  _target="$(physpath "$_dir")"; _cl="$(physpath "$CLAUDE_DIR")"
  if inside "$_target" "$_cl" || inside "$_cl" "$_target"; then refuse "$_dir is inside (or holds) ~/.claude. Restore into a new, empty folder elsewhere."; fi
  if [ -e "$_dir" ]; then
    [ -d "$_dir" ] || refuse "$_dir exists and is not a folder."
    [ -z "$(ls -A "$_dir")" ] || refuse "$_dir is not empty. Restore only into a new, empty folder."
  else
    [ -d "$(dirname "$_dir")" ] || refuse "the folder that would hold $_dir does not exist."
  fi
  _i=0
  for _a in "$@"; do
    _i=$((_i + 1)); [ "$_i" -eq $# ] && break
    _b="$(basename "$_a")"
    case "$_i:$_b" in
      1:claude-projects_*_full.tar.gz.enc) ;;
      1:*) refuse "the first archive must be a _full one; $_b is not." ;;
      *:claude-projects_*_incr.tar.gz.enc) ;;
      *) refuse "after the full, only _incr archives may follow; $_b is not." ;;
    esac
    if [ -n "$_prev" ] && ! before "$_prev" "$_b"; then
      refuse "$_b is older than $_prev. Give them oldest first: the full, then each incremental in name order."
    fi
    _prev="$_b"
    verify_one "$_a" || exit 1
  done
  mkdir -p "$_dir" || fail "cannot make $_dir"
  _i=0
  for _a in "$@"; do
    _i=$((_i + 1)); [ "$_i" -eq $# ] && break
    decrypt "$_a" | tar -xzpf - -C "$_dir" || fail "extracting $(basename "$_a") stopped; $_dir holds what came before it"
    say "restored $(basename "$_a")"
  done
  say "Done: $_dir/.claude/projects (and .claude/CLAUDE.md). Compare before copying anything back, with Claude Code closed."
}
do_restore_latest() {
  [ $# -eq 1 ] || refuse "usage: --restore-latest DIR"
  _into="$1"
  resolve_dest look
  _full="$(archives | grep '_full\.tar\.gz\.enc$' | tail -n 1)"
  [ -n "$_full" ] || refuse "no full archive in $DEST_BASE"
  _fb="$(basename "$_full")"
  # (no case inside $( ): bash 3.2, which is macOS /bin/sh, misparses it)
  _chain="$(archives | grep '_incr\.tar\.gz\.enc$' | while IFS= read -r _f; do
              if before "$_fb" "$(basename "$_f")"; then printf '%s\n' "$_f"; fi
            done)"
  set -- "$_full"
  set -f; _ifs="$IFS"; IFS='
'
  for _f in $_chain; do set -- "$@" "$_f"; done
  IFS="$_ifs"; set +f
  say "Restoring $# archive(s): $_fb and the incrementals after it."
  do_restore "$@" "$_into"
}

# ---------------------------------------------------------------------------------------------------------- prune-plan
do_prune_plan() {
  case "$1" in ''|*[!0-9]*|0) refuse "--prune-plan KEEP: KEEP is a whole number, 1 or more" ;; esac
  resolve_dest look
  _fulls="$(archives | grep -c '_full\.tar\.gz\.enc$')"
  if [ "$_fulls" -le "$1" ]; then say "There are $_fulls full archive(s); keeping $1 moves nothing."; return 0; fi
  _cut="$(archives | grep '_full\.tar\.gz\.enc$' | tail -n "$1" | head -n 1)"; _cb="$(basename "$_cut")"
  say "Plan only, nothing is moved. Keeping the newest $1 full archive(s) (from $_cb on) WOULD move aside:"
  _tot=0; _n=0; _all="$(archives)"
  set -f; _ifs="$IFS"; IFS='
'
  for _f in $_all; do
    IFS="$_ifs"; _b="$(basename "$_f")"
    before "$_b" "$_cb" || continue
    _s="$(size_of "$_f")"; _tot=$((_tot + _s)); _n=$((_n + 1))
    printf '  %10s  %s\n' "$(human "$_s")" "$_b"
  done
  IFS="$_ifs"; set +f
  say "$_n archive(s), $(human "$_tot"), each with its .sha256. To do it: --move-old $1 DIR (moves them, e.g. to a drive)."
}

# --move-old KEEP DIR: the same selection as --prune-plan, moved (never deleted) into DIR/<year>/, each with its .sha256,
# and each checked against its .sha256 after the move. DIR must exist and must not be inside this destination or
# ~/.claude. A name that already exists in DIR is refused. Partial leftovers are never moved.
do_move_old() {
  case "$1" in ''|*[!0-9]*|0) refuse "--move-old KEEP DIR: KEEP is a whole number, 1 or more" ;; esac
  [ -n "${2-}" ] || refuse "usage: --move-old KEEP DIR"
  [ -d "$2" ] || refuse "--move-old: $2 does not exist (plug the drive in, or make the folder) first."
  resolve_dest look
  _to="$(physpath "$2")"
  if inside "$_to" "$DEST_PHYS" || [ "$_to" = "$DEST_PHYS" ]; then refuse "--move-old: $2 is inside the destination itself."; fi
  if inside "$_to" "$(physpath "$CLAUDE_DIR")"; then refuse "--move-old: $2 is inside ~/.claude."; fi
  _fulls="$(archives | grep -c '_full\.tar\.gz\.enc$')"
  if [ "$_fulls" -le "$1" ]; then say "There are $_fulls full archive(s); keeping $1 moves nothing."; return 0; fi
  _cut="$(archives | grep '_full\.tar\.gz\.enc$' | tail -n "$1" | head -n 1)"; _cb="$(basename "$_cut")"
  _n=0; _tot=0; _all="$(archives)"
  set -f; _ifs="$IFS"; IFS='
'
  for _f in $_all; do
    IFS="$_ifs"; _b="$(basename "$_f")"
    case "$_b" in *.partial) continue ;; esac
    before "$_b" "$_cb" || continue
    _y="$(printf '%s' "$_b" | sed -n 's/^claude-projects_\([0-9][0-9][0-9][0-9]\).*/\1/p')"; [ -n "$_y" ] || _y=other
    mkdir -p "$_to/$_y" || fail "cannot make $_to/$_y"
    [ -e "$_to/$_y/$_b" ] && refuse "$_to/$_y/$_b already exists; nothing is overwritten (nothing moved after this point)."
    _s="$(size_of "$_f")"
    mv "$_f" "$_to/$_y/$_b" || fail "cannot move $_b"
    [ -f "$_f.sha256" ] && { mv "$_f.sha256" "$_to/$_y/$_b.sha256" || fail "cannot move $_b.sha256"; }
    if [ -f "$_to/$_y/$_b.sha256" ]; then
      _want="$(awk '{ print $1 }' "$_to/$_y/$_b.sha256")"; _got="$(shasum -a 256 < "$_to/$_y/$_b" | awk '{ print $1 }')"
      [ "$_want" = "$_got" ] || fail "$_b moved but its sha256 does not match; check the copy at $_to/$_y before anything else"
    fi
    _n=$((_n + 1)); _tot=$((_tot + _s)); say "  moved $_b ($(human "$_s"))"
  done
  IFS="$_ifs"; set +f
  say "$_n archive(s), $(human "$_tot"), moved to $_to (checked against their .sha256). The newest $1 full chain(s) stay in $DEST_BASE."
  say "To restore from moved archives: --restore-latest --dest $_to DIR (or --restore FILE... DIR)."
}

# ------------------------------------------------------------------------------------------------------------- install
# One LaunchAgent per destination: the default (iCloud) keeps the plain label; a --dest gets its own label and log, so
# a drive can be scheduled beside iCloud instead of replacing it.
label_for_dest() {
  [ -n "$OPT_DEST" ] || return 0
  LABEL="$LABEL.dest-$(printf '%s' "$OPT_DEST" | cksum | awk '{ print $1 }')"
  PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
  LOGNAME_="$LABEL.log"
}
LOGNAME_="archive.log"

do_install() {
  check_passfile
  resolve_dest look
  label_for_dest
  mkdir -p "$HOME/Library/LaunchAgents" "$LOGDIR" || fail "cannot make the LaunchAgents or log folder"
  _destxml=""
  if [ -n "$OPT_DEST" ]; then
    _d="$(printf '%s' "$OPT_DEST" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')"
    _destxml="
        <string>--dest</string>
        <string>$_d</string>"
  fi
  # Launched through a file named after the job, so Login Items shows "claude-projects-archive", not "sh".
  _launcher="$(dirname "$SELF")/launchd/claude-projects-archive"
  [ -x "$_launcher" ] || fail "missing or not executable: $_launcher"
  _launcherxml="$(printf '%s' "$_launcher" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')"
  _new="$CONFIG/work-$LABEL.plist"
  mkdir -p "$CONFIG" && chmod 700 "$CONFIG"
  cat > "$_new" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<!--
  claude-projects-archive, nightly at 00:40 (after the desk's 23:55 and 23:58 jobs). Written by the
  script's install mode; its uninstall mode unloads it and moves this file aside.
  StartCalendarInterval runs on wake if the Mac slept through 00:40; RunAtLoad with the if-due mode covers
  a Mac that was off, at login, and costs nothing when the last success is under 20 hours old.
-->
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$LABEL</string>
    <key>ProgramArguments</key>
    <array>
        <string>$_launcherxml</string>
        <string>--if-due</string>$_destxml
    </array>
    <key>StartCalendarInterval</key>
    <dict><key>Hour</key><integer>0</integer><key>Minute</key><integer>40</integer></dict>
    <key>RunAtLoad</key>
    <true/>
    <key>ProcessType</key>
    <string>Background</string>
    <key>LowPriorityIO</key>
    <true/>
    <key>Nice</key>
    <integer>10</integer>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/usr/bin:/bin:/usr/sbin:/sbin</string>
    </dict>
    <key>StandardOutPath</key>
    <string>$LOGDIR/$LOGNAME_</string>
    <key>StandardErrorPath</key>
    <string>$LOGDIR/$LOGNAME_</string>
</dict>
</plist>
EOF
  plutil -lint "$_new" >/dev/null || fail "the rendered plist does not lint"
  if [ -e "$PLIST" ]; then
    if cmp -s "$_new" "$PLIST"; then say "$PLIST is already this; reloading it."
    else
      _old="$(retire "$PLIST")" && say "the previous plist was moved to $_old"
    fi
  fi
  [ -e "$PLIST" ] || mv "$_new" "$PLIST" || fail "cannot write $PLIST"
  chmod 644 "$PLIST"
  if [ "${CLAUDE_ARCHIVE_NO_LAUNCHCTL:-0}" = 1 ]; then say "rendered $PLIST (CLAUDE_ARCHIVE_NO_LAUNCHCTL=1: not loaded)"; return 0; fi
  launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
  launchctl bootstrap "gui/$(id -u)" "$PLIST" || fail "launchctl bootstrap refused $PLIST"
  say "Loaded $LABEL: nightly at 00:40, --if-due. Log: $LOGDIR/$LOGNAME_"
  say "Check it: launchctl print gui/$(id -u)/$LABEL | grep -E 'state|last exit'"
}
do_uninstall() {
  label_for_dest
  if [ "${CLAUDE_ARCHIVE_NO_LAUNCHCTL:-0}" != 1 ]; then launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true; fi
  if [ -e "$PLIST" ]; then
    _old="$(retire "$PLIST")" && say "Unloaded $LABEL; its plist was moved to $_old (archives and state untouched)."
  else
    say "No $PLIST; nothing to unload."
  fi
}

do_notify_test() {
  ntfy_load; _rc=$?
  [ "$_rc" = 1 ] && refuse "no $NTFY_ENV (or CLAUDE_ARCHIVE_NO_NTFY=1). See the walkthrough: how to make ntfy.env."
  [ "$_rc" = 0 ] || refuse "$NTFY_ENV is not usable (the line above says why)."
  if ntfy_send "Claude archive: test note" low test_tube \
       "A test from $(hostname -s). Failures and full archives will arrive here."; then
    say "sent a test note to the topic in ntfy.env ($( [ -n "$N_TOKEN" ] && echo with || echo without) a token). Check your phone."
  else
    fail "the test note was not taken (see the line above)."
  fi
}

# ---------------------------------------------------------------------------------------------------------------- main
usage() { sed -n '2,20p' "$SELF" | sed 's/^# \{0,1\}//'; }
OPT_DEST="${CLAUDE_ARCHIVE_DEST:-}"; OPT_FULL=0; MODE=""; POS_N=0
# Options may come anywhere; what is left, in order, are the mode's own arguments.
while [ $# -gt 0 ]; do
  case "$1" in
    --dest) [ $# -ge 2 ] || refuse "--dest needs a folder"; OPT_DEST="$2"; shift 2; continue ;;
    --dest=*) OPT_DEST="${1#--dest=}" ;;
    --full) OPT_FULL=1 ;;
    -h|--help) usage; exit 0 ;;
    --init|--run|--if-due|--status|--list|--verify|--restore|--restore-latest|--prune-plan|--move-old|--install|--uninstall|--notify-test)
      [ -z "$MODE" ] || refuse "one mode at a time ($MODE and $1)"; MODE="$1" ;;
    --) shift; while [ $# -gt 0 ]; do POS_N=$((POS_N + 1)); eval "POS_$POS_N=\$1"; shift; done; break ;;
    -*) refuse "unknown option $1 (try --help)" ;;
    *) POS_N=$((POS_N + 1)); eval "POS_$POS_N=\$1" ;;
  esac
  shift
done
set --
_k=1; while [ "$_k" -le "$POS_N" ]; do eval "set -- \"\$@\" \"\$POS_$_k\""; _k=$((_k + 1)); done

case "$MODE" in
  --init) [ $# -eq 0 ] || refuse "--init takes no arguments"; do_init ;;
  --run) [ $# -eq 0 ] || refuse "--run takes no arguments"; do_run ;;
  --if-due) [ $# -eq 0 ] || refuse "--if-due takes no arguments"; do_if_due ;;
  --status) [ $# -eq 0 ] || refuse "--status takes no arguments"; do_status ;;
  --list) do_list ;;
  --verify) [ $# -eq 1 ] || refuse "usage: --verify FILE"; do_verify "$1" ;;
  --restore) do_restore "$@" ;;
  --restore-latest) do_restore_latest "$@" ;;
  --prune-plan) [ $# -eq 1 ] || refuse "usage: --prune-plan KEEP"; do_prune_plan "$1" ;;
  --move-old) [ $# -eq 2 ] || refuse "usage: --move-old KEEP DIR"; do_move_old "$1" "$2" ;;
  --install) do_install ;;
  --uninstall) do_uninstall ;;
  --notify-test) [ $# -eq 0 ] || refuse "--notify-test takes no arguments"; do_notify_test ;;
  "") usage; exit 2 ;;
esac
