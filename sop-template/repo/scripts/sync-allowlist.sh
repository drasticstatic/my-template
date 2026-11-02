#!/bin/sh
# sync-allowlist.sh — the allowlist sync's two halves, used by the sync workflows and runnable locally as a dry run.
#
#   sh scripts/sync-allowlist.sh stage <allowlist-file> <stage-dir>   # copy ONLY the listed paths, then run the tripwire
#   sh scripts/sync-allowlist.sh apply <stage-dir> <destination-clone> # replace what the sync owns in the destination
#
# Allowlist file: one path per line, relative to the repository root (a file, or a folder copied whole). Blank lines and
# lines starting with # are ignored. No globs, no "..", no absolute paths, no hidden paths. An empty list means "publish
# nothing": stage exits 3 and the workflow stops with a notice, not a failure.
#
# Environment:
#   PREFIX           where the staged paths land in the destination (default: the root). With a PREFIX the sync owns only
#                    that folder (a lab desk writing into proposals/lab-desk/ of a reading room); without one it owns
#                    everything except RESERVED.
#   RESERVED         space-separated top-level names the destination keeps as its own (its README, its front end);
#                    an allowlist line that would land on one of them fails the tripwire.
#   TRIPWIRE_PUBLIC  1 when the destination is public: runs
#                    the public-lane tripwire scripts/scan-public-lane.sh on everything staged (PDF text via pdftotext,
#                    .docx/.xlsx text, pictures only under assets/ or icons/ or a listed folder, legal lanes refused by
#                    path). A public lane never publishes a file a machine or a person has not read.
#   ATTESTED         the attestation file for that tripwire (default PUBLIC-ALLOWLIST-ATTESTED.txt, used when it exists):
#                    "path | officer | YYYY-MM-DD | opened and read" for files a person opened and read.
#   MEDIA            the media list for that tripwire (default PUBLIC-LANE-MEDIA.txt, used when it exists): folders whose
#                    pictures and fonts this lane publishes on purpose, under "approved by <name> | YYYY-MM-DD".
#   MANIFEST         a file name (e.g. room-manifest.json): apply writes the list of synced files there, for a front end.
#
# Exit codes: 0 done · 1 tripwire or usage · 3 the allowlist is empty (nothing to do).
# It never deletes anything outside the destination clone it is given, and it never pushes: the workflow does that.
set -eu

die () { echo "tripwire: $*" >&2; exit 1; }

# Paths that never travel, whatever an allowlist says (fleet rule: no agent notes, no secrets, no tool configuration).
FORBIDDEN_NAMES='AGENT-SYNC|AGENT-SYNC-*|CLAUDE.md|AGENTS.md|PENDING-TASKS.md|pending-tasks.md|node_modules'
# File names that look like keys, wallets or environment files.
FORBIDDEN_FILES='*.pem|*.key|*.p12|*.pfx|id_rsa*|id_ed25519*|*.keystore|*keystore*|*mnemonic*|*seed-phrase*|*.secret|*.env|.env*|*credentials*.json|*service-account*.json'
# Content that must never appear in a synced text file: credentials, and pointers into agent notes (a lab hub such as
# AGENT-SYNC-<org>, a created-by-<agent> lane, a dated handoff or prompt). A link to the public attribution spec
# (my-template/AGENT-SYNC/README.md) is allowed; a path segment named AGENT-SYNC never travels (above).
SECRET_RE='BEGIN [A-Z ]*PRIVATE KEY|ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|gho_[A-Za-z0-9]{20,}|(^|[^A-Za-z0-9])sk-[A-Za-z0-9_-]{32,}|xox[abprs]-[A-Za-z0-9-]{10,}|AKIA[0-9A-Z]{16}|AGENT-SYNC/created-by|AGENT-SYNC-[a-z]|created-by-(fortuna|alfred|kavanah|auggie|littlebird|mystarch|cosmos)|HANDOFF_20[0-9]{6}|_PROMPT_20[0-9]{6}'
# The personal-matter words (divorce, custody, tax-assistant) moved into scan-public-lane.sh with the other sensitive shapes.

stage () {
  list="$1"; out="$2"
  [ -f "$list" ] || die "allowlist $list not found"
  prefix="${PREFIX:-}"; prefix="${prefix%/}"
  mkdir -p "$out"
  n=0
  # read line by line; strip comments, surrounding spaces and a trailing slash
  while IFS= read -r line || [ -n "$line" ]; do
    p="$(printf '%s' "$line" | sed -e 's/#.*$//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's:/*$::')"
    [ -n "$p" ] || continue
    case "$p" in /*|-*) die "'$p': absolute paths and leading dashes are not allowed";; esac
    case "$p" in *'*'*|*'?'*|*'['*) die "'$p': globs are not allowed; list each path";; esac
    case "/$p/" in */../*|*/./*) die "'$p': '..' and '.' segments are not allowed";; esac
    case "/$p" in */.*) die "'$p': hidden paths (.git, .github, .env…) never travel";; esac
    old_ifs="$IFS"; IFS=/
    for seg in $p; do
      eval "case \"\$seg\" in $FORBIDDEN_NAMES) IFS=\"\$old_ifs\"; die \"'\$p': '\$seg' never travels\";; esac"
    done
    IFS="$old_ifs"
    if [ -z "$prefix" ] && [ -n "${RESERVED:-}" ]; then
      top="${p%%/*}"
      for r in $RESERVED; do [ "$top" = "$r" ] && die "'$p' would overwrite the destination's own '$r'"; done
    fi
    [ -e "$p" ] || die "'$p' is listed but does not exist"
    [ -L "$p" ] && die "'$p' is a symbolic link"
    dest="$out${prefix:+/$prefix}/$p"
    mkdir -p "$(dirname "$dest")"
    if [ -d "$p" ] && [ -d "$dest" ]; then cp -R "$p/." "$dest/"; else cp -R "$p" "$dest"; fi
    n=$((n + 1))
  done < "$list"
  [ "$n" -gt 0 ] || { echo "allowlist $list is empty: nothing to publish"; exit 3; }

  # the tripwire, on what was actually staged
  bad="$(find "$out" -type l)"; [ -z "$bad" ] || die "symbolic links staged: $bad"
  find "$out" -type f | while IFS= read -r f; do
    b="$(basename "$f")"
    eval "case \"\$b\" in $FORBIDDEN_FILES) echo \"\$f\";; esac"
  done > "$out.names"
  [ ! -s "$out.names" ] || { cat "$out.names" >&2; rm -f "$out.names"; die "file names that look like keys, wallets or environment files"; }
  rm -f "$out.names"
  big="$(find "$out" -type f -size +15M)"; [ -z "$big" ] || die "files over 15 MB: $big"
  # credentials and agent notes here; on a public lane the personal-matter words and every other sensitive
  # shape are checked by scan-public-lane.sh below, where a person's attestation can clear a false alarm
  re="$SECRET_RE"
  find "$out" -type f > "$out.files"
  : > "$out.hits"
  while IFS= read -r f; do
    case "$f" in
      *.pdf) if command -v pdftotext >/dev/null 2>&1; then
               if pdftotext -q "$f" - 2>/dev/null | grep -Eiq "$re"; then echo "$f" >> "$out.hits"; fi
             elif [ "${TRIPWIRE_PUBLIC:-0}" != 1 ]; then echo "note: pdftotext not installed; $f checked by its name only"; fi ;;
      *.png|*.jpg|*.jpeg|*.gif|*.webp|*.ico|*.woff|*.woff2) : ;;
      *) if grep -Eiq "$re" "$f"; then echo "$f" >> "$out.hits"; fi ;;
    esac
  done < "$out.files"
  hits="$(cat "$out.hits")"; rm -f "$out.files" "$out.hits"
  if [ -n "$hits" ]; then echo "$hits" >&2; die "content the tripwire refuses (agent notes, a credential, or a personal matter) in the files above"; fi
  # the public-lane tripwire: every staged file is read (text, PDF text, office XML) or attested by a person, or refused
  if [ "${TRIPWIRE_PUBLIC:-0}" = 1 ]; then
    scanner="$(cd "$(dirname "$0")" && pwd)/scan-public-lane.sh"
    [ -f "$scanner" ] || die "scripts/scan-public-lane.sh is missing; a public lane does not run without it (copy it from my-template/scripts/)"
    att="${ATTESTED:-PUBLIC-ALLOWLIST-ATTESTED.txt}"
    if [ -f "$att" ]; then set -- "$out${prefix:+/$prefix}" "$att"; else set -- "$out${prefix:+/$prefix}"; fi
    media="${MEDIA:-PUBLIC-LANE-MEDIA.txt}"
    if [ -f "$media" ]; then set -- --media "$media" "$@"; fi
    sh "$scanner" "$@" || die "the public-lane tripwire refused the files named above; nothing was published"
  fi
  echo "staged $n allowlisted path(s) into $out${prefix:+/$prefix}; tripwire clean"
}

apply () {
  src="$1"; dst="$2"
  [ -d "$dst/.git" ] || die "$dst is not a git clone"
  prefix="${PREFIX:-}"; prefix="${prefix%/}"
  (
    cd "$dst"
    if [ -n "$prefix" ]; then
      # the sync owns only its prefix folder
      if [ -e "$prefix" ]; then git rm -r -q -- "$prefix"; fi
    else
      # the sync owns everything but .git and the destination's reserved names
      for p in * .[!.]*; do
        [ -e "$p" ] || continue
        keep=0; for r in .git ${RESERVED:-}; do [ "$p" = "$r" ] && keep=1; done
        [ "$keep" = 1 ] && continue
        git rm -r -q --ignore-unmatch -- "$p"
      done
    fi
  )
  if [ -d "$src${prefix:+/$prefix}" ]; then
    mkdir -p "$dst${prefix:+/$prefix}"
    cp -R "$src${prefix:+/$prefix}/." "$dst${prefix:+/$prefix}/"
  fi
  if [ -n "${MANIFEST:-}" ]; then
    ( cd "$src" && find . -type f | sed 's|^\./||' | sort ) | python3 -c 'import sys,json,datetime; files=[l.strip() for l in sys.stdin if l.strip()]; print(json.dumps({"generated":datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%MZ"),"files":files},indent=1))' > "$dst/$MANIFEST"
  fi
  ( cd "$dst" && git add -A && git status --short )
}

cmd="${1:-}"; [ $# -ge 1 ] && shift
case "$cmd" in
  stage) [ $# -eq 2 ] || die "usage: stage <allowlist-file> <stage-dir>"; stage "$1" "$2" ;;
  apply) [ $# -eq 2 ] || die "usage: apply <stage-dir> <destination-clone>"; apply "$1" "$2" ;;
  *) die "usage: sh scripts/sync-allowlist.sh stage|apply …" ;;
esac
