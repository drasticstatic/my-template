<div align="center">

<img src="../assets/icons-phosphor/sprout.svg" width="56" height="56" alt="">

# Tutorials

*Learn by doing: one task from start to finish, with what you should see at every step.*

![Kind](https://img.shields.io/badge/Kind-Tutorials-800020?style=flat-square)
![Changed](https://img.shields.io/badge/Changed-2026--11--12-800020?style=flat-square)
![For](https://img.shields.io/badge/For-Anyone_learning_a_tool_by_using_it-64748b?style=flat-square)

<img src="../assets/icons-phosphor/map-pin.svg" width="16" height="16" alt=""> **You are here:** drasticstatic lab › [`my-template`](../README.md) › `tutorials/` · public · `main` is the working branch

</div>

## <img src="../assets/icons-phosphor/compass.svg" width="24" height="24" alt=""> TL;DR

1. <img src="../assets/icons-phosphor/sprout.svg" width="16" height="16" alt=""> **A tutorial teaches by doing.** You start with nothing, finish with something that works, and know why each step was there.
2. <img src="../assets/icons-phosphor/layers.svg" width="16" height="16" alt=""> **It is one of four shelves** (below). Pick the shelf by what the reader needs, not by how long the page is.
3. <img src="../assets/icons-phosphor/footprints.svg" width="16" height="16" alt=""> **Writing one?** Copy [`tutorials-template/repo/_template/TUTORIAL-NAME.md`](../tutorials-template/repo/_template/TUTORIAL-NAME.md) to `tutorials/<TASK-IN-CAPITALS>.md`.

## <img src="../assets/icons-phosphor/layers.svg" width="24" height="24" alt=""> The four shelves

| Shelf | What it is | The reader is… | Numbered? | Here |
|---|---|---|---|---|
| <img src="../assets/icons-phosphor/list-checks.svg" width="16" height="16" alt=""> **SOP** | a numbered, repeatable procedure: how an approved thing is done, every time, by the people whose job it is | doing their job | yes, `SOP-DEPT-NNN` ([`NUMBERING.md`](../NUMBERING.md)) | [`sop-template/`](../sop-template/) |
| <img src="../assets/icons-phosphor/scroll-text.svg" width="16" height="16" alt=""> **Proposal** | an ask: a decision someone is being asked to make | deciding | yes, per desk (`THEF-018`) | [`proposals-template/`](../proposals-template/) |
| <img src="../assets/icons-phosphor/route.svg" width="16" height="16" alt=""> **Walkthrough** | a one-time setup: get from nothing to done, once | setting something up | no | [`walkthroughs/`](../walkthroughs/) |
| <img src="../assets/icons-phosphor/sprout.svg" width="16" height="16" alt=""> **Tutorial** | learn by doing: one task start to finish, with what you should see at each step, so the reader can do the next one alone | learning | no | this folder |

A walkthrough and a tutorial look alike. The difference is what the reader keeps: after a walkthrough they **have**
something set up; after a tutorial they **know how** to do it again, and why.

## <img src="../assets/icons-phosphor/book-open.svg" width="24" height="24" alt=""> The tutorials

| | Tutorial | You will learn to… |
|---|---|---|
| <img src="../assets/icons-phosphor/book-marked.svg" width="16" height="16" alt=""> | [Open your first vault](OPEN-YOUR-FIRST-VAULT.md) | install a Markdown vault app, open a folder you already have as a vault, tell whether Restricted mode is on, and know which of the app's own files a team commits |
| <img src="../assets/icons-phosphor/history.svg" width="16" height="16" alt=""> | [Find, resume or rebuild an old session](FIND-RESUME-OR-REBUILD-A-SESSION.md) | find a Claude Code session's transcript, resume it from any folder, know what a resumed long session remembers, and start again from a rebuilt record when the transcript is gone |
| <img src="../assets/icons-phosphor/circle-check.svg" width="16" height="16" alt=""> | [A runbook tray in the menu bar](A-RUNBOOK-TRAY-IN-THE-MENU-BAR.md) | put one item in the macOS menu bar that shows each scheduled job's state, your own checks and the Mac's memory, swap, processor and disk, built from AppleScript and Python's standard library with nothing installed; write its status command and config, prove them, build it, and read its meters |

## <img src="../assets/icons-phosphor/shapes.svg" width="24" height="24" alt=""> How a tutorial is named and laid out

- **Name:** `tutorials/<WHAT-YOU-WILL-DO-IN-CAPITALS>.md`, a verb first: `OPEN-YOUR-FIRST-VAULT.md`.
- **Not numbered.** Tutorials carry no ID unless [`NUMBERING.md`](../NUMBERING.md) later gives them one. Link them by file name.
- **Layout**, in this order: the centred header and *You are here*; TL;DR; **What you will learn**; **Before you start** (time, what to have installed, placeholders); numbered steps, each one action with *You should see* after it; **Check what you learned**; **Where next**; folded sources with the date each was checked; *Suggest a change*.
- **Every behaviour checked** against the vendor's own documentation, with the link and date in the sources. What could not be confirmed is left out or marked *unverified*; what is the fleet's own practice is marked as ours.
- **No PDF yet.** The lab's PDF renderer reads `walkthroughs/` only; a tutorial is read as markdown.
- **The Lucid look** ([`LUCID.md`](../LUCID.md)): plain words, an icon beside each idea, placeholders instead of real paths and names ([`NAMES-POLICY.md`](../NAMES-POLICY.md)).

The template and an organisation's copy of this folder: [`tutorials-template/`](../tutorials-template/). To lay this shelf beside every procedures repository and reading room on a machine: `sh scripts/lay-tutorials-shelf.sh --scan <ROOT>` (a dry run; [`scripts/README.md`](../scripts/README.md#lay-tutorials-shelfsh--a-tutorials-shelf-beside-every-sop-location-and-reading-room)).

## <img src="../assets/icons-phosphor/git-pull-request.svg" width="24" height="24" alt=""> Suggest a change

Noticed something wrong, or know a better way? Open an [issue](https://github.com/drasticstatic/my-template/issues) or a pull request against `main`; the lab steward reads them, and a person with the role merges with a merge commit so your name stays on it. Not on GitHub? Tell any steward you know, or your helper, in your own words.

<sub>Part of [`my-template`](../README.md). Icons: Phosphor duotone (MIT).</sub>
