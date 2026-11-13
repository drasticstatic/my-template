# `runbook-tray/`: scheduled jobs and this Mac, in the menu bar

One item in the macOS menu bar. Its menu shows each scheduled job with a mark, your own checks, a section on the
Mac itself (memory as one meter and part by part, swap, processor, disk, the last hour of memory, the apps holding
the most memory), and a few
entries that run a script or open a page. Built from what macOS ships: AppleScript, compiled by `osacompile`. No
package is installed, nothing is downloaded, and Xcode is not used.

The lesson, start to finish: [`tutorials/A-RUNBOOK-TRAY-IN-THE-MENU-BAR.md`](../../tutorials/A-RUNBOOK-TRAY-IN-THE-MENU-BAR.md).

```sh
python3 -I runbook-tray.py doctor --config YOUR.json           # check a config; runs nothing
python3 -I runbook-tray.py render --config YOUR.json --state /tmp/tray-try --print   # the menu, as text
sh build.sh --config YOUR.json --print                         # what a build would do; writes nothing
sh build.sh --config YOUR.json                                 # builds ~/Applications/Runbook Tray.app; starts nothing
sh runbook-tray.selftest.sh                                    # 222 checks in a temporary folder
sh runbook-tray.selftest.sh --with-applet                      # 251: also draws every menu (an item shows for a second)
```

## What is here

| File | What it is |
|---|---|
| [`tray.applescript`](tray.applescript) | the menu-bar item. It only draws: it reads `menu.json`, shows it, and asks the helper to act when an entry is chosen |
| [`runbook-tray.py`](runbook-tray.py) | the helper, Python's standard library only. It runs your status command, reads this Mac, decides every word and mark, and writes `menu.json`. Its first lines give the status command's format |
| [`build.sh`](build.sh) | fills the applet's six paths, compiles it with `osacompile`, marks it as having no Dock icon, and signs it for this Mac only |
| [`config.example.json`](config.example.json), [`status.example.py`](status.example.py) | a config and a status command to start from |
| [`runbook-tray.selftest.sh`](runbook-tray.selftest.sh) | the proof, with a made-up home, status command, entries and opener |

## The rules it keeps

- **It reads and runs only what you name.** Commands are lists of words in your config and never pass through a
  shell. A config that another account on the Mac could write is refused. Nothing of the caller's environment is
  passed to a command except `HOME`, the config's `PATH` and the account's name.
- **It never schedules, edits or stops a scheduled job,** never asks for a password, and adds nothing to Login
  Items. The one thing it stops is its own command that has run past its timeout.
- **It names apps, never their arguments.** The memory list is read with `top -stats pid,mem` and
  `ps -o pid=,comm=`; a helper process is counted with its app.
- **Two entries are always in the menu,** whatever the helper wrote: *Refresh now* and *Quit*.
- **A long side list folds away.** Name a group in the config (`"status": {"fold": ["Group name"]}`) and its rows
  sit in a submenu, under one row that carries their worst state and counts them. A row your status command marks
  `"counted": false` is shown with its state and never raises the mark in the menu bar: for things worth seeing
  that are not the machine's own jobs, such as the tools a session needs before it starts.
- **Its files** are in `~/Library/Application Support/<name>/`, readable by you alone: `menu.json`, `status.json`,
  `history.json` (six hours of samples), `processes.json`, `tray.log`, `actions/` with each entry's last output,
  and `days/<date>.csv`, one line a minute of the Mac's memory, swap and processor, which nothing removes.
  An earlier build is moved to `previous-builds/` there, never deleted.
- **It has no button that "frees" memory.** macOS gives cached files back by itself the moment something needs
  the room, and what apps hold comes back as soon as they are used. The tray shows where memory is, so that the
  owner can close what is holding it.

## What the colours mean

| Mark | Meaning |
|---|---|
| green tick, amber triangle, red octagon, grey dash | a row's state as your status command gave it: good, look, bad, off. The shape carries it as well as the colour |
| grey question mark | `unknown`: the check cannot tell from where it runs (a remote service it does not call, say). Shown, never counted, like `off` |
| a blue bar | a measure with no alarm attached |
| an amber or red memory bar | the kernel's own memory pressure level is *warning* or *critical* (`kern.memorystatus_vm_pressure_level`) |
| grey bars | a ranking, largest first, each against the largest |
| blue, pink and violet in one split bar | memory's parts: app memory, wired, compressed. Hues that tell parts apart, never a state. Cached files and free memory are greys. The three hues were checked as neighbours for colour-blind readers, on a light and a dark menu |
| the menu bar's picture | plain when all is good; amber or red, with a count, when rows need a look; the small upright gauge is memory used |

## Limits, stated plainly

- Built and run on one Mac (Apple silicon, macOS 15.4.1, Nov 13, 2026). Not tried on another Mac or macOS version.
- *Memory used* is app memory + wired + compressed, from `vm_stat`. It was not compared with Activity Monitor's figure.
  The five parts do not add to the whole exactly: a small remainder that `vm_stat` puts in none of them shows as
  faint track at the end of the split bar.
- *Compressed … holding N GB* is `vm_stat`'s "Pages stored in compressor", which its manual calls "the total number
  of pages (uncompressed) held within the compressor". Whether that includes what has gone on to swap is not stated
  there and was not established.
- Swap is drawn against the size of memory, because swap has no fixed limit of its own.
- The processor figure is the share of time not idle since the tray's previous sample, about a minute.
- The picture-drawing uses `lockFocus`, which Apple marks as deprecated. If it stops working, rows lose their bars
  and keep their words; the menu bar falls back to the plain picture.
- The app is signed for the Mac that built it and is not notarised. Build it on each Mac from this folder.
