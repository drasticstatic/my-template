# SOP-IT-005 · Dependabot, by the fleet: who tests the updates, and the one line a helper hands over

![SOP](https://img.shields.io/badge/SOP-IT--005-d9a441?style=flat-square)
![Status](https://img.shields.io/badge/Status-draft-334155?style=flat-square)
![Changed](https://img.shields.io/badge/Changed-2026--11--05-8a6a2a?style=flat-square)
![For](https://img.shields.io/badge/For-Alfred%2C_Mystarch_and_any_helper-64748b?style=flat-square)

**Department:** IT · **ID:** 005 · **Status:** draft (approved when tagged) · **Owner:** the lab steward · **Last changed:** 2026-11-05

## <img src="../assets/icons/compass.svg" width="24" height="24" alt=""> Purpose
Dependabot's pull requests should not sit waiting for someone to notice them. The lab steward decided on Nov 4, 2026 that the fleet's helpers take them periodically. **What a helper does today:** tests and prepares each one, then hands the steward a one-line `! gh pr merge N --merge`. The permission system refused a session's `gh pr merge` on Nov 5, 2026, and a helper does not work around a refusal. If the steward adds a permission rule later, this page changes and step 6 becomes the helper's own. A change the fleet writes for an organisation still waits for a human with the role (SOP-OPS-002). This page says what a helper must check, and when to stop and ask.

## <img src="../assets/icons/map.svg" width="24" height="24" alt=""> Scope
Pull requests authored by `dependabot[bot]` on the lab's repositories and the organisations' repositories the lab maintains. **Not covered:** repositories someone else maintains (a member's own apps, third-party copies under `code-forked`), which get a note to their maintainer and no merge. How Dependabot is configured to stay gentle is in `my-template/walkthroughs/DEPENDABOT.md`.

## <img src="../assets/icons/users.svg" width="24" height="24" alt=""> Roles
| Role | Does |
|---|---|
| <img src="../assets/icons/bot.svg" width="16" height="16" alt=""> Helper | runs this page, prepares what passes, hands over the one-line merge, writes one line per sweep |
| <img src="../assets/icons/user-round.svg" width="16" height="16" alt=""> Lab steward | runs the one-line merge; decides every major upgrade the sweep sets aside; can stop the sweep with a word |

## <img src="../assets/icons/route.svg" width="24" height="24" alt=""> The decision

```mermaid
flowchart TD
  A["A Dependabot pull request"] --> B{"Someone else<br/>maintains this repo?"}
  B -->|"yes"| N["Note to the maintainer;<br/>no merge"]
  B -->|"no"| M{"A public mirror the<br/>lane force-pushes?"}
  M -->|"yes"| C["It can never merge:<br/>take the bump on the<br/>private source; close it"]
  M -->|"no"| D{"A major, in the title<br/>or in package.json?"}
  D -->|"yes"| H["Set aside for the steward,<br/>with what would break"]
  D -->|"no"| E{"Checks green, no new<br/>install scripts, tests<br/>pass in a scratch copy?"}
  E -->|"no"| S["Stop; report what failed"]
  E -->|"yes"| F["Hand over one line:<br/>! gh pr merge N --merge;<br/>one line in the log"]
```

## <img src="../assets/icons/list-checks.svg" width="24" height="24" alt=""> Prerequisites
A clean scratch worktree, never the working clone. A desk with something running from its folder (the ARB monitor, a listener) is never tested in place: installing would change what is running.

## <img src="../assets/icons/footprints.svg" width="24" height="24" alt=""> Steps

1. **List them.** `gh search prs --author app/dependabot --owner <owner> --state open --json repository,number,title,url`. They never appear in a person's inbox at `github.com/pulls`, because nobody is assigned; that is why a sweep exists. *You should see:* the same list as each repository's Pull requests tab.
2. **Sort by version, from the diff.** Read `package.json` in the diff (`gh pr diff <n>`), because a Dependabot group title can hide a major: the ARB repository's #6 was titled a security group and carried Hardhat 3 and toolbox 7. A patch or minor goes on. **A major stops here** and goes to the steward's list, with one sentence on what it would change. A group containing one major is treated as a major.
3. **Check the checks.** `gh pr checks <n> -R <repo>`. Red or pending means not today.
4. **Look for what is new.** In the lockfile diff, look for a package name that was not there before, and for `"hasInstallScript": true` on anything added or changed. Either one means reading that package's repository first (the external-package checklist in every `CLAUDE.md`: scripts, credential paths, provenance, typosquatting, network calls). An unexplained new package is a stop.
5. **Run it in a scratch copy.** `git worktree add <scratch> <pr-branch>`, then `npm ci --ignore-scripts`, then the repository's build and tests, or the offline tests a desk names. *You should see:* the same pass counts as `main`. If `main` itself fails, say so and stop: that failure is not the update's.
6. **Hand over the merge.** Give the steward one line per pull request, `! gh pr merge <n> -R <repo> --merge`, never squash. One at a time on a repository, waiting for its checks in between, because each merge can conflict the next. Dependabot rebases the rest; `@dependabot rebase` asks it to. *Today a session's own `gh pr merge` is refused by the permission system (seen Nov 5, 2026): report it and hand over the line; do not look for another route.*
7. **Write the line.** In the repository's `logs/` or pending tasks: the date, what is ready, what merged, what was set aside and why.
8. **Leave running desks alone.** A merge changes the lockfile, not the installed folder. Whoever next restarts that desk runs the install on purpose, during a quiet hour, and checks its heartbeat afterwards.

## <img src="../assets/icons/shield-check.svg" width="24" height="24" alt=""> When to stop and ask
- A major version, or a compiler, framework or runtime change (Hardhat, solc, Next.js, Astro majors).
- Anything that touches signing, wallets, keys or money movement, whatever its version number.
- A new package nobody asked for, a new install script, or a maintainer change in the release notes.
- Tests that pass on `main` and fail on the branch.
- A security alert marked critical with no patched version: that goes to the steward the same day.

## <img src="../assets/icons/circle-check.svg" width="24" height="24" alt=""> Verification
After the steward's merges, the repository's Pull requests tab shows only what was set aside. `main`'s checks are green after the last merge. The log line exists. The desk's own monitor is still ticking.

## <img src="../assets/icons/history.svg" width="24" height="24" alt=""> Change log
| Date | Change |
|---|---|
| 2026-11-05 | The first sweep: the permission system refused a session's `gh pr merge`, so a helper tests and prepares and hands over `! gh pr merge N --merge`; the page changes if the steward adds a rule. Read `package.json` in the diff: a group title can hide a major (#6 did). |
| 2026-11-04 | Drafted on the lab steward's word: Dependabot's pull requests are the fleet's to take, on these checks; first sweep queued in Mystarch's pending tasks. |
