# `scripts/`

Setup scripts for this template. Two of them matter when bootstrapping a repo or onboarding an
agent; run both once per clone. The rest are the gitmoji tests, the banner maker and two fleet sweeps (dry run by
default), described below.

---

## `install-hooks.sh` — activate the commit-attribution hook

```sh
sh scripts/install-hooks.sh
```

Run this **once per clone**, including fresh clones of a repo that already has the hook committed.

### Why it needs running at all

Git deliberately does not version-control hooks. `.git/hooks/` is local-only, and for good reason —
a repository that could ship executable code which runs automatically on `git commit` would be an
obvious attack vector against anyone who cloned it.

So a hook committed to the repo is inert by default. The script does the one thing that cannot be
done for you:

```sh
git config core.hooksPath .githooks
```

That points this clone at the version-controlled `.githooks/` directory. It is a local config write,
which is why *you* have to run it — and why an agent working in a fresh clone should run it before
its first commit rather than discovering the convention through a rejection.

### What the hook enforces

`.githooks/commit-msg` rejects any commit whose message lacks the fleet attribution footer:

```
Co-Authored-By: <Agent> · <Engine> · <Provider> [<Model>]                  # direct
Co-Authored-By: <Agent> · <Engine> · <Gateway> · <Provider> [<Model>]      # proxied
<Platform>-Session: <full session URL>
```

**The field definitions live in exactly one place and are deliberately not repeated here:**
[`AGENT-SYNC/README.md`](../AGENT-SYNC/README.md). That file documents the *convention*; this one
documents the *scripts*.

The split is not tidiness. This file used to restate the whole field table, and when the convention
gained a Gateway field, this copy was missed — it spent a release telling readers to write
`NVIDIA NIM` in the Provider slot, which credits a router for work it did not do. A second copy of a
spec is a second thing to forget.

What the hook *does*, as distinct from what the convention *says*:

| Outcome | Trigger |
|---|---|
| **Reject** | The shape is wrong — no footer, hyphens instead of `·`, missing `[Model]`, too few fields |
| **Warn** | The shape is fine but the content looks wrong — five semantic checks |
| **Pass** | Merge, revert, fixup and squash commits are exempt |

It rejects on shape and only warns on meaning, deliberately. The footer's job is to record what
happened; a hook that blocks an honest-but-unusual record just teaches agents to write a tidy false
one.

### The ggshield interaction — why there are two hooks

`.githooks/` carries a `pre-commit` as well as a `commit-msg`, and the second one exists for a
reason worth knowing before you vendor these files piecemeal.

ggshield installs its secret scanner via a **global** `core.hooksPath`. Setting a **local**
`core.hooksPath` — which is exactly what `install-hooks.sh` does — does not merge with that, it
replaces it. Git then looks for every hook in `.githooks/` and nowhere else. With no `pre-commit`
file there, git stops looking for one at all.

The net effect, found the hard way on 2026-09-14: **activating this fleet's attribution hook
silently switched off secret scanning** in every repo it touched. No error, no warning, no output.
The only symptom was ggshield's output going quiet, which is indistinguishable from a clean scan.

`.githooks/pre-commit` re-chains to ggshield explicitly, and `install-hooks.sh` now **refuses to
run** if ggshield is on PATH while that file is missing, rather than merely documenting the hazard
in a comment. A comment protects whoever reads it; a check protects whoever doesn't.

If you are copying hooks into a repo by hand, **copy both files.** One without the other is worse
than neither.

### The image guard in `pre-commit` (2026-11-04)

Before chaining to ggshield, `pre-commit` reads the size of every **staged** image (`png jpg jpeg gif
webp svg heic`, from the staged blob, so a shrink that was not `git add`ed again is still caught).
Over **15 MB** it refuses the commit: that is the public-lane tripwire's limit
(`scan-public-lane.sh`, `MAX_BYTES`), so the file would be committed only to be stopped at the twin.
Over **2 MB** it warns and prints the exact line to fix it: for a PNG
`pngquant --quality=65-80 --speed=1 --skip-if-larger --ext .png --force <file>`, otherwise
`sh scripts/shrink-images.sh <file>`. The CI twin for organisation repositories is
`sop-template/repo/.github/workflows/image-size-check.yml` (plain bash and `git diff`; fails over
15 MB, comments the same line on a pull request over 2 MB).

### Escape hatches

```sh
git commit --no-verify     # human-only commit, bypasses the hook
```

Use it for your own commits. An agent bypassing this hook is a problem: the footer is how a change
is traced back to the run that produced it, which matters most precisely when something went wrong.

### Why attribution is enforced rather than requested

A convention documented in a README gets followed until someone is in a hurry. With several agents
and a human committing to 40 repositories, "mostly attributed" history is not much better than
unattributed — you cannot tell whether a missing footer means a human wrote it or an agent skipped
it. A hook makes the convention true by construction instead of by diligence.

---

## `scaffold-agent-sync.sh` — create the right coordination layout

```sh
sh scripts/scaffold-agent-sync.sh            # detect visibility automatically
sh scripts/scaffold-agent-sync.sh --private  # or state it explicitly
sh scripts/scaffold-agent-sync.sh --public
```

Creates the correct agent-coordination directories for the repository's visibility, because the
choice is not cosmetic:

| | Private repo | Public repo |
|---|---|---|
| `AGENT-SYNC/` | the coordination lane | **never** — internal handoffs would be world-readable |
| `AGENT-SYNC_PUBLIC/` | not used | the coordination lane |
| `logs/` | private session timeline | **never** |

Visibility is detected via `gh`, then an anonymous API call, then a naming heuristic — in that order,
so it still works without a GitHub token. Pass `--private` or `--public` to skip detection.

### The trap this script exists to prevent

Getting it wrong is silent. Committing `AGENT-SYNC/` to a public repo does not error; it publishes
internal agent coordination and nobody notices. That is not hypothetical — it happened across five
repositories in this fleet, and exports of working conversations sat publicly readable for months
before an audit caught them.

If your repo publishes through a sync workflow, note the related trap: **a new root directory must be
classified in `.github/workflows/sync-public.yml` in the same commit.** Under an allowlist model an
unclassified directory fails the next sync; under an exclude model it silently publishes. The second
is worse.

---

## The gitmoji hint: `.githooks/gitmoji-check.sh` and `test-gitmoji.sh`

```sh
sh scripts/test-gitmoji.sh                       # run the parser tests
sh .githooks/gitmoji-check.sh .git/COMMIT_EDITMSG  # check one message by hand
```

`commit-msg` calls `.githooks/gitmoji-check.sh` **only after the attribution check has passed**. It
reads the subject and, when the subject doesn't follow [`GITMOJI.md`](../GITMOJI.md), prints one
line, for example `⚠ gitmoji: :bug: goes with 'fix', not 'feat' (GITMOJI.md)`. It **always exits 0**.
Merge, `Revert "…"`, `fixup!`, `squash!` and `amend!` subjects are exempt. A glyph (`✨ feat: …`) is
accepted with a nudge towards the alias. The tests also prove that the attribution check still
rejects and passes exactly as it did before the hint was added. Vendoring the hooks? Copy
`gitmoji-check.sh` along with `commit-msg`. Without it, `commit-msg` simply skips the hint.

---

## Fleet sweeps: `lay-pending-archive.sh` and `sync-claude-section.sh`

Two batch scripts for changes that touch many repositories at once. Both run as a **dry run unless
`--apply` is given**, are **idempotent** (a second `--apply` changes nothing), and **never commit**:
you review `git diff` in each repository and commit there, on its working branch.

Neither script carries the fleet's repository list. This repository is public, and some repository
names are not for visitors. Keep the list in a private file and pass it with `--list FILE` (one path
per line, `#` comments allowed, `~` expanded), or let `--scan ROOT` find the files.

```sh
sh scripts/lay-pending-archive.sh --scan ~/code --scan ~/dappu            # dry run
sh scripts/lay-pending-archive.sh --apply --list ~/private/pending-repos.txt
```

For each repository with `pending-tasks.md` or `PENDING-TASKS.md` at its root (matched by exact case,
because macOS disks ignore case), it creates `pending-tasks_archive.md` / `PENDING-TASKS_ARCHIVE.md`
to match. That file has a header, the rule (an item moves when it has been done for 30 days or
superseded, and keeps its date and commit; Christopher decides what moves), and an empty
`## Archived` section. It also adds one pointer line under the pending file's title, unless the file
already mentions its archive. Nothing is moved.

```sh
sh scripts/sync-claude-section.sh --scan ~/code --scan ~/dappu            # dry run, with diffs
sh scripts/sync-claude-section.sh --apply --quiet --list ~/private/claude-files.txt
```

It puts the block between `<!-- fleet:pull-requests-and-promotes:start … -->` and
`<!-- fleet:pull-requests-and-promotes:end -->` in [`../CLAUDE.md`](../CLAUDE.md) (the only place to
edit it) into each target. If the target already has the markers, it replaces that block. If it has
the heading without markers, it replaces that section. Otherwise it inserts the block before
`## Commit Convention`, or appends it at the end. Headings inside code fences are ignored, and a file
with a start marker but no end marker is skipped and reported.

---

## Before you start work in an existing clone

Fetch first, and do it in a way that cannot lose uncommitted work:

```sh
git pull --rebase --autostash
```

With several agents and a human pushing to these repos, a clone goes stale quickly — and a stale
clone does not fail loudly. It fails at push time, after the work is done, as a non-fast-forward
rejection. `--autostash` stashes uncommitted changes, rebases, and reapplies them, so running it is
safe even with a dirty working tree.

See `AGENTS.md` § *Start of session* for the full rule.

### `sync-local.sh` — every clone on this machine at once

VS Code and every helper read local files, so when GitHub has moved on (another helper pushed, the PDF bot
committed, a Promote was merged) a stale clone shows the old page. This brings them all up to date:

```sh
sh scripts/sync-local.sh                 # fetch, then pull --rebase --autostash each clone that is behind
sh scripts/sync-local.sh --dry-run       # fetch and report only
sh scripts/sync-local.sh --no-fetch      # report from local knowledge, no network
sh scripts/sync-local.sh --quiet ~/code  # one root; print only what is behind, ahead, dirty or in trouble
```

It looks up to three folders deep under `~/code`, `~/drasticstaticLabs` (the labs, since Nov 6, 2026), `~/dappu` and each organisation's folder, `~/theholyearthfoundation`,
`~/psychedelicsinrecovery`, `~/Octagon-Religious-Research-Group-ORG`, `~/psanctuary`, `~/psanctuarychurch`, `~/taylordwraps`
and `~/WILSONSLAWNMAINTENANCE` (or the roots you give),
skips `node_modules`, and reports each clone's branch, ahead/behind and local changes. A clone that would conflict is
aborted at once and left exactly as it was. It **never** pushes, clones, switches branches or forces anything; it
skips detached clones, clones without an upstream, and clones already mid-rebase. Public lanes are never cloned by
it; one already cloned is pulled like any other (it only reads), or left out with `--skip-lanes`.

### `clone-map.sh` — where every clone is, and which ones are spares

```sh
sh scripts/clone-map.sh                  # one line per repository: path, origin, branch, dirty, ahead, marks
sh scripts/clone-map.sh --duplicates     # only the rows that share an origin URL with another
sh scripts/clone-map.sh --json           # the same rows as a JSON array
sh scripts/clone-map.sh ~/drasticstaticLabs  # your own roots
```

The map behind [`NESTED-REPOS-GUIDE.md`](../NESTED-REPOS-GUIDE.md) § *The organisation clone is canonical*. It walks
`~/code`, `~/dappu`, `~/code-forked`, `~/intent`, `~/littlebirds-git-home` and every `~/<org>/` folder above, up to four
folders deep (Intent keeps a repository at `workspaces/<slug>/<repository>`), and prints each repository's path, origin
URL, current branch, dirty count and commits ahead of its upstream (0 when it has none). Two rows with the same origin
(`.git`, a trailing slash, case and the ssh/https spelling ignored) are both marked `DUPLICATE`; the one outside every
`~/<org>/` folder, when a copy inside one exists, is also `SPARE`, and `NOTED` when a `WHERE-EVERYTHING-WENT.md` sits
beside it. It is read-only by construction: `GIT_OPTIONAL_LOCKS=0`, so even `git status` writes nothing, and it never
fetches, pulls, pushes, switches or removes. A spare is information for a person; no helper removes one.

---

## `shrink-images.sh` — pictures small enough to commit and publish

```sh
sh scripts/shrink-images.sh --check assets                    # list size, pixels and verdict; touch nothing; exit 1 if any is over 15 MB
sh scripts/shrink-images.sh assets/cover.png                   # resize to 2500 px on the longer side, then pngquant
sh scripts/shrink-images.sh --no-quantise photos/              # resize only: a photograph as PNG keeps its colours
sh scripts/shrink-images.sh --max 1600 --quality 70-85 FILE    # a README banner needs no more than ~1600 px
```

For given files or a folder (searched to any depth, `node_modules` and `.git` skipped). Raster images are
resized with `sips -Z` **only when the longer side is over the limit** (`sips` would otherwise upscale);
then PNG goes through `pngquant --quality=65-80 --speed=1 --skip-if-larger --ext .png --force` and JPEG is
re-saved by `sips` at quality 80. A file is replaced only when the result is smaller; otherwise it is left
exactly as it was and the line says so. GIF (an animation would be flattened) and SVG (text) are listed and
left alone. It never runs git: `git add` the shrunk files again.

`pngquant` is **lossy**: it quantises to a 256-colour palette, which a banner, diagram or screenshot survives
unchanged to the eye and a photograph does not (gradients band). The skill
[`.claude/skills/compress-images.md`](../.claude/skills/compress-images.md) says to flag a photograph and run
`--no-quantise`, never force it. On this machine `sips` (macOS) and `pngquant` (`/opt/homebrew/bin`, 3.0.3)
are installed; `oxipng`, `jpegoptim`, `cwebp` and `magick` are not, and the script says so in its header and
falls back to `sips` for everything.

---

## `make-banner.py` — a repository's front door

```sh
python3 scripts/make-banner.py --list                     # the colour families and the pictures
python3 scripts/make-banner.py --title NAME --subtitle "WHAT IT IS" --kicker "WHOSE IT IS" \
        --family amber --motif waves --out assets/banner.svg
python3 scripts/make-banner.py --check assets/banner.svg  # any banner, by hand or not
python3 scripts/make-banner.py --check-readme README.md   # the page, as far as a machine can read it
python3 scripts/make-banner.py --icons README.md --family amber   # copy the icons the page names, toned (Lucide; Phosphor for maroon)
python3 scripts/make-banner.py --title Proposals --subtitle "WHAT IT IS" --kicker "WHOSE IT IS" --family purple --motif proposal \
        --labels 000,001,002,004 --glyph heart --out assets/banner.svg    # a proposals repository: real numbers on the pages, its own seal
python3 scripts/make-banner.py ... --family brass --motif proposal --accent 5b2bb5   # a lab desk: brass, with the served organisation's hue on the seal
sh scripts/test-make-banner.sh                            # its own tests: no network, no browser
```

Python 3 standard library only. The same words draw the same picture and other words another. It never writes
outside `--out` and the page's own icon folder, and it never commits. The rules it keeps, and why, are in
[`README-STANDARD.md`](../README-STANDARD.md).

## `.gitignore`: the macOS `Icon` line, and why it changed (Nov 5, 2026)

The template used to ignore `Icon?`. On a case-insensitive disk that pattern also matches a folder named `icons`, so
`assets/icons/` quietly stayed out of git: a page looked right on the Mac and showed broken pictures on GitHub (`pir` had
one of its 51 proposal icons tracked). The file macOS actually hides is `Icon` plus one carriage return, so the line is now
`Icon` and **two** carriage returns, because git removes one before the newline; tested Nov 5, 2026 with `git check-ignore`:
one carriage return does not match the file, two do, and `assets/icons/*.svg` stays tracked.

```sh
printf 'Icon\r\r\n' >> .gitignore   # how to write it; an editor may strip the carriage returns, so check with: grep -c "$(printf 'Icon\r')" .gitignore
```

Only this template changed. Copies of the old line in other repositories stay until someone is in the room: `git add -f`
new icons there, or replace the line the same way.

---

## `to-phosphor.py` — two-tone icons for what is drasticstatic's own

```sh
python3 scripts/to-phosphor.py assets/icons                  # each mapped .svg becomes Phosphor duotone, maroon; the FILENAME stays
python3 scripts/to-phosphor.py assets/icons --primary 0f3460 # the same art in another colour
python3 scripts/to-phosphor.py --check                       # the map covers the Lucide set; every master file is sound
python3 scripts/to-phosphor.py --build                       # maintainers: fetch the art again with curl, reading each file first
```

The map is [`phosphor-map.tsv`](phosphor-map.tsv), one line per Lucide name; the art is [`assets/icons-phosphor/`](../assets/icons-phosphor/).
Anything not in the map, and every `status-*` icon, is left alone. No README link changes, because the filenames do not. The
MIT licence lands beside the art, as `LICENSE` or, where another licence already sits there, as `LICENSE-phosphor`. It never
commits. Which family goes where is in [`LUCID.md`](../LUCID.md).

---

## `render-walkthrough-pdfs.sh` — every guide as a PDF beside its markdown

```sh
sh scripts/render-walkthrough-pdfs.sh --list                 # the guides it would render; draws nothing, installs nothing
sh scripts/render-walkthrough-pdfs.sh SECURE-TWO-FACTOR      # one guide → walkthroughs/pdf/SECURE-TWO-FACTOR.pdf
sh scripts/render-walkthrough-pdfs.sh                        # every guide, then drop any PDF whose source is gone
```

Every `walkthroughs/*.md` (the index `README.md` excepted) becomes `walkthroughs/pdf/<NAME>.pdf`, Letter, maroon with navy links
(`proposals-template/TONES.md`; the `TONE_*` variables override per run). `<details>` open for print, GitHub callouts
become bold labels, and ```` ```mermaid ```` blocks are drawn as SVG first by `sop-template/repo/scripts/mermaid-prerender.sh`
(`@mermaid-js/mermaid-cli`, pinned); `md-to-pdf@5` does the rest through your installed Chrome. It runs from the
repository root, so the pages' `../assets/icons-phosphor/` links resolve as they do on GitHub.
`.github/workflows/walkthroughs-pdf.yml` runs the same script on a push to `main` that touches a walkthrough and commits
the PDFs as the Actions bot, so nobody needs to render by hand; a Mac short of memory should let it. The markdown stays
the source: edit the page, never the PDF ([why both](../walkthroughs/MARKDOWN-BESIDE-PDF.md)).

## `git-safety-backup.sh` — what GitHub lacks, as finished files in iCloud Drive

```sh
sh scripts/git-safety-backup.sh --init       # once per machine: write the skip list, then read it
sh scripts/git-safety-backup.sh --dry-run    # report what would be written, write nothing
sh scripts/git-safety-backup.sh              # write
sh scripts/git-safety-backup.selftest.sh     # prove it in a throwaway folder, restore included
```

GitHub keeps what is committed and pushed. iCloud only receives finished files holding what GitHub does not yet have.
Repositories never live in iCloud. For each repository with uncommitted work or unpushed commits, it writes one thin,
verified git bundle to `GitBackups/<repo-path-slug>/<UTC timestamp>.bundle` and keeps the newest seven. A clean, pushed
repository writes nothing. Your index and stash list are never touched, and paths named like secrets are dropped and only
counted. It refuses to run until a skip list exists, so a new Mac cannot send a private repository anywhere first.

`launchd/git-safety-backup.plist.template` runs it every two hours on `StartCalendarInterval`, because `StartInterval`
misses a sleeping Mac. Why it works this way, the restore steps and its limits:
[`walkthroughs/ICLOUD-AND-GITHUB-TOGETHER.md`](../walkthroughs/ICLOUD-AND-GITHUB-TOGETHER.md).

## `scan-public-lane.sh` — the public-lane tripwire (master copy)

```sh
sh scripts/scan-public-lane.sh [--strip N] [--media PUBLIC-LANE-MEDIA.txt] <directory-about-to-be-published> [PUBLIC-ALLOWLIST-ATTESTED.txt]
sh scripts/scan-public-lane.selftest.sh     # needs pdftotext: brew install poppler
```

**A public lane never publishes a file a machine or a person has not read.** The scanner reads every file under the
directory: text directly, PDFs through `pdftotext`, `.docx`/`.xlsx`/`.pptx` through their XML. It refuses (exit 1,
naming each file) a credential or agent-note pointer anywhere; a sensitive shape (identity-number shapes, tax and
birth-date labels, street addresses, labelled account numbers over four digits, the fleet's personal-matter words);
a PDF with no words or with wordless pages; a picture outside `assets/`, `icons/` and the folders the lane's media list
names; an SVG that can run something; base64 embedding a script, HTML, a PDF or an executable; any other binary; and, by path,
`entity/ tax/ filings/ counsel/`. A person who opened a file can clear the attestable cases with one line in
`PUBLIC-ALLOWLIST-ATTESTED.txt` (`path | officer | YYYY-MM-DD | opened and read`, optionally `| sha256:<hex>`); the
credential, legal-lane and never-travels refusals cannot be attested away. Matched text is never printed.

`PUBLIC-LANE-MEDIA.txt` lists folders whose pictures and fonts the lane publishes on purpose, each under
`approved by <name> | YYYY-MM-DD`. A person chose these folders; a machine still reads what it can: bytes must match the
name and are searched for credentials, and nothing but pictures and fonts is opened. `--media` names the file, and the
scanner never looks for one inside the folder it reads.

Three narrow exceptions (Nov 4). A link to `github.com/drasticstatic/<name>-public-preview` or
`drasticstatic.github.io/<name>-public-preview/` is not a personal-matter hit (a public preview is public by definition;
only that link token, only for those words: a street address inside it still trips). The guardianship word negated
(`no …`, `non-…`) is a compliance note, not the matter. Pagefind's search index under a `pagefind/` folder passes when
its bytes are what pagefind writes (gzip for `*.pf_fragment` `*.pf_index` `*.pf_meta`; for `wasm.*.pagefind` gzip that
inflates to WebAssembly behind pagefind's marker, or a bare module); the gzip is inflated and searched for credentials,
and anything else there is refused as before.

It keeps every pattern of the fleet's two `sync-allowlist.sh` families (THEF `stage|apply`, Psanctuary `--check`),
unioned. The self-test builds its fixtures at run time (hand-assembled PDFs, office zips, a PNG; no fixture is
committed) and checks that `sop-template/repo/scripts/` holds byte-identical copies; CI runs it in
`.github/workflows/tripwire-selftest.yml`. Callers: `sop-template/repo/scripts/sync-allowlist.sh` (when
`TRIPWIRE_PUBLIC=1`) and `workflow-templates/sync-public-allowlist.yml` (HEAD and every historical version, since
that model publishes history), `workflow-templates/sync-public-excludelist.yml` and
`workflow-templates/publish-masked-public-copy.yml`. Copy it, do not fork it. Every copy in the fleet, with the commit
that added it and what a rehearsal found: [`sop-template/TRIPWIRE-COPIES.md`](../sop-template/TRIPWIRE-COPIES.md).
