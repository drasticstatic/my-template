#!/bin/sh
# scaffold-agent-sync.sh — create the correct agent-coordination layout for THIS repo.
#
# The rule agents keep getting wrong:
#
#     PRIVATE repo  →  AGENT-SYNC/   +  logs/
#     PUBLIC  repo  →  AGENT-SYNC_PUBLIC/   and NO logs/   (no logs_PUBLIC/ exists)
#
# Documenting that was not enough, so this script decides and builds it for you.
# Run from anywhere inside the repo:
#
#     sh scripts/scaffold-agent-sync.sh            # detect visibility, scaffold
#     sh scripts/scaffold-agent-sync.sh --private  # force
#     sh scripts/scaffold-agent-sync.sh --public   # force
#     sh scripts/scaffold-agent-sync.sh --check    # report only, change nothing
#
# Safe and idempotent: it only ever creates missing directories and placeholders.
# It never deletes a directory that already has content.

set -e
cd "$(git rev-parse --show-toplevel)"

AGENTS="alfred auggie christopher fortuna kavanah mystarch Littlebird
cosmos_Advisor-drasticstatic cosmos_Advisor-drasticstatica"

# Repo identity comes from the remote, not the checkout directory name — a clone
# may sit in a directory called anything at all.
REPO_NAME=$(git config --get remote.origin.url 2>/dev/null \
  | sed -E 's#(git@github.com:|https://github.com/)##; s#\.git$##; s#.*/##')
[ -n "$REPO_NAME" ] || REPO_NAME=$(basename "$(pwd)")

MODE=""
CHECK=no
case "${1:-}" in
  --private) MODE=private ;;
  --public)  MODE=public ;;
  --check)   CHECK=yes ;;
  "")        ;;
  *) echo "usage: $0 [--private|--public|--check]" >&2; exit 2 ;;
esac

# ---- 1. Determine visibility -------------------------------------------------
detect() {
  if command -v gh >/dev/null 2>&1; then
    v=$(gh repo view --json isPrivate -q .isPrivate 2>/dev/null || echo "")
    [ "$v" = "true" ]  && { echo private; return; }
    [ "$v" = "false" ] && { echo public;  return; }
  fi
  url=$(git config --get remote.origin.url 2>/dev/null || echo "")
  slug=$(printf '%s' "$url" | sed -E 's#(git@github.com:|https://github.com/)##; s#\.git$##')
  if [ -n "$slug" ] && command -v curl >/dev/null 2>&1; then
    code=$(curl -s -o /dev/null -w '%{http_code}' "https://api.github.com/repos/$slug" 2>/dev/null || echo "")
    [ "$code" = "200" ] && { echo public;  return; }   # visible anonymously
    [ "$code" = "404" ] && { echo private; return; }   # invisible anonymously
  fi
  # Heuristic of last resort: mirror repos are public by naming convention.
  case "$REPO_NAME" in
    *-public|*-public-preview|*_astro-public) echo public; return ;;
  esac
  echo unknown
}

if [ -z "$MODE" ]; then
  MODE=$(detect)
  if [ "$MODE" = "unknown" ]; then
    echo "✗ Could not determine repository visibility." >&2
    echo "  Re-run with --private or --public." >&2
    exit 1
  fi
  echo "Detected visibility: $MODE"
else
  echo "Visibility (forced): $MODE"
fi

# my-template is the canonical template. It is public, yet intentionally ships BOTH
# layouts so a new repo can copy whichever one applies. It is the one repo where a
# public checkout legitimately contains logs/ — holding the convention doc, never a
# real session log.
IS_TEMPLATE=no
case "$REPO_NAME" in
  my-template|my-template-clean) IS_TEMPLATE=yes ;;
esac

if [ "$MODE" = "private" ]; then
  LANE="AGENT-SYNC"; WANT_LOGS=yes; WRONG="logs_PUBLIC"
else
  LANE="AGENT-SYNC_PUBLIC"; WANT_LOGS=no; WRONG="logs logs_PUBLIC"
fi

if [ "$IS_TEMPLATE" = yes ]; then
  echo "Note: this is the canonical template — it ships both layouts on purpose."
  WANT_LOGS=yes; WRONG="logs_PUBLIC"
fi

# ---- 2. Report ---------------------------------------------------------------
echo "  coordination lane : $LANE/"
echo "  logs/             : $([ "$WANT_LOGS" = yes ] && echo 'yes' || echo 'no — public repos never get logs/')"

if [ "$CHECK" = yes ]; then
  rc=0
  [ -d "$LANE" ] || { echo "  ✗ missing $LANE/"; rc=1; }
  if [ "$WANT_LOGS" = yes ]; then
    [ -d logs ] || { echo "  ✗ missing logs/"; rc=1; }
  else
    [ -d logs ] && { echo "  ✗ logs/ present in a PUBLIC repo — must not exist"; rc=1; }
  fi
  if [ "$IS_TEMPLATE" = yes ] && [ -d AGENT-SYNC ] && [ -d AGENT-SYNC_PUBLIC ]; then
    echo "  ✓ both layouts present, as the template intends"
  fi
  [ -d logs_PUBLIC ] && { echo "  ✗ logs_PUBLIC/ exists — no such thing, remove it"; rc=1; }
  [ $rc -eq 0 ] && echo "  ✓ layout correct"
  exit $rc
fi

# ---- 3. Scaffold -------------------------------------------------------------
mkdir -p "$LANE"
for a in $AGENTS; do
  d="$LANE/created-by-$a"
  mkdir -p "$d"
  [ -z "$(ls -A "$d" 2>/dev/null)" ] && : > "$d/.gitkeep"
done

if [ "$WANT_LOGS" = yes ]; then
  mkdir -p logs
  [ -f logs/README.md ] || echo "See my-template/logs/README.md for the convention." > logs/README.md
fi

# ---- 4. Flag the layout that should not exist --------------------------------
for w in $WRONG; do
  if [ -d "$w" ]; then
    echo ""
    echo "  ⚠ '$w/' exists but should not in a $MODE repo."
    if [ -z "$(ls -A "$w" 2>/dev/null)" ]; then
      rmdir "$w" && echo "    (was empty — removed)"
    else
      echo "    It has content, so nothing was deleted. Move it into the private repo"
      echo "    and remove it here. Session logs must never reach a public mirror."
    fi
  fi
done

echo ""
echo "✓ $LANE/ scaffolded ($(ls -1 "$LANE" | wc -l | tr -d ' ') lanes)"
echo ""
echo "Reminder: if this repo syncs to a public mirror, any NEW root directory must be"
echo "classified in .github/workflows/sync-public.yml in the same commit, or the next"
echo "sync fails (allowlist model) or leaks (exclude model)."
