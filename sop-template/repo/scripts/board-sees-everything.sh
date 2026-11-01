#!/bin/sh
# board-sees-everything.sh — keep a board team's Read on every private repository of an organisation (SOP-GOV-001).
#   sh scripts/board-sees-everything.sh <org> [team] [--apply]
# A GitHub team sees only the repositories someone added to it, one by one. When the organisation's base permission is
# "No permission" (SOP-GOV-002), a repository created next month is invisible to the board until it is added. Run this
# after creating any repository, and once a month. Without --apply it only lists what is missing (read-only); with
# --apply it grants Read (pull) on each missing private repository. An owner runs it; it never adds or removes people.
set -eu
org="${1:?usage: board-sees-everything.sh <org> [team] [--apply]}"; team="${2:-board}"; apply="${3:-}"
[ "$team" = "--apply" ] && { team=board; apply=--apply; }
t () { perl -e 'alarm 90; exec @ARGV' "$@"; }   # the resolver can stall (SOP-IT-001)
t gh api "orgs/$org/teams/$team" --jq .slug >/dev/null 2>&1 || { echo "$org has no team named '$team' (create it first: SOP-GOV-001 step 1)."; exit 2; }
private=$(t gh api --paginate "orgs/$org/repos?type=private" --jq '.[] | select(.archived|not) | .name' | sort)
granted=$(t gh api --paginate "orgs/$org/teams/$team/repos" --jq '.[].name' | sort)
g=$(mktemp); trap 'rm -f "$g"' EXIT; printf '%s\n' "$granted" > "$g"
missing=$(printf '%s\n' "$private" | comm -23 - "$g")
if [ -z "$missing" ]; then echo "$org/$team reads all $(printf '%s\n' "$private" | grep -c .) private repositories."; exit 0; fi
echo "$org/$team is missing Read on:"; printf '  %s\n' $missing
[ "$apply" = "--apply" ] || { echo "(read-only; add --apply to grant Read on these)"; exit 1; }
for r in $missing; do t gh api -X PUT "orgs/$org/teams/$team/repos/$org/$r" -f permission=pull && echo "  granted Read: $r"; done
