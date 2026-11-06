#!/bin/sh
# sync-local.sh — bring every local clone up to date with GitHub, so what VS Code shows is what GitHub holds.
#
#     sh scripts/sync-local.sh [--dry-run] [--no-fetch] [--skip-lanes] [--quiet] [ROOT ...]
#
#   (no flag)     fetch, then `git pull --rebase --autostash` each clone that is behind its upstream
#   --dry-run     fetch and report only; change no working tree
#   --no-fetch    report from what is already known locally (no network at all); implies --dry-run
#   --skip-lanes  leave out clones whose origin is a public lane (-public, -public-preview, -publish-preview)
#   --quiet       print only clones that are behind, ahead, dirty or in trouble, and the summary
#   ROOT ...      where to look (default: ~/code ~/drasticstaticLabs ~/dappu ~/theholyearthfoundation ~/psychedelicsinrecovery
#                 ~/Octagon-Religious-Research-Group-ORG ~/psanctuary ~/psanctuarychurch ~/taylordwraps
#                 ~/WILSONSLAWNMAINTENANCE)
#
# What it does, per clone found up to three folders deep under each ROOT (node_modules skipped):
#   - fetches its upstream, each network call time-limited (a stalling resolver: SOP-IT-001);
#   - reports branch, ahead/behind its upstream, and how many files are changed locally (dirty);
#   - when it is behind: `git pull --rebase --autostash`. Uncommitted work is stashed, the branch is rebased onto
#     GitHub's, and the work is put back. If the rebase conflicts, it is aborted at once and the clone is left
#     exactly as it was, reported as "conflict: left as it was" for a person to resolve.
# What it never does: push, force anything, switch branches, clone, delete, or touch a clone that is detached,
# has no upstream, or is already in the middle of a rebase or merge.
#
# Public lanes are receivers (a sync or a site build writes them; nobody edits them by hand). This script never clones
# one. A lane that is already cloned is pulled like any other clone, which is harmless (it only reads), unless
# --skip-lanes says to leave it out.
#
# Why: VS Code and every helper read local files. When GitHub has moved on (another helper pushed, the PDF bot
# committed, a Promote was merged), a stale clone shows the old page and invites a force-push later.
# Exit code: 0 when nothing is in trouble; 1 when at least one clone needs a person (conflict, fetch failed).
set -u

DRY=0; FETCH=1; SKIP_LANES=0; QUIET=0; ROOTS=""
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY=1 ;;
    --no-fetch) FETCH=0; DRY=1 ;;
    --skip-lanes) SKIP_LANES=1 ;;
    --quiet) QUIET=1 ;;
    -h|--help) sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*) echo "unknown option: $1" >&2; exit 2 ;;
    *) ROOTS="$ROOTS
$1" ;;
  esac
  shift
done
[ -n "$ROOTS" ] || ROOTS="$HOME/code
$HOME/drasticstaticLabs
$HOME/dappu
$HOME/theholyearthfoundation
$HOME/psychedelicsinrecovery
$HOME/Octagon-Religious-Research-Group-ORG
$HOME/psanctuary
$HOME/psanctuarychurch
$HOME/taylordwraps
$HOME/WILSONSLAWNMAINTENANCE"

limit () { perl -e 'alarm shift; exec @ARGV' "$@"; }   # limit SECONDS cmd...

TOTAL=0; PULLED=0; CURRENT=0; TROUBLE=0; SKIPPED=0; DIRTY=0
row () { # path branch ahead behind dirty result
  case "$6" in up\ to\ date*) [ "$QUIET" = 1 ] && [ "$3" = 0 ] && [ "$5" = 0 ] && return ;; esac
  printf '%-58s %-16s %5s %6s %5s  %s\n' "$1" "$2" "$3" "$4" "$5" "$6"
}

printf '%-58s %-16s %5s %6s %5s  %s\n' "clone" "branch" "ahead" "behind" "dirty" "result"
LIST=$(printf '%s\n' "$ROOTS" | while IFS= read -r root; do
  [ -n "$root" ] && [ -d "$root" ] || continue
  find "$root" -maxdepth 3 -name .git -not -path '*/node_modules/*' 2>/dev/null
done | sed 's:/\.git$::' | sort -u)

OLDIFS=$IFS
IFS='
'
for repo in $LIST; do
  IFS=$OLDIFS
  TOTAL=$((TOTAL+1))
  short=$(printf '%s' "$repo" | sed "s:^$HOME:~:")
  g () { git -C "$repo" "$@"; }
  origin=$(g remote get-url origin 2>/dev/null || true)
  case "$origin" in
    *-public|*-public.git|*-public-preview|*-public-preview.git|*-publish-preview|*-publish-preview.git)
      if [ "$SKIP_LANES" = 1 ]; then SKIPPED=$((SKIPPED+1)); row "$short" "-" "-" "-" "-" "skipped: public lane"; IFS='
'; continue; fi ;;
  esac
  gd=$(g rev-parse --git-dir 2>/dev/null) || { SKIPPED=$((SKIPPED+1)); row "$short" "-" "-" "-" "-" "skipped: not a git work tree"; IFS='
'; continue; }
  case "$gd" in /*) ;; *) gd="$repo/$gd" ;; esac
  branch=$(g symbolic-ref --short -q HEAD || echo "")
  dirty=$(g status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  [ "$dirty" != 0 ] && DIRTY=$((DIRTY+1))
  if [ -d "$gd/rebase-merge" ] || [ -d "$gd/rebase-apply" ] || [ -f "$gd/MERGE_HEAD" ]; then
    TROUBLE=$((TROUBLE+1)); row "$short" "${branch:--}" "-" "-" "$dirty" "skipped: a rebase or merge is already in progress"; IFS='
'; continue
  fi
  if [ -z "$branch" ]; then SKIPPED=$((SKIPPED+1)); row "$short" "(detached)" "-" "-" "$dirty" "skipped: detached HEAD"; IFS='
'; continue; fi
  up=$(g rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || echo "")
  if [ -z "$up" ]; then SKIPPED=$((SKIPPED+1)); row "$short" "$branch" "-" "-" "$dirty" "skipped: no upstream"; IFS='
'; continue; fi
  if [ "$FETCH" = 1 ]; then
    remote=${up%%/*}
    if ! limit 60 git -C "$repo" fetch -q "$remote" 2>/dev/null; then
      TROUBLE=$((TROUBLE+1)); row "$short" "$branch" "?" "?" "$dirty" "fetch failed or timed out (network? SOP-IT-001)"; IFS='
'; continue
    fi
  fi
  set -- $(g rev-list --left-right --count "HEAD...$up" 2>/dev/null || echo "? ?")
  ahead=$1; behind=$2
  if [ "$behind" = 0 ]; then
    CURRENT=$((CURRENT+1)); row "$short" "$branch" "$ahead" "$behind" "$dirty" "up to date$( [ "$ahead" != 0 ] && echo ', ahead: push it yourself when ready')"
  elif [ "$DRY" = 1 ]; then
    row "$short" "$branch" "$ahead" "$behind" "$dirty" "behind (dry run: not pulled)"
  elif limit 120 git -C "$repo" pull -q --rebase --autostash >/dev/null 2>&1; then
    PULLED=$((PULLED+1)); row "$short" "$branch" "$ahead" "$behind" "$dirty" "pulled"
  else
    if [ -d "$gd/rebase-merge" ] || [ -d "$gd/rebase-apply" ]; then
      g rebase --abort >/dev/null 2>&1
      TROUBLE=$((TROUBLE+1)); row "$short" "$branch" "$ahead" "$behind" "$dirty" "conflict: rebase aborted, left as it was"
    else
      TROUBLE=$((TROUBLE+1)); row "$short" "$branch" "$ahead" "$behind" "$dirty" "pull failed or timed out: left as it was"
    fi
  fi
  IFS='
'
done
IFS=$OLDIFS

echo ""
echo "clones: $TOTAL · pulled: $PULLED · already current: $CURRENT · skipped: $SKIPPED · need a person: $TROUBLE · with local changes: $DIRTY$( [ "$DRY" = 1 ] && echo ' · dry run')"
echo "Nothing was pushed. A clone that is ahead holds commits only you (or its helper) can push."
[ "$TROUBLE" = 0 ]
