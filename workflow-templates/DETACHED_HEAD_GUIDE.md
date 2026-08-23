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

**`divorce-custody-assistant/DETACHED_HEAD_GUIDE.md`**

Read it there for the full explanation, including the 2026-08-23 update on how Christopher actually uses
the split (Intent workspace = durable `main`, detached home-repo worktree = safe sandbox for practicing
git concepts).

If any repo in the ecosystem finds itself in an unexpected detached-HEAD state, check that file's "Quick
check commands" section before assuming something's wrong — `git status --short --branch` and
`git worktree list --porcelain` will tell you whether it's a deliberate setup like this one.
