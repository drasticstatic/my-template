<div align="center">

<img src="../assets/icons-phosphor/history.svg" width="56" height="56" alt="">

# Find, resume or rebuild an old session

*Find a Claude Code conversation you had last week, pick it up from any folder, and start again cleanly when its transcript is gone.*

![Kind](https://img.shields.io/badge/Kind-Tutorial-800020?style=flat-square)
![Changed](https://img.shields.io/badge/Changed-2026--11--12-800020?style=flat-square)
![For](https://img.shields.io/badge/For-Anyone_who_works_in_Claude_Code-64748b?style=flat-square)

<img src="../assets/icons-phosphor/map-pin.svg" width="16" height="16" alt=""> **You are here:** drasticstatic lab › [`my-template`](../README.md) › [`tutorials`](README.md) › `FIND-RESUME-OR-REBUILD-A-SESSION.md` · public · `main` is the working branch

</div>

## <img src="../assets/icons-phosphor/compass.svg" width="24" height="24" alt=""> TL;DR

1. <img src="../assets/icons-phosphor/files.svg" width="16" height="16" alt=""> **Every session is a file:** `~/.claude/projects/<project>/<session-id>.jsonl`, filed under the folder it started in.
2. <img src="../assets/icons-phosphor/search.svg" width="16" height="16" alt=""> **`/resume` shows this folder's sessions; `Ctrl+A` shows every project's.** `claude --resume <session-id>` works from any folder.
3. <img src="../assets/icons-phosphor/triangle-alert.svg" width="16" height="16" alt=""> **A resumed long session remembers a summary of its early work, not every word.** Point it at its latest handoff note first.
4. <img src="../assets/icons-phosphor/trash-2.svg" width="16" height="16" alt=""> **Transcripts are deleted after 30 days by default** (`cleanupPeriodDays`). When one is gone, your prompts, your commits and your handoffs usually are not.

> **Handing this to your AI helper?** Say: *"Read FIND-RESUME-OR-REBUILD-A-SESSION.md and help me find the session where we worked on <topic>. Don't open any transcript until I say which one."*

## <img src="../assets/icons-phosphor/sprout.svg" width="24" height="24" alt=""> What you will learn

- where Claude Code keeps each conversation, and how to find the one you want;
- three ways to resume it, and what comes back with it;
- how long transcripts are kept, and how to keep them longer;
- what to do when the transcript is already gone.

## <img src="../assets/icons-phosphor/list-checks.svg" width="24" height="24" alt=""> Before you start

**You need:** Claude Code installed (`claude --version`), and at least one earlier session.

| Placeholder | Meaning | Example |
|---|---|---|
| `REPO` | the folder you usually work in | `~/code/my-repo` |
| `SESSION_ID` | a session's ID, the name of its transcript file without `.jsonl` | `0a1b2c3d-…` |

## <img src="../assets/icons-phosphor/files.svg" width="24" height="24" alt=""> 1. Find where the transcripts are

Claude Code saves each session as you work, as one JSON Lines file:

```text
~/.claude/projects/<project>/<session-id>.jsonl
```

`<project>` is the folder the session started in, with every character that is not a letter or a digit turned into
`-`. So a session started in `/Users/you/code/my-repo` is filed under `-Users-you-code-my-repo`. (A name longer than
200 characters is cut short and given a hash of the full path.)

```sh
ls ~/.claude/projects/
ls -t ~/.claude/projects/-Users-you-code-my-repo/ | head
```

*You should see:* one folder per place you have started Claude, and in each, `.jsonl` files named by session ID, newest
first. The file's format is internal to Claude Code and changes between versions, so read it through Claude Code
(below) or `/export`, not with a script of your own.

## <img src="../assets/icons-phosphor/search.svg" width="24" height="24" alt=""> 2. Pick it from the list

From `REPO`, run `claude --resume` with nothing after it, or type `/resume` inside a running session.

| Key | What it does |
|---|---|
| type any words | search the list |
| `Space` | preview the highlighted session |
| `Enter` | resume it |
| `Ctrl+A` | show sessions from **every project on this machine**; press again to come back |
| `Ctrl+W` | show every worktree of this repository (only in a repository with several) |
| `Ctrl+B` | only sessions from the current git branch |
| `Esc` | leave the list |

*You should see:* this folder's sessions first, each with its name or a generated title, how long ago it was used, its
branch and its size. If the one you want started in another folder, press `Ctrl+A`. Picking a session from an
unrelated project copies a `cd` and resume command to your clipboard instead of opening it.

## <img src="../assets/icons-phosphor/key-round.svg" width="24" height="24" alt=""> 3. Resume it by ID, from anywhere

```sh
claude --resume SESSION_ID
```

This works **from any folder**: Claude Code looks in the current project first, then in every other project on the
machine. It resumes only when exactly one project holds that ID; a hand-copied duplicate makes it report
`No conversation found with session ID: …` rather than guess.

Two more doors, for when you know something else:

```sh
claude --resume ~/.claude/projects/-Users-you-code-my-repo/SESSION_ID.jsonl   # the transcript's full path
claude --continue                                                             # the most recent session in this folder
```

*You should see:* the conversation where you left it. It comes back with its history, its model and, from the
terminal by ID, its permission mode. Flags such as `--add-dir` and `--mcp-config` are not restored: pass them again.

## <img src="../assets/icons-phosphor/route.svg" width="24" height="24" alt=""> 4. Started in the wrong folder? Move it with `/cd`

Inside a running session, `/cd <path>` moves it to another working folder and keeps the conversation. It also moves the
session to that folder's project storage, so it shows up in that folder's `/resume` list from then on. The new folder's
`CLAUDE.md` and project settings apply as soon as you move.

*You should see:* the session carry on, and `claude --resume` from the new folder list it.

## <img src="../assets/icons-phosphor/triangle-alert.svg" width="24" height="24" alt=""> 5. Know what a resumed long session remembers

> [!WARNING]
> **A resumed long session remembers a summary of its early work, not every detail.** When a session has been
> compacted, it reopens at a *Conversation compacted* row and carries on with the last summary, the messages that
> summary left out, and everything after. The messages that were summarised are not loaded again. The transcript on
> disk still holds every word, but the session is not reading it.
>
> So when you resume a long session, **point it at its latest handoff note first**: *"Before anything else, read
> `AGENT-SYNC/created-by-<you>/<the latest handoff>.md`."* (That is the fleet's practice; the handoff lanes are in
> [`AGENT-SYNC/README.md`](../AGENT-SYNC/README.md).)

Resuming a long conversation after a break can also cost more than you expect, because the cache it ran on has expired;
Claude Code may ask *Resume this conversation?* with an estimate of the usage it would take. **Start a new
conversation** is the right answer when the next task does not need the old one.

## <img src="../assets/icons-phosphor/history.svg" width="24" height="24" alt=""> 6. Keep transcripts longer than 30 days

Claude Code deletes old session data quietly, in the background, after a session starts. The age is
`cleanupPeriodDays`: **30 by default, at least 1**, and `0` is refused as invalid. There is no "never"; the docs
suggest a large number for long retention. In `~/.claude/settings.json`:

```json
{
  "cleanupPeriodDays": 3650
}
```

The same sweep removes more than transcripts: subagent transcripts, **file history** (the snapshots behind checkpoint
restore), **plans**, the **paste cache** of large pastes, debug logs and a few others. It does **not** remove your
prompt history (`~/.claude/history.jsonl`) or a project's auto memory (`projects/<project>/memory/`).

*You should see:* no settings warning in `/status`. A settings file Claude Code cannot read pauses the sweep, and `/status` warns about it.

> [!NOTE]
> Transcripts are plain text and can hold anything that passed through a tool, a pasted key included. Keeping them
> longer keeps that longer too. A nightly sealed copy is one answer: [`CLAUDE-PROJECTS-ARCHIVE.md`](../walkthroughs/CLAUDE-PROJECTS-ARCHIVE.md).

## <img src="../assets/icons-phosphor/wrench.svg" width="24" height="24" alt=""> 7. When the transcript is gone: rebuild the record

The conversation cannot come back. Most of what it did usually can:

| What survives | Where | How to read it |
|---|---|---|
| **Your own prompts**, with time and folder | `~/.claude/history.jsonl` (kept until you delete it) | `grep -F 'words you remember' ~/.claude/history.jsonl \| tail` |
| **The commits it made**, with its session ID | each repository's history | `git log --format='%h %ad %s%n  %(trailers:key=Claude-Session,valueonly)' --date=short` |
| **Its handoffs and notes** | the repository's `AGENT-SYNC/created-by-*/` lanes | open the newest files |
| **What Claude noted for itself** | `~/.claude/projects/<project>/memory/` | read the files there |
| **A sealed copy**, if you keep one | your nightly archive | restore it into a new folder, never over the live one |

Then start fresh, in the right folder:

1. Write what you found into one note, **marked as rebuilt** at the top (*"REBUILT on <date> from prompts, commits and
   handoffs; not the original transcript"*), and save it in that repository's own lane. A rebuilt record is never
   passed off as the original (fleet practice).
2. `cd REPO && claude`.
3. First message: *"Read <the rebuilt note> and the latest handoff, then tell me where we stand before doing anything."*

*You should see:* a new session that knows the decisions and the state of the work, says what it cannot know, and
asks before acting on anything the note leaves unclear.

## <img src="../assets/icons-phosphor/circle-check.svg" width="24" height="24" alt=""> Check what you learned

- [ ] You can find any session's file from the folder it started in.
- [ ] You can resume a session from another folder by its ID.
- [ ] You know a resumed long session reads a summary, and you point it at its handoff first.
- [ ] You know your retention setting, and what survives when a transcript is gone.

## <img src="../assets/icons-phosphor/link.svg" width="24" height="24" alt=""> Where next

- <img src="../assets/icons-phosphor/map-pin.svg" width="16" height="16" alt=""> [Start Claude in the right folder](../walkthroughs/CLAUDE-SESSION-ORDER.md): so sessions are filed where you will look for them.
- <img src="../assets/icons-phosphor/folder-lock.svg" width="16" height="16" alt=""> [A nightly sealed copy of `~/.claude/projects`](../walkthroughs/CLAUDE-PROJECTS-ARCHIVE.md): so a transcript outlives the sweep.

<details>
<summary><b>Sources, checked 2026-11-12</b></summary>

| Claim | Source |
|---|---|
| Where transcripts are stored and how `<project>` is named; `--resume` by ID, name or path; `--continue`; the picker's keys; resuming by ID from any directory; what a resumed session restores, including after compaction; `/cd` moving a session's storage; the *Resume this conversation?* dialog | <https://code.claude.com/docs/en/sessions> |
| `cleanupPeriodDays`: default 30, minimum 1, `0` fails validation, a large value for long retention | <https://code.claude.com/docs/en/settings-reference#cleanupperioddays> |
| What the sweep deletes (file history, plans, paste cache, …), what it keeps (`history.jsonl`, auto memory), plaintext storage | <https://code.claude.com/docs/en/claude-directory> |
| `/cd` keeps the conversation and applies the new folder's configuration | <https://code.claude.com/docs/en/permissions> |

Pointing a resumed session at its handoff, and marking a rebuilt record as rebuilt, are the fleet's practice.

</details>

## <img src="../assets/icons-phosphor/git-pull-request.svg" width="24" height="24" alt=""> Suggest a change

Noticed something wrong, or know a better way? Open an [issue](https://github.com/drasticstatic/my-template/issues) or a pull request against `main`; the lab steward reads them, and a person with the role merges with a merge commit so your name stays on it. Not on GitHub? Tell any steward you know, or your helper, in your own words.

<sub>One of the [tutorials](README.md) in `my-template`, in the shape of [`tutorials-template/`](../tutorials-template/). Icons: Phosphor duotone (MIT). Claude Code's behaviour is Anthropic's to change; check the pages above before relying on a detail here.</sub>
