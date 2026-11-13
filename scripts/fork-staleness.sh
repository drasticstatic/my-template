#!/bin/sh
# fork-staleness.sh: how far each fork's pin sits behind its upstream, from what git already knows.
#
#   sh scripts/fork-staleness.sh [--fetch] [--tsv] [<folder>]        (default folder: ~/code-forked)
#
# For each git repository directly under <folder> it prints:
#   repo      the folder name
#   branch    the checked-out branch, or "(detached)"
#   head      HEAD's short hash: the pinned revision
#   tag       the nearest tag reachable from HEAD, or "-"
#   upstream  the URL of the remote named "upstream", or "(none)"
#   compared  the upstream branch it was compared with: upstream/HEAD's target, else upstream/main or upstream/master
#   behind    commits on that branch that HEAD does not have
#   ahead     commits on HEAD that that branch does not have
# Counts come from the remote-tracking refs as of the last fetch: no network by default.
#
# --fetch   first runs `git fetch upstream --tags` in each repository that has an upstream remote. This is the ONLY
#           network call the script can make, and it never runs unless asked. A fetch updates remote-tracking refs and
#           adds tags; it does not move a branch, touch the working tree, or overwrite a tag that already exists.
# --tsv     tab-separated output with a header row, for scripts and the self-test.
#
# It never merges, checks out, resets or changes a branch. Reads run with GIT_OPTIONAL_LOCKS=0, so even the index is
# not refreshed. Folders that are not repositories are listed once as skipped.
#
# Exit codes: 0 done · 2 usage, or the folder does not exist.
# Self-test: sh scripts/fork-staleness.selftest.sh
set -u

fetch=0; tsv=0; dir=""
while [ $# -gt 0 ]; do
  case "$1" in
    --fetch) fetch=1 ;;
    --tsv) tsv=1 ;;
    -h|--help) sed -n '2,26p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    --*) echo "fork-staleness: unknown option $1" >&2; exit 2 ;;
    *) [ -z "$dir" ] || { echo "fork-staleness: one folder only" >&2; exit 2; }; dir="$1" ;;
  esac
  shift
done
[ -n "$dir" ] || dir="$HOME/code-forked"
[ -d "$dir" ] || { echo "fork-staleness: no such folder: $dir" >&2; exit 2; }

export GIT_OPTIONAL_LOCKS=0
g() { git -C "$repo" "$@" 2>/dev/null; }

row() {
  if [ "$tsv" -eq 1 ]; then
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$@"
  else
    printf '%-26s %-26s %-9s %-14s %-8s %-8s %-18s %s\n' "$1" "$2" "$3" "$4" "$7" "$8" "$6" "$5"
  fi
}

row repo branch head tag upstream compared behind ahead
skipped=""
for repo in "$dir"/*/; do
  [ -d "$repo" ] || continue
  repo="${repo%/}"
  name="$(basename "$repo")"
  if [ ! -e "$repo/.git" ]; then
    skipped="$skipped $name"
    continue
  fi
  url="$(g remote get-url upstream)" || url=""
  if [ -n "$url" ] && [ "$fetch" -eq 1 ]; then
    echo "fork-staleness: fetching upstream for $name" >&2
    git -C "$repo" fetch --quiet upstream --tags >&2 || echo "fork-staleness: fetch failed for $name" >&2
  fi
  branch="$(g symbolic-ref --quiet --short HEAD)" || branch="(detached)"
  head="$(g rev-parse --short HEAD)" || head="?"
  tag="$(g describe --tags --abbrev=0 HEAD)" || tag="-"
  compared="-"; behind="-"; ahead="-"
  if [ -n "$url" ]; then
    ref="$(g symbolic-ref --quiet --short refs/remotes/upstream/HEAD)" || ref=""
    if [ -z "$ref" ]; then
      for b in main master; do
        if g rev-parse --verify --quiet "refs/remotes/upstream/$b" >/dev/null; then ref="upstream/$b"; break; fi
      done
    fi
    if [ -n "$ref" ]; then
      compared="$ref"
      behind="$(g rev-list --count "HEAD..$ref")" || behind="?"
      ahead="$(g rev-list --count "$ref..HEAD")" || ahead="?"
    else
      compared="(not fetched)"
    fi
  else
    url="(none)"
  fi
  row "$name" "$branch" "$head" "$tag" "$url" "$compared" "$behind" "$ahead"
done

if [ -n "$skipped" ] && [ "$tsv" -eq 0 ]; then
  echo ""
  echo "Not repositories (skipped):$skipped"
fi
if [ "$tsv" -eq 0 ]; then
  if [ "$fetch" -eq 1 ]; then
    echo "Counts are as of the fetch just made."
  else
    echo "Counts are as of each repository's last fetch; nothing was fetched (--fetch would)."
  fi
fi
exit 0
