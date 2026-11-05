#!/bin/sh
# repo-guard.sh — prints the GitHub settings a drasticstatic-managed repository should carry, as gh commands, and runs none of them.
#
#   sh scripts/repo-guard.sh --plan [path-to-a-clone]      # the current repository when no path is given
#
# --plan is the only mode. There is no --apply: a person with the role reads the plan, then pastes what they agree with.
# What it prints, for the repository at <path>:
#   1. a ruleset for main (and for preview, if that branch exists): changes arrive by pull request, the status checks the
#      repository actually has must pass (tripwire self-test, ggshield, image-size-check, lifecycle-scripts-check), no
#      force-push, no deletion;
#   2. the merge-method setting: squash and rebase off, merge commit on (SOP-OPS-002: a squash erases attribution);
#   3. a CODEOWNERS suggestion for PUBLIC-ALLOWLIST*.txt, .github/ and scripts/ (the files that decide what goes public
#      and what runs);
#   4. a plain note when the repository is private and its owner is on GitHub Free: rulesets and branch protection need
#      GitHub Pro (a personal account) or Team (an organisation) on a private repository, so until then the merge rule
#      is one people keep, not a lock the platform holds (SOP-IT-004, Safe to merge).
# Reads only: git for the remote and the branches, the clone's .github/workflows/ for which checks exist, and, when gh is
# signed in, a few GETs (repository visibility, existing rulesets, the owner's plan). Each gh call is time-limited, as in
# sop-template/repo/scripts/legend.sh, because the resolver stalls (SOP-IT-001). Without gh it still prints the plan,
# with <owner>/<repo> read from the remote and the plan-dependent lines marked "unknown".
# A public twin (name ends -public, -public-preview or -publish-preview) gets a deletion-only ruleset: its lane pushes straight
# to main through a deploy key, force-pushed on the allowlist model, so pull_request and non_fast_forward would break the sync
# (branch-protection/README.md); the guards belong on the source it is built from. Nothing here changes a repository, a
# setting or a file.
set -eu

usage() { echo "usage: sh scripts/repo-guard.sh --plan [path]   (prints gh commands; runs none of them)" >&2; exit 2; }
[ $# -ge 1 ] || usage
[ "$1" = "--plan" ] || usage
shift
[ $# -le 1 ] || usage
target="${1:-.}"
[ -d "$target" ] || { echo "repo-guard: $target is not a directory" >&2; exit 2; }
top="$(git -C "$target" rev-parse --show-toplevel 2>/dev/null)" || { echo "repo-guard: $target is not inside a git repository" >&2; exit 2; }

# ── facts from the clone (read-only git) ──────────────────────────────────────────────────────────────────────────────
remote="$(git -C "$top" remote get-url origin 2>/dev/null || true)"
slug=""
case "$remote" in
  *github.com[:/]*) slug="$(printf '%s' "$remote" | sed -E 's#^.*github\.com[:/]##; s#\.git$##; s#/+$##')" ;;
esac
case "$slug" in */*) ;; *) slug="" ;; esac
owner="${slug%%/*}"; repo="${slug##*/}"
[ -n "$slug" ] || { owner="<owner>"; repo="<repo>"; slug="<owner>/<repo>"; }

has_branch() { # local or on origin
  git -C "$top" show-ref --verify --quiet "refs/heads/$1" || git -C "$top" show-ref --verify --quiet "refs/remotes/origin/$1"
}
branches="main"
has_branch main || branches=""
has_branch preview && branches="${branches:+$branches }preview"
[ -n "$branches" ] || branches="main"   # a fresh repository: plan for main anyway

twin=0
case "$repo" in *-public|*-public-preview|*-publish-preview) twin=1 ;; esac

# Which checks does this repository actually run? A required check whose workflow is not in the repository never
# reports, and a check that never reports blocks every merge. So only checks found under .github/workflows/ are named.
# The context GitHub matches on is the job's name: its `name:` if set, else its id (the first key under jobs:).
wfdir="$top/.github/workflows"
job_context() { # <workflow file> -> the first job's name or id
  awk '
    /^jobs:/ { injobs=1; next }
    injobs && /^  [A-Za-z0-9_-]+:[ \t]*$/ && !id { sub(/^  /, ""); sub(/:.*/, ""); id=$0; next }
    injobs && id && /^    name:/ { sub(/^    name:[ \t]*/, ""); gsub(/^["'"'"']|["'"'"']$/, ""); name=$0; exit }
    injobs && id && /^  [A-Za-z0-9_-]+:[ \t]*$/ { exit }
    END { print (name != "" ? name : id) }' "$1"
}
has_paths_filter() { # a paths: filter under on: means the check will not report on every pull request
  awk '/^jobs:/ {exit} /^[ \t]+paths(-ignore)?:/ {found=1} END {exit !found}' "$1"
}
contexts=""; skipped=""; filtered=""
for want in tripwire-selftest image-size-check lifecycle-scripts-check; do
  f=""
  for cand in "$wfdir/$want.yml" "$wfdir/$want.yaml"; do [ -f "$cand" ] && f="$cand" && break; done
  if [ -z "$f" ]; then skipped="${skipped:+$skipped, }$want"; continue; fi
  ctx="$(job_context "$f")"; [ -n "$ctx" ] || ctx="$want"
  if has_paths_filter "$f"; then filtered="${filtered:+$filtered, }$ctx ($want.yml has a paths: filter)"; else contexts="${contexts:+$contexts
}$ctx"; fi
done

# ── facts from GitHub (read-only, optional, time-limited) ─────────────────────────────────────────────────────────────
api() { perl -e 'alarm 40; exec @ARGV' gh api "$@" 2>/dev/null; }
have_gh=0
if [ -n "$owner" ] && [ "$owner" != "<owner>" ] && command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then have_gh=1; fi
visibility="unknown"; owner_type="unknown"; plan="unknown"; existing=""; merge_now="unknown"; rulesets_api="unknown"
if [ "$have_gh" = 1 ]; then
  # gh api prints the error body on stdout when a call fails (404 on a repository it cannot see), so the exit status decides.
  if info="$(api "repos/$slug" --jq '[.visibility, .owner.type, (.allow_merge_commit|tostring), (.allow_squash_merge|tostring), (.allow_rebase_merge|tostring)] | @tsv')" && [ -n "$info" ]; then
    visibility="$(printf '%s' "$info" | cut -f1)"
    owner_type="$(printf '%s' "$info" | cut -f2)"
    merge_now="merge=$(printf '%s' "$info" | cut -f3) squash=$(printf '%s' "$info" | cut -f4) rebase=$(printf '%s' "$info" | cut -f5)"
  fi
  case "$owner_type" in
    Organization) plan="$(api "orgs/$owner" --jq '.plan.name // "unknown"')" || plan=unknown ;;
    User)         plan="$(api user --jq 'if .login == "'"$owner"'" then (.plan.name // "unknown") else "unknown (not the signed-in account)" end')" || plan=unknown ;;
  esac
  [ -n "$plan" ] || plan="unknown"
  if raw="$(perl -e 'alarm 40; exec @ARGV' gh api "repos/$slug/rulesets" 2>&1)"; then
    rulesets_api="available"
    existing="$(printf '%s' "$raw" | python3 -I -c 'import sys,json
try:
    for r in json.load(sys.stdin): print(f"{r[\"id\"]}\t{r[\"name\"]}")
except Exception: pass' 2>/dev/null || true)"
  else
    case "$raw" in *[Uu]pgrade*) rulesets_api="not on this plan" ;; *) rulesets_api="unknown" ;; esac
  fi
fi

free_private=0
case "$visibility" in private|internal)
  case "$plan" in free|Free|FREE) free_private=1 ;; esac
  [ "$rulesets_api" = "not on this plan" ] && free_private=1 ;;
esac

# ── the plan ──────────────────────────────────────────────────────────────────────────────────────────────────────────
echo "# repo-guard plan for $slug — printed $(date -u +%Y-%m-%dT%H:%MZ); NOTHING below has been run."
echo "# clone: $top"
echo "# visibility: $visibility · owner: $owner_type · plan: $plan · rulesets API: $rulesets_api · merge methods now: $merge_now"
echo "# branches planned: $branches$( [ "$twin" = 1 ] && printf ' · a public twin: deletion-only, its lane writes main directly' )"
if [ -n "$existing" ]; then
  echo "# rulesets already on this repository (id, name) — amend one with --method PUT repos/$slug/rulesets/<id> rather than POST a second:"
  printf '%s\n' "$existing" | while IFS="$(printf '\t')" read -r id name; do echo "#   $id  $name"; done
fi
[ -n "$contexts" ] && echo "# status checks found in .github/workflows/: $(printf '%s' "$contexts" | tr '\n' ',' | sed 's/,$//; s/,/, /g')"
[ -n "$skipped" ]  && echo "# not in this repository, so not required (add the workflow first, then the check): $skipped"
[ -n "$filtered" ] && echo "# left out because a paths: filter means it will not report on every pull request, and a required check that never reports blocks the merge: $filtered"
echo "# ggshield: the GitGuardian app reports as 'GitGuardian Security Checks'; it is listed below commented out — uncomment once the app is installed on this repository and you have seen that name on a pull request's Checks tab."
echo

if [ "$free_private" = 1 ]; then
  echo "# ─────────────────────────────────────────────────────────────────────────────────────────────────────────────"
  echo "# NOTE: $slug is $visibility and its owner is on GitHub Free. Rulesets and branch protection are not offered on a"
  echo "# private repository on that plan: section 1 below will be refused with an 'Upgrade' message until the owner is on"
  echo "# GitHub Pro (a personal account) or GitHub Team (an organisation). Sections 2 and 3 work on any plan. Until then the"
  echo "# merge rule (a person with the role merges, never a helper, never a squash) is a rule people keep, not a lock the"
  echo "# platform holds: SOP-IT-004, 'Safe to merge'. Say so in the repository's LEGEND.md row."
  echo "# ─────────────────────────────────────────────────────────────────────────────────────────────────────────────"
  echo
elif [ "$visibility" = "unknown" ] || [ "$plan" = "unknown" ]; then
  echo "# plan check skipped (gh not signed in, or the owner is not the signed-in account): if this repository is private, confirm"
  echo "# the owner's plan first — gh api user --jq .plan.name (a person) or gh api orgs/$owner --jq .plan.name (an organisation)."
  echo "# On GitHub Free, section 1 is refused on a private repository; sections 2 and 3 still apply."
  echo
fi

echo "# ── 1. rulesets: changes arrive by pull request, the checks pass, nothing is force-pushed or deleted ───────────"
echo "# required_approving_review_count is 0 because many of these repositories have one human with the role, and 1 would"
echo "# lock that person out of their own merge button. Raise it to 1 the day there are two. require_code_owner_review goes"
echo "# true once .github/CODEOWNERS (section 3) is in. No bypass_actors: the rule binds owners too, which is the point;"
echo "# branch-protection/README.md has the one safe way to loosen a ruleset for a single push, then restore it."
for br in $branches; do
  echo
  if [ "$br" = preview ]; then
    echo "# preview is where helpers push directly today (SOP-OPS-001). With pull_request on it, every change to preview needs a"
    echo "# branch and a pull request of its own. If that is more than this repository wants, keep only deletion (and"
    echo "# non_fast_forward) on preview and put pull_request and the checks on main alone."
  fi
  if [ "$twin" = 1 ]; then
    # A twin is written only by its lane: the sync pushes (and, on the allowlist model, force-pushes) straight to main through
    # a deploy key. pull_request would stop the lane, non_fast_forward would stop the force-push. Deletion-only, as
    # branch-protection/ruleset-public-preview.json; the guards for a twin sit on the source repository.
    echo "# a public twin: deletion-only. Its lane pushes straight to main through a deploy key (sync-public.yml, force-pushed on"
    echo "# the allowlist model), so pull_request and non_fast_forward would break the sync (branch-protection/README.md). The"
    echo "# pull-request rule and the checks belong on the source repository this twin is built from."
    echo "gh api repos/$slug/rulesets --method POST --input - <<'JSON'"
    echo "{"
    echo "  \"name\": \"protect-$br\","
    echo "  \"target\": \"branch\","
    echo "  \"enforcement\": \"active\","
    echo "  \"conditions\": { \"ref_name\": { \"include\": [\"refs/heads/$br\"], \"exclude\": [] } },"
    echo "  \"rules\": [ { \"type\": \"deletion\" } ]"
    echo "}"
    echo "JSON"
    continue
  fi
  if [ -z "$contexts" ]; then
    echo "# no required_status_checks rule below: none of the check workflows is in this clone's .github/workflows/ yet, and a"
    echo "# required check that never reports blocks every merge. Copy the workflows in first, run this plan again."
  fi
  echo "# to add ggshield once the GitGuardian app reports here: { \"context\": \"GitGuardian Security Checks\" } in required_status_checks"
  echo "gh api repos/$slug/rulesets --method POST --input - <<'JSON'"
  echo "{"
  echo "  \"name\": \"protect-$br\","
  echo "  \"target\": \"branch\","
  echo "  \"enforcement\": \"active\","
  echo "  \"conditions\": { \"ref_name\": { \"include\": [\"refs/heads/$br\"], \"exclude\": [] } },"
  echo "  \"rules\": ["
  echo "    { \"type\": \"deletion\" },"
  echo "    { \"type\": \"non_fast_forward\" },"
  echo "    { \"type\": \"pull_request\", \"parameters\": {"
  echo "        \"required_approving_review_count\": 0,"
  echo "        \"dismiss_stale_reviews_on_push\": true,"
  echo "        \"require_code_owner_review\": false,"
  echo "        \"require_last_push_approval\": false,"
  echo "        \"required_review_thread_resolution\": false } }$( [ -n "$contexts" ] && printf ',' )"
  if [ -n "$contexts" ]; then
    echo "    { \"type\": \"required_status_checks\", \"parameters\": {"
    echo "        \"strict_required_status_checks_policy\": true,"
    echo "        \"do_not_enforce_on_create\": false,"
    echo "        \"required_status_checks\": ["
    # one { "context": ... } per line, commas between and none after the last
    printf '%s\n' "$contexts" | awk 'NF { items[++n]=$0 } END { for (i=1;i<=n;i++) printf "          { \"context\": \"%s\" }%s\n", items[i], (i<n ? "," : "") }'
    echo "        ] } }"
  fi
  echo "  ]"
  echo "}"
  echo "JSON"
done
echo
echo "# ── 2. merge methods: merge commit only (a squash folds commits into one and erases their attribution; SOP-OPS-002) ─"
echo "gh api -X PATCH repos/$slug -F allow_squash_merge=false -F allow_rebase_merge=false -F allow_merge_commit=true"
echo "gh api repos/$slug --jq '{merge: .allow_merge_commit, squash: .allow_squash_merge, rebase: .allow_rebase_merge}'   # read it back"
echo
echo "# ── 3. CODEOWNERS: who must look when the public lists, the workflows or the scripts change ─────────────────────"
case "$owner_type" in
  Organization) handle="@$owner/stewards"; handle_note="@$owner/stewards is a team: create it (SOP-GOV-002), or write one login per line (@<login>)" ;;
  User)         handle="@$owner";          handle_note="" ;;
  *)            handle="@$owner";          handle_note="a login, or @<org>/<team> in an organisation" ;;
esac
echo "# Put this in .github/CODEOWNERS on the working branch (it is a file in the repository, so it goes in by pull request"
echo "# like anything else). It is advisory until require_code_owner_review is true in section 1; GitHub then asks a listed"
echo "# owner to review any pull request touching these paths."
[ -n "$handle_note" ] && echo "# $handle_note"
echo "cat > .github/CODEOWNERS <<'EOF'"
echo "# Code owners: a listed owner reviews any pull request that touches these paths."
echo "/PUBLIC-ALLOWLIST*.txt   $handle"
echo "/PUBLIC-LANE-MEDIA.txt   $handle"
echo "/.github/                $handle"
echo "/scripts/                $handle"
echo "EOF"
echo
echo "# ── done. Nothing above was run; a person with the role applies what they agree with. ──────────────────────────"
