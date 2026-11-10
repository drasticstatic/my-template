# Fleet note: scratch that survives a restart, the transcript archive, merge methods

**From:** Alfred
**Date:** 2026-11-10
**For:** every helper that uses this template

## Scratch that must survive a restart

`sh scripts/keep-scratch.sh save SRC REPO TOPIC "what it waits on"`

1. It picks the place for you. Anything that looks like a secret, by file name or by what is inside the file, and
   anything over 1 GB stays in a local folder that never syncs. Everything else goes to the synced scratch folder.
2. When unsure, add `--local`. The content check catches common credential shapes, not every secret.
3. It never overwrites and never deletes. `keep-scratch.sh done FOLDER` moves a finished folder to `done/`.
4. `keep-scratch.sh status` lists what is open. A session-start hook can run it, so a new session sees what is
   still waiting. A session already running when the hook is added sees it after a restart.
5. Legal or case documents go in neither place. Throwaway files stay in the session's own scratchpad.

## The transcript archive

`scripts/claude-projects-archive.sh` takes an encrypted nightly snapshot of the Claude Code transcript folder, and
catches up at login when the last good run is over 20 hours old. `--status` shows the last run. Walkthrough:
[`walkthroughs/CLAUDE-PROJECTS-ARCHIVE.md`](../../walkthroughs/CLAUDE-PROJECTS-ARCHIVE.md).

## Merge methods and guardrails

- Squash merging is off, so every commit keeps its author. Rebase merging is off too, with a few named exceptions
  (`scripts/merge-methods-exceptions.txt`). Pull requests merge with a merge commit.
- `scripts/set-merge-methods.sh` sets this per repository.
- A guardrail ruleset pair is piloting on each organisation's `brand-assets` repository: merge commits only for pull
  requests, and no force-push or branch deletion for anyone. Files and the reasons are in
  [`branch-protection/`](../../branch-protection/).
- Before rolling the pair out wider, check that no scheduled job pushes straight to a protected branch in a way the
  ruleset would refuse.

## Background jobs: asleep or off

A scheduled job on a Mac (launchd) that falls due while the Mac is **asleep** runs once when it wakes. One that
falls due while the Mac is **powered off** is missed, unless the job itself checks at login whether it is due. With
FileVault on, nothing that belongs to a user runs until that user logs in. Keep a runbook of your own jobs, with a
daily and a weekly check and the steps after a restart.

## Gemini CLI

Gemini Code Assist and Workspace AI Ultra can no longer be bought. The open doors are a paid Gemini API key, Vertex
AI, or Antigravity (`agy`). Walkthrough: [`walkthroughs/GEMINI-CLI-ACCESS.md`](../../walkthroughs/GEMINI-CLI-ACCESS.md).
Give Gemini the text or a PDF, never a link.
