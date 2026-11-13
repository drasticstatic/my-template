#!/bin/sh
# fork-staleness.selftest.sh: proves fork-staleness.sh's counts on throwaway repositories.
#
#   sh scripts/fork-staleness.selftest.sh
#
# Builds an "upstream" repository and two forks in a temporary folder (every remote is a local path, so --fetch never
# leaves the machine here), checks the pin, tag, behind and ahead counts with and without --fetch, and checks that no
# branch or HEAD moved. The folder is removed afterwards. It never reads your real clones.
#
# Exit codes: 0 every case as expected · 1 a case failed.
set -u
here="$(cd "$(dirname "$0")" && pwd)"
tool="$here/fork-staleness.sh"
[ -f "$tool" ] || { echo "selftest: $tool not found" >&2; exit 1; }
work="$(mktemp -d "${TMPDIR:-/tmp}/fork-staleness-selftest.XXXXXX")" || exit 1
work="$(cd "$work" && pwd -P)"
trap 'python3 -I -c "import shutil,sys; shutil.rmtree(sys.argv[1], ignore_errors=True)" "$work"' EXIT INT TERM

export HOME="$work/home"
mkdir -p "$HOME"
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL="$work/gitconfig"
git config --global user.name selftest
git config --global user.email selftest@localhost
git config --global init.defaultBranch main
git config --global advice.detachedHead false

fails=0; passes=0
ok()    { passes=$((passes+1)); echo "ok    $1"; }
bad()   { fails=$((fails+1)); echo "FAIL  $1"; [ -n "${2:-}" ] && printf '%s\n' "$2" | sed 's/^/      /'; }
check() { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1" "expected [$3]
got      [$2]"; fi; }
commit() { git -C "$1" commit --quiet --allow-empty -m "$2"; }
# field <tsv output> <repo> <column number>
field() { printf '%s\n' "$1" | awk -F'\t' -v r="$2" -v c="$3" '$1 == r { print $c }'; }

up="$work/up"; forks="$work/forks"
mkdir -p "$forks"
git init --quiet "$up"
commit "$up" one; commit "$up" two
git -C "$up" tag v1.0

# Fork A: cloned at v1.0, origin renamed to upstream, one commit of its own.
git clone --quiet "$up" "$forks/fork-a"
git -C "$forks/fork-a" remote rename origin upstream
commit "$forks/fork-a" "our note"

# Fork B: no upstream remote at all.
git init --quiet "$forks/fork-b"; commit "$forks/fork-b" solo

# A folder that is not a repository.
mkdir -p "$forks/plain-folder"

# Upstream moves on by three commits; fork A has not fetched.
commit "$up" three; commit "$up" four; commit "$up" five; git -C "$up" tag v1.1

before_head="$(git -C "$forks/fork-a" rev-parse HEAD)"
before_branch="$(git -C "$forks/fork-a" symbolic-ref HEAD)"

out="$(sh "$tool" --tsv "$forks")"
check "header row"                     "$(printf '%s\n' "$out" | head -1)" "$(printf 'repo\tbranch\thead\ttag\tupstream\tcompared\tbehind\tahead')"
check "fork-a: branch"                 "$(field "$out" fork-a 2)" "main"
check "fork-a: head is the pin"        "$(field "$out" fork-a 3)" "$(git -C "$forks/fork-a" rev-parse --short HEAD)"
check "fork-a: nearest tag"            "$(field "$out" fork-a 4)" "v1.0"
check "fork-a: upstream url"           "$(field "$out" fork-a 5)" "$up"
check "fork-a: compared with"          "$(field "$out" fork-a 6)" "upstream/main"
check "fork-a: behind, before a fetch" "$(field "$out" fork-a 7)" "0"
check "fork-a: ahead"                  "$(field "$out" fork-a 8)" "1"
check "fork-b: no upstream"            "$(field "$out" fork-b 5)" "(none)"
check "fork-b: no counts"              "$(field "$out" fork-b 7)" "-"
check "plain folder not listed"        "$(field "$out" plain-folder 1)" ""

out="$(sh "$tool" --tsv --fetch "$forks" 2>/dev/null)"
check "fork-a: behind, after --fetch"  "$(field "$out" fork-a 7)" "3"
check "fork-a: ahead, after --fetch"   "$(field "$out" fork-a 8)" "1"
check "--fetch brought the new tag"    "$(git -C "$forks/fork-a" tag -l v1.1)" "v1.1"

check "HEAD did not move"              "$(git -C "$forks/fork-a" rev-parse HEAD)" "$before_head"
check "branch did not change"          "$(git -C "$forks/fork-a" symbolic-ref HEAD)" "$before_branch"
check "working tree clean"             "$(git -C "$forks/fork-a" status --porcelain)" ""

# Without --fetch, a later upstream commit is not seen (no network, no fetch).
commit "$up" six
out="$(sh "$tool" --tsv "$forks")"
check "no fetch by default"            "$(field "$out" fork-a 7)" "3"

# Detached HEAD at the tag.
git -C "$forks/fork-a" checkout --quiet v1.0
out="$(sh "$tool" --tsv "$forks")"
check "detached HEAD shown"            "$(field "$out" fork-a 2)" "(detached)"
git -C "$forks/fork-a" checkout --quiet main

# Usage errors.
sh "$tool" "$work/no-such-folder" >/dev/null 2>&1; check "missing folder exits 2" "$?" "2"
sh "$tool" --bogus "$forks" >/dev/null 2>&1;       check "unknown option exits 2" "$?" "2"

echo ""
echo "fork-staleness selftest: $passes passed, $fails failed"
[ "$fails" -eq 0 ]
