<div align="center">

<img src="../sop-template/repo/assets/icons/cloud.svg" width="56" height="56" alt="">

# iCloud and GitHub, together

*GitHub keeps what is committed and pushed. iCloud only receives finished files holding what GitHub does not yet have. Repositories never live in iCloud.*

![Standard](https://img.shields.io/badge/Standard-Lucid-d9a441?style=flat-square)
![Status](https://img.shields.io/badge/Status-tested_not_yet_scheduled-334155?style=flat-square)
![Checked](https://img.shields.io/badge/Docs_checked-2026--11--03-64748b?style=flat-square)

</div>

## <img src="../sop-template/repo/assets/icons/compass.svg" width="24" height="24" alt=""> TL;DR

1. <img src="../sop-template/repo/assets/icons/git-branch.svg" width="16" height="16" alt=""> **Commit and push is still the backup.** Everything else on this page covers the gap before you push.
2. <img src="../sop-template/repo/assets/icons/cloud.svg" width="16" height="16" alt=""> **iCloud holds finished files, never a live repository.** One script writes a verified git bundle for each repository that has something GitHub lacks. A clean, fully pushed repository writes nothing.
3. <img src="../sop-template/repo/assets/icons/shield-check.svg" width="16" height="16" alt=""> **Your staging is not touched.** The script works in a temporary copy of the index and a temporary object folder. It captures staged, unstaged and untracked work without changing your index or your stash list.
4. <img src="../sop-template/repo/assets/icons/key-round.svg" width="16" height="16" alt=""> **Files named like secrets stay behind.** There is no tar of your folder, so a `.env` ignored by git never travels. Paths named like secrets are dropped and counted, never listed. It goes by name only, so a secret in `notes.txt` would travel: see [what this does not do](#-what-this-does-not-do).
5. <img src="../sop-template/repo/assets/icons/history.svg" width="16" height="16" alt=""> **Restoring is a fresh clone plus one bundle.** The steps below are run by the self-test every time.
6. <img src="../sop-template/repo/assets/icons/triangle-alert.svg" width="16" height="16" alt=""> **This does not replace Time Machine.** It saves repository work, not your Mac.

> **Handing this to your AI helper?** Say: *"Read ICLOUD-AND-GITHUB-TOGETHER.md. Run the self-test and a dry run, show me the
> summary, and don't schedule anything until I say so."*

**Tested, not yet scheduled.** The script, its restore steps and a real write to iCloud Drive have been run. The two-hour
schedule has never been loaded on a machine, so [step 5](#-set-it-up) is the untested part.

## <img src="../sop-template/repo/assets/icons/route.svg" width="24" height="24" alt=""> The road

```mermaid
flowchart TD
  C["Your clone<br/>stays where it is"] -->|"commit and push"| G["GitHub<br/>everything pushed"]
  C -->|"every two hours"| S{"Anything GitHub lacks,<br/>changed since last time?"}
  S -->|"no"| N["write nothing"]
  S -->|"mid-rebase, mid-merge, locked"| D["leave it alone,<br/>try next run"]
  S -->|"yes"| B["build a bundle in a temporary folder<br/>and check it with git bundle verify"]
  B --> I["iCloud Drive<br/>GitBackups/repo-path/timestamp.bundle<br/>newest seven kept"]
  G --> R["Fresh clone<br/>+ one bundle<br/>= your work back"]
  I --> R
```

## <img src="../sop-template/repo/assets/icons/layers.svg" width="24" height="24" alt=""> Who keeps what

| | Keeps | Does not keep | If you lose your Mac |
|---|---|---|---|
| **GitHub** | commits you pushed | anything not pushed | clone it again |
| **iCloud Drive, through this script** | staged, unstaged and untracked work; stashes; unpushed commits and tags; repositories with no remote | files named like secrets, ignored files, anything already on GitHub | restore on top of the clone |
| **Time Machine** | your files, apps and settings, to an external drive | anything since the last backup, or if the drive is lost with the Mac | restore the machine |
| **A password manager** | `.env` values, keys, seed phrases | code | fill your `.env` files in again |

The last row is the gap people forget. **On purpose, nothing here carries your `.env` files.** A clean-slate Mac gets its code
back from GitHub and iCloud, and its secrets back from wherever you keep secrets.

**A handy side effect:** `--dry-run` is also a list of every repository holding work GitHub lacks.

## <img src="../sop-template/repo/assets/icons/shield-check.svg" width="24" height="24" alt=""> Why not simply put the repository in iCloud, or tar it there?

Three rules follow from one fact: iCloud syncs files one at a time, and a repository only makes sense as a whole.

**Never keep a repository in iCloud Drive.** That includes `~/Desktop` and `~/Documents` if you have turned on iCloud's
"Desktop & Documents Folders": those two then count as iCloud Drive. Keep clones in a folder of their own, such as `~/code`.

The first draft of this plan came from an AI research chat and a brief from Littlebird. It had the principle right. This table
shows what changed, and why:

| The first draft said | This does | Why |
|---|---|---|
| `git add -A` in the repository, then `git stash create` or a hidden branch | A temporary `GIT_INDEX_FILE` and a temporary object folder, then `add -A`, `write-tree` and `commit-tree` there | `git add -A` changes what you had staged. It also writes an unignored `.env` into `.git/objects`. `git stash create` has no option for untracked files. A hidden branch leaves something new in your repository. |
| `tar` the working tree | No tar at all | A tar carries every `.env`, key and wallet file into iCloud, ignored by git or not. It is also much larger. |
| A full bundle of every repository, every run | A thin bundle: only what the remote branches lack. A full one only when there is no remote | iCloud storage is shared with your photos and device backups. History that is already on GitHub need not be stored twice. |
| Always write | Compare a stored hash, and write nothing if nothing changed | Seven identical copies would push out your last seven real ones. |
| Write the archive into place | Build in a temporary folder, run `git bundle verify`, then move it in whole | iCloud should never see, or sync, half a file. |
| "launchd catches up after sleep", hourly with `StartInterval` | `StartCalendarInterval`, twelve times a day | `man launchd.plist` says a `StartInterval` firing is **missed** while the Mac sleeps. Only the calendar form runs on wake. |
| iCloud "corrupts repositories" | The same rule, with softer words | Reports of damage are real, but they come from users, not from Apple. See [what was checked](#-what-was-checked-and-how-far-to-trust-it). |

## <img src="../sop-template/repo/assets/icons/wrench.svg" width="24" height="24" alt=""> Set it up

You need `git` and `python3`. On a new Mac, `xcode-select --install` provides both. Run the commands from your clone of this repository.

1. <img src="../sop-template/repo/assets/icons/flask-conical.svg" width="16" height="16" alt=""> **Prove it on this machine.** This works in a throwaway folder and never touches your clones or your iCloud Drive.
   ```sh
   sh scripts/git-safety-backup.selftest.sh
   ```
   *You should see:* `selftest: all … cases as expected.`

2. <img src="../sop-template/repo/assets/icons/folder-lock.svg" width="16" height="16" alt=""> **Decide what never leaves this machine.** The script refuses to run until the skip list exists, so a new Mac cannot send a private repository to iCloud before someone has thought about it.
   ```sh
   sh scripts/git-safety-backup.sh --init
   open -e ~/.config/git-safety-backup/skip.txt
   ```
   Add one per line: a folder name, or a `~/full/path`. A skipped repository is never opened, and neither is a worktree or a clone of it.
   *You should see:* `Wrote …/skip.txt.`

3. <img src="../sop-template/repo/assets/icons/eye.svg" width="16" height="16" alt=""> **Look before anything is written.**
   ```sh
   sh scripts/git-safety-backup.sh --dry-run
   ```
   *You should see:* a `WOULD WRITE` line per repository, then a `SUMMARY` line with the total. A `HELD` line means you need to look at that repository ([below](#-what-the-log-words-mean)).

4. <img src="../sop-template/repo/assets/icons/cloud.svg" width="16" height="16" alt=""> **Run it once for real.**
   ```sh
   sh scripts/git-safety-backup.sh
   ```
   *You should see:* `WROTE` lines, and bundles in Finder under iCloud Drive, in `GitBackups`.

5. <img src="../sop-template/repo/assets/icons/workflow.svg" width="16" height="16" alt=""> **Schedule it. Untested: nobody has loaded this yet.**
   ```sh
   sed -e "s#__HOME__#$HOME#g" -e "s#__SCRIPT__#$PWD/scripts/git-safety-backup.sh#g" \
     scripts/launchd/git-safety-backup.plist.template > ~/Library/LaunchAgents/local.git-safety-backup.plist
   plutil -lint ~/Library/LaunchAgents/local.git-safety-backup.plist
   launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/local.git-safety-backup.plist
   ```
   *You should see:* `OK` from `plutil`. Because the job runs at load, a new `SUMMARY` line should also appear in `~/Library/Logs/git-safety-backup.log`.
   **Not confirmed:** whether a background job may write into iCloud Drive without an extra macOS permission. If the log says `cannot write`, give the job Full Disk Access in System Settings, or tell your helper.
   To stop it: `launchctl bootout gui/$(id -u)/local.git-safety-backup`.

**Roots:** by default it looks in a fixed list of folders under your home, whichever exist. To use your own, write one folder per line in `~/.config/git-safety-backup/roots.txt`.

## <img src="../sop-template/repo/assets/icons/history.svg" width="24" height="24" alt=""> Get your work back

The self-test runs these same steps, so they stay true. If Finder shows a cloud icon on the bundle, download it first: with "Optimize Mac Storage" on, iCloud may keep only the online copy.

1. <img src="../sop-template/repo/assets/icons/git-branch.svg" width="16" height="16" alt=""> **Clone from GitHub, then check the bundle fits.** Copy the bundle somewhere outside iCloud first.
   ```sh
   git clone <your-repository-url> restored && cd restored
   git bundle verify /path/to/copy.bundle
   ```
   *You should see:* `… is okay`, then `The bundle requires…` with the commits it builds on, or `The bundle records a complete history.` If it says commits are missing, see [the limits](#-what-this-does-not-do).

2. <img src="../sop-template/repo/assets/icons/files.svg" width="16" height="16" alt=""> **Bring everything in, under its own name, so nothing collides.**
   ```sh
   git fetch /path/to/copy.bundle 'refs/*:refs/restored/*'
   git for-each-ref refs/restored
   ```
   *You should see:* `refs/restored/heads/…` for each unpushed branch, `refs/restored/safety/wip` for uncommitted work, and `refs/restored/safety/stash/…` for each stash.

3. <img src="../sop-template/repo/assets/icons/git-merge.svg" width="16" height="16" alt=""> **Recover an unpushed branch.**
   ```sh
   git branch my-branch refs/restored/heads/my-branch
   ```

4. <img src="../sop-template/repo/assets/icons/pencil-line.svg" width="16" height="16" alt=""> **Recover your uncommitted work, staged and unstaged as they were.**
   ```sh
   base="$(git log -1 --format='%(trailers:key=Base,valueonly)' refs/restored/safety/wip)"
   git switch --detach "$base"
   git read-tree -u --reset refs/restored/safety/wip
   git read-tree "$(git rev-parse -q --verify refs/restored/safety/wip-staged || echo "$base")"
   git switch -c recovered-work
   ```
   *You should see:* `git status` showing what you had, as you had it.
   **Only want one file?** `git show refs/restored/safety/wip:path/to/file > path/to/file`

5. <img src="../sop-template/repo/assets/icons/list-checks.svg" width="16" height="16" alt=""> **Recover a stash,** using a name from step 2. The numbers may have gaps, because a stash holding a secret-named path stays behind.
   ```sh
   git stash store -m restored "$(git rev-parse refs/restored/safety/stash/<number>)"
   ```

**A repository with no remote:** replace step 1 with `git init restored && cd restored`. Its bundle holds the whole history.

## <img src="../sop-template/repo/assets/icons/scroll-text.svg" width="24" height="24" alt=""> What the log words mean

| Word | Meaning | What you do |
|---|---|---|
| `WROTE` · `WOULD WRITE` | a bundle was written, or would be | nothing |
| `DEFER` | a lock file, or a rebase, merge, cherry-pick, revert or bisect under way. Left alone until next run | nothing, unless it repeats. It says so if a lock looks stale |
| `HELD` | commits GitHub lacks touch a path named like a secret. A commit cannot be filtered, so the whole repository waits, uncommitted work included | look at it. Fix the history, or if it is a false alarm, add the repository's path to `history-ok.txt` beside the skip list |
| `TOO BIG` | the bundle is over the cap (1 GB by default), or changed files add up to four times that, which are then not even read. Nothing is written, so **this repository has no backup** | usually unignored logs or build output: add them to `.gitignore` or `.git/info/exclude`. Or push, or raise `--max-bundle-mb` |
| `WARN` | a changed file over the cap (100 MB by default) was left out, or could not be read | commit it, ignore it, or raise `--max-file-mb` |
| `FAIL` | something went wrong; exit code 1 | read the line |

Left-out paths are counted and never named, so the log itself cannot leak a file name.

## <img src="../sop-template/repo/assets/icons/triangle-alert.svg" width="24" height="24" alt=""> What this does not do

- <img src="../sop-template/repo/assets/icons/lock.svg" width="16" height="16" alt=""> **Bundles are not encrypted by this script.** Under iCloud's standard data protection, iCloud Drive is encrypted but Apple holds the keys. Under Advanced Data Protection, only your trusted devices hold them, and Apple cannot help you recover the data. For private repositories, make that choice knowingly, and use the skip list for anything that should never leave.
- <img src="../sop-template/repo/assets/icons/key-round.svg" width="16" height="16" alt=""> **Name matching is broad, and it is only names.** `wallet*` also drops `WalletConnect.jsx`, and a secret in a file called `notes.txt` travels. The list covers forms like `client_secret_*.json`, `my-wallet.json`, `.git-credentials` and `*.gpg`, and it will still miss a name nobody thought of. Keep secrets in ignored files, and keep your [secret scan](SECRET-SCAN.md) on. To the count in the log, a real secret and a false alarm look the same.
- <img src="../sop-template/repo/assets/icons/cloud.svg" width="16" height="16" alt=""> **iCloud Drive syncs; it is not an archive.** Delete a file on one device and it goes on all of them, recoverable for 30 days. The free tier is 5 GB, shared with photos and device backups. Plan for up to seven bundles per repository, though the seven usually overlap.
- <img src="../sop-template/repo/assets/icons/git-branch.svg" width="16" height="16" alt=""> **"What GitHub lacks" is judged offline,** from your clone's last fetch. If a branch was deleted on GitHub and your clone has not noticed, a bundle may need commits a fresh clone cannot get. `git bundle verify` names them. The same goes for commits from another remote, such as `upstream` in a fork: add that remote and fetch before you restore.
- <img src="../sop-template/repo/assets/icons/files.svg" width="16" height="16" alt=""> **Not carried:** ignored files, `node_modules`, a repository's own hooks and config, and Git LFS objects for commits already made. A changed LFS-tracked file travels whole, within the size cap.
- <img src="../sop-template/repo/assets/icons/circle-dashed.svg" width="16" height="16" alt=""> **Not covered:** repositories outside the roots, or more than eight folders deep, and a Mac that never reaches iCloud.

## <img src="../sop-template/repo/assets/icons/file-check.svg" width="24" height="24" alt=""> What was checked, and how far to trust it

**Run on macOS 15.4 with git 2.39, on 2026-11-03.** The self-test, plus a separate check in a throwaway repository:
staged, unstaged, untracked and unpushed work all came back in a fresh clone from a bundle read out of real iCloud Drive; the
index, stash list, refs and object store were unchanged; a planted `.env` and `.pem` were absent from `git ls-tree` on every
ref, and from every object. That test bundle was then removed.

**A second, independent check the same day found three things the first had missed.** It hunted for planted text in every
object each bundle adds, across more repository shapes. The first two are fixed, and the third corrects the sentence above.

- **A stash could carry a secret in its history.** With `.env` committed, a stash made, and that commit then amended away, the
  stash still pointed at it, and the `.env` went into the bundle. Such a stash now stays behind and is counted.
- **Ordinary names got through.** `secret.json`, `client_secret_*.json`, `my-wallet.json`, `.git-credentials` and 12 others all
  travelled. The list is wider now, and the self-test plants these names.
- **"Object store unchanged" was slightly too strong.** No object is added or changed, and the index is the same byte for byte.
  But when captured work matches an object the repository already has, git refreshes that file's modified time, as any
  `git add` does. Time Machine may then copy that file again, packfiles included. How often that matters is **UNVERIFIED**.

**Confirmed in the source:**

| Fact | Source |
|---|---|
| A bundle made with exclusions needs those commits at the destination; `git bundle verify` checks them and names what is missing | [git-bundle](https://git-scm.com/docs/git-bundle) |
| `git stash create` makes a stash without a ref. `--include-untracked` is listed for `push`, `save` and `show`, not `create` | [git-stash](https://git-scm.com/docs/git-stash) |
| A `StartInterval` firing is missed while the Mac sleeps; a `StartCalendarInterval` one runs on wake, and missed ones fold into one | `man launchd.plist`, macOS 15.4 |
| iCloud Drive: standard protection, Apple holds the keys; Advanced Data Protection, only trusted devices do, and Apple cannot help you recover | [iCloud data security overview](https://support.apple.com/en-us/102651) |
| 5 GB free, shared; deleted files recoverable for 30 days | [Manage your iCloud storage](https://support.apple.com/en-us/108922) |
| Optimize Mac Storage moves documents to iCloud when space is needed; Desktop and Documents can join iCloud Drive | [Store files in iCloud Drive](https://support.apple.com/guide/mac-help/store-files-in-icloud-drive-mchle5a61431/mac) |
| Time Machine backs up to an external storage device, only what changed | [Back up your Mac with Time Machine](https://support.apple.com/en-us/104984) |

**Reports, not documentation:** damage to `.git` inside iCloud Drive. A [2019 Apple Developer Forums thread](https://developer.apple.com/forums/thread/123145)
reports `.git` renamed to a file called `git 2`; no Apple engineer replied there. A [developer's post](https://dev.to/architchandra/a-side-effect-of-storing-a-git-repository-in-icloud-drive-7ed)
reports duplicate refs such as `main 2`. I found nothing from Apple on it, and nothing saying newer macOS versions fixed or kept it.
The rule stands anyway, because the safe path costs nothing.

**Seen once:** after the test bundle and its folder were removed, iCloud Drive brought the folder back, empty, within seconds. Removing it
again worked. Deleting in iCloud Drive is not instant either, and an empty folder does no harm.

**UNVERIFIED:**

- Whether a background job needs Full Disk Access to write into iCloud Drive. Step 5 will show.
- How long iCloud takes to upload a bundle. A bundle written just before a disaster may not have left the Mac.
- Whether a `.nosync` name protects a folder inside iCloud Drive. The first draft said it does not help `.git`. Nothing here relies on it.
- Whether evicted iCloud files still appear as hidden `.name.icloud` placeholders on current macOS. The pruning code handles both forms.
