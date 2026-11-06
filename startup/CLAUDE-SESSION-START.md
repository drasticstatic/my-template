<div align="center">

<img src="../assets/icons-phosphor/map-pin.svg" width="56" height="56" alt="">

# Start a Claude session

### In the repository, not the folder above it

*What to type, what the guard in `~/.zshrc` is doing when it refuses, and how to check the pieces are still there.*

![Kind](https://img.shields.io/badge/Kind-Start--up_procedure-800020?style=flat-square)
![Changed](https://img.shields.io/badge/Changed-2026--11--06-5c1a2b?style=flat-square)
![For](https://img.shields.io/badge/For-Claude_Code_on_a_Mac-64748b?style=flat-square)

<img src="../assets/icons-phosphor/map-pin.svg" width="16" height="16" alt=""> **You are here:** drasticstatic lab › [`my-template`](../README.md) › [`startup/`](README.md) › `CLAUDE-SESSION-START.md` · public · `main` is the working branch

</div>

## <img src="../assets/icons-phosphor/list-checks.svg" width="24" height="24" alt=""> Copy, paste

```sh
cd ~/code/<repo>                 # or ~/dappu/<repo>, ~/drasticstaticLabs/<repo>, ~/<organisation>/<repo>
git pull --rebase --autostash    # sync first, every time
claude                           # a new session, filed under this repository
claude --continue                # or: pick up the latest session started in this folder
claude --resume                  # or: choose from the sessions started in this folder
```

Already in a session in the wrong folder? Type `/cd ~/code/<repo>` inside it. Really mean a parent folder? `claude --here`.

## <img src="../assets/icons-phosphor/compass.svg" width="24" height="24" alt=""> TL;DR

1. <img src="../assets/icons-phosphor/files.svg" width="16" height="16" alt=""> **A session is filed under the folder `claude` starts in.** Start in the repository and its transcript, its memory and `claude --resume` all line up.
2. <img src="../assets/icons-phosphor/shield-check.svg" width="16" height="16" alt=""> **The guard in `~/.zshrc` refuses parent folders.** In a new Terminal tab, `claude` in `~`, `~/code`, `~/dappu`, `~/drasticstaticLabs` or an organisation folder lists the repositories and stops. `claude --here` starts anyway.
3. <img src="../assets/icons-phosphor/bot.svg" width="16" height="16" alt=""> **The SessionStart hook speaks to the agent**, in every app: started in a parent folder, the agent is told to ask which repository you mean.
4. <img src="../assets/icons-phosphor/scan-search.svg" width="16" height="16" alt=""> **Wrong folder anyway?** `/cd <repo>` in the session moves it there.

## <img src="../assets/icons-phosphor/shield-check.svg" width="24" height="24" alt=""> The guard: why `claude` says no

The guard is a zsh function named `claude`, between the lines `# >>> claude-parent-guard (zsh)` and `# <<< claude-parent-guard (zsh)` in `~/.zshrc`. It runs before the real `claude` and checks the folder you are in.

| You are in | `claude` does |
|---|---|
| `~`, `~/code`, `~/dappu`, `~/drasticstaticLabs`, `~/intent/workspaces` | refuses, lists `cd <folder>/<repo> && claude` for each repository inside, exits 1 |
| a folder directly in `~` that is not a repository but holds repositories (each organisation folder, such as `~/theholyearthfoundation`) | the same |
| a repository, or any folder inside one | starts as normal |
| anywhere, with `--here` | starts as normal; `--here` is removed before the real `claude` sees it |

- **What passes straight through, anywhere:** `claude -p`, `--print`, `-v`, `--version`, `-h`, `--help`, and the subcommands `mcp`, `config`, `doctor`, `update`, `install`, `plugin`, `plugins`, `purge`, `auth`, `agents`, `attach`, `stop`, `rm`, `setup-token`.
- **What does not:** `claude --resume`, `claude --continue` and `claude --teleport` in a parent folder are refused like a bare `claude`, because they would file the session there too. Add `--here` if you mean it.
- **Variables in front still work.** `SOME_VAR=1 claude` passes the variable through the function to the real `claude` (zsh exports it for the length of the call). The Alfred-NIM line relies on this.
- **Skip the guard once:** `command claude` runs the real program without the function.
- **Terminal only.** VS Code and the desktop app start Claude without a shell, so the guard never sees them. The hook covers those.
- **New tabs only.** `~/.zshrc` is read when a tab opens. A tab opened before the guard was installed has no guard.

## <img src="../assets/icons-phosphor/bot.svg" width="24" height="24" alt=""> The hook: what the agent hears

`scripts/claude-session-start.sh` runs at every session start (new, resume, clear, compact, fork), from `~/.claude/settings.json`.

1. It adds one row to `~/.claude/projects/SESSIONS-LOG.tsv`: date, session id, source, folder.
2. In a parent folder (the same list as the guard), it adds a note to the agent's context before your first prompt: *this session started in a parent folder; ask which repository this is for, and suggest a restart there or `/cd`*. It names the repositories inside.

It never blocks a session and always exits 0. Claude Code gives SessionStart no way to stop a session, so the hook can only ask. Type `/hooks` in a session to see it listed under SessionStart.

## <img src="../assets/icons-phosphor/route.svg" width="24" height="24" alt=""> Moving, resuming, and web sessions

| You want to | Do this |
|---|---|
| move a running session to the right repository | `/cd ~/code/<repo>` inside the session. Claude Code moves it to that folder's project storage, and `claude --resume` there finds it |
| reopen an earlier session | `cd` into the folder it started in, then `claude --resume` (a list) or `claude --continue` (the latest). It lists only sessions from this folder, from this machine |
| bring a web session (claude.ai/code) to the terminal | `cd` into a clean checkout of the **same** repository, then `claude --teleport` (a list) or `claude --teleport <session-id>`. The terminal copy is filed under the folder you ran it in, like any start |
| start a session in the cloud from here | `claude --cloud "the task"` in the repository; it clones the GitHub remote at your current branch, so push first |

`--teleport` and `--cloud` need the claude.ai sign-in. They do not work in a tab started for Alfred-NIM (that tab sends the proxy's token instead).

## <img src="../assets/icons-phosphor/circle-check.svg" width="24" height="24" alt=""> Check the pieces are installed

```sh
grep -c claude-parent-guard ~/.zshrc     # 2: the two marker lines of the guard
type claude                              # "claude is a shell function from ~/.zshrc"
python3 -I -c 'import json, os; print(json.load(open(os.path.expanduser("~/.claude/settings.json"))).get("cleanupPeriodDays"))'   # 3650
```

The last line reads only the `cleanupPeriodDays` key (transcripts kept ten years, not the default 30 days) and prints nothing else from `settings.json`, which can hold tokens. Then, in a session, `/hooks` lists `claude-session-start.sh` under SessionStart. In a new tab, `cd ~/code && claude` should list the repositories and stop.

Missing? `sh ~/code/my-template/scripts/install-claude-session-order.sh` installs all three pieces, backs up both files first, and is safe to run twice. Run it yourself: it changes your own settings and shell profile.

## <img src="../assets/icons-phosphor/history.svg" width="24" height="24" alt=""> Undo

- **Everything, back to before the first install:** `sh ~/code/my-template/scripts/install-claude-session-order.sh --undo`. It copies back the whole of both files as they were, so anything added since (an alias, a permission) goes too. Copy the current files aside first if that matters.
- **Only the guard:** open `~/.zshrc` and comment out the lines between the two `claude-parent-guard` markers, then open a new tab.
- **Just this once:** `command claude` or `claude --here`.

Full background, the backups table and the manifest: [Start Claude in the right folder](../walkthroughs/CLAUDE-SESSION-ORDER.md).

## <img src="../assets/icons-phosphor/history.svg" width="24" height="24" alt=""> Change log

| Date | Change |
|---|---|
| 2026-11-06 | First version, from `scripts/claude-session-start.sh`, `scripts/install-claude-session-order.sh` and the Claude Code docs on sessions and cloud sessions. |

## <img src="../assets/icons-phosphor/git-pull-request.svg" width="24" height="24" alt=""> Suggest a change

Noticed something wrong, or know a better way? Open an [issue](https://github.com/drasticstatic/my-template/issues) or a pull request against `main`; the lab steward reads them, and a person with the role merges with a merge commit so your name stays on it. Not on GitHub? Tell any steward you know, or your helper, in your own words.

<sub>Part of [`my-template`](../README.md) › [`startup/`](README.md). Icons: Phosphor duotone (MIT).</sub>
