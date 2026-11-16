<div align="center">

<img src="../assets/icons-phosphor/layers.svg" width="56" height="56" alt="">

# Xcode projects in git

*An Xcode or Swift package project lives in git like any other. Commit the source and the project's description; keep out what Xcode writes for one person or rebuilds by itself.*

![Kind](https://img.shields.io/badge/Kind-Walkthrough-800020?style=flat-square)
![Changed](https://img.shields.io/badge/Changed-2026--11--16-800020?style=flat-square)
![Docs checked](https://img.shields.io/badge/Docs_checked-2026--11--16-64748b?style=flat-square)

<img src="../assets/icons-phosphor/map-pin.svg" width="16" height="16" alt=""> **You are here:** drasticstatic lab › [`my-template`](../README.md) › [`walkthroughs/`](README.md) › `XCODE-PROJECTS-IN-GIT.md` · public · `main` is the working branch

</div>

## <img src="../assets/icons-phosphor/compass.svg" width="24" height="24" alt=""> TL;DR

1. <img src="../assets/icons-phosphor/circle-check.svg" width="16" height="16" alt=""> **Git-tracked Xcode projects work fine.** The template's five ignore files carry an *Apple / Xcode / Swift* block, so a
   project copied from this template starts with the right rules.
2. <img src="../assets/icons-phosphor/filter.svg" width="16" height="16" alt=""> **Never committed:** each person's workspace state (`xcuserdata/`), build products (`DerivedData/`, `build/`,
   archives, `.ipa`, debug symbols), and SwiftPM's caches (`.build/`, `.swiftpm/`).
3. <img src="../assets/icons-phosphor/file-check.svg" width="16" height="16" alt=""> **Always committed:** the source, `project.pbxproj`, shared schemes (`xcshareddata/`), `Package.swift` and
   `Package.resolved`.
4. <img src="../assets/icons-phosphor/git-merge.svg" width="16" height="16" alt=""> **Fewer merge conflicts:** use Xcode 16's buildable folders, which record a folder in the project file instead
   of every file in it.
5. <img src="../assets/icons-phosphor/cloud.svg" width="16" height="16" alt=""> **Keep the clone out of iCloud.** Not on an iCloud-synced Desktop or in Documents; `~/code/` is the usual place.

> **Handing this to your AI helper?** Say: *"Read XCODE-PROJECTS-IN-GIT.md, then run `git status --ignored` in my
> project and tell me whether anything listed under 'never committed' is tracked."* A helper can check the rules
> without running Xcode or any of its tools.

## <img src="../assets/icons-phosphor/filter.svg" width="24" height="24" alt=""> What never gets committed, and why

| Path or pattern | What Xcode keeps there | Why it stays out |
|---|---|---|
| `xcuserdata/`, `*.xcuserstate` | one person's window layout, open tabs, breakpoints, which scheme is selected | it changes every time the project is opened, differs per person, and causes conflicts that mean nothing |
| `*.xcscmblueprint`, `*.xccheckout` | older Xcode's notes on where the source control lives | written per machine; current Xcode does not need them |
| `DerivedData/`, `build/` | every compiled file, index and intermediate | rebuilt from the source on any machine; large, and it goes stale |
| `.build/` | Swift Package Manager's build cache and downloaded dependencies | rebuilt from `Package.swift` and `Package.resolved` |
| `.swiftpm/` | the Xcode workspace state SwiftPM keeps when Xcode opens a package | per person, like `xcuserdata/`. (If a package needs a shared scheme, add an exception for `.swiftpm/xcode/xcshareddata/` in that repository) |
| `*.ipa`, `*.xcarchive`, `*.dSYM`, `*.dSYM.zip`, `*.hmap` | signed app packages, archives, debug symbols, header maps | build output. A shipped build's symbols belong with the release, not in git |
| `timeline.xctimeline`, `playground.xcworkspace` | a playground's run state | per run |
| `fastlane/report.xml`, `Preview.html`, `screenshots/`, `test_output/` | fastlane's output | rebuilt each run; the `Fastfile` itself stays tracked |
| `*.mobileprovision`, `*.provisionprofile` | provisioning profiles | signing material, kept with your certificates, never in a repository |
| `Pods/` (commented out) | CocoaPods' copy of dependencies | a choice per project: some teams commit it so a build needs no network. Uncomment the line to keep it out |

**What stays tracked, on purpose.** `*.xcodeproj/project.pbxproj` is the project itself. `xcshareddata/` holds the
schemes everyone shares. `Package.resolved` pins every dependency to an exact version, so two machines build the
same thing; no rule in the block hides it, wherever Xcode puts it (beside `Package.swift`, or inside
`project.xcworkspace/xcshareddata/swiftpm/`).

**One trap this template had, now closed.** The template's `.gitignore` ignores every `*.json` to stop credentials
being committed by accident. Xcode's asset catalogues describe each image set in a `Contents.json`, so the Xcode
block adds `!**/*.xcassets/**/Contents.json`. Without it, an app's icon and images would leave git silently.

The agent-ignore files (`.claudeignore`, `.augmentignore`, `.cosmosignore`, `.graphifyignore`) carry the same list for
a different reason: build products and user state are large and say nothing an AI helper can use, so they stay out
of its reading. Source, the project file and shared schemes stay readable.

## <img src="../assets/icons-phosphor/git-merge.svg" width="24" height="24" alt=""> Fewer `project.pbxproj` conflicts: buildable folders

Before Xcode 16, the project file listed every source file by name, so two people adding files on two branches both
edited the same list, and the merge conflicted. Xcode 16 added **buildable folders**: a folder whose contents
follow what is on disk. Apple's own words, from the
[Xcode 16 release notes](https://developer.apple.com/documentation/xcode-release-notes/xcode-16-release-notes)
(Project Management, New Features):

> "Minimize project file changes, and avoid version control conflicts with buildable folder references."
>
> "Convert an existing group to a buildable folder with the "Convert to Folder" context menu item in the Project
> Navigator. Buildable folders only record the folder path into the project file without enumerating the contained
> files. This minimizes diffs to the project when files are added and removed, and avoids source control conflicts
> with your team."

So:

1. A new project made in Xcode 16 or later starts with buildable folders.
2. In an older project, right-click a group in the Project Navigator and choose **Convert to Folder**.
3. To ship a folder as one opaque resource, as Xcode did before 16, Apple's same note says to uncheck *Build Folder
   Contents* in the File Inspector.

A Swift package has no `project.pbxproj` at all: `Package.swift` and the folder layout describe it, which is the
other way to keep merges plain.

*Checked 2026-11-16 against the release notes' text. How each step looks on screen was not tried here: Xcode is not
run on this machine yet.*

## <img src="../assets/icons-phosphor/cloud.svg" width="24" height="24" alt=""> Keep active clones out of iCloud-synced folders

Apple's support page
[Add your Desktop and Documents files to iCloud Drive](https://support.apple.com/en-us/109344) says: "When you turn on
Desktop & Documents Folders, your Desktop folder and Documents folder are stored in iCloud Drive." A clone made on
the Desktop or in Documents is then a live repository inside iCloud Drive, and two programs, git and iCloud's sync,
are writing the same `.git` folder at once.

- Keep clones in a folder iCloud does not sync, such as `~/code/`.
- Let GitHub hold what is committed and pushed. For work not pushed yet, see
  [iCloud and GitHub, together](ICLOUD-AND-GITHUB-TOGETHER.md): it puts verified git bundles in iCloud, never a
  repository.
- Xcode's `DerivedData` sits in `~/Library/Developer/Xcode/DerivedData/` by default, outside the project, so it is
  outside both git and iCloud. The `DerivedData/` rule catches a project set to keep it beside the source.

## <img src="../assets/icons-phosphor/list-checks.svg" width="24" height="24" alt=""> Check a project

```sh
git status --ignored --short                 # !! lines are ignored, as they should be
git ls-files | grep -E 'xcuserdata|DerivedData|\.xcuserstate$|/\.build/|^\.build/'    # should print nothing
git check-ignore -v path/to/file             # which rule ignores a file, and from which ignore file
```

If something from *never committed* is already tracked, an ignore rule does not remove it. Stop tracking it while
keeping the file on disk with `git rm --cached <path>` (the file stays; only git forgets it), then commit. That
is a person's step: in this fleet a helper proposes the command and the owner runs it.

## <img src="../assets/icons-phosphor/git-pull-request.svg" width="24" height="24" alt=""> Suggest a change

Noticed something wrong, or know a better way? Open an [issue](https://github.com/drasticstatic/my-template/issues) or a pull request against `main`; the lab steward reads them, and a person with the role merges with a merge commit so your name stays on it. Not on GitHub? Tell any steward you know, or your helper, in your own words.

<sub>Part of [`my-template`](../README.md). Icons: Phosphor duotone (MIT). The ignore rules were tried with `git check-ignore` on a made-up project layout on 2026-11-16; no Xcode tool was run.</sub>
