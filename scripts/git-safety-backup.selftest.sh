#!/bin/sh
# git-safety-backup.selftest.sh: proves the backup in a throwaway folder, by restoring from what it wrote.
#
#   sh scripts/git-safety-backup.selftest.sh
#
# Every repository, the fake iCloud folder and the fake home are made at test time and removed afterwards. Planted
# "secrets" are harmless sentinels. It never reads your real clones or your real iCloud Drive.
#
# Exit codes: 0 every case as expected · 1 a case failed.
set -u
here="$(cd "$(dirname "$0")" && pwd)"
tool="$here/git-safety-backup.sh"
[ -f "$tool" ] || { echo "selftest: $tool not found" >&2; exit 1; }
work="$(mktemp -d "${TMPDIR:-/tmp}/gsb-selftest.XXXXXX")" || exit 1
work="$(cd "$work" && pwd -P)"
trap 'python3 -I -c "import shutil,sys; shutil.rmtree(sys.argv[1], ignore_errors=True)" "$work"' EXIT INT TERM

export HOME="$work/home"
mkdir -p "$HOME"
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL="$work/gitconfig"
git config --global user.name selftest
git config --global user.email selftest@localhost
git config --global init.defaultBranch main
git config --global advice.detachedHead false

SENTINEL="GSBSENTINEL""7f3a"      # assembled, so this file does not contain what it hunts for
cfg="$work/config"; dest="$work/icloud"; roots="$work/roots"
mkdir -p "$cfg" "$dest" "$roots"
: > "$cfg/skip.txt"

fails=0; passes=0
ok()   { passes=$((passes+1)); echo "ok    $1"; }
bad()  { fails=$((fails+1));  echo "FAIL  $1"; [ -n "${2:-}" ] && printf '%s\n' "$2" | sed 's/^/      /'; }
check() { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1" "expected [$3]
got      [$2]"; fi; }
run()  { sh "$tool" --config-dir "$cfg" --dest "$dest" "$@"; }

# Everything under .git: names, sizes, modification times, contents. A rewrite of any file shows here.
digest() {
  python3 -I - "$1" <<'PY'
import hashlib, os, sys
top = sys.argv[1]; out = hashlib.sha256()
for folder, dirs, files in sorted(os.walk(top)):
    dirs.sort()
    for f in sorted(files):
        p = os.path.join(folder, f); st = os.lstat(p)
        out.update(("%s %d %d\n" % (p, st.st_size, st.st_mtime_ns)).encode())
        out.update(open(p, "rb").read() if os.path.isfile(p) else b"")
print(out.hexdigest())
PY
}
slug() { printf '%s' "${1#/}" | sed 's#/#--#g'; }           # the folder name, up to its short hash
one_bundle() { ls "$dest"/"$1"*/*.bundle 2>/dev/null | tail -1; }
count_bundles() { ls "$dest"/"$1"*/*.bundle 2>/dev/null | wc -l | tr -d ' '; }

# ── 1. one repository holding every kind of work ─────────────────────────────────────────────────────────────────────
git init -q --bare "$work/origin.git"
git clone -q "$work/origin.git" "$roots/work" 2>/dev/null
cd "$roots/work" || exit 1
printf '*.log\n' > .gitignore
echo one > tracked.txt; echo keep > unstaged.txt; echo gone > gone.txt; echo base > both.txt; echo v1 > wallet.json
git add . && git commit -q -m base && git push -q origin main
echo more > unpushed.txt; git add . && git commit -q -m "unpushed on main"
git switch -q -c feature; echo f > feature.txt; git add . && git commit -q -m "unpushed branch"; git switch -q main
echo "stashed" > stashed.txt; git stash push -q -u -m kept-stash
echo "$SENTINEL-stash" > .env.stash; git stash push -q -u -m secret-stash
git stash list | wc -l | tr -d ' ' > "$work/stash-count"
echo staged >> tracked.txt; git add tracked.txt
echo new > staged-new.txt; git add staged-new.txt
echo "both staged" >> both.txt; git add both.txt; echo "both unstaged" >> both.txt
echo edited >> unstaged.txt
rm gone.txt
mkdir -p "dir with space"; echo u > "dir with space/untracked file.txt"; echo u > "caf$(printf '\303\251').txt"
echo "$SENTINEL-ignored" > ignored.log
mkdir -p node_modules/pkg; echo "$SENTINEL-nodemodules" > node_modules/pkg/index.js
python3 -I -c "open('big.bin','w').write('$SENTINEL-big ' * 200000)"
# staged and tracked secret-named paths, not only untracked ones
echo "$SENTINEL-stagedpem" > staged.pem; git add staged.pem
echo "$SENTINEL-trackedwallet" >> wallet.json
for name in .env .env.local server.pem deploy.key client.p12 wallet.dat my-mnemonic.txt app.secret.json id_rsa SERVER.PEM; do
  echo "$SENTINEL-$name" > "$name"
done
mkdir -p keystore config; echo "$SENTINEL-keystore" > keystore/UTC--fake.json; echo "$SENTINEL-cfg" > config/.env.prod
LEFT_OUT='\.env|\.pem|\.key|\.p12|wallet|mnemonic|\.secret|id_rsa|keystore|config/|node_modules|big\.bin|ignored\.log'
expected_status="$(git status --porcelain --untracked-files=all | grep -v -E "$LEFT_OUT" | LC_ALL=C sort)"

before="$(digest .git)"
stash_before="$(git stash list --format=%H)"
out="$(run --root "$roots" --max-file-mb 1 2>&1)"; rc=$?
check "the run succeeds" "$rc" 0
check "the real .git is untouched: index, refs, stash, objects" "$(digest .git)" "$before"
check "the stash list is unchanged" "$(git stash list --format=%H)" "$stash_before"
case "$out" in *"left out by name"*) ok "left-out paths are counted in the log" ;; *) bad "counted" "$out" ;; esac
case "$out" in *wallet.dat*|*server.pem*|*"$SENTINEL"*) bad "the log names no left-out path" "$out" ;; *) ok "the log names no left-out path" ;; esac
case "$out" in *"over 1 MB"*) ok "an oversize file earns a warning" ;; *) bad "oversize warning" "$out" ;; esac

s="$(slug "$roots/work")"
bundle="$(one_bundle "$s")"
[ -f "$bundle" ] && ok "a bundle is in place" || bad "a bundle is in place" "$out"
case "$(basename "$bundle")" in [0-9]*T[0-9]*Z.bundle) ok "it carries a UTC timestamp" ;; *) bad "timestamp" "$bundle" ;; esac
ls "$dest"/"$s"* | grep -q partial && bad "no partial file is left" || ok "no partial file is left"

# ── 2. the restore steps, exactly as the walkthrough gives them ──────────────────────────────────────────────────────
cp "$bundle" "$work/copy.bundle"
git clone -q "$work/origin.git" "$work/restored" 2>/dev/null
cd "$work/restored" || exit 1
git bundle verify -q "$work/copy.bundle" >/dev/null 2>&1 && ok "git bundle verify passes in a fresh clone" || bad "verify in fresh clone"
git fetch -q "$work/copy.bundle" 'refs/*:refs/restored/*' && ok "the bundle fetches into a fresh clone" || bad "fetch"
git rev-parse -q --verify refs/restored/heads/feature >/dev/null && ok "the unpushed branch came through" || bad "feature branch"
git branch -q feature refs/restored/heads/feature
check "its commit is the right one" "$(git log -1 --format=%s feature)" "unpushed branch"
git rev-parse -q --verify refs/restored/heads/main >/dev/null && ok "the unpushed commit on main came through" || bad "main"

base="$(git log -1 --format='%(trailers:key=Base,valueonly)' refs/restored/safety/wip)"
git switch -q --detach "$base"
git read-tree -u --reset refs/restored/safety/wip
git read-tree "$(git rev-parse -q --verify refs/restored/safety/wip-staged || echo "$base")"
git switch -q -c recovered-work
check "staged, unstaged, untracked and deleted all come back as they were" \
  "$(git status --porcelain --untracked-files=all | LC_ALL=C sort)" "$expected_status"
check "the staged half of a half-staged file is staged" "$(git show :both.txt)" "base
both staged"
check "the unstaged half is in the file" "$(cat both.txt)" "base
both staged
both unstaged"
[ -f "dir with space/untracked file.txt" ] && ok "a path with spaces came through" || bad "spaces"
[ -f "caf$(printf '\303\251').txt" ] && ok "a non-ASCII path came through" || bad "non-ASCII"
[ ! -e gone.txt ] && ok "the deletion came through" || bad "deletion"

stash_refs="$(git for-each-ref --format='%(refname)' 'refs/restored/safety/stash')"
check "one stash came through, one with a secret-named path stayed behind" "$(printf '%s\n' "$stash_refs" | grep -c .)" 1
git stash store -m restored "$(git rev-parse "$stash_refs")" && git stash show --include-untracked --name-only stash@{0} 2>/dev/null | grep -q stashed.txt \
  && ok "the stash entry restores" || bad "stash restore"

# ── 3. nothing planted is in the bundle, by name or by content ───────────────────────────────────────────────────────
names="$(for r in $(git for-each-ref --format='%(refname)' refs/restored); do git ls-tree -r --name-only "$r"; done | LC_ALL=C sort -u)"
leaked="$(printf '%s\n' "$names" | grep -E '(^|/)(\.env|.*\.pem|.*\.key|.*\.p12|.*mnemonic|.*\.secret|id_rsa|keystore|config/|node_modules|big\.bin|ignored\.log)' || true)"
check "git ls-tree: no planted path in any ref" "$leaked" ""
check "wallet.json is carried at its pushed version, without the edit" "$(git show refs/restored/safety/wip:wallet.json)" v1
found="$(git cat-file --batch-all-objects --batch 2>/dev/null | LC_ALL=C grep -a -c "$SENTINEL")"
check "no planted content in any object the bundle delivered" "$found" 0
cd "$roots/work" || exit 1
check "the original still has its files" "$(cat .env)" "$SENTINEL-.env"
check "and its staging is as it was" "$(git diff --cached --name-only | grep -c staged.pem)" 1

# ── 4. writes only when there is something new ───────────────────────────────────────────────────────────────────────
n="$(count_bundles "$s")"
run --root "$roots" --max-file-mb 1 >/dev/null 2>&1
check "an unchanged repository writes nothing" "$(count_bundles "$s")" "$n"
run --root "$roots" --max-file-mb 1 --dry-run >/dev/null 2>&1
echo change >> unstaged.txt
out="$(run --root "$roots" --max-file-mb 1 --dry-run 2>&1)"
case "$out" in *"WOULD WRITE"*) ok "--dry-run reports the change" ;; *) bad "dry-run report" "$out" ;; esac
check "--dry-run writes nothing" "$(count_bundles "$s")" "$n"
for i in 1 2 3; do echo "$i" >> unstaged.txt; run --root "$roots" --max-file-mb 1 --keep 2 >/dev/null 2>&1; done
check "only the newest are kept" "$(count_bundles "$s")" 2

# ── 5. a clean, pushed repository; and one with no remote ────────────────────────────────────────────────────────────
git init -q --bare "$work/clean-origin.git"
git clone -q "$work/clean-origin.git" "$roots/clean" 2>/dev/null
cd "$roots/clean" || exit 1; echo x > x; git add . && git commit -q -m x && git push -q origin main
git init -q "$roots/lonely"
cd "$roots/lonely" || exit 1; echo a > a; git add . && git commit -q -m first; echo b > b; git add . && git commit -q -m second
echo c > c
run --root "$roots" >/dev/null 2>&1
check "a clean, fully pushed repository writes nothing" "$(count_bundles "$(slug "$roots/clean")")" 0
lb="$(one_bundle "$(slug "$roots/lonely")")"
mkdir -p "$work/lonely-restored" && cd "$work/lonely-restored" && git init -q
git bundle verify -q "$lb" >/dev/null 2>&1 && ok "a no-remote bundle verifies in an empty repository" || bad "no-remote verify"
git fetch -q "$lb" 'refs/*:refs/restored/*'
check "it holds the whole history" "$(git rev-list --count refs/restored/heads/main)" 2
check "and the uncommitted file" "$(git show refs/restored/safety/wip:c)" c

# ── 6. a repository in the middle of something is left alone ─────────────────────────────────────────────────────────
git init -q "$work/deferroot-tmpl"
for state in index.lock rebase-merge rebase-apply MERGE_HEAD CHERRY_PICK_HEAD; do
  r="$work/defer/$state"; mkdir -p "$r"; cd "$r" || exit 1; git init -q; echo a > a; git add .; git commit -q -m a; echo b > b
  case "$state" in rebase-*) mkdir ".git/$state" ;; *) : > ".git/$state" ;; esac
  out="$(run --root "$r" 2>&1)"
  case "$out" in *DEFER*) ok "$state: deferred" ;; *) bad "$state: deferred" "$out" ;; esac
  check "$state: nothing written" "$(count_bundles "$(slug "$r")")" 0
done

# ── 7. the skip list ─────────────────────────────────────────────────────────────────────────────────────────────────
mkdir -p "$work/skiproot/private-thing/inner"
cd "$work/skiproot/private-thing/inner" || exit 1; git init -q; echo a > a
cd "$work/skiproot/private-thing" || exit 1; git init -q; echo a > a; git add a; git commit -q -m a; echo b > b
git worktree add -q "$work/skiproot/elsewhere" 2>/dev/null
git clone -q . "$work/skiproot/renamed-clone" 2>/dev/null
before="$(digest .git)"
echo "private-thing" > "$cfg/skip.txt"
out="$(run --root "$work/skiproot" --verbose 2>&1)"
check "a skipped repository is not opened" "$(digest .git)" "$before"
case "$out" in *WROTE*) bad "a skipped repository, its worktree and a clone of it write nothing" "$out" ;; *) ok "a skipped repository, its worktree and a clone of it write nothing" ;; esac
: > "$cfg/skip.txt"
mv "$cfg/skip.txt" "$cfg/skip.txt.away"
run --root "$roots" >/dev/null 2>&1; check "no skip list: refuses to run" "$?" 3
run --root "$roots" --dry-run >/dev/null 2>&1; check "no skip list: --dry-run refuses too" "$?" 3
sh "$tool" --config-dir "$work/fresh-config" --init >/dev/null; check "--init writes the list" "$?" 0
[ -f "$work/fresh-config/skip.txt" ] && ok "the list exists" || bad "the list exists"
mv "$cfg/skip.txt.away" "$cfg/skip.txt"
sh "$tool" --config-dir "$cfg" --root "$roots" >/dev/null 2>&1; check "no iCloud Drive and no --dest: refuses" "$?" 4

# ── 8. a secret committed but not pushed; the size cap; a linked worktree ────────────────────────────────────────────
git init -q --bare "$work/held-origin.git"; git clone -q "$work/held-origin.git" "$work/heldroot/held" 2>/dev/null
cd "$work/heldroot/held" || exit 1; echo x > x; git add .; git commit -q -m x; git push -q origin main
echo "$SENTINEL-committed" > .env; git add -f .env; git commit -q -m "oops"
out="$(run --root "$work/heldroot" 2>&1)"
case "$out" in *HELD*) ok "a secret-named path in unpushed commits holds the repository back" ;; *) bad "held" "$out" ;; esac
check "and writes nothing" "$(count_bundles "$(slug "$work/heldroot/held")")" 0
printf '%s\n' "$work/heldroot/held" > "$cfg/history-ok.txt"
run --root "$work/heldroot" >/dev/null 2>&1
check "history-ok.txt lets a person decide" "$(count_bundles "$(slug "$work/heldroot/held")")" 1
: > "$cfg/history-ok.txt"
git rm -q --cached .env; printf '.env.example\n' > /dev/null; echo TEMPLATE=1 > .env.example; git add .env.example; git reset -q --hard origin/main
echo TEMPLATE=1 > .env.example; git add -f .env.example; git commit -q -m "a template"
out="$(run --root "$work/heldroot" 2>&1)"
case "$out" in *HELD*) bad "a committed .env.example is not held" "$out" ;; *) ok "a committed .env.example is not held" ;; esac

git init -q "$work/bigroot/big"; cd "$work/bigroot/big" || exit 1
python3 -I -c "import os; open('blob','wb').write(os.urandom(3*1024*1024))"; git add .; git commit -q -m blob
out="$(run --root "$work/bigroot" --max-bundle-mb 1 2>&1)"
case "$out" in *"TOO BIG"*) ok "a bundle over the cap earns a warning" ;; *) bad "bundle cap" "$out" ;; esac
check "and is not written" "$(count_bundles "$(slug "$work/bigroot/big")")" 0
out="$(run --root "$work/bigroot" --max-bundle-mb 1 2>&1)"
case "$out" in *"last too big"*) ok "an unchanged too-big repository is not bundled again" ;; *) bad "too-big memo" "$out" ;; esac
out="$(run --root "$work/bigroot" --max-bundle-mb 1 --dry-run 2>&1)"
case "$out" in *"would not be written"*"would write 0"*) ok "--dry-run reports it too, outside the total" ;; *) bad "dry-run over the cap" "$out" ;; esac

# Many changed files under the per-file cap: refused by adding up their sizes, before git reads any of them.
git init -q "$work/manyroot/many"; cd "$work/manyroot/many" || exit 1
echo a > a; git add a; git commit -q -m a
for i in 1 2 3 4 5; do python3 -I -c "open('run$i.log','wb').write(b'x' * (1024*1024))"; done
out="$(run --root "$work/manyroot" --max-bundle-mb 1 2>&1)"
case "$out" in *"so they were not read"*) ok "changed files far over the cap are refused unread" ;; *) bad "changed files over the cap" "$out" ;; esac
check "and nothing is written" "$(count_bundles "$(slug "$work/manyroot/many")")" 0

git init -q --bare "$work/wt-origin.git"; git clone -q "$work/wt-origin.git" "$work/wtroot/main-copy" 2>/dev/null
cd "$work/wtroot/main-copy" || exit 1; echo x > x; git add .; git commit -q -m x; git push -q origin main
git worktree add -q -b side "$work/wtroot/linked" 2>/dev/null
cd "$work/wtroot/linked" || exit 1; echo w > worktree-work.txt
before="$(digest "$work/wtroot/main-copy/.git")"
run --root "$work/wtroot" >/dev/null 2>&1
check "a linked worktree leaves the shared .git untouched" "$(digest "$work/wtroot/main-copy/.git")" "$before"
wb="$(one_bundle "$(slug "$work/wtroot/linked")")"
cd "$work/wtroot/main-copy" || exit 1
git clone -q "$work/wt-origin.git" "$work/wt-restored" 2>/dev/null; cd "$work/wt-restored" || exit 1
git fetch -q "$wb" 'refs/*:refs/restored/*'
check "and its uncommitted work comes back" "$(git show refs/restored/safety/wip:worktree-work.txt)" w

# ── 9. nothing staged: the same restore steps, and no secret-named path ever reaches the tree ───────────────────────────
git init -q --bare "$work/ns-origin.git"; git clone -q "$work/ns-origin.git" "$work/nsroot/ns" 2>/dev/null
cd "$work/nsroot/ns" || exit 1; echo a > a; git add .; git commit -q -m a; git push -q origin main
echo edit >> a; echo new > new.txt
run --root "$work/nsroot" >/dev/null 2>&1
nb="$(one_bundle "$(slug "$work/nsroot/ns")")"
git clone -q "$work/ns-origin.git" "$work/ns-restored" 2>/dev/null; cd "$work/ns-restored" || exit 1
git fetch -q "$nb" 'refs/*:refs/restored/*'
base="$(git log -1 --format='%(trailers:key=Base,valueonly)' refs/restored/safety/wip)"
git switch -q --detach "$base"
git read-tree -u --reset refs/restored/safety/wip
git read-tree "$(git rev-parse -q --verify refs/restored/safety/wip-staged || echo "$base")"
check "with nothing staged, the restore leaves it all unstaged" "$(git status --porcelain --untracked-files=all | LC_ALL=C sort)" " M a
?? new.txt"

# ── 10. a repository's LFS filter is not run: it would write into .git/lfs, and a missing git-lfs would stop the add ───
git init -q "$work/lfsroot/lfs"; cd "$work/lfsroot/lfs" || exit 1
echo a > a; git add a; git commit -q -m a
printf '*.bin filter=lfs\n' > .gitattributes
git config filter.lfs.clean "touch '$work/lfs-ran'; exit 1"
git config filter.lfs.required true
echo data > d.bin
out="$(run --root "$work/lfsroot" 2>&1)"; rc=$?
check "a required LFS filter does not stop the run" "$rc" 0
[ ! -e "$work/lfs-ran" ] && ok "and is not run" || bad "the LFS filter ran" "$out"
lb="$(one_bundle "$(slug "$work/lfsroot/lfs")")"
mkdir -p "$work/lfs-restored" && cd "$work/lfs-restored" && git init -q
git fetch -q "$lb" 'refs/*:refs/restored/*'
check "and the file travels whole" "$(git show refs/restored/safety/wip:d.bin)" data

# ── 11. a very long path still gets a folder name the disk accepts ───────────────────────────────────────────────────
long="$work/longroot"
for part in 1 2 3 4; do long="$long/$(printf "segment$part%060d" 0)"; done
mkdir -p "$long"; cd "$long" || exit 1; git init -q; echo a > a
out="$(run --root "$work/longroot" 2>&1)"; rc=$?
check "a long path: the run succeeds" "$rc" 0
check "a long path: the bundle is there" "$(count_bundles "$(slug "$long" | cut -c1-200)")" 1


# ── a stash on a commit no branch holds any more, and names people really use ────────────────────────────────────────
hunt() { # bundle-folder-slug origin: how many of the objects this bundle adds hold the sentinel
  hb="$(one_bundle "$1")"; hx="$work/hunt"; rm -rf "$hx"
  [ -f "$hb" ] || { echo none; return; }
  git clone -q --bare "$2" "$hx" 2>/dev/null
  git -C "$hx" cat-file --batch-all-objects --batch-check='%(objectname)' | LC_ALL=C sort > "$work/hunt.before"
  git -C "$hx" fetch -q "$hb" '+refs/*:refs/got/*' 2>/dev/null || { echo fetch-failed; return; }
  git -C "$hx" cat-file --batch-all-objects --batch-check='%(objectname)' | LC_ALL=C sort > "$work/hunt.after"
  LC_ALL=C comm -13 "$work/hunt.before" "$work/hunt.after" | while read -r o; do
    [ "$(git -C "$hx" cat-file -t "$o")" = blob ] && git -C "$hx" cat-file blob "$o" | LC_ALL=C grep -a -c "$SENTINEL"
  done | awk '{s+=$1} END {print s+0}'
}
newrepo() {
  git init -q --bare "$work/$1.git"; git clone -q "$work/$1.git" "$roots/$1" 2>/dev/null; cd "$roots/$1" || exit 1
  echo base > a.txt; git add .; git commit -q -m base; git push -q origin main
}

newrepo stashbase
echo "$SENTINEL-amended" > .env; git add .env; git commit -q -m oops
echo wip >> a.txt; git stash push -q -m on-a-bad-base
git reset -q --hard HEAD~1; echo keep > keep.txt
out="$(run --root "$roots/stashbase" 2>&1)"
check "a stash on a secret-touching commit no branch holds: nothing planted in the bundle" \
  "$(hunt "$(slug "$roots/stashbase")" "$work/stashbase.git")" 0
case "$out" in *"1 stash entr"*) ok "and that stash is counted as left behind" ;; *) bad "stash counted" "$out" ;; esac
git -C "$work/hunt" rev-parse -q --verify refs/got/safety/wip >/dev/null \
  && ok "and the rest of the work still travels" || bad "the rest of the work travels" "$out"

newrepo realnames
for name in secret.json client_secret_123.apps.googleusercontent.com.json .git-credentials serviceAccountKey.json \
  service_account.json my-wallet.json hot_wallet.dat api_keys.txt token.json private_key.txt deployer.key.bak .pypirc \
  .dockercfg passwords.txt backup.gpg UTC--2024-01-01T00-00-00.000Z--abc; do echo "$SENTINEL-$name" > "$name"; done
mkdir -p .aws; echo "$SENTINEL-aws" > .aws/config
printf 'export const useWallet = 1\n' > useWallet.ts
out="$(run --root "$roots/realnames" 2>&1)"
check "names people really use: nothing planted in the bundle" "$(hunt "$(slug "$roots/realnames")" "$work/realnames.git")" 0
git -C "$work/hunt" show refs/got/safety/wip:useWallet.ts 2>/dev/null | grep -q useWallet \
  && ok "source code that only mentions a wallet still travels" || bad "useWallet.ts travels" "$out"

# Git refreshes the modified time of an object it is asked to write again, so this compares names and contents, not times.
contents() {
  python3 -I -c '
import hashlib, os, sys
top = sys.argv[1]; out = hashlib.sha256()
for folder, dirs, files in sorted(os.walk(top)):
    dirs.sort()
    for f in sorted(files):
        p = os.path.join(folder, f); out.update(p.encode()); out.update(open(p, "rb").read())
print(out.hexdigest())
' "$1"
}
newrepo backtohead
echo "$SENTINEL-staged" > wallet.dat; git add wallet.dat; echo fine > ok.txt
index_before="$(stat -f '%m %z' .git/index; cksum < .git/index)"; before="$(contents .git)"
run --root "$roots/backtohead" >/dev/null 2>&1
check "a left-out staged file: the real index is the same, byte for byte and in its modified time" \
  "$(stat -f '%m %z' .git/index; cksum < .git/index)" "$index_before"
check "and no file under .git was added, removed or changed" "$(contents .git)" "$before"
check "and it is still staged" "$(git diff --cached --name-only)" wallet.dat
check "nothing planted in that bundle either" "$(hunt "$(slug "$roots/backtohead")" "$work/backtohead.git")" 0
cd "$work" || exit 1

# ── 12. the launchd template: valid, and on the key that catches up after sleep ──────────────────────────────────────
tpl="$here/launchd/git-safety-backup.plist.template"
sed -e "s#__HOME__#$HOME#g" -e "s#__SCRIPT__#$tool#g" "$tpl" > "$work/job.plist"
if command -v plutil >/dev/null 2>&1; then
  plutil -lint -s "$work/job.plist" >/dev/null && ok "the filled-in plist is valid" || bad "plist lint"
fi
check "no placeholder is left" "$(grep -c '__' "$work/job.plist")" 0
check "it fires twelve times a day" "$(grep -c '<key>Hour</key>' "$tpl")" 12
check "StartInterval, which misses a sleeping Mac, is not used" "$(grep -c '<key>StartInterval</key>' "$tpl")" 0

echo
if [ "$fails" -eq 0 ]; then echo "selftest: all $passes cases as expected."; exit 0; fi
echo "selftest: $fails failed, $passes passed."; exit 1
