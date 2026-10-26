# 📜 Proposals template

**TL;DR:** a ready-to-copy `proposals` repository. Each idea becomes one folder with a plain-language
README (TL;DR first, the itinerary, questions, a decisions log, technical detail folded away), and a
workflow renders every proposal to a **PDF** on each push, so it can be emailed to people who never open
GitHub. Five organizations in this fleet run it today.

| | What's in [`repo/`](repo/) | |
|---|---|---|
| 🏠 | [`README.md`](repo/README.md) | The index: the proposals table, how a proposal is shaped, how the org decides |
| 🌱 | [`_template/README.md`](repo/_template/README.md) | The skeleton to copy for each new proposal (never rendered, because it doesn't start with three digits) |
| 📄 | [`.github/workflows/pdf.yml`](repo/.github/workflows/pdf.yml) | Renders `NNN-name/README.md` → `pdf/NNN-name.pdf`, accordions opened for print |
| 🎨 | [`assets/icons/`](repo/assets/icons/) | 33 Lucide icons (ISC licence), one per idea |

## 🚀 Adopt it in five steps

1. **Copy** `repo/` into a new folder named `proposals`, then `git init` it.
2. **Rename** the index's title and the "How we decide" paragraph for your organization. Choose `Letter`
   or `A4` in `pdf.yml` (`--pdf-options`).
3. **Write proposal 001** by copying `_template/` to `001-short-name/`. Add it to the index table.
4. **Create the private repo and push** (an owner's action):
   `gh repo create <org>/proposals --private --source . --push`
5. **Turn Actions on** if the org has them off for new repos:
   `gh api -X PUT repos/<org>/proposals/actions/permissions -F enabled=true`
   About a minute after each push, the PDFs appear in `pdf/`.

Or ask your AI helper: *"Read my-template/proposals-template/README.md and set up a proposals repo for
our organization, starting with a proposal about …"*

<details>
<summary><b>🧭 Writing a proposal people actually read</b></summary>

- **The TL;DR is five numbered lines:** what, why it matters, what's already true, what's asked and of
  whom, and what keeps running until then.
- **Ask, don't announce.** A proposal never changes anything by itself. Offer choices ("yes / not yet /
  pick 1 or 2") so answering takes a minute.
- **The itinerary is the promise.** Mark each stop done as it happens, with the date, so the proposal
  doubles as the progress report. A big proposal can keep a `progress/` folder of stop pages.
- **One icon per idea**, beside its words, and screenshots where they help. Screenshots go in the
  proposal's own folder; the PDF's CSS gives any image whose path contains `screenshots` the full width.
- **Name people by first name and last initial**, and never put a key, password or private story in a
  proposal. The organization's `AGENTS.md` is where "never publish" rules live.

</details>

<details>
<summary><b>📄 How the PDF workflow works, and its small gotchas</b></summary>

- It runs on pushes to `main` that touch `NNN-*/README.md` or `assets/`, and on demand (Actions → Render
  proposals to PDF → Run workflow).
- Before printing, it opens every `<details>` and turns GitHub's `> [!TIP]`-style alerts into bold labels,
  because print engines don't understand either.
- It uses `md-to-pdf@5` (Chromium underneath) with `--basedir .`, so relative icon paths resolve.
- It commits the PDFs as `github-actions[bot]` with "📄 Render proposal PDFs". **Pull before your next
  push**, or your push is rejected for being behind.
- Private repos spend Actions minutes; each render takes about a minute.

</details>

<details>
<summary><b>📥 One inbox for a board (optional)</b></summary>

When committees each keep their own `proposals/`, a board can collect them all into its own repo every
day with a small workflow and a **read-only** fine-grained token (Contents: Read on the committee repos).
The workflow clones each repo sparsely, copies finished proposals (never `drafts/`), and commits with the
built-in `GITHUB_TOKEN`, so the token never needs write access anywhere. Nothing is deleted when a
committee removes a file; the board keeps what it was sent.

</details>

Related: [the members' edition of a profile](../walkthroughs/MEMBERS-PROFILE.md) (a members-only
"What's happening" can point to every proposal), and [version lineage](../walkthroughs/VERSION-LINEAGE.md).
