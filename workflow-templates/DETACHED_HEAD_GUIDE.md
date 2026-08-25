---
name: detached-head-guide-stub
description: Redirect stub — canonical detached-HEAD teaching guide lives in divorce-custody-assistant
metadata:
  type: reference
---

# Detached HEAD Guide — see canonical file

This is a pointer, not a copy. The full guide — what detached HEAD means, why one particular repo
runs a detached checkout as its primary working environment on purpose, and the quick-reference
commands to tell an attached checkout from a detached one — lives at:

**[`divorce-custody-assistant/DETACHED_HEAD_GUIDE.md`](https://github.com/drasticstatic/divorce-custody-assistant/blob/main/DETACHED_HEAD_GUIDE.md)**

Short version: that checkout is where real work has been landing and pushing successfully; a separate
Augment Intent worktree has drifted stale by comparison. The one command the whole setup exists to
explain: when a push from a detached checkout fails (common with editor git UIs, including VS Code),
run `git push origin HEAD:main` directly.

If any repo in the ecosystem finds itself in an unexpected detached-HEAD state, check that file's
Quick Reference table before assuming something's wrong — `git status --short --branch` and
`git worktree list --porcelain` will tell you whether it's a deliberate setup like this one.
