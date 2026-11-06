#!/bin/sh
# clone-map.sh — one line per git repository on this machine: where it is, where it points, and whether it is a spare.
#
#     sh scripts/clone-map.sh [--json] [--duplicates] [ROOT ...]
#
#   (no flag)      a table: path, origin URL, current branch, dirty count, commits ahead of upstream, marks
#   --json         the same rows as a JSON array (one object per repository)
#   --duplicates   only the rows that share an origin URL with another row
#   ROOT ...       where to look (default: ~/code ~/dappu ~/code-forked ~/intent ~/littlebirds-git-home and every
#                  organisation folder: ~/theholyearthfoundation ~/psychedelicsinrecovery
#                  ~/Octagon-Religious-Research-Group-ORG ~/psanctuary ~/psanctuarychurch ~/taylordwraps
#                  ~/WILSONSLAWNMAINTENANCE)
#
# Columns:
#   path      the repository, with $HOME written as ~
#   origin    `git remote get-url origin`, or "-" when there is none
#   branch    the current branch, or "(detached)"
#   dirty     lines of `git status --porcelain`: changed, staged and untracked files together
#   ahead     commits on HEAD that its upstream lacks; 0 when the branch has no upstream (the marks say NO-UPSTREAM)
#   marks     DUPLICATE  another row has the same origin URL (compared with .git, a trailing slash, case and
#                        the ssh/https spelling ignored)
#             SPARE      a DUPLICATE that sits outside every ~/<org>/ folder while a copy inside one exists:
#                        the organisation's clone is the one to work in (NESTED-REPOS-GUIDE.md)
#             NOTED      a SPARE whose parent folder holds a WHERE-EVERYTHING-WENT.md, so the spare is accounted for
#             NO-UPSTREAM, NO-ORIGIN, DETACHED  as they say
#
# Read-only, by construction: GIT_OPTIONAL_LOCKS=0 so `git status` writes nothing, not even an index refresh;
# it never fetches, pulls, pushes, switches, clones or deletes. It looks up to four folders deep under each root
# (Intent keeps repositories at workspaces/<slug>/<repository>), skips node_modules, and does not descend into .git.
# A nested repository (a lab under ~/code with children inside it) is listed once for the parent and once per child.
#
# Exit code: 0 always, unless an option is unknown (2). Reporting a duplicate is information, not a failure.
set -u
export GIT_OPTIONAL_LOCKS=0

JSON=0; DUPS_ONLY=0; ROOTS=""
while [ $# -gt 0 ]; do
  case "$1" in
    --json) JSON=1 ;;
    --duplicates) DUPS_ONLY=1 ;;
    -h|--help) sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*) echo "unknown option: $1" >&2; exit 2 ;;
    *) ROOTS="$ROOTS
$1" ;;
  esac
  shift
done

ORG_ROOTS="$HOME/theholyearthfoundation
$HOME/psychedelicsinrecovery
$HOME/Octagon-Religious-Research-Group-ORG
$HOME/psanctuary
$HOME/psanctuarychurch
$HOME/taylordwraps
$HOME/WILSONSLAWNMAINTENANCE"

[ -n "$ROOTS" ] || ROOTS="$HOME/code
$HOME/dappu
$HOME/code-forked
$HOME/intent
$HOME/littlebirds-git-home
$ORG_ROOTS"

# Every .git (a folder, or the file a worktree keeps) up to four folders deep; never inside node_modules or another .git.
LIST=$(printf '%s\n' "$ROOTS" | while IFS= read -r root; do
  # A root written as ~ or ~/x, quoted on the line. An `if`, not a `case`: bash 3.2 (macOS /bin/sh) cannot parse a case
  # pattern's `)` inside $( ).
  if [ "$root" = '~' ] || [ "${root%%/*}" = '~' ]; then root="$HOME${root#?}"; fi
  [ -n "$root" ] && [ -d "$root" ] || continue
  find "$root" -maxdepth 4 -name node_modules -prune -o -name .git -print -prune 2>/dev/null
done | sed 's:/\.git$::' | sort -u)

TMP=$(mktemp "${TMPDIR:-/tmp}/clone-map.XXXXXX") || exit 1
trap 'rm -f "$TMP"' EXIT INT TERM   # the only file this script removes is its own temporary one

# One record per repository, fields separated by the unit separator (US, 0x1f) so a path may hold spaces.
US=$(printf '\037')
OLDIFS=$IFS
IFS='
'
for repo in $LIST; do
  IFS=$OLDIFS
  g () { git -C "$repo" "$@"; }
  g rev-parse --git-dir >/dev/null 2>&1 || { IFS='
'; continue; }
  origin=$(g remote get-url origin 2>/dev/null || true)
  [ -n "$origin" ] || origin="-"
  branch=$(g symbolic-ref --short -q HEAD 2>/dev/null || echo "(detached)")
  dirty=$(g status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  up=$(g rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || echo "")
  if [ -n "$up" ]; then ahead=$(g rev-list --count "$up..HEAD" 2>/dev/null || echo 0); hasup=1
  else ahead=0; hasup=0; fi
  # The key duplicates are compared on: lower case, no .git, no trailing slash, ssh and https spelled the same.
  key=$(printf '%s' "$origin" | tr 'A-Z' 'a-z' | sed -e 's#^git@\([^:]*\):#https://\1/#' -e 's#^ssh://git@#https://#' \
        -e 's#/*$##' -e 's#\.git$##')
  inorg=0
  for o in $(printf '%s\n' "$ORG_ROOTS"); do case "$repo" in "$o"/*) inorg=1 ;; esac; done
  noted=0; [ -f "$(dirname "$repo")/WHERE-EVERYTHING-WENT.md" ] && noted=1
  short=$(printf '%s' "$repo" | sed "s:^$HOME:~:")
  printf '%s\n' "$short$US$origin$US$branch$US$dirty$US$ahead$US$hasup$US$key$US$inorg$US$noted" >> "$TMP"
  IFS='
'
done
IFS=$OLDIFS

# Second pass: count each origin key, note whether an ~/<org>/ copy exists for it, then print.
awk -F "$US" -v json="$JSON" -v dupsonly="$DUPS_ONLY" '
function jstr(s) { gsub(/\\/, "\\\\", s); gsub(/"/, "\\\"", s); gsub(/\t/, "\\t", s); return "\"" s "\"" }
NR == FNR { if ($2 != "-") { n[$7]++; if ($8 == 1) org[$7] = 1 }; next }
{
  path=$1; origin=$2; branch=$3; dirty=$4; ahead=$5; hasup=$6; key=$7; inorg=$8; noted=$9
  dup = (origin != "-" && n[key] > 1) ? 1 : 0
  spare = (dup && !inorg && org[key]) ? 1 : 0
  if (dupsonly && !dup) next
  marks = ""
  if (dup) marks = marks "DUPLICATE "
  if (spare) marks = marks "SPARE "
  if (spare && noted) marks = marks "NOTED "
  if (origin == "-") marks = marks "NO-ORIGIN "
  else if (!hasup) marks = marks "NO-UPSTREAM "
  if (branch == "(detached)") marks = marks "DETACHED "
  sub(/ $/, "", marks)
  if (json) {
    printf("%s  {\"path\": %s, \"origin\": %s, \"branch\": %s, \"dirty\": %d, \"ahead\": %d, \"upstream\": %s, \"duplicate\": %s, \"spare\": %s, \"noted\": %s}",
      (rows++ ? ",\n" : "[\n"), jstr(path), jstr(origin == "-" ? "" : origin), jstr(branch), dirty, ahead,
      hasup ? "true" : "false", dup ? "true" : "false", spare ? "true" : "false", (spare && noted) ? "true" : "false")
  } else {
    if (!rows++) printf("%-62s %-70s %-24s %5s %5s  %s\n", "path", "origin", "branch", "dirty", "ahead", "marks")
    printf("%-62s %-70s %-24s %5s %5s  %s\n", path, origin, branch, dirty, ahead, marks)
    if (dup) dups++
    if (spare) spares++
  }
}
END {
  if (json) { print (rows ? "\n]" : "[]") }
  else {
    print ""
    printf("repositories: %d · sharing an origin with another: %d · spares outside ~/<org>/: %d\n", rows + 0, dups + 0, spares + 0)
    print "Read-only: nothing was fetched, pulled, pushed or removed. A spare is left where it is; a person decides, never a helper."
  }
}' "$TMP" "$TMP"
