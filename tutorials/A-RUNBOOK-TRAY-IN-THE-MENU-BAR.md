<div align="center">

<img src="../assets/icons-phosphor/circle-dashed.svg" width="56" height="56" alt="">

# A runbook tray in the menu bar

*Learn how a small menu-bar item could show each scheduled job's state at a glance, why it goes through the same gate as any outside code, and how to get most of it today with the Shortcuts app.*

![Kind](https://img.shields.io/badge/Kind-Tutorial-800020?style=flat-square)
![Status](https://img.shields.io/badge/Status-designed,_not_built-5c1a2b?style=flat-square)
![Changed](https://img.shields.io/badge/Changed-2026--11--12-800020?style=flat-square)
![For](https://img.shields.io/badge/For-Anyone_who_runs_scheduled_jobs_on_a_Mac-64748b?style=flat-square)

<img src="../assets/icons-phosphor/map-pin.svg" width="16" height="16" alt=""> **You are here:** drasticstatic lab › [`my-template`](../README.md) › [`tutorials`](README.md) › `A-RUNBOOK-TRAY-IN-THE-MENU-BAR.md` · public · `main` is the working branch

</div>

> [!IMPORTANT]
> **Designed, not built.** Nothing on this page has been installed or run. The tray is a design; its code below is a
> sketch that has never been executed. The part that works today is [step 6, the Shortcuts route](#-6-the-route-that-works-today-shortcuts-in-the-menu-bar).

## <img src="../assets/icons-phosphor/compass.svg" width="24" height="24" alt=""> TL;DR

1. <img src="../assets/icons-phosphor/circle-dashed.svg" width="16" height="16" alt=""> **The tray:** one small item in the menu bar, a coloured dot per scheduled job, and three entries: *Run the daily check*, *Open the runbook*, *Refresh*.
2. <img src="../assets/icons-phosphor/sprout.svg" width="16" height="16" alt=""> **The tools:** Python and the `rumps` package, which its maintainers describe as "Ridiculously Uncomplicated macOS Python Statusbar apps". No Xcode.
3. <img src="../assets/icons-phosphor/shield-check.svg" width="16" height="16" alt=""> **Its packages are outside code.** `rumps` and what it needs go through [SOP-IT-900](../sop-template/repo/IT/SOP-IT-900-bringing-in-outside-code.md) and [SOP-IT-901](../sop-template/repo/IT/SOP-IT-901-antivirus-screening-of-outside-code.md) before anything runs.
4. <img src="../assets/icons-phosphor/footprints.svg" width="16" height="16" alt=""> **Today:** the built-in Shortcuts app has a *Menu Bar* collection whose shortcuts appear in its menu in the macOS menu bar, so the same scripts can be one click away now.
5. <img src="../assets/icons-phosphor/list-checks.svg" width="16" height="16" alt=""> **Windows** gets its own counterpart, a listed task for the first Windows machine.

> **Handing this to your AI helper?** Say: *"Read A-RUNBOOK-TRAY-IN-THE-MENU-BAR.md. Help me set up step 6 for my
> daily check script. Don't install any package."*

## <img src="../assets/icons-phosphor/sprout.svg" width="24" height="24" alt=""> What you will learn

- what a runbook tray is for, and what it should and should not do;
- how a menu-bar app is put together in Python with `rumps`, from its own documentation;
- why a tray you write yourself still brings in outside code, and the gate it goes through;
- how to put the same scripts in the menu bar today with Shortcuts.

## <img src="../assets/icons-phosphor/list-checks.svg" width="24" height="24" alt=""> Before you start

**You need:** a Mac, a script you already run by hand (a daily check, for example), and about 20 minutes for step 6. Steps 1 to 5 are reading.

| Placeholder | Meaning | Example |
|---|---|---|
| `CHECK_SCRIPT` | the script your daily check runs | `~/code/<tool>/scripts/daily-check.sh` |
| `RUNBOOK` | the page you keep your runbook in | `~/vault/RUNBOOK.md` |
| `JOB_LABEL` | a scheduled job's launchd label | `local.example.nightly` |

## <img src="../assets/icons-phosphor/eye.svg" width="24" height="24" alt=""> 1. What the tray shows

```mermaid
flowchart LR
  J["scheduled jobs<br/>(launchd)"] -->|"read their state,<br/>every few minutes"| T["menu-bar item<br/>● ● ●"]
  T --> M1["Run the daily check"]
  T --> M2["Open the runbook"]
  T --> M3["Refresh"]
  M1 -->|"runs"| S["CHECK_SCRIPT,<br/>the same one you<br/>run by hand"]
```

- **A dot per job:** green when its last run succeeded, amber when it has not run when it should have, red when it failed. Hovering or opening the menu says which job is which.
- **Three entries, nothing more.** *Run the daily check* runs the script you already trust. *Open the runbook* opens `RUNBOOK`. *Refresh* reads the jobs' state again.
- **It only reads and runs what exists.** The tray never schedules, edits or deletes a job, and never asks for a password.

*You should see,* once it exists: one glance at the menu bar tells you whether the night went well.

## <img src="../assets/icons-phosphor/layers.svg" width="24" height="24" alt=""> 2. The pieces, from `rumps`'s own documentation

| Piece | What `rumps` documents |
|---|---|
| **The app** | `rumps.App` takes a `name`, a `title` ("text that will be displayed for the application in the statusbar"), an `icon`, a `menu` and a `quit_button`; `run()` starts the timers, registers the click callbacks and starts the run loop |
| **A menu entry** | a method decorated with `@rumps.clicked("<entry name>")` runs when that entry is chosen |
| **A timer** | `rumps.Timer(callback, interval)`: "Function that should be called every interval seconds", with `start()` and `stop()` |
| **What it needs** | PyObjC; installed with `pip install rumps` |
| **Licence** | Modified BSD (the repository labels it BSD-3-Clause) |
| **An app of its own later** | its README recommends py2app, and setting `LSUIElement` to `True` so the app shows no Dock icon |

The newest release on PyPI on 2026-11-12 was **0.4.0, from Oct 15, 2022**. An old last release is not a fault by itself, but it is a question the review in step 3 asks out loud.

## <img src="../assets/icons-phosphor/shield-check.svg" width="24" height="24" alt=""> 3. The gate comes before any code

You write the tray, but `rumps`, PyObjC, and py2app if you ever package it, are **someone else's code**. Before any of them is installed:

1. <img src="../assets/icons-phosphor/scan-search.svg" width="16" height="16" alt=""> A text review of each, at a pinned version, against the checklist in [SOP-IT-900](../sop-template/repo/IT/SOP-IT-900-bringing-in-outside-code.md#the-review-checklist): what the install runs, what it writes outside its folder, what leaves the machine, the licence, who publishes each dependency.
2. <img src="../assets/icons-phosphor/shield-check.svg" width="16" height="16" alt=""> The owner's antivirus scan of the staged packages, with a receipt ([SOP-IT-901](../sop-template/repo/IT/SOP-IT-901-antivirus-screening-of-outside-code.md)).
3. <img src="../assets/icons-phosphor/lock.svg" width="16" height="16" alt=""> Installed into the tray's own virtual environment, at those pinned versions, never system-wide and never by a piped installer.

*You should see:* a review and a receipt for each package before the first `import rumps`.

## <img src="../assets/icons-phosphor/file-text.svg" width="24" height="24" alt=""> 4. A sketch of the code (never run)

> [!WARNING]
> **Untested sketch.** This has not been run on any machine. It uses only the `rumps` names documented above and
> Python's own `subprocess`. Read it to learn the shape; do not install anything to try it until step 3 is done.

```python
import os
import subprocess
import rumps

JOBS = ["JOB_LABEL"]                      # one launchd label per scheduled job
CHECK_SCRIPT = "/path/to/daily-check.sh"  # the script you already run by hand
RUNBOOK = "/path/to/RUNBOOK.md"

def job_dot(label):
    """Green, amber or red for one job, from what launchctl prints. A sketch: the parsing is yours to write."""
    out = subprocess.run(["launchctl", "print", f"gui/{os.getuid()}/{label}"],
                         capture_output=True, text=True)
    if out.returncode != 0:
        return "🔴"
    return "🟢" if looks_healthy(out.stdout) else "🟠"

def looks_healthy(text):
    """Placeholder: decide from the job's own status file, or from launchctl's text once you have read it by eye."""
    return False

class RunbookTray(rumps.App):
    def __init__(self):
        super().__init__("Runbook", title="…", quit_button="Quit")
        self.timer = rumps.Timer(self.refresh, 300)   # every five minutes
        self.timer.start()

    def refresh(self, _=None):
        self.title = " ".join(job_dot(j) for j in JOBS)

    @rumps.clicked("Run the daily check")
    def run_check(self, _):
        subprocess.Popen(["/bin/sh", CHECK_SCRIPT])

    @rumps.clicked("Open the runbook")
    def open_runbook(self, _):
        subprocess.Popen(["open", RUNBOOK])

    @rumps.clicked("Refresh")
    def refresh_now(self, _):
        self.refresh()

if __name__ == "__main__":
    RunbookTray().run()
```

The text that `launchctl print` writes is the system's own and is not a documented interface, so the parsing in `job_dot` is a placeholder; the template's archive walkthrough reads the same command by eye ([*Check it*](../walkthroughs/CLAUDE-PROJECTS-ARCHIVE.md#-set-it-up-four-lines-in-this-order)). A job that writes its own status file is easier to read and is the better design.

## <img src="../assets/icons-phosphor/wrench.svg" width="24" height="24" alt=""> 5. Running it later, by hand

Once the gate is passed: start it from Terminal with the tray's own environment's Python, `python tray.py`, and stop it from its *Quit* entry. Making it start at login, or packaging it as an app with py2app, is a later step and a separate decision: py2app is outside code too.

## <img src="../assets/icons-phosphor/footprints.svg" width="24" height="24" alt=""> 6. The route that works today: Shortcuts in the menu bar

Apple's Shortcuts guide for macOS describes a sidebar collection named **Menu Bar**: it "contains shortcuts that appear in the Shortcuts menu in the macOS menu bar". So each entry of the tray can be a shortcut there today, with nothing installed.

1. <img src="../assets/icons-phosphor/pencil-line.svg" width="16" height="16" alt=""> **Make a shortcut named *Run the daily check*** in the Shortcuts app, whose one action runs `CHECK_SCRIPT`. The action that runs a shell script is **UNVERIFIED** here: Apple's guide pages read on 2026-11-12 do not describe it; look for it in the app's action library. *You should see:* the shortcut in **All Shortcuts**.
2. <img src="../assets/icons-phosphor/shield-alert.svg" width="16" height="16" alt=""> **Allow scripts, knowingly.** Apple's guide describes **Shortcuts › Settings › Advanced › Allow Running Scripts**, with its own warning: "Running shortcuts with scripts could cause data loss." Turn it on only if you will run your own reviewed scripts this way. *You should see:* the setting on.
3. <img src="../assets/icons-phosphor/layers.svg" width="16" height="16" alt=""> **Put the shortcut in the Menu Bar collection.** How a shortcut is added to that collection is **UNVERIFIED**: Apple's guide names the collection but, on the pages read today, does not say how a shortcut gets into it. *You should see:* the shortcut listed under **Menu Bar** in the sidebar.
4. <img src="../assets/icons-phosphor/circle-check.svg" width="16" height="16" alt=""> **Test it from Terminal first,** with the command Apple documents: `shortcuts run "Run the daily check"`. *You should see:* the same result as running `CHECK_SCRIPT` by hand.
5. <img src="../assets/icons-phosphor/sparkles.svg" width="16" height="16" alt=""> **Then from the menu bar:** open the Shortcuts menu there and choose it. Repeat for *Open the runbook*. *You should see:* both entries in the menu.

What Shortcuts does not give you is the row of dots: it runs things, it does not watch them. That is the part the tray adds.

## <img src="../assets/icons-phosphor/circle-check.svg" width="24" height="24" alt=""> Check what you learned

- [ ] You can say what the tray shows and what it never does.
- [ ] You can name the three `rumps` pieces the design uses, and where each is documented.
- [ ] You know why `rumps` goes through SOP-IT-900 and SOP-IT-901 before it is installed.
- [ ] Your daily check runs from the Shortcuts menu in the menu bar, and from `shortcuts run`.

## <img src="../assets/icons-phosphor/list-checks.svg" width="24" height="24" alt=""> Windows counterpart (a listed task)

| Task | Waits on | Notes |
|---|---|---|
| Design the same tray for Windows: a dot per scheduled task, the same three entries | the first Windows machine in the fleet | not started; its tools are outside code and take the same gate; checked against the vendor's own documentation when it is written, not before |

## <img src="../assets/icons-phosphor/link.svg" width="24" height="24" alt=""> Where next

- <img src="../assets/icons-phosphor/shield-check.svg" width="16" height="16" alt=""> [SOP-IT-900, bringing in outside code](../sop-template/repo/IT/SOP-IT-900-bringing-in-outside-code.md): the gate in full.
- <img src="../assets/icons-phosphor/brain-circuit.svg" width="16" height="16" alt=""> [The second brain](../walkthroughs/THE-SECOND-BRAIN.md): where a runbook and the daily check notes can live.

<details>
<summary><b>Sources, checked 2026-11-12</b></summary>

| Claim | Source |
|---|---|
| `rumps`'s description, PyObjC requirement, `pip install rumps`, the licence, py2app and `LSUIElement`, the `@rumps.clicked` example | <https://github.com/jaredks/rumps> |
| `rumps.App`'s parameters and `run()` | <https://rumps.readthedocs.io/en/latest/App.html> |
| `rumps.Timer(callback, interval)`, `start()`, `stop()` | <https://rumps.readthedocs.io/en/latest/Timer.html> |
| Newest release 0.4.0, Oct 15, 2022; BSD licence | <https://pypi.org/project/rumps/> |
| The *Menu Bar* collection in the Shortcuts sidebar (guide for macOS 27) | <https://support.apple.com/guide/shortcuts-mac/intro-to-shortcuts-apdf22b0444c/mac> |
| *Allow Running Scripts* and its warning | <https://support.apple.com/guide/shortcuts-mac/advanced-shortcuts-settings-apdfeb05586f/mac> |
| `shortcuts run "<name>"` | <https://support.apple.com/guide/shortcuts-mac/run-shortcuts-from-the-command-line-apd455c82f02/mac> |

**Unverified:** the action that runs a shell script, and how a shortcut is added to the Menu Bar collection; neither is described on the Apple pages read that day. The tray's design, the three entries, the dots and the gate are the fleet's own practice.

</details>

## <img src="../assets/icons-phosphor/git-pull-request.svg" width="24" height="24" alt=""> Suggest a change

Noticed something wrong, or built the tray and learned something? Open an [issue](https://github.com/drasticstatic/my-template/issues) or a pull request against `main`; the lab steward reads them, and a person with the role merges with a merge commit so your name stays on it. Not on GitHub? Tell any steward you know, or your helper, in your own words.

<sub>One of the [tutorials](README.md) in `my-template`, in the shape of [`tutorials-template/`](../tutorials-template/). Icons: Phosphor duotone (MIT). `rumps` is its maintainers' work and Shortcuts is Apple's; this page is not affiliated with either, and their behaviour is theirs to change.</sub>
