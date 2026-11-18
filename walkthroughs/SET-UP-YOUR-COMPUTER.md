<div align="center">

<img src="../assets/icons-phosphor/wrench.svg" width="56" height="56" alt="">

# Set up your computer

### Git, the GitHub CLI, VS Code and Claude Code, on Windows or on macOS, from nothing

*Every install and sign-in the first evening needs, two tracks side by side, each command checked against its maker's own page on the date beside it.*

![Kind](https://img.shields.io/badge/Kind-Walkthrough-800020?style=flat-square)
![Changed](https://img.shields.io/badge/Changed-2026--11--18-5c1a2b?style=flat-square)
![For](https://img.shields.io/badge/For-Someone_who_has_never_opened_a_terminal-64748b?style=flat-square)

<img src="../assets/icons-phosphor/map-pin.svg" width="16" height="16" alt=""> **You are here:** drasticstatic lab › [`my-template`](../README.md) › [`walkthroughs`](README.md) › `SET-UP-YOUR-COMPUTER.md` · public · `main` is the working branch

</div>

> **Handing this to your AI helper?** Say: *"Read SET-UP-YOUR-COMPUTER.md. I am on Windows (or: macOS). Walk me
> through it one section at a time. Before each command, tell me what it does. Anything that signs in or asks for a
> password, I type myself. Install nothing this page does not name."*

## <img src="../assets/icons-phosphor/compass.svg" width="24" height="24" alt=""> TL;DR

1. <img src="../assets/icons-phosphor/wrench.svg" width="16" height="16" alt=""> **Windows uses PowerShell and `winget`; macOS uses Terminal and Homebrew.** Each section below has both. Read only yours.
2. <img src="../assets/icons-phosphor/layers.svg" width="16" height="16" alt=""> **Install, in order:** Git, the GitHub CLI (`gh`), VS Code, Claude Code. Codex and Antigravity are optional.
3. <img src="../assets/icons-phosphor/log-in.svg" width="16" height="16" alt=""> **Sign in, yourself:** `gh auth login`, Claude Code, and the secret scan. Each opens a browser; you finish it there.
4. <img src="../assets/icons-phosphor/folder-lock.svg" width="16" height="16" alt=""> **Three homes:** `code` for your own repositories, `<your-login>Labs` for labs, one folder per organisation.
5. <img src="../assets/icons-phosphor/lock.svg" width="16" height="16" alt=""> **Everything you create is private,** with a `.gitignore` before the first commit, and you can check visibility with one command.

## <img src="../assets/icons-phosphor/list-checks.svg" width="24" height="24" alt=""> Before you start

| You need | Why |
|---|---|
| **Windows 10 version 1809 or later, or Windows 11; or macOS 13 or later** | Claude Code's own minimum ([system requirements](https://code.claude.com/docs/en/setup#system-requirements), checked 2026-11-18) |
| **A GitHub account with two-factor sign-in on** | [Secure two-factor](SECURE-TWO-FACTOR.md); GitHub's path is *Settings › Password and authentication › Enable two-factor authentication* ([GitHub](https://docs.github.com/en/authentication/securing-your-account-with-two-factor-authentication-2fa/configuring-two-factor-authentication), checked 2026-11-18) |
| **A paid Claude plan** (Pro, Max, Ultra, Team or Enterprise) or a Console account | "The free claude.ai plan does not include Claude Code access" ([Anthropic](https://code.claude.com/docs/en/setup#authenticate), checked 2026-11-18) |
| **About an hour**, and someone beside you the first time | the installers ask questions; it helps to have a second pair of eyes |

> [!IMPORTANT]
> **Windows will pop up questions while you install.** When an installer needs to change the system, Windows asks
> *"Do you want to allow this app to make changes to your device?"* (User Account Control). Microsoft's words:
> "Windows will prompt you to elevate. If you choose not to elevate, the application will fail to install"
> ([WinGet](https://learn.microsoft.com/en-us/windows/package-manager/winget/), checked 2026-11-18). Say **Yes** only
> to an installer you just started. On a Mac, Homebrew may ask for the Mac's own password; nothing shows on screen as
> you type it, which is normal.

## <img src="../assets/icons-phosphor/wrench.svg" width="24" height="24" alt=""> 1 · Open the terminal

The terminal is a window where you type a command and press **Enter**; the computer does that one thing and writes
back what happened.

**Windows (PowerShell).** Press **Win + X** and choose **Terminal** or **Windows PowerShell**. Each line starts with
`PS C:\Users\<you>>`. If it starts without `PS`, you are in CMD: close it and open PowerShell instead. Paste with
**Ctrl + V** or a right-click. Do not choose an entry with `(x86)` in its name.

**macOS (Terminal).** Press **Cmd + Space**, type `Terminal`, press **Return**. Paste with **Cmd + V**.

<sub>Checked 2026-11-18 against Anthropic's [terminal guide](https://code.claude.com/docs/en/terminal-guide).</sub>

> **One habit for the whole page:** after installing anything, **close the terminal window and open a new one**
> before you check it. A new window is how the computer learns where the new program lives.

## <img src="../assets/icons-phosphor/layers.svg" width="24" height="24" alt=""> 2 · The installer for installers

**Windows: `winget`** is already there on Windows 11 and modern Windows 10, as part of **App Installer**. Check:

```powershell
winget --version
```

*You should see:* a version number. If PowerShell says `winget` is not recognised, install **App Installer** from the
Microsoft Store ([link from Microsoft's page](https://apps.microsoft.com/detail/9nblggh4nns1)), then open a new window.

<sub>Checked 2026-11-18 against [Use WinGet to install and manage applications](https://learn.microsoft.com/en-us/windows/package-manager/winget/).</sub>

**macOS: Homebrew.** This downloads Homebrew's own installer and runs it. It explains what it will do and waits for
you before it starts.

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

*You should see:* the installer finish. If it ends with **Next steps** and some lines to run, run those lines, then
open a new window and check with `brew --version`.

<sub>Checked 2026-11-18 against [brew.sh](https://brew.sh).</sub>

## <img src="../assets/icons-phosphor/git-branch.svg" width="24" height="24" alt=""> 3 · Git

Git is the program that keeps the history of every file: who changed what, and when.

**Windows.**

```powershell
winget install --id Git.Git -e --source winget
```

The Git website notes that this `winget` package "is *not* maintained by the Git for Windows project and might deviate
from the latest official version". If you prefer the project's own installer, download it from
[git-scm.com/install/windows](https://git-scm.com/install/windows) and click **Next** on each screen, keeping the
defaults; at *"Adjusting your PATH environment"*, keep the recommended option (Anthropic's terminal guide gives the
same advice).

<sub>Checked 2026-11-18 against [git-scm.com/install/windows](https://git-scm.com/install/windows) (Git 2.56.1 that day) and the [terminal guide](https://code.claude.com/docs/en/terminal-guide#windows).</sub>

**macOS.**

```sh
brew install git
```

(Apple also ships Git with its Command Line Tools: `xcode-select --install` opens Apple's own install window.)

<sub>Checked 2026-11-18 against [git-scm.com/install/mac](https://git-scm.com/install/mac).</sub>

*You should see,* in a new window: `git --version` prints a version number.

**Windows only: keep scripts' line endings as they are.** The lab's hooks and scripts are shell scripts, and a shell
script stops working when Windows line endings are written into it. Git can convert line endings when it checks files
out; tell it to leave them alone on checkout and tidy them on commit:

```powershell
git config --global core.autocrlf input
```

<sub>`input` "convert[s] CRLF to LF on commit but not the other way around" ([Pro Git, Git Configuration](https://git-scm.com/book/en/v2/Customizing-Git-Git-Configuration), checked 2026-11-18). Pro Git suggests `true` for Windows in general; `input` is this page's choice because the lab's repositories do not yet carry a `.gitattributes` that pins scripts to LF ([GitHub on `eol=lf`](https://docs.github.com/en/get-started/git-basics/configuring-git-to-handle-line-endings)). **Untested on Windows in this lab so far.** Set it before your first clone.</sub>

## <img src="../assets/icons-phosphor/git-pull-request.svg" width="24" height="24" alt=""> 4 · The GitHub CLI, `gh`

`gh` lets the terminal talk to GitHub: sign in, clone, create a repository, check whether one is private.

**Windows.**

```powershell
winget install --id GitHub.cli --source winget
```

GitHub's note: "When using Windows Terminal, you will need to open a new window for the changes to take effect."

<sub>Checked 2026-11-18 against [gh's Windows install page](https://github.com/cli/cli/blob/trunk/docs/install_windows.md).</sub>

**macOS.**

```sh
brew install gh
```

<sub>Checked 2026-11-18 against [gh's macOS install page](https://github.com/cli/cli/blob/trunk/docs/install_macos.md).</sub>

*You should see,* in a new window: `gh --version` prints a version number.

## <img src="../assets/icons-phosphor/layers.svg" width="24" height="24" alt=""> 5 · VS Code

VS Code is the editor: your files on the left, the file you are reading in the middle, and the AI helpers in a panel
beside them.

**Windows.** Download the **User setup** from [code.visualstudio.com/download](https://code.visualstudio.com/download).
Microsoft: "The User setup is the recommended installation for most people because it does not require administrator
permissions." On the **Select Additional Tasks** screen, make sure **Add to PATH** is ticked, so `code` works in the
terminal.

<sub>Checked 2026-11-18 against [Visual Studio Code on Windows](https://code.visualstudio.com/docs/setup/windows). Microsoft's `winget` repository also lists a package, `winget install --id Microsoft.VisualStudioCode -e` ([winget-pkgs](https://github.com/microsoft/winget-pkgs/tree/master/manifests/m/Microsoft/VisualStudioCode)); VS Code's own setup page does not mention it, so the download above is this page's first choice.</sub>

**macOS.** Download VS Code for macOS, open the `.dmg` and drag **Visual Studio Code.app** to **Applications**. Open it,
press **Cmd + Shift + P**, and run **Shell Command: Install 'code' command in PATH** (newer versions call it *Install
'code' and optionally 'copilot' commands in PATH*; if it asks about the Copilot command, either answer is fine).
Restart the terminal.

<sub>Checked 2026-11-18 against [Visual Studio Code on macOS](https://code.visualstudio.com/docs/setup/mac). Homebrew also carries it, `brew install --cask visual-studio-code` ([Homebrew's listing](https://formulae.brew.sh/cask/visual-studio-code)); VS Code's page does not mention Homebrew.</sub>

*You should see,* in a new window: `code --version` prints a version, and `code .` opens the folder you are in.

## <img src="../assets/icons-phosphor/bot.svg" width="24" height="24" alt=""> 6 · Claude Code: the extension and the terminal command

There are two pieces, and you want both. **The extension** is a panel inside VS Code. **The terminal command**,
`claude`, is the same helper in the terminal. Anthropic: "Installing the extension does not put `claude` on your shell
PATH."

**The terminal command, Windows (PowerShell).** `irm` fetches Anthropic's installer and `iex` runs it. It shows no
progress while it downloads; wait.

```powershell
irm https://claude.ai/install.ps1 | iex
```

(Or, with `winget`: `winget install Anthropic.ClaudeCode`. That copy does not update itself; run
`winget upgrade Anthropic.ClaudeCode` now and then.) You do not need to run as Administrator. With Git installed
(section 3), Claude Code uses Git Bash for its commands; without it, PowerShell.

**The terminal command, macOS.**

```sh
curl -fsSL https://claude.ai/install.sh | bash
```

(Or, with Homebrew: `brew install --cask claude-code`, which does not update itself; `brew upgrade claude-code`.)

*You should see,* in a new window: `claude --version` prints a version such as `2.1.211 (Claude Code)`. For a fuller
check, `claude doctor` reads the installation and changes nothing. If the window says `claude` is not recognised or not
found, follow Anthropic's [Fix your PATH](https://code.claude.com/docs/en/troubleshoot-install#command-not-found-claude-after-installation).

<sub>Checked 2026-11-18 against [Advanced setup](https://code.claude.com/docs/en/setup) and the [terminal guide](https://code.claude.com/docs/en/terminal-guide).</sub>

**The extension, both systems.** In VS Code, press **Ctrl + Shift + X** (Windows) or **Cmd + Shift + X** (macOS),
search for **Claude Code**, and choose **Install** on the one published by Anthropic (its ID is
`anthropic.claude-code`). It needs VS Code 1.94 or later. Open its panel, choose **Sign in**, and finish in the browser.

<sub>Checked 2026-11-18 against [Use Claude Code in VS Code](https://code.claude.com/docs/en/vs-code) and its [Marketplace listing](https://marketplace.visualstudio.com/items?itemName=anthropic.claude-code).</sub>

**Signing in the terminal command.** Go into a folder first (section 9 makes them), type `claude`, and follow the
browser. Then read [New to Claude Code](../startup/NEW-TO-CLAUDE-CODE.md) before you ask it for anything.

## <img src="../assets/icons-phosphor/handshake.svg" width="24" height="24" alt=""> 7 · Optional: Codex and Antigravity

Both are other companies' helpers that live in VS Code too. They read the same rulebook (`AGENTS.md`) in every
repository here ([Many AI tools, one team](MANY-AI-TOOLS-ONE-TEAM.md)). Skip this section tonight if you like.

**Codex (OpenAI).** *The extension:* search the Extensions view for **Codex**, published by OpenAI (its ID is
`openai.chatgpt`), install it, and sign in. *The terminal command,* from OpenAI's own repository:

```powershell
# Windows (PowerShell). "-ExecutionPolicy ByPass" lets this one window run OpenAI's installer script.
powershell -ExecutionPolicy ByPass -c "irm https://chatgpt.com/codex/install.ps1 | iex"
```

```sh
# macOS
brew install --cask codex
```

The first time you run `codex` in a project folder, choose **Sign in with ChatGPT**.

<sub>Checked 2026-11-18 against [Codex IDE extension](https://learn.chatgpt.com/docs/codex/ide), [Codex CLI](https://learn.chatgpt.com/docs/codex/cli) and the [openai/codex README](https://github.com/openai/codex). **Unverified:** how well the extension and the terminal command work on native Windows. OpenAI's pages read that day did not say, and its documentation lists separate pages for Windows and WSL that were not read.</sub>

**Antigravity (Google).** *The extension:* search the Extensions view for **Google Antigravity**, published by Google
(`Google.google-antigravity`), install it, then choose the Antigravity icon in the side bar and **Sign In**. It needs VS
Code 1.90 or later, on Windows, macOS or Linux, and installs its own local backend (`agy`) the first time. Any personal
Google account works, on a Free, Pro or Ultra plan; Google: "Google Workspace plans don't include Antigravity plans."
Google also makes a desktop app and a full editor of its own, from [antigravity.google/download](https://antigravity.google/download).

<sub>Checked 2026-11-18 against [Antigravity's VS Code guide](https://antigravity.google/docs/ide/extensions/vscode), [extensions overview](https://antigravity.google/docs/ide/extensions) and [authentication](https://antigravity.google/docs/install). **Unverified:** the install command for the `agy` terminal tool on its own; Google's pages read that day point to a quickstart that was not read.</sub>

## <img src="../assets/icons-phosphor/log-in.svg" width="24" height="24" alt=""> 8 · Sign the terminal in to GitHub, and put your name on commits

**Sign in.** Type this **yourself**, in your own terminal window. It asks a few questions: choose **GitHub.com**,
**HTTPS**, and **Login with a web browser**. It shows a one-time code, opens the browser, and you paste the code there.

```sh
gh auth login
```

GitHub: "an authentication token will be stored securely in the system credential store." Nobody copies it anywhere.
Check (this one your helper may run):

```sh
gh auth status
```

*You should see:* logged in to `github.com` as your login. If `git` later asks for a password when you push, run
`gh auth setup-git`, which "configures git to use the GitHub CLI as a credential helper".

<sub>Checked 2026-11-18 against [gh auth login](https://cli.github.com/manual/gh_auth_login) and [gh auth setup-git](https://cli.github.com/manual/gh_auth_setup-git).</sub>

**Your name on commits.** Every commit carries a name and an email. Use the private address GitHub gives you, so your
own email never appears in a public history. Find your account's number first:

```sh
gh api user --jq .id
```

Then, replacing `<id>` with that number and `<login>` with your GitHub login:

```sh
git config --global user.name "Your Name"
git config --global user.email "<id>+<login>@users.noreply.github.com"
git config --global init.defaultBranch main
git config --global --list
```

*You should see:* `user.name`, `user.email` ending in `users.noreply.github.com`, and `init.defaultbranch=main`. On
GitHub, also tick **Keep my email addresses private** under *Settings › Emails*.

<sub>Checked 2026-11-18 against GitHub's [Setting your commit email address](https://docs.github.com/en/account-and-profile/setting-up-and-managing-your-personal-account-on-github/managing-email-preferences/setting-your-commit-email-address) and [email addresses reference](https://docs.github.com/en/account-and-profile/reference/email-addresses-reference) (the `ID+USERNAME@users.noreply.github.com` form, for accounts made after July 18, 2017), and [Pro Git, First-Time Git Setup](https://git-scm.com/book/en/v2/Getting-Started-First-Time-Git-Setup).</sub>

## <img src="../assets/icons-phosphor/folder-lock.svg" width="24" height="24" alt=""> 9 · Three homes for repositories

The same layout the lab uses, so a helper always knows where to look ([Nested repositories](../NESTED-REPOS-GUIDE.md)
says why):

| Home | What goes in it | Example |
|---|---|---|
| `~/code/` | **your own** repositories, under your own account | `~/code/my-first-app` |
| `~/<your-login>Labs/` | **labs:** your own working copies for exploring, and clones of other people's lab repositories you work on | `~/<your-login>Labs/<a-lab-repository>` |
| `~/<organisation>/` | **an organisation's** repositories, the folder named exactly as the organisation is on GitHub | `~/<organisation>/reading-room` |

`~` means your home folder: `C:\Users\<you>` on Windows, `/Users/<you>` on a Mac. An organisation's repository never
goes inside a lab; the organisation's folder is the one place to look for it.

**Windows (PowerShell).** `$HOME` is your home folder.

```powershell
mkdir "$HOME\code"
mkdir "$HOME\<your-login>Labs"
mkdir "$HOME\<organisation>"
```

**macOS.**

```sh
mkdir -p ~/code ~/<your-login>Labs ~/<organisation>
```

**Parents and children.** `~/code` (and each lab folder) can itself be a small git repository that keeps only its own
README and a `.gitignore`, while every folder inside it is a repository of its own. The parent's `.gitignore` names
each child, one per line, so the parent never records the children's files:

```gitignore
# Every subdirectory is its own independent git repository; see README.md
my-first-app/
my-template/
```

Make the parent once, inside the folder: `git init`, a short `README.md`, and that `.gitignore`. Add a line each time a
new child arrives. Your helper can do this for you; the pattern, and why it is not a submodule, is in
[Nested repositories](../NESTED-REPOS-GUIDE.md).

## <img src="../assets/icons-phosphor/users.svg" width="24" height="24" alt=""> 10 · Clone an organisation's repository

To *clone* is to copy a repository from GitHub onto your computer, history and all. Your steward tells you which one.
It goes in that organisation's home.

```powershell
# Windows
gh repo clone <organisation>/<repository> "$HOME\<organisation>\<repository>"
cd "$HOME\<organisation>\<repository>"
```

```sh
# macOS
gh repo clone <organisation>/<repository> ~/<organisation>/<repository>
cd ~/<organisation>/<repository>
```

<sub>Checked 2026-11-18 against [gh repo clone](https://cli.github.com/manual/gh_repo_clone).</sub>

**Switch the hooks on, once per clone.** Git never runs a repository's own checks until you point it at them. On a Mac,
and inside Claude Code on either system:

```sh
sh scripts/install-hooks.sh
```

From PowerShell itself, the same script runs through Git's own shell (Git for Windows puts it in this folder by default):

```powershell
& "C:\Program Files\Git\bin\bash.exe" scripts/install-hooks.sh
```

*You should see:* `✓ core.hooksPath set to .githooks`, and `git config core.hooksPath` then prints `.githooks`.
**Untested on Windows in this lab so far:** tonight's first Windows evening is the test. If a hook fails with a
message about `\r`, the line-ending setting in section 3 was set after the clone; tell your steward.

<sub>The `bash.exe` path is the one Anthropic's [setup page](https://code.claude.com/docs/en/setup#install-on-native-windows) gives for Git for Windows, checked 2026-11-18. The script is [`scripts/install-hooks.sh`](../scripts/install-hooks.sh).</sub>

**Sign the secret scan in.** GitGuardian's `ggshield` reads every commit for passwords and keys before it leaves your
computer ([The secret scan](SECRET-SCAN.md)). Install it, then sign in **yourself** (it opens the browser):

```powershell
# Windows (PowerShell)
irm https://raw.githubusercontent.com/GitGuardian/ggshield/main/scripts/install/install.ps1 | iex
```

```sh
# macOS
brew install ggshield
```

```sh
ggshield auth login
ggshield api-status
```

<sub>Checked 2026-11-18 against GitGuardian's [Getting started](https://docs.gitguardian.com/ggshield-docs/getting-started). `pipx install ggshield` also works on either system.</sub>

## <img src="../assets/icons-phosphor/sprout.svg" width="24" height="24" alt=""> 11 · Turn one of your own app folders into a private repository

You have a folder of work (an app your AI helpers built, say) and you want it kept safely, privately, under your own
account. Five small steps. Your helper can do each one; read what it shows you.

1. **Move the folder into `~/code`** (drag it in File Explorer or Finder), and go into it with `cd`. Moving deletes
   nothing. Add its name to `~/code/.gitignore` if `~/code` is a parent repository.
2. **Write the `.gitignore` first.** It lists what must never be recorded. At the very least:

   ```gitignore
   .env
   .env.*
   !.env.example
   node_modules/
   .DS_Store
   ```

   This template's own [`.gitignore`](../.gitignore) is a fuller start.
3. **Bring in the lab's two hooks** (the secret scan, and a commit-credit check that only advises and never blocks),
   from a clone of this template at `~/code/my-template` (`gh repo clone drasticstatic/my-template ~/code/my-template`):

   ```powershell
   # Windows (PowerShell), inside your app folder
   mkdir .githooks, scripts
   Copy-Item "$HOME\code\my-template\org-onboarding\githooks\pre-commit" .githooks\pre-commit
   Copy-Item "$HOME\code\my-template\org-onboarding\githooks\commit-msg.advisory" .githooks\commit-msg
   Copy-Item "$HOME\code\my-template\scripts\install-hooks.sh" scripts\install-hooks.sh
   ```

   ```sh
   # macOS, inside your app folder
   mkdir -p .githooks scripts
   cp ~/code/my-template/org-onboarding/githooks/pre-commit .githooks/pre-commit
   cp ~/code/my-template/org-onboarding/githooks/commit-msg.advisory .githooks/commit-msg
   cp ~/code/my-template/scripts/install-hooks.sh scripts/install-hooks.sh
   ```

   ([which file goes where](../org-onboarding/README.md))
4. **Start the history and look before you commit.** `git init` makes the folder a repository; `git add .` lists every
   file for the first commit; `git status` shows you that list.

   ```sh
   git init
   git add .
   git status
   ```

   **Read the list.** If you see `.env`, a key, a wallet or anything with *secret*, *token* or *credentials* in its
   name, stop: `git restore --staged <that file>` takes it off the list (it stays on your disk), and add its name to
   `.gitignore`. When the list is clean, switch the hooks on and make the first commit (from PowerShell, use the
   `bash.exe` form of the first line, as in section 10):

   ```sh
   sh scripts/install-hooks.sh
   git commit -m ":tada: chore(init): first commit"
   ```

5. **Create the private repository on GitHub and send the history there,** in one command, from inside the folder:

   ```sh
   gh repo create <name> --private --source=. --push
   ```

   `--private` makes it private; `--source=.` means *this folder*; `--push` sends your commits. Never type `--public`
   here. Making something public is a later decision, made by its owner after the public-lane scanner has read it
   ([`scripts/scan-public-lane.sh`](../scripts/scan-public-lane.sh)).

<sub>Checked 2026-11-18 against [gh repo create](https://cli.github.com/manual/gh_repo_create) ("Make the new repository private", "Specify path to local repository to use as source", "Push local commits to the new repository").</sub>

## <img src="../assets/icons-phosphor/eye.svg" width="24" height="24" alt=""> 12 · Private or public? How to tell

GitHub's definitions: "Public repositories are accessible to everyone on the internet." "Private repositories are only
accessible to you, people you explicitly share access with," and, for an organisation, certain of its members.

**Ask the terminal; it does not guess.**

```sh
gh repo view <owner>/<name> --json visibility --jq .visibility
```

*You should see:* `PRIVATE` (or `PUBLIC`, or `INTERNAL` in some organisations). To list every public repository an
account has:

```sh
gh repo list <owner> --visibility public
```

An empty answer for your own login means none of yours is public.

**On the website,** GitHub shows a small **Private** or **Public** label beside a repository's name at the top of its
page. (GitHub's own page on repositories does not describe the label, so when it matters, trust the command.)

<sub>Checked 2026-11-18 against [About repositories](https://docs.github.com/en/repositories/creating-and-managing-repositories/about-repositories), [gh repo view](https://cli.github.com/manual/gh_repo_view) (its `--json` fields include `visibility` and `isPrivate`) and [gh repo list](https://cli.github.com/manual/gh_repo_list) (`--visibility {public|private|internal}`).</sub>

## <img src="../assets/icons-phosphor/network.svg" width="24" height="24" alt=""> Later: connections for your helpers

Not for the first evening. Each connection lets your Claude Code read or write in another tool, after you sign in to
that tool in the browser. Anthropic's own warning: "Verify you trust each server before connecting it."

| Tool | The command (in a terminal) | Then |
|---|---|---|
| **Linear** | `claude mcp add --transport http linear-server https://mcp.linear.app/mcp` | in a Claude Code session, `/mcp`, and sign in ([Linear](https://linear.app/docs/mcp), checked 2026-11-18). For Codex: `codex mcp add linear --url https://mcp.linear.app/mcp` |
| **Miro** | `claude plugin install miro@claude-plugins-official` | follow the sign-in it asks for ([Miro](https://developers.miro.com/docs/miro-mcp), checked 2026-11-18; its server is `https://mcp.miro.com/`) |
| **Littlebird** | see [Connect Littlebird](CONNECT-LITTLEBIRD.md) | the walkthrough covers what stays private |
| **Any other** | `claude mcp add --transport http <name> <url>` | `/mcp` to sign in. Added this way it works in one project only; `--scope user` makes it work in all of yours ([Anthropic](https://code.claude.com/docs/en/mcp), checked 2026-11-18) |

## <img src="../assets/icons-phosphor/message-circle-question.svg" width="24" height="24" alt=""> When something goes wrong

| What you see | What it usually means | What to do |
|---|---|---|
| `... is not recognized` (Windows) or `command not found` (macOS) right after an install | the window is older than the install | close it, open a new one, try again |
| `'irm' is not recognized` | you are in CMD, not PowerShell | open PowerShell (section 1) |
| `The token '&&' is not a valid statement separator` | you are in PowerShell, running a CMD command | use the PowerShell command instead |
| `claude` is still not found in a new window | the install folder is not on your PATH | Anthropic's [Fix your PATH](https://code.claude.com/docs/en/troubleshoot-install#command-not-found-claude-after-installation) |
| `git push` asks for a password | git is not using `gh`'s sign-in | `gh auth setup-git` (section 8) |
| the secret scan stops a commit | a secret is in the change | stop; [The secret scan](SECRET-SCAN.md) says what to do. Never `--no-verify` |
| anything else | | ask your helper *"what does this message mean? Don't change anything yet"*, or your steward |

<sub>The first three rows are Anthropic's, from the [setup page](https://code.claude.com/docs/en/setup) and [terminal guide](https://code.claude.com/docs/en/terminal-guide), checked 2026-11-18.</sub>

<details>
<summary><b>Every source, and what is not verified</b></summary>

All read on 2026-11-18.

| Claim | Source |
|---|---|
| Claude Code: requirements, installers (PowerShell, CMD, macOS, Homebrew, WinGet), `claude --version`, `claude doctor`, Git for Windows optional, paid plan | <https://code.claude.com/docs/en/setup> |
| Opening PowerShell and Terminal, pasting, the `(x86)` and PATH fixes | <https://code.claude.com/docs/en/terminal-guide> |
| The VS Code extension: ID, VS Code 1.94+, sign-in, it does not put `claude` on PATH | <https://code.claude.com/docs/en/vs-code> |
| Adding a remote MCP server, scopes, `/mcp`, the trust warning | <https://code.claude.com/docs/en/mcp> |
| WinGet: where it comes from, elevation prompts, `--version` | <https://learn.microsoft.com/en-us/windows/package-manager/winget/> |
| Homebrew's install command | <https://brew.sh> |
| Git for Windows via winget, and its caveat; Git 2.56.1 | <https://git-scm.com/install/windows> |
| Git on macOS | <https://git-scm.com/install/mac> |
| `user.name`, `user.email`, `init.defaultBranch` | <https://git-scm.com/book/en/v2/Getting-Started-First-Time-Git-Setup> |
| `core.autocrlf` | <https://git-scm.com/book/en/v2/Customizing-Git-Git-Configuration>, <https://docs.github.com/en/get-started/git-basics/configuring-git-to-handle-line-endings> |
| `gh` install | <https://github.com/cli/cli/blob/trunk/docs/install_windows.md>, <https://github.com/cli/cli/blob/trunk/docs/install_macos.md> |
| `gh auth login`, `gh auth setup-git`, `gh repo clone`, `gh repo create`, `gh repo view`, `gh repo list` | <https://cli.github.com/manual/> (each command's page) |
| The noreply address | <https://docs.github.com/en/account-and-profile/reference/email-addresses-reference> |
| Two-factor | <https://docs.github.com/en/authentication/securing-your-account-with-two-factor-authentication-2fa/configuring-two-factor-authentication> |
| Public and private | <https://docs.github.com/en/repositories/creating-and-managing-repositories/about-repositories> |
| VS Code on Windows and macOS | <https://code.visualstudio.com/docs/setup/windows>, <https://code.visualstudio.com/docs/setup/mac> |
| Codex extension, CLI, and its install commands | <https://learn.chatgpt.com/docs/codex/ide>, <https://learn.chatgpt.com/docs/codex/cli>, <https://github.com/openai/codex> |
| Antigravity extension and accounts | <https://antigravity.google/docs/ide/extensions/vscode>, <https://antigravity.google/docs/install> |
| ggshield | <https://docs.gitguardian.com/ggshield-docs/getting-started> |
| Linear and Miro connections | <https://linear.app/docs/mcp>, <https://developers.miro.com/docs/miro-mcp> |

**Unverified or untested:** Codex on native Windows (extension and terminal command); the `agy` terminal tool's own
install command; the **Private**/**Public** label's wording on GitHub's site (seen, not documented); the
`Microsoft.VisualStudioCode` winget package (listed in Microsoft's repository, not on VS Code's setup page); and every
lab script (`install-hooks.sh`, the hooks, the scanner) on Windows, which no one in the lab has run there yet.

</details>

## <img src="../assets/icons-phosphor/history.svg" width="24" height="24" alt=""> Change log

| Date | Change |
|---|---|
| 2026-11-18 | First version, for the first Windows newcomer's evening: two tracks, every command checked against its maker's page. No PDF yet. |

## <img src="../assets/icons-phosphor/git-pull-request.svg" width="24" height="24" alt=""> Suggest a change

Ran this on your own computer and a step was different? That is the most useful thing you can tell us. Open an [issue](https://github.com/drasticstatic/my-template/issues) or a pull request against `main`; the lab steward reads them, and a person with the role merges with a merge commit so your name stays on it. Not on GitHub? Tell any steward you know, or your helper, in your own words.

<sub>Part of the [walkthroughs](README.md); the evening it serves is [`START-HERE.md`](../START-HERE.md). Icons: Phosphor duotone (MIT). Git, GitHub, Homebrew, VS Code, Claude Code, Codex, Antigravity, GitGuardian, Linear and Miro are their makers' work, and their commands are theirs to change: when a step here stops matching, the maker's page wins.</sub>
