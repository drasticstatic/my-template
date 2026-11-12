<div align="center">

<img src="../assets/icons-phosphor/book-marked.svg" width="56" height="56" alt="">

# Open your first vault

*Install a Markdown vault app, open a folder you already have as a vault, and learn which of its files a team shares.*

![Kind](https://img.shields.io/badge/Kind-Tutorial-800020?style=flat-square)
![Changed](https://img.shields.io/badge/Changed-2026--11--12-800020?style=flat-square)
![For](https://img.shields.io/badge/For-Anyone_opening_a_notes_folder_for_the_first_time-64748b?style=flat-square)

<img src="../assets/icons-phosphor/map-pin.svg" width="16" height="16" alt=""> **You are here:** drasticstatic lab › [`my-template`](../README.md) › [`tutorials`](README.md) › `OPEN-YOUR-FIRST-VAULT.md` · public · `main` is the working branch

</div>

## <img src="../assets/icons-phosphor/compass.svg" width="24" height="24" alt=""> TL;DR

1. <img src="../assets/icons-phosphor/book-marked.svg" width="16" height="16" alt=""> **A vault is just a folder** of Markdown notes, plus one hidden folder where the app keeps its settings. The app used here is [Obsidian](https://obsidian.md).
2. <img src="../assets/icons-phosphor/shield-check.svg" width="16" height="16" alt=""> **Restricted mode is on by default** and stops third-party plugins from running. Leave it on. You can tell it is on when **Settings → Community plugins** shows a **Turn on community plugins** button.
3. <img src="../assets/icons-phosphor/folder-lock.svg" width="16" height="16" alt=""> **The app's own folder is `.obsidian/`.** A team commits the few files that describe how the vault behaves, and keeps one person's window layout to themselves.
4. <img src="../assets/icons-phosphor/users.svg" width="16" height="16" alt=""> **Who does what:** you install the app and click through its windows. A helper can explain each step and check the folder afterwards.

> **Handing this to your AI helper?** Say: *"Read OPEN-YOUR-FIRST-VAULT.md and walk me through it, one step at a time. I will click; you check."*

## <img src="../assets/icons-phosphor/sprout.svg" width="24" height="24" alt=""> What you will learn

- how to open a folder you already have as a vault, without moving or copying it;
- how to tell, at a glance, that no third-party code can run in it;
- what the app writes into your folder, and which of those files belong in a shared repository.

## <img src="../assets/icons-phosphor/list-checks.svg" width="24" height="24" alt=""> Before you start

**You need:** about 15 minutes, a Mac (the steps for other systems are on Obsidian's [install page](https://obsidian.md/help/install)), and a folder of notes, for example a clone of your team's repository.

| Placeholder | Meaning | Example |
|---|---|---|
| `VAULT` | the folder you will open as a vault | `~/notes/team-notes` |

## <img src="../assets/icons-phosphor/footprints.svg" width="24" height="24" alt=""> 1. Install the app

1. Open <https://obsidian.md/download>.
2. Under **macOS**, click **Universal**.
3. Open the file you downloaded, and in the window that opens drag **Obsidian** to **Applications**.
4. Open Obsidian as you would any other app.

*You should see:* Obsidian's window. Nothing has been written to `VAULT` yet.

## <img src="../assets/icons-phosphor/door-open.svg" width="24" height="24" alt=""> 2. Open your folder as a vault

1. At the bottom left, select the **vault profile** icon.
2. In the menu that pops up, choose **Manage Vaults…**
3. To the right of **Open folder as vault**, click **Open**.
4. Choose `VAULT` in the file browser and click **Open**.

*You should see:* your folder's notes listed in the app. The files stayed where they were: the vault is the folder itself.

## <img src="../assets/icons-phosphor/shield-check.svg" width="24" height="24" alt=""> 3. Check that Restricted mode is on

Obsidian runs in **Restricted mode** by default, so that no third-party plugin code runs. Installed plugins stay in the vault but are ignored while it is on.

1. Open **Settings**.
2. In the side menu, select **Community plugins**.

*You should see:* a **Turn on community plugins** button. That button is the sign Restricted mode is **on**. **Do not press it.** Pressing it turns Restricted mode off; Obsidian's own advice is to do that only if you trust the authors of the plugins you install.

If you see a list of plugin settings instead, Restricted mode is off. To turn it back on: **Settings → Community plugins**, then next to **Restricted mode**, select **Turn on**.

## <img src="../assets/icons-phosphor/folder-lock.svg" width="24" height="24" alt=""> 4. Find the app's own folder, `.obsidian/`

Obsidian keeps every setting for this vault in a **configuration folder** inside it, named `.obsidian`. A name that starts with a dot is hidden, so show hidden files first (in Finder, **⌘⇧.**; see [Show hidden files](../walkthroughs/SHOW-HIDDEN-FILES.md)).

```sh
ls -A VAULT/.obsidian
```

*You should see:* a few `.json` files. In a vault opened for the first time on 2026-11-12 they were `app.json`, `appearance.json`, `core-plugins.json`, `graph.json` and `workspace.json` (what we saw; Obsidian's help does not list them, and a newer version may write others).

The folder's name can be changed (**Settings → Files and links → Override config folder**, then relaunch), but settings do not move with it. Keep the default unless your team has agreed otherwise.

## <img src="../assets/icons-phosphor/git-branch.svg" width="24" height="24" alt=""> 5. Decide what a team commits

Obsidian's help gives no rule for version control, so this is **the fleet's practice**, not Obsidian's:

| File | Commit it? | Why |
|---|---|---|
| `app.json`, `appearance.json`, `core-plugins.json` | yes | they say how the vault behaves for everyone: links, look, which built-in features are on |
| `community-plugins.json`, written as `[]` | yes | an empty list on purpose: any plugin someone installs then shows up as a change in review |
| `workspace.json` | no | one person's window: which panes are open and which files were open last. It changes every time you click |
| `graph.json` | your choice | how the graph view is drawn; harmless either way |

Many repositories ignore every `*.json` file (this template's `.gitignore` does). Then each file you mean to commit needs its own exception line, such as `!.obsidian/app.json`. Check one:

```sh
git -C VAULT check-ignore -v .obsidian/app.json
```

*You should see:* nothing, once the exception is in place. A line naming `*.json` means the file is still ignored.

## <img src="../assets/icons-phosphor/cloud.svg" width="24" height="24" alt=""> 6. The Obsidian folder in iCloud Drive

You may find a folder named **Obsidian**, with the app's icon, in iCloud Drive, and it may be empty. Obsidian's help says vaults that **sync through iCloud** go inside that folder. A vault kept anywhere else, such as a git repository on your disk, does not use it, so an empty one can be left alone. (When that folder appears is our observation, not something Obsidian's help states.)

Obsidian's help also warns against syncing one vault through more than one service at once. A vault that is a git repository stays out of iCloud Drive altogether ([iCloud and GitHub, together](../walkthroughs/ICLOUD-AND-GITHUB-TOGETHER.md)).

## <img src="../assets/icons-phosphor/circle-check.svg" width="24" height="24" alt=""> Check what you learned

- [ ] Your notes open in the app, and they never left `VAULT`.
- [ ] **Settings → Community plugins** shows **Turn on community plugins**, and you did not press it.
- [ ] You can say which `.obsidian/` files your team commits, and why `workspace.json` is not one of them.

## <img src="../assets/icons-phosphor/link.svg" width="24" height="24" alt=""> Where next

- <img src="../assets/icons-phosphor/eye.svg" width="16" height="16" alt=""> [Show hidden files](../walkthroughs/SHOW-HIDDEN-FILES.md): see `.obsidian` and `.git` in Finder.
- <img src="../assets/icons-phosphor/history.svg" width="16" height="16" alt=""> [Find, resume or rebuild an old session](FIND-RESUME-OR-REBUILD-A-SESSION.md): the next tutorial.

<details>
<summary><b>Sources, checked 2026-11-12</b></summary>

| Claim | Source |
|---|---|
| Install steps on macOS | <https://obsidian.md/help/install> |
| A vault is a folder with your notes and the configuration folder; opening a folder as a vault | <https://obsidian.md/help/manage-vaults> |
| Restricted mode is on by default; turning it off and on | <https://obsidian.md/help/plugin-security>, <https://obsidian.md/help/community-plugins> |
| The configuration folder, `.obsidian`, and overriding its name | <https://obsidian.md/help/configuration-folder> |
| iCloud vaults go inside the Obsidian folder; avoid syncing one vault through several services | <https://obsidian.md/help/sync-notes> |

The files a fresh vault holds, and when the iCloud folder appears, are our own observation. What a team commits is the fleet's practice.

</details>

## <img src="../assets/icons-phosphor/git-pull-request.svg" width="24" height="24" alt=""> Suggest a change

Noticed something wrong, or know a better way? Open an [issue](https://github.com/drasticstatic/my-template/issues) or a pull request against `main`; the lab steward reads them, and a person with the role merges with a merge commit so your name stays on it. Not on GitHub? Tell any steward you know, or your helper, in your own words.

<sub>One of the [tutorials](README.md) in `my-template`, in the shape of [`tutorials-template/`](../tutorials-template/). Icons: Phosphor duotone (MIT). Obsidian's name belongs to its makers; this page is not affiliated with them.</sub>
