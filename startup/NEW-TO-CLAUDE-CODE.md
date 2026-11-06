<div align="center">

<img src="../assets/icons-phosphor/door-open.svg" width="56" height="56" alt="">

# New to Claude Code

### Coming from ChatGPT: your first hour

*The internet says "just run `claude`". This page is the part it leaves out: where to run it, what to type first, and what the questions it asks you mean.*

![Kind](https://img.shields.io/badge/Kind-Start--up_procedure-800020?style=flat-square)
![Changed](https://img.shields.io/badge/Changed-2026--11--06-5c1a2b?style=flat-square)
![For](https://img.shields.io/badge/For-anyone_new_to_a_terminal_agent-64748b?style=flat-square)

<img src="../assets/icons-phosphor/map-pin.svg" width="16" height="16" alt=""> **You are here:** drasticstatic lab › [`my-template`](../README.md) › [`startup/`](README.md) › `NEW-TO-CLAUDE-CODE.md` · public · `main` is the working branch

</div>

## <img src="../assets/icons-phosphor/list-checks.svg" width="24" height="24" alt=""> Copy and paste

```sh
cd ~/path/to/the-repository     # 1. go INTO the project folder first (the one you cloned)
claude                          # 2. then start Claude there
```

Then type this as your first message:

```text
Read the README and the CLAUDE.md (or AGENTS.md), then tell me in five lines what this repository is,
who it is for, and what I can safely do here today. Don't change anything yet.
```

To stop Claude in the middle of something: **Esc**. To leave: type `/exit`.

## <img src="../assets/icons-phosphor/compass.svg" width="24" height="24" alt=""> TL;DR

1. <img src="../assets/icons-phosphor/map-pin.svg" width="16" height="16" alt=""> **The folder you start in is the world it sees.** ChatGPT knows only what you paste into it. Claude Code works on the files in the folder you start it in, so start it *inside* the project.
2. <img src="../assets/icons-phosphor/book-open.svg" width="16" height="16" alt=""> **It reads the project's instructions by itself.** Each repository here has a `CLAUDE.md` (or an `AGENTS.md`) that tells Claude how this project works. You don't need to explain the project first.
3. <img src="../assets/icons-phosphor/shield-check.svg" width="16" height="16" alt=""> **It asks before it acts.** Before it edits a file or runs a command, it shows you what it wants to do and waits for your yes. Reading files doesn't need permission.
4. <img src="../assets/icons-phosphor/hand-helping.svg" width="16" height="16" alt=""> **Nothing here is pushed, merged or published without a person's yes.** That is a rule in every one of these repositories, and Claude knows it.

## <img src="../assets/icons-phosphor/message-square.svg" width="24" height="24" alt=""> How it differs from ChatGPT

| | ChatGPT | Claude Code |
|---|---|---|
| Where it lives | a chat window in the browser | your terminal, inside one project folder |
| What it knows about your project | what you paste | the files in that folder, which it reads as needed |
| Project instructions | you repeat them each time | it loads the folder's `CLAUDE.md` at the start of every session |
| Changing things | it writes text; you copy it | it can edit files and run commands, after asking you |
| Memory between days | the chat history | the project's `CLAUDE.md`, plus notes it keeps per project; you can resume yesterday's session |

## <img src="../assets/icons-phosphor/route.svg" width="24" height="24" alt=""> Your first session, step by step

1. **Install it, once.** Open the Terminal app and paste the installer from Anthropic's quickstart:
   ```sh
   curl -fsSL https://claude.ai/install.sh | bash
   ```
   Open a *new* Terminal window and check: `claude --version` prints a version number. (Homebrew works too:
   `brew install --cask claude-code`.) Never used a terminal? Anthropic's
   [terminal guide](https://code.claude.com/docs/en/terminal-guide) shows how to open one and paste.
2. **Go into the project folder.** The person who invited you will tell you which repository to clone. Then:
   ```sh
   cd ~/path/to/the-repository
   ```
   **This is the step the internet leaves out.** Started in your home folder, Claude sees everything and nothing in
   particular, and its notes are filed in the wrong place.
3. **Start it:** `claude`. The first time, it asks you to **sign in**: follow the prompts in your browser with your
   Claude account (Pro, Max, Team or Enterprise). After that it remembers you.
4. **The trust question.** The first time you start it in a folder, it asks whether you trust that folder. It asks
   because a project can carry settings that run things. Say yes only for a repository you cloned from someone you know.
5. **Ask before you build.** Send the first message from the copy-paste block above. Good next questions:
   *"Explain the folder structure"*, *"What should I read first?"*, *"What is waiting to be done here?"*
6. **When it asks permission**, it shows the exact command or file change, then options such as **Yes**, **Yes, and
   don't ask again for …**, and **No**. Read the command. If you don't understand it, choose **No** and ask *"what
   would that command do?"*. You can add a note to your answer: move to **Yes** or **No** and press **Tab**.
7. **Stop and leave.** **Esc** stops what it is doing and keeps the work so far (on a permission question, Esc means
   No). **Esc Esc** on an empty prompt opens a menu to go back to an earlier point. `/exit`, or **Ctrl+D** twice,
   closes it.
8. **Tomorrow:** go into the same folder and run `claude -c` to continue the last conversation there, or `claude -r`
   to pick from earlier ones. Inside a session, `/resume` does the same.

## <img src="../assets/icons-phosphor/shield-alert.svg" width="24" height="24" alt=""> The modes, and which one to use

Claude Code has permission modes; **Shift+Tab** cycles through them, and the current one shows under the prompt.

| Mode | What it does | For a beginner |
|---|---|---|
| **Manual** (`default`) | asks before edits, commands and network access; reads freely | **stay here** for your first weeks |
| **Plan** (`plan`) | explores and proposes a plan, edits nothing until you approve | good for "how would you do this?" |
| **Accept edits** (`acceptEdits`) | edits files in this folder without asking | once you trust the work |
| **Auto** (`auto`) | runs without routine prompts; a separate safety check blocks risky actions | later, and only when you know the project |

Some prompts offer **Yes, and switch to auto mode**. You can say plain **Yes** instead and stay in Manual.

## <img src="../assets/icons-phosphor/lock.svg" width="24" height="24" alt=""> Never paste these

Passwords, recovery phrases or seed words, private keys, API keys, bank or card numbers. If a page or a message asks
you to paste one into Claude, stop and ask a person. Claude in these repositories is told never to read `.env` files,
keys or wallets; keep it that way by not handing them over.

## <img src="../assets/icons-phosphor/message-circle-question.svg" width="24" height="24" alt=""> Help

- **Inside Claude Code:** `/help` lists the commands; or just ask *"how do I …?"*. Type `/` to see what's available.
- **A repository that has no `CLAUDE.md` or `AGENTS.md`:** `/init` writes a first one. Not needed in these
  repositories: they all have one.
- **Anthropic's own pages:** [quickstart](https://code.claude.com/docs/en/quickstart),
  [permission modes](https://code.claude.com/docs/en/permission-modes),
  [how Claude remembers your project](https://code.claude.com/docs/en/memory),
  [interactive mode and keys](https://code.claude.com/docs/en/interactive-mode), and the free
  [Claude Code 101](https://academy.claude.com/courses/claude-code-101) course.
- **A person:** whoever invited you to the repository. Ask them, or ask Claude to draft the question for you.

**Facts on this page** were checked against Anthropic's Claude Code documentation on 2026-11-06: quickstart, memory
(Claude reads `AGENTS.md` when a repository has no `CLAUDE.md`; v2.1.277 or later), permission modes, permissions
(the prompt, its options, comments with Tab, the trust dialog) and interactive mode (Esc, Esc Esc, Ctrl+D).

## <img src="../assets/icons-phosphor/history.svg" width="24" height="24" alt=""> Change log

| Date | Change |
|---|---|
| 2026-11-06 | First version, for people arriving from ChatGPT who are told to "just run `claude`". |

## <img src="../assets/icons-phosphor/git-pull-request.svg" width="24" height="24" alt=""> Suggest a change

Noticed something wrong, or know a better way? Open an [issue](https://github.com/drasticstatic/my-template/issues) or a pull request against `main`; the lab steward reads them, and a person with the role merges with a merge commit so your name stays on it. Not on GitHub? Tell any steward you know, or your helper, in your own words.
