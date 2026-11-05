<div align="center">

<img src="../assets/icons-phosphor/handshake.svg" width="56" height="56" alt="">

# Many AI tools, one team

*Several helpers, side by side, sharing one rulebook, one notebook, one credit line and one set of connections.*

![Kind](https://img.shields.io/badge/Walkthrough-many_AI_tools_one_team-800020?style=flat-square)
![Changed](https://img.shields.io/badge/Changed-2026--11--04-5c1a2b?style=flat-square)
![For](https://img.shields.io/badge/For-Anyone_working_with_more_than_one_helper-64748b?style=flat-square)

<img src="../assets/icons-phosphor/map-pin.svg" width="16" height="16" alt=""> **You are here:** drasticstatic lab › [`my-template`](../README.md) › [walkthroughs](README.md) › `MANY-AI-TOOLS-ONE-TEAM.md` · public · `main` is the working branch

</div>

## <img src="../assets/icons-phosphor/compass.svg" width="24" height="24" alt=""> TL;DR

You can use Claude, Codex, ChatGPT, Cursor, Littlebird and Cosmos side by side without
confusion, because they share four things:

1. <img src="../assets/icons-phosphor/scroll-text.svg" width="16" height="16" alt=""> **One rulebook:** `AGENTS.md`.
2. <img src="../assets/icons-phosphor/notebook-pen.svg" width="16" height="16" alt=""> **One notebook:** `PENDING-TASKS.md`, `AGENT-SYNC/` and `logs/`.
3. <img src="../assets/icons-phosphor/pencil-line.svg" width="16" height="16" alt=""> **One credit line:** a single trailer that names which helper did what.
4. <img src="../assets/icons-phosphor/network.svg" width="16" height="16" alt=""> **One set of connections:** the same MCP servers and skills, wherever the tool supports them.

The diversity of tools is a strength. Each has its gifts, and together they make one body of work.

## <img src="../assets/icons-phosphor/map.svg" width="24" height="24" alt=""> Where each helper works

There are two kinds of helpers.

**Helpers that work *where you are*:** on your computer, in your terminal or app, beside you.
- **Claude Code**, **Codex CLI and app**, **Cursor**, **Augment Intent**.
- They see your local files and your unfinished work.
- They need you (or your computer) to be there.

**Helpers that work *where the code is*:** in the cloud, on GitHub's copy of the project.
- **Codex cloud**, **Cosmos experts**, **Claude Code on the web**.
- They can wake on an event (a new pull request, an issue), do a scoped job, and report back while you're
  away.
- They only see what has been pushed.

**And helpers that remember:**
- **Littlebird** keeps a private memory of your day on your own computer.
- **ChatGPT and Claude Projects** keep a conversation's files and instructions together.

> Think of it as a household with a few kinds of help. Some cook with you in the kitchen. Some tend the
> garden while you sleep. Someone keeps the family calendar. They all follow the same house rules, and they
> leave each other notes.

## <img src="../assets/icons-phosphor/scroll-text.svg" width="24" height="24" alt=""> One rulebook: `AGENTS.md`

Every repository has an `AGENTS.md` at its root:
- **Codex** reads it on its own.
- **Claude Code** reads `CLAUDE.md`, which begins by pointing to `AGENTS.md`.
- **Cursor, Cosmos and others** are told to read it in their own instructions.

It holds:
- **The house rules:** sync first, rehearse first, never publish what isn't ours, no secrets, both
  languages, credit the work.
- **Where the words live.**
- **The voice of the people the site serves.**
- **How changes go live.**

**Rule of thumb:**
- Anything every helper should know goes in `AGENTS.md`.
- Anything only one tool needs goes in that tool's own file (`CLAUDE.md`, `.cursor/`, a Cosmos expert's
  instructions).

## <img src="../assets/icons-phosphor/notebook-pen.svg" width="24" height="24" alt=""> One notebook

| File | What it's for |
|---|---|
| `PENDING-TASKS.md` | The shared to-do list. Add, don't erase; mark finished items ✅ |
| `AGENT-SYNC/created-by-<helper>/` | Handoff notes from one helper (or person) to the next: what was done, what's next, what to watch for |
| `logs/` | Session logs, when a helper keeps them |

A helper starting fresh reads these first, so nobody begins from zero and nobody repeats work.

## <img src="../assets/icons-phosphor/pencil-line.svg" width="24" height="24" alt=""> One credit line

```
Co-Authored-By: <Agent> · <Engine> · <Provider> [<Model>]
```

| Who helped | Credit line |
|---|---|
| Claude Code (Anthropic) | `Co-Authored-By: Alfred · ClaudeCodeCLI · Anthropic [Opus-5.5]` |
| Codex in the cloud | `Co-Authored-By: Codex · CodexCloud · OpenAI [<model>]` |
| Codex on your computer | `Co-Authored-By: Codex · CodexCLI · OpenAI [<model>]` |
| ChatGPT through GitHub | `Co-Authored-By: ChatGPT · GitHubConnector · OpenAI [<model>]` |
| A Cosmos expert | `Co-Authored-By: <Expert> · Cosmos · <Provider> [<model>]` |
| No AI | *(no line: it's recorded as your own work)* |

- **Which application launched the session decides the name.** The same model in two apps is credited as
  two helpers.
- **The separator** is the middle dot `·`, and the model goes in `[square brackets]`.
- **A session link** goes on its own line.
- **The local check only advises**, and nobody should need `--no-verify`.

How one person names a whole fleet of helpers: see the worked example in
[AGENT_IDENTITY_REFERENCE.md](https://github.com/drasticstatic/anthropas-argus-alfred-public-preview/blob/main/sandbox/AGENT_IDENTITY_REFERENCE.md),
and for the cloud side,
[COSMOS_AGENT_ROLE_REFERENCE.md](https://github.com/drasticstatic/anthropas-argus-alfred-public-preview/blob/main/sandbox/COSMOS_AGENT_ROLE_REFERENCE.md).

## <img src="../assets/icons-phosphor/network.svg" width="24" height="24" alt=""> One set of connections

**MCP (Model Context Protocol)** is the open standard that lets any helper use the same outside tools.
The same Firecrawl, Wix or WordPress server works in Claude, Codex, ChatGPT, Cursor and Cosmos, each
connected through that tool's own settings (see the "Connect" guides in this folder).

**Skills** are packaged instructions and scripts for a repeatable job. They follow an open format that
Claude and Codex both read, so a skill written once can serve several helpers.

## <img src="../assets/icons-phosphor/shield-check.svg" width="24" height="24" alt=""> What keeps a many-helper team safe

- <img src="../assets/icons-phosphor/flask-conical.svg" width="16" height="16" alt=""> **Rehearsal first:** helpers change `preview`; a person promotes to live.
- <img src="../assets/icons-phosphor/key-round.svg" width="16" height="16" alt=""> **Scoped access:** each helper's GitHub app is installed on the organization with only the repositories
  it needs. Owners can widen that when the team is ready.
- <img src="../assets/icons-phosphor/shield-alert.svg" width="16" height="16" alt=""> **The tripwire and the secret scan** catch what a helper might miss.
- <img src="../assets/icons-phosphor/history.svg" width="16" height="16" alt=""> **Honest records:** the credit line and the notebook mean anyone, looking back years from now, can see
  who did what and why.

Starting your own fleet? → [BUILD_YOUR_OWN_FLEET.md](../BUILD_YOUR_OWN_FLEET.md)

## <img src="../assets/icons-phosphor/git-pull-request.svg" width="24" height="24" alt=""> Suggest a change

Noticed something wrong, or a step that could be kinder? Open an [issue](https://github.com/drasticstatic/my-template/issues)
or a pull request against `main`, changing this page. A person with the role reads it and merges with a merge commit, so
your name stays on it. An AI helper may do all of that up to the merge. Not on GitHub? Tell any steward you know, or your
helper, in your own words.

*Part of the [walkthroughs](README.md). See also: [Session messaging](SESSION-MESSAGING.md) ·
[Working with the fleet](WORKING-WITH-THE-FLEET.md).*
