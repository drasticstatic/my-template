# Changelog: `runbook-tray/`

What changed in the menu-bar runbook tray, newest first. The form follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/): each entry is dated, says what was added, changed or fixed,
and names its commit in this repository. The tray has no version numbers yet; a commit is its version.

This file was written on 2026-11-16, afterwards, from `git log -- scripts/runbook-tray/` and the tutorial
`tutorials/A-RUNBOOK-TRAY-IN-THE-MENU-BAR.md`, and from each commit's own message. Nothing in an entry is newer than
its commit. From now on, a change to this folder adds its entry here in the same commit.

## [Unreleased]

### Added
- `DESIGN-NATIVE-SHELLS.md`, PROPOSED: one Python core, whose `render` already writes `menu.json`, and a thin shell
  per system (SwiftUI `MenuBarExtra` on macOS, `pystray` or .NET `NotifyIcon` on Windows, AppIndicator on Linux), the
  steps for a dedicated Xcode session, and a phone companion. Nothing built; no Xcode tool run.

## 2026-11-13 · `3aaac74`: folding groups, rows not counted, and *unknown*

### Added
- `"fold": ["Group name"]` beside the status command: that group's rows sit in a submenu, under one row that carries
  their worst state as its mark and counts each state.
- A row with `"counted": false` is shown with its state and never raises the mark in the menu bar.
- A fifth state, `unknown`: a grey question mark, for what the check cannot tell from where it runs. Shown, never
  counted.

### Changed
- Self-test: 222 checks, 251 with the applet's round. First use: the MCP servers a Claude session needs before it
  starts, on the Mac it was built on.

## 2026-11-13 · `110d7ef`: memory part by part, and a record of each day

### Added
- A submenu, *Memory, part by part*: one thin bar split into app memory, wired, compressed, cached files and free, a
  line for each with its amount and what it is, and the kernel's pressure level with the share of memory it counts as
  available. Compressed also says how much it is holding, from `vm_stat`.
- `days/<date>.csv` in the tray's folder: one line a minute of memory, swap, the parts and the processor. Nothing
  removes a day.

### Changed
- The parts are told apart by three hues checked as neighbours for colour-blind readers, on a light and a dark menu;
  amber, red and green stay with state. The same split shows small on the row in the main menu.
- Every row has a picture, so the words line up; the state marks show their inner sign.
- Self-test: 203 checks, 230 with the applet's round.

### Not added, on purpose
- A button that "frees" memory. The README says why.

## 2026-11-13 · `b1c2f83`: notes for the next editor

### Added
- `tray.applescript`: what to know before editing the applet's source. AppleScript's case-blind names collide with
  AppKit's method names, and a few plain words are already taken.

## 2026-11-13 · `66b3564`: built, with nothing installed

### Added
- The tray itself, one item in the macOS menu bar: a mark per scheduled job, the owner's own checks, the Mac's memory,
  swap, processor and disk as meters, the last hour of memory as a line, the apps holding the most memory in a submenu,
  and entries that run a script or open a page.
- `tray.applescript`: the menu-bar item, an AppleScript applet. It only draws.
- `runbook-tray.py`: the helper, Python's standard library only. It runs the status command, reads the Mac (`sysctl`,
  `vm_stat`, `top`, `ps`, `df`), decides every word and mark, and writes `menu.json`. `doctor` checks a config and runs
  nothing.
- `build.sh`: `osacompile`, `plutil`, `codesign` (ad hoc). Starts nothing, adds nothing to Login Items, and moves an
  earlier build aside instead of deleting it.
- `config.example.json`, `status.example.py`: a config and a status command to start from.
- `runbook-tray.selftest.sh`: 182 checks in a temporary folder; 205 with `--with-applet`, which draws every menu, reads
  back from AppKit what was drawn, and saves a picture of each for a person to look at.

### Changed
- The design no longer uses the `rumps` package, which was waiting on the outside-code review. This one has no outside
  code.
- The tutorial is rewritten as built, with what was and was not tested: one Mac, Apple silicon, macOS 15.4.1.

## 2026-11-12 · `9571c2a`: designed, not built

### Added
- `tutorials/A-RUNBOOK-TRAY-IN-THE-MENU-BAR.md`: a menu-bar item in Python with `rumps` (a dot per scheduled job; run
  the daily check, open the runbook, refresh), an untested sketch, the Shortcuts menu-bar route, and a Windows
  counterpart as a listed task. No code in this folder yet.
