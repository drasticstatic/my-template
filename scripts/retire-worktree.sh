#!/bin/sh
# retire-worktree.sh: make a linked worktree read-only history. A `git worktree lock` alone only stops prune, move
# and remove; it does not stop a commit. This adds the second half: that worktree (and only that one) runs the hooks in
# scripts/retired-worktree-hooks/, which refuse every ref update made from it, even with --no-verify.
#
#   sh scripts/retire-worktree.sh <worktree path> ["reason"]     # lock + guard (safe to run twice)
#   sh scripts/retire-worktree.sh --undo <worktree path>         # remove the guard; the lock stays (unlock by hand)
#
# How: turns on extensions.worktreeConfig in the repository (git 2.20+; core.bare/core.worktree must not be set in the
# shared config, which this checks), then sets core.hooksPath for that worktree only. Deletes nothing.
set -eu
HOOKS="$(cd "$(dirname "$0")" && pwd)/retired-worktree-hooks"
if [ "${1-}" = --undo ]; then
  git -C "$2" config --worktree --unset core.hooksPath && echo "guard removed from $2"; exit 0
fi
WT="${1:?worktree path}"; WHY="${2:-retired: history only; do not commit here}"
[ -f "$WT/.git" ] || { echo "$WT is not a linked worktree (no .git file)"; exit 1; }
COMMON="$(git -C "$WT" rev-parse --git-common-dir)"
case "$COMMON" in /*) ;; *) COMMON="$WT/$COMMON";; esac
for k in core.bare core.worktree; do
  v="$(git --git-dir="$COMMON" config --get "$k" || true)"
  [ -z "$v" ] || [ "$k:$v" = core.bare:false ] || { echo "refusing: $k is set in the shared config"; exit 1; }
done
git -C "$WT" worktree lock --reason "$WHY" "$WT" 2>/dev/null || true
git --git-dir="$COMMON" config extensions.worktreeConfig true
git -C "$WT" config --worktree core.hooksPath "$HOOKS"
# prove it without risk: a ref transaction that is prepared and then aborted creates nothing, whatever happens
if printf 'start\ncreate refs/retire-worktree-probe HEAD\nprepare\nabort\n' | git -C "$WT" update-ref --stdin >/dev/null 2>&1; then
  echo "GUARD FAILED: $WT still accepts ref updates"; exit 1
fi
echo "retired: $WT (locked; every ref update from it is refused)"
