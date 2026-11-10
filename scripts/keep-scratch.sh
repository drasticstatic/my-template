#!/bin/sh
# keep-scratch.sh: keep scratch work through a restart, routed to the right place.
#
#   keep-scratch.sh save SRC REPO TOPIC [NOTE...] [--local]
#   keep-scratch.sh status [--hook]
#   keep-scratch.sh done FOLDER
#
# The fork in the road:
#   synced (iCloud)  ordinary drafts, command lists, small backups; follows you to every device
#   local (~/Archive) anything that looks like a secret, anything over 1 GB, or --local;
#                     never synced, and Time Machine picks it up
# Nothing is ever deleted: `done` moves a folder to done/YYYY/MM/. Copies never overwrite.

set -eu

SYNCED="${KEEP_SCRATCH_SYNCED:-$HOME/Library/Mobile Documents/com~apple~CloudDocs/__Scratchpad-4-Claude__}"
LOCAL="${KEEP_SCRATCH_LOCAL:-$HOME/Archive/claude-scratch}"
LIMIT_KB="${KEEP_SCRATCH_LIMIT_KB:-1048576}"

usage() { sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//'; exit 2; }

secret_hits() {
  find "$1" \( -iname '.env' -o -iname '.env.*' -o -iname '*.env' -o -iname '*passphrase*' \
    -o -iname '*client_secret*' -o -iname '*credential*' -o -iname '*.pem' -o -iname '*.key' \
    -o -iname 'id_rsa*' -o -iname 'id_ed25519*' -o -iname '*.p12' -o -iname '*.keystore' \
    -o -iname '*mnemonic*' -o -iname '*wallet*.json' -o -iname '*token*.json' \) \
    -print 2>/dev/null | head -5
  # Also look inside text files (under 5 MB) for common credential shapes. Only file names are reported,
  # never the matching text.
  find "$1" -type f -size -5M -print0 2>/dev/null | xargs -0 grep -I -l -E \
    -e '-----BEGIN [A-Z ]*PRIVATE KEY-----' -e 'AKIA[0-9A-Z]{16}' -e 'sk-ant-[A-Za-z0-9_-]{20,}' \
    -e 'sk-[A-Za-z0-9]{32,}' -e 'gh[pousr]_[A-Za-z0-9]{30,}' -e 'xox[abprs]-[A-Za-z0-9-]{10,}' \
    -e 'AIza[0-9A-Za-z_-]{35}' -e 'eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}' \
    -e '(api[_-]?key|secret|token|passphrase|password)["'"'"' ]*[:=]["'"'"' ]*[A-Za-z0-9/+_.-]{12,}' \
    2>/dev/null | head -5 || true
}

fresh_dir() {
  base="$1"; d="$base"; n=2
  while [ -e "$d" ]; do d="$base-$n"; n=$((n + 1)); done
  mkdir -p "$d"; printf '%s\n' "$d"
}

cmd_save() {
  [ $# -ge 3 ] || usage
  src="$1" repo="$2" topic="$3"; shift 3
  force_local=0; note=""
  for a in "$@"; do
    if [ "$a" = "--local" ]; then force_local=1; else note="${note:+$note }$a"; fi
  done
  [ -e "$src" ] || { echo "keep-scratch: no such path: $src" >&2; exit 1; }

  size_kb=$(du -sk "$src" | cut -f1)
  hits=$(secret_hits "$src")
  if [ "$force_local" = 1 ]; then root="$LOCAL"; why="asked for local"
  elif [ -n "$hits" ]; then root="$LOCAL"; why="looks like it holds secrets, so it never syncs"
  elif [ "$size_kb" -gt "$LIMIT_KB" ]; then root="$LOCAL"; why="larger than 1 GB"
  else root="$SYNCED"; why="no secrets found and under 1 GB"
  fi

  dest=$(fresh_dir "$root/open/$(date +%Y-%m-%d)_${repo}_${topic}")
  if [ -d "$src" ]; then rsync -a "$src/" "$dest/$(basename "$src")/"; else rsync -a "$src" "$dest/"; fi
  {
    printf '# %s / %s\n\n' "$repo" "$topic"
    printf -- '- Saved: %s\n- From: %s\n- Route: %s (%s)\n' "$(date '+%Y-%m-%d %H:%M %Z')" "$src" "$root" "$why"
    [ -n "$hits" ] && printf -- '- Secret-looking files (names only):\n%s\n' "$(printf '%s\n' "$hits" | sed 's/^/  - /')"
    printf -- '- Waiting on: %s\n' "${note:-say what this is waiting on}"
    printf '\nWhen finished: sh ~/code/my-template/scripts/keep-scratch.sh done "%s"\n' "$dest"
  } > "$dest/NOTE.md"
  printf '%s\n' "$dest"
}

list_open() {
  [ -d "$1/open" ] || return 0
  find "$1/open" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort
}

cmd_status() {
  hook=0; [ "${1:-}" = "--hook" ] && hook=1
  s=$(list_open "$SYNCED"); l=$(list_open "$LOCAL")
  ns=$(printf '%s' "$s" | grep -c . || true); nl=$(printf '%s' "$l" | grep -c . || true)
  if [ "$hook" = 1 ] && [ "$ns" = 0 ] && [ "$nl" = 0 ]; then exit 0; fi
  echo "Scratch kept through restarts: $ns synced, $nl local (keep-scratch.sh status lists them; done moves one to done/)."
  for d in $(printf '%s\n%s\n' "$s" "$l" | head -8 | tr ' ' '\001'); do
    d=$(printf '%s' "$d" | tr '\001' ' ')
    first=$(sed -n 's/^- Waiting on: //p' "$d/NOTE.md" 2>/dev/null | head -1)
    echo "  - $(basename "$d"): ${first:-no NOTE.md}"
  done
}

cmd_done() {
  [ $# -eq 1 ] || usage
  d="${1%/}"; [ -d "$d" ] || { echo "keep-scratch: not a folder: $d" >&2; exit 1; }
  case "$d" in */open/*) ;; *) echo "keep-scratch: only folders under open/ can be finished" >&2; exit 1 ;; esac
  root="${d%/open/*}"; to="$root/done/$(date +%Y)/$(date +%m)"
  mkdir -p "$to"; target=$(fresh_dir "$to/$(basename "$d")"); rmdir "$target"
  mv -n "$d" "$target" && printf '%s\n' "$target"
}

case "${1:-}" in
  save) shift; cmd_save "$@" ;;
  status) shift; cmd_status "$@" ;;
  done) shift; cmd_done "$@" ;;
  *) usage ;;
esac
