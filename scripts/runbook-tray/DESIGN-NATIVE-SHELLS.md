# Design: native shells for the runbook tray

**Status: PROPOSED (2026-11-16).** Nothing on this page is built. No Xcode tool was run to write it (no `xcodebuild`,
`swift`, `swiftc` or `xcode-select`); the macOS part waits for a dedicated session in which the owner allows Xcode.
Apple's wording quoted here was read on developer.apple.com the same day; everything else marked *to check* was not.

## The principle: one core, a thin shell per system

The tray already splits in two. `runbook-tray.py` decides every word, mark and colour and writes them as JSON;
`tray.applescript` only draws that file and asks the helper to act. A new shell keeps exactly that split. It draws,
it asks, and it never decides anything, reads the config or runs a command of its own.

**The core already has the JSON output. No `--json` flag is needed.** The command every shell runs is:

```sh
python3 -I runbook-tray.py render --config CONFIG --state STATE
```

It writes `STATE/menu.json` whole or not at all (written beside it, then moved over it), and exits 0 when all is
good, 1 when something needs a look or the check did not run, 2 on a config error (in which case `menu.json` still carries a problem menu). On
macOS `STATE` is `~/Library/Application Support/<name>/` by default. `--print` adds a text drawing of the same menu to
stdout, for a person; shells read the file, not stdout.

When an entry is chosen, the shell runs:

```sh
python3 -I runbook-tray.py act ID --config CONFIG --state STATE
```

and renders again a second later, as the applet does.

### The contract: `menu.json`, version 1

```json
{"version": 1, "name": "Runbook", "epoch": 1763280000, "stale_after": 300,
 "bar": {"symbol": "checklist", "tint": "amber", "text": "2", "tooltip": "Runbook: 2 need a look …", "gauge": 0.62},
 "items": [{"kind": "info", "title": "…", "subtitle": "…", "state": "look",
            "symbol": "exclamationmark.triangle.fill", "tint": "amber", "mark": "!"}]}
```

Item kinds a shell draws: `info`, `header`, `separator`, `meter` (`value` 0 to 1, `tint`), `spark` (`values`),
`parts` (split bar, each part with `light` and `dark` colours), `swatch`, `group` (a submenu with `items`, sometimes
`parts` or a state), and `action` (`id`, `enabled`, `symbol`). Rules for every shell:

- **A kind it does not know, it skips.** A key it does not know, it ignores. A `version` above the one it knows, it
  shows as a problem row and still offers *Refresh now* and *Quit*.
- **Symbols are a wish, marks are the floor.** `symbol` names an SF Symbol (macOS only). Every `info` and `group`
  row also carries `mark` (✓ ! ✕ – ?) and `tint`, so a shell without SF Symbols still shows shape and colour.
- **Stale is the shell's one judgement:** when `now - epoch > stale_after`, it says the menu is old. That is the only
  thing a shell works out for itself.

## What stays the same on every system

- The config file and its rules, the status command's JSON, `menu.json`, the `act` command and its locks, the
  tray's folder and what is kept there.
- Commands are lists of words, never passed through a shell; the helper builds each child's environment itself.
- *Refresh now* and *Quit* are always in the menu, whatever the helper wrote.
- One render at a time: while one runs (up to 120 s), a second request waits and runs once when it ends.
- Refresh every `EVERY` seconds (60 by default, 15 at least), on start, after an entry, and on *Refresh now*.
- No button that "frees" memory; nothing added to login items; nothing scheduled, edited or stopped.
- A self-test mode in each shell, the applet's shape: `<shell> --selftest <folder of menu.json files> <report>`,
  fed the fixtures `runbook-tray.selftest.sh` already writes.

## macOS: SwiftUI `MenuBarExtra`

**What Apple says.** `MenuBarExtra` is "a scene that renders itself as a persistent control in the system menu bar",
available from macOS 13.0. "For apps that only show in the menu bar, … set the `LSUIElement` flag in your app's
Information Property List file to `true`", and "an app that only shows in the menu bar will be automatically
terminated if the user removes the extra from the menu bar." For "more complex or data rich menu bar extras", the
window style "displays a popover-like window from the menu bar icon".
([MenuBarExtra](https://developer.apple.com/documentation/swiftui/menubarextra), read 2026-11-16.)

**What it reads.** The six values the applet is stamped with today: the python, the helper, the config, the state
folder, the name and the interval. Proposed: the same six, kept in the app's `Info.plist` at build time (keys
`RunbookPython`, `RunbookHelper`, `RunbookConfig`, `RunbookState`, `RunbookName`, `RunbookEvery`), so the app reads
nothing else. Then `STATE/menu.json` after each render.

**How it acts.** Foundation's `Process` with `executableURL` set to the python and `arguments`
`["-I", helper, "act", id, "--config", config, "--state", state]`: no shell, no environment of its own. It waits on
the process's termination, then reloads `menu.json`. App Nap is held off the way the applet does it
(`ProcessInfo.beginActivity`), or the minute timer drifts.

**What it draws.** First the menu style, which matches today's applet row for row. Meters, the split memory bar and
the last-hour line become small images drawn with SwiftUI (`ImageRenderer`, *to check* that it renders crisply in a
menu), which retires the deprecated `lockFocus` drawing the README names as a limit. The window style is the second
step, once the menu style matches: it can show the meters as live SwiftUI views.

**Built with** either an Xcode project (macOS App, SwiftUI) or a Swift package with an executable target. A package
builds the program but not the `.app` around it, so it would need a small script, like `build.sh`, to assemble the
bundle and its `Info.plist` (*to check* in the Xcode session). Either way it lives under
`scripts/runbook-tray/shells/macos/`, with the template's Xcode ignore rules
([`walkthroughs/XCODE-PROJECTS-IN-GIT.md`](../../walkthroughs/XCODE-PROJECTS-IN-GIT.md)) and buildable folders.

**Signing.**

- *Personal use, one Mac:* signed to run locally, as `build.sh` signs the applet today (ad hoc). No account needed.
  The App Sandbox stays off: the shell must start a python and read its own folder. That rules out the Mac App Store,
  whose apps must be sandboxed (*to check*; not re-read today).
- *Given to other people:* Apple's notarisation page says "Beginning in macOS 10.15, all software built after June 1,
  2019, and distributed with Developer ID must be notarized", and the Developer ID page says "you must be the Account
  Holder of your development team in the Apple Developer Program in order to generate this certificate."
  ([Notarizing macOS software](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution),
  [Developer ID](https://developer.apple.com/developer-id/), read 2026-11-16.) A paid membership, then; and the
  python and helper it calls must come with it or be found on that Mac, which is a packaging question of its own.

## Windows: `pystray`, or .NET `NotifyIcon`

- **The core does not run on Windows yet.** Read from the code, not tried: `import fcntl` at the top (POSIX only, so
  the helper will not start), `os.getuid()` and the group/other write bits in the config check, `os.killpg` when a
  command passes its timeout, `/usr/bin/open` as the default opener, and a macOS `PATH` default. Each needs a
  Windows branch in the same file (`msvcrt` locking, an ACL or owner check, `Popen.kill` on a new process group,
  `os.startfile`). The machine section returns nothing off macOS; a Windows reader (`GlobalMemoryStatusEx` through
  `ctypes`, no outside code) is separate work.
- **Shell A, `pystray`** (Python). Its `win32` backend "supports all features" (pystray's usage page). It and Pillow
  are outside code, so they go through the outside-code review and a pinned fork first. Menus are text: meters
  become `▰▱` bars, which `as_text` in the helper already draws.
- **Shell B, a small C# app with `System.Windows.Forms.NotifyIcon`** and a context menu: no Python packages, ships as
  one signed `.exe`, draws bars as images. Signing for other people's machines is its own question (*to check*).
- Status on Windows is still the owner's own command. One that reads `Get-ScheduledTask` prints the same JSON; the
  tray does not change. (A saved Google AI Mode answer suggested a separate `runbook-tray-win.py`; this design keeps
  one core with a branch per system instead, so the rules cannot drift apart.)

## Linux: AppIndicator through `pystray`

- `pystray`'s `appindicator` backend is preferred on Linux, falls back to ayatana-appindicator, and supports "all
  features except a menu default action". Its `gtk` backend needs "a third party plugin" on a GNOME Shell session to
  show a tray icon at all, and `xorg` has no menus. ([pystray usage](https://pystray.readthedocs.io/en/latest/usage.html),
  read 2026-11-16.)
- The core runs there once the opener is `xdg-open` (a config can name one with `open_with` today). A Linux machine
  reader would read `/proc/meminfo` and `/proc/stat`; until then the section is left out, as now.

## The dedicated Xcode session: steps

1. The owner changes his own rule ("Xcode tools are never run") for that session, in writing. Start the session in
   this repository.
2. Installing Xcode, choosing it with `xcode-select` and accepting its licence all pop prompts: warn first.
3. New macOS App project (SwiftUI, Swift) under `scripts/runbook-tray/shells/macos/`, bundle id
   `local.runbook-tray.native`, buildable folders, `LSUIElement` on, App Sandbox off, *Sign to Run Locally*.
4. `Codable` types for `menu.json` version 1, skipping unknown kinds; decode every fixture the self-test writes.
5. One runner: `Process`, no shell, one render at a time, the 120 s guard, a re-render a second after `act`.
6. The menu style, item for item against the applet; then the stale rule, then *Refresh now* and *Quit*.
7. `--selftest <folder> <report>`, wired into `runbook-tray.selftest.sh` beside `--with-applet`.
8. Quit the AppleScript tray before trying the new one; both on one state folder would run the status command
   twice a minute.
9. Note in the README's limits what was tried, on which Mac and macOS; add the changelog entry. The applet stays as
   the no-Xcode road and is not removed.

## A phone companion

- **iOS.** Without a paid membership, Xcode uses a Personal Team, and Apple's comparison page says: "Provisioning
  profiles that enable apps to be installed on a device will expire 7 days from issuance. You'll need to rebuild and
  reinstall your app to your device after expiration", with "up to 3 apps per device". TestFlight and the App Store
  go through App Store Connect, which needs the Apple Developer Program.
  ([Choosing a membership](https://developer.apple.com/support/compare-memberships/), read 2026-11-16.) So anything
  beyond a short-lived install on your own phone needs the membership. A phone cannot run the helper either: it
  would read a `menu.json` the Mac publishes somewhere, which is a new way out of the machine and needs its own
  review.
- **A Telegram mini app** is the cross-platform alternative: Telegram's documentation describes interfaces built
  with JavaScript that "can be launched right inside Telegram" ([Telegram Mini Apps](https://core.telegram.org/bots/webapps),
  read 2026-11-16), so one page serves iOS, Android and desktop with no Apple account. It needs a bot and a host for
  the page and the state it shows, which is a public surface: the owner's decision, and the same review.
