---
name: detached-head-guide-stub
description: Redirect stub — canonical detached-HEAD teaching guide lives in divorce-custody-assistant
metadata:
  type: reference
---

# Detached HEAD Guide — see canonical file

This is a pointer, not a copy. The full guide — what detached HEAD means, why one particular repo
keeps a checkout deliberately detached as a hands-on git-learning sandbox (not an oversight), and the
quick-check commands to tell an attached checkout from a detached one — lives at:

**[`divorce-custody-assistant/DETACHED_HEAD_GUIDE.md`](https://github.com/drasticstatic/divorce-custody-assistant/blob/main/DETACHED_HEAD_GUIDE.md)**

Read it there for the full explanation, including the 2026-08-24 update (checked against actual git
history, correcting an earlier draft) on how Christopher actually uses the split: this checkout is where
real work has been landing and pushing successfully via Claude Code CLI; the Augment Intent worktree's
`main` has been sitting stale/behind. VS Code's push flow doesn't reliably handle pushing a detached HEAD
to a named remote branch, so Alfred fixes it with `git push origin HEAD:main` when that happens.

If any repo in the ecosystem finds itself in an unexpected detached-HEAD state, check that file's "Quick
check commands" section before assuming something's wrong — `git status --short --branch` and
`git worktree list --porcelain` will tell you whether it's a deliberate setup like this one.
