#!/bin/sh
# nest-manifest.selftest.sh: proves nest-manifest.py on fake nests in a throwaway folder. Nothing real is read: no gh
# calls (--no-gh, a cache made here), no private-word file but the one made here.
#
#   sh scripts/nest-manifest.selftest.sh
#
# Exit codes: 0 every case as expected · 1 a case failed.
set -u
here="$(cd "$(dirname "$0")" && pwd)"
R="$(mktemp -d "${TMPDIR:-/tmp}/nest-selftest.XXXXXX")" || exit 1
R="$(cd "$R" && pwd -P)"
N="$R/nest"; mkdir -p "$N"
mk() { mkdir -p "$1"; git -C "$1" init -q -b main; git -C "$1" -c core.hooksPath=/dev/null -c user.email=a@b -c user.name=a commit -q --allow-empty -m one; }
T="python3 -I $here/nest-manifest.py --no-gh --cache $R/cache.json --private-file $R/private.txt"
pass=0; fail=0; ok() { if [ "$1" = "$2" ]; then pass=$((pass+1)); else fail=$((fail+1)); echo "FAIL $3: got [$1] want [$2]"; fi; }
M="$N/MANIFEST.md"
row() { grep -F "| $1 |" "$M" | head -1; }

# fixture: a parent repo with a tracked child (alpha, pushed then one ahead), an unignored one (beta), a plain folder
# holding a repo (shelf/delta), a repo with a nested repo (eps/phi), a private one, a plain folder and a dot repo
mk "$N"; printf 'alpha/\neps/\nshelf/\nsealed-matter-x/\n.github/\n*.code-workspace\n' > "$N/.gitignore"
git init -q --bare "$R/remote.git"
mk "$N/alpha"; git -C "$N/alpha" remote add origin "https://github.com/someone/alpha.git"
git -C "$N/alpha" push -q "$R/remote.git" main 2>/dev/null; git -C "$N/alpha" fetch -q "$R/remote.git" main:refs/remotes/origin/main
git -C "$N/alpha" branch -q --set-upstream-to=origin/main; git -C "$N/alpha" -c core.hooksPath=/dev/null -c user.email=a@b -c user.name=a commit -q --allow-empty -m two
mk "$N/beta"; mk "$N/shelf/delta"; mk "$N/eps"; mk "$N/eps/phi"; printf 'phi/\n' > "$N/eps/.gitignore"
mk "$N/.github"; mkdir -p "$N/assets" "$N/sealed-matter-x"; printf 'gitdir: %s/nowhere\n' "$R" > "$N/sealed-matter-x/.git"
printf '# words\nsealed-matter\n' > "$R/private.txt"
printf '{"repos":{"someone/alpha":"private"},"owners":{}}' > "$R/cache.json"
cat > "$N/nest.code-workspace" <<'EOF'
{
  // VS Code allows comments
  "folders": [
    { "path": "alpha" },
    { "path": "shelf/delta" },
    { "path": "eps" },
    { "path": ".github" },
    { "path": "gone" },
    { "name": "nest (parent)", "path": "." },
  ],
}
EOF
before=$(git -C "$N/alpha" status --porcelain; ls -A "$N/beta" "$N/eps")

$T "$N" >/dev/null; ok "$?" 0 "first run writes"
ok "$(grep -c 'nest-manifest:begin' "$M")" 1 "the generated markers are written"
ok "$(row '`alpha`' | grep -c 'someone/alpha | private | main | 1 / 0 |')" 1 "alpha: origin, cached visibility, branch, one ahead"
ok "$(row '`beta`' | grep -c 'no origin | — | main | no upstream |.* | no | no |$')" 1 "beta: no origin, no upstream, not in workspace, not ignored"
ok "$(row '`shelf/delta`' | grep -c '| yes | yes |$')" 1 "a repo inside a plain folder is a child"
ok "$(row '↳ `eps/phi`' | grep -c 'yes (by `eps`)')" 1 "a nested repo is indented and checked against its own folder"
ok "$(grep -c 'sealed' "$M")" 0 "the private folder is never named"
ok "$(grep -c '^\*\*Private:\*\* 1 more' "$M")" 1 "the private folder is counted"
ok "$(grep -c 'Other folders (not repositories):\*\* `assets`' "$M")" 1 "a plain folder is listed as one"
ok "$(grep -c 'missing: `' "$M")" 1 "a workspace entry for a missing folder is reported"
ok "$(row '`.github`' | grep -c '| yes | yes |$')" 1 "a dot-folder repo is a child"
ok "$(git -C "$N/alpha" status --porcelain; ls -A "$N/beta" "$N/eps")" "$before" "children are not written to"

out=$($T "$N" --check); ok "$?" 1 "--check finds the gaps"
ok "$(printf '%s\n' "$out" | grep -c '`beta`')" 2 "--check: beta not in the workspace and not ignored"
ok "$(printf '%s\n' "$out" | grep -c 'missing')" 1 "--check: the missing folder"

# the hand-written part survives, and its on-purpose line is read back
sed -i.bak 's/^Outside the workspace on purpose:.*/Outside the workspace on purpose: `beta`/' "$M" && rm -f "$M.bak"
printf '\nA note of my own.\n' >> "$M"
$T "$N" >/dev/null
ok "$(grep -c 'A note of my own.' "$M")" 1 "text outside the markers survives a rewrite"
ok "$(row '`beta`' | grep -c 'on purpose, no')" 1 "the on-purpose line exempts beta from the workspace check"
printf 'beta/\n' >> "$N/.gitignore"; sed -i.bak '/"gone"/d' "$N/nest.code-workspace" && rm -f "$N/nest.code-workspace.bak"
$T "$N" --check >/dev/null; ok "$?" 0 "--check is clean once both are fixed"

# a plain (not a repo) nest: no ignore column, a workspace elsewhere via --workspace, the manifest via --out
P="$R/org"; mk "$P/one"; mk "$P/two"; printf '{"folders":[{"path":"org/one"},{"path":"org/two"}]}' > "$R/org.code-workspace"
$T "$P" --workspace "$R/org.code-workspace" --out "$R/ORG.md" >/dev/null
ok "$(grep -c '| yes | — |$' "$R/ORG.md")" 2 "a plain nest: in the workspace, no ignore column"
ok "$($T "$P" --workspace "$R/org.code-workspace" --check >/dev/null; echo $?)" 0 "--check passes for a plain nest"
ok "$($T "$R/org" --check | grep -c 'no workspace file')" 1 "a nest with no workspace file says so"

# a workspace that lists a plain folder covers the repositories inside it
mkdir -p "$P/box"; mk "$P/box/three"; printf '{"folders":[{"path":"org/one"},{"path":"org/two"},{"path":"org/box"}]}' > "$R/org.code-workspace"
$T "$P" --workspace "$R/org.code-workspace" --out "$R/ORG.md" >/dev/null
ok "$(grep -F '| `box/three` |' "$R/ORG.md" | grep -c 'yes (via `box`)')" 1 "a repo inside a listed plain folder counts as in the workspace"

# a manifest that lost its markers is refused, not rewritten
printf '# mine\n' > "$P/MANIFEST.md"; $T "$P" >/dev/null; ok "$?" 2 "lost markers: refused"
ok "$(cat "$P/MANIFEST.md")" "# mine" "lost markers: left as it was"

echo "nest-manifest: $pass passed, $fail failed"; exit $fail
