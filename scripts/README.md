# `scripts/`

Setup scripts for this template. Two of them matter when bootstrapping a repo or onboarding an
agent; run both once per clone. The rest are the gitmoji tests and two fleet sweeps (dry run by
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

It looks up to three folders deep under `~/code`, `~/dappu` and each organisation's folder, `~/theholyearthfoundation`,
`~/psychedelicsinrecovery`, `~/Octagon-Religious-Research-Group-ORG`, `~/psanctuary`, `~/psanctuarychurch` and `~/taylordwraps-org` (or the roots you give),
skips `node_modules`, and reports each clone's branch, ahead/behind and local changes. A clone that would conflict is
aborted at once and left exactly as it was. It **never** pushes, clones, switches branches or forces anything; it
skips detached clones, clones without an upstream, and clones already mid-rebase. Public lanes are never cloned by
it; one already cloned is pulled like any other (it only reads), or left out with `--skip-lanes`.

---

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

It keeps every pattern of the fleet's two `sync-allowlist.sh` families (THEF `stage|apply`, Psanctuary `--check`),
unioned. The self-test builds its fixtures at run time (hand-assembled PDFs, office zips, a PNG; no fixture is
committed) and checks that `sop-template/repo/scripts/` holds byte-identical copies; CI runs it in
`.github/workflows/tripwire-selftest.yml`. Callers: `sop-template/repo/scripts/sync-allowlist.sh` (when
`TRIPWIRE_PUBLIC=1`) and `workflow-templates/sync-public-allowlist.yml` (HEAD and every historical version, since
that model publishes history), `workflow-templates/sync-public-excludelist.yml` and
`workflow-templates/publish-masked-public-copy.yml`. Copy it, do not fork it. Every copy in the fleet, with the commit
that added it and what a rehearsal found: [`sop-template/TRIPWIRE-COPIES.md`](../sop-template/TRIPWIRE-COPIES.md).
