#!/bin/sh
# set-merge-methods.sh: keep repositories on merge commits only (squash off, rebase off, merge commit on).
#   sh scripts/set-merge-methods.sh --audit OWNER [OWNER...]      read-only; exit 1 if any repository drifted
#   sh scripts/set-merge-methods.sh --fix OWNER/REPO [OWNER/REPO...]   squash off, rebase off, merge commit on
# Repositories listed in scripts/merge-methods-exceptions.txt (or $MERGE_EXCEPTIONS) are reported, never changed.
# Exit codes: 0 clean, or every fix applied · 1 drift found, a repository unreadable, or a fix failed · 2 usage.
set -u
here="$(cd "$(dirname "$0")" && pwd)"
GH="${GH:-gh}"
EXC="${MERGE_EXCEPTIONS:-$here/merge-methods-exceptions.txt}"

usage() { sed -n '2,6p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 2; }
is_exception() {
  [ -f "$EXC" ] || return 1
  sed 's/#.*//' "$EXC" | tr -d ' \t\r' | grep -qx "$1"
}
# Prints "merge squash rebase" as true/false words.
settings() { $GH api "repos/$1" -q '[.allow_merge_commit,.allow_squash_merge,.allow_rebase_merge]|map(tostring)|join(" ")'; }

[ $# -ge 2 ] || usage
mode="$1"; shift
rc=0

case "$mode" in
  --audit)
    for owner in "$@"; do
      case "$owner" in */*|'') echo "set-merge-methods: --audit takes owners, not owner/repo: '$owner'" >&2; exit 2;; esac
    done
    printf 'repository\tmerge\tsquash\trebase\tstate\n'
    for owner in "$@"; do
      repos=$($GH repo list "$owner" --limit 1000 --no-archived --json nameWithOwner -q '.[].nameWithOwner') \
        || { echo "set-merge-methods: cannot list '$owner'" >&2; rc=1; continue; }
      for r in $repos; do
        s=$(settings "$r") || { printf '%s\t?\t?\t?\tunreadable\n' "$r"; rc=1; continue; }
        m=${s%% *}; rest=${s#* }; q=${rest%% *}; b=${rest#* }
        if is_exception "$r"; then state=exception
        elif [ "$m" = true ] && [ "$q" = false ] && [ "$b" = false ]; then state=ok
        else state=DRIFT; rc=1
        fi
        printf '%s\t%s\t%s\t%s\t%s\n' "$r" "$m" "$q" "$b" "$state"
      done
    done
    ;;
  --fix)
    for r in "$@"; do
      case "$r" in */?*) ;; *) echo "set-merge-methods: --fix takes owner/repo, not '$r'" >&2; exit 2;; esac
    done
    for r in "$@"; do
      if is_exception "$r"; then echo "$r: skipped (listed in $(basename "$EXC"))"; continue; fi
      out=$($GH api -X PATCH "repos/$r" -F allow_squash_merge=false -F allow_rebase_merge=false -F allow_merge_commit=true \
        -q '[.allow_merge_commit,.allow_squash_merge,.allow_rebase_merge]|map(tostring)|join(" ")') \
        || { echo "$r: FAILED"; rc=1; continue; }
      if [ "$out" = "true false false" ]; then echo "$r: merge commits only"; else echo "$r: unexpected settings after fix ($out)"; rc=1; fi
    done
    ;;
  *) usage ;;
esac
exit $rc
