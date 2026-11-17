# PR closing keywords: how a pull request names an issue

**Proposed 2026-11-16, for Christopher's approval. Until he approves it, this page is a draft. No Linear or GitHub
setting has been changed because of it.**

A pull request into `preview` names its Linear issue with `ref`. Only the Promote, from `preview` into `main`, uses a
closing word, and it names every issue again:

```text
ref KEY-12             # a pull request into preview: links, never completes
Fixes KEY-12           # the Promote, preview into main: completes it when a person merges
```

`KEY` is the Linear team's identifier and `12` the issue's number (Linear's own example is `ENG-123`).

This page is the single source for how a pull request, a branch or a commit names an issue. It sits beside
[`GITMOJI.md`](./GITMOJI.md) (the subject line) and
[`my-template/AGENT-SYNC/README.md`](https://github.com/drasticstatic/my-template/blob/main/AGENT-SYNC/README.md) (the trailers).
A `CLAUDE.md` points here and does not copy these tables. The product facts below are Linear's and GitHub's, quoted
from their pages as read on Nov 16, 2026. The policy after them is ours.

---

## What the products do (checked 2026-11-16)

### 1. GitHub closes its own issues only on a merge into the default branch

GitHub's rule is separate from Linear's. GitHub's page says:

> "The special keywords in a pull request description are interpreted only when the pull request targets the
> repository's default branch. If the pull request targets any other branch, then these keywords are ignored, no links
> are created, and merging the PR has no effect on the issues."

- **GitHub's words:** "close closes closed fix fixes fixed resolve resolves resolved", used "in the pull request's
  description or in a commit message". They "can be followed by colons or in uppercase".
- **GitHub's syntax:** `KEYWORD #ISSUE-NUMBER`, or `KEYWORD OWNER/REPOSITORY#ISSUE-NUMBER` for another repository.
  Several issues need "full syntax for each issue".
- **Commits:** "The issue will be closed when you merge the commit into the default branch, but the pull request that
  contains the commit will not be listed as a linked pull request."
- **In this fleet** `main` is the default branch (checked on Nov 16 for this repository and for one lab procedures
  desk; [`sop-template/repo/OPS/SOP-OPS-001-how-a-change-travels.md`](./sop-template/repo/OPS/SOP-OPS-001-how-a-change-travels.md)
  treats `main` as the live copy). So `Fixes #10` in a pull request into `preview` does nothing on GitHub. On the
  Promote into `main`, it closes #10.
- A Linear ID is not a GitHub issue number. GitHub's syntax is `#10` or `owner/repo#10`, so `Fixes KEY-12` should be
  read by Linear only. That is our reading of the syntax table. It has not been tested.

### 2. Linear has three kinds of word: closing, non-closing and relation

Linear's page says:

> "When you use a closing magic word, the issue will move through your mapped automation workflow when the branch is
> pushed and to the status configured for On PR or commit merge when the PR or commit is merged. When you use a
> non-closing magic word, the linked PR or commit will still move the issue through other statuses per your workflow
> settings, but it will not apply the On PR or commit merge status when the PR or commit merges. When you use a
> relation magic word, Linear simply marks the PR as related to the issue, with no status changes."

| Kind | Linear's words | When the pull request merges |
|---|---|---|
| closing | close, closes, closed, closing, fix, fixes, fixed, fixing, resolve, resolves, resolved, resolving, complete, completes, completed, completing, implement, implements, implemented, implementing, linear issue | the issue moves to the team's "On PR or commit merge" status ("Done" by default) |
| non-closing | ref, refs, references, part of, contributes to, toward, towards | that merge status is skipped; other configured statuses (on open, on review) can still apply |
| relation | relates to, related to | linked, "with no status changes" |
| unlink | skip, ignore | "This will fully unlink the PR and prevent status automation, even if the branch name still includes the issue ID." |

- **Where the words work:** "Use a magic word + issue ID in the PR description or title". "Magic words in PR
  comments won't create links."
- **Commits:** "Use a magic word before the issue ID in commit message to link issues. We'll move the issue to In
  Progress when the commit is pushed and Done when the commit reaches the default branch." Commit linking is a toggle
  ("Link commits to issues with magic words"). Linear also says: "You will only be able to use commit linking with a
  single GitHub organization."
- **`ref` is not "nothing happens."** It skips only the merge status. For no status change at all, write `relates to`.
- An AI Mode answer Christopher saved on Nov 16 listed "related to" as non-closing. Linear's page lists it as a
  relation word, with no status changes.

### 3. An ID in a branch name or a title links by itself, and rules act on the branch merged into

- **Branch name:** "Include issue ID in the branch name." Then: "If your branch name includes a Linear issue ID,
  Linear will automatically link the pull request to that issue. Even if you manually unlink it, the connection can
  return when you push new commits or when the PR is merged."
- **Title:** "Include the Linear issue ID (e.g. ID-123) in the title when creating pull requests."
- **Defaults:** "By default, we will move linked issues to "In Progress" when PRs are open and "Done" when PRs
  merge." They are team settings: "Since this is a team setting, it must be configured for each team in your
  workspace."
- **Target branches:** "Branch rules apply only to target branches—the branch a PR is being merged into. Automations
  are not supported for source branches, the branch the PR is created from." A rule can also be "no action", "so that
  issues linked to a change in that branch will not change status."
- **Several pull requests on one issue:** "The Linear issue status will be updated when the final linked PR moves to
  the required state from your workflow."
- **Not stated:** the page does not say whether a branch-name or title link without a magic word counts as closing.
  Treat it as closing until a test shows otherwise (**unverified**).
- **Test before relying on it.** Before a team counts on a `preview` or `main` rule, run it once on a harmless issue
  (a title such as *Test: preview and main automation*). Write down what each merge did.

### 4. A Promote must name its issues again

Linear's FAQ, under *Does the GitHub integration support squash merging?*:

> "If you have already merged multiple PRs into a single branch and you want to merge that branch into a new branch,
> we will not auto-detect any Linear issues that were linked in the previous PRs. You will need to link each issue
> anew. You can do this by mentioning the Linear issue IDs in the new PR title or by mentioning them alongside magic
> words in the PR description."

So a link made on a pull request into `preview` does not carry forward to the Promote. The Promote lists every issue
again.

**Reverts:** neither page says that reverting a merged pull request reopens an issue. On Nov 16 both pages were
searched for "revert" and "reopen", with no match. The AI Mode answer of Nov 16 said a revert "Automatically reopens
the issue". No vendor page read supports that, so this fleet does not rely on it.

### 5. People merge: our rule, not a limit of the tools

Linear's integration can move statuses, and a helper's Linear connection may offer write tools. In this fleet a
person with the role merges on GitHub, with a merge commit ([`SOP-OPS-002`](./sop-template/repo/OPS/SOP-OPS-002-pull-requests-and-promotes.md)).
That is governance. It is not something Linear or a helper is unable to do. Each team's automation settings are
written down with the date someone looked (below), and no helper switches one on.

---

## The fleet's policy

1. **A pull request into `preview`** says `ref KEY-12` in its description. It never uses a closing word, Linear's or
   GitHub's. Put the ID only after `ref` (or `relates to`), not bare in the branch name or the title. A bare ID may
   count as a closing link (point 3). Relax this only after the team sets a `preview` rule and tests it.
2. **A commit** carries the ID in its body after `ref`, or not at all. A commit message never carries a closing word.
   Completing an issue happens in one place: the Promote's description.
3. **The Promote** (`preview` into `main`) names every issue again. It uses `Fixes KEY-12` for each issue it completes
   and `ref KEY-13` for each it carries but does not finish. It also uses `Fixes #10` for any GitHub issue it closes.
4. **A repository with no `preview`** (pull requests straight into `main`) puts the closing word on the pull request
   that finishes the work, and `ref` on the ones before it.
5. **People merge,** with a merge commit, never a squash. Helpers prepare everything up to the merge. They do not
   move an issue's status unless a person asks, and they never turn on an automation.
6. **No promise about reverts.** If a merge is reverted, a person reopens the issue by hand, and the revert's pull
   request says `ref KEY-12`.
7. **One GitHub organisation, one Linear workspace.** Linear says: "It is not possible to connect multiple Linear
   workspaces to a single GitHub organization." So each organisation's issues live in that organisation's workspace,
   and a pull request names only issues from the workspace its repository is connected to.
8. **`<KEY>-<n>` means a Linear issue.** Proposals are not cited in that form: a lab desk's is `THEF-D-018` (decided Nov 16 in
   [`NUMBERING.md`](./NUMBERING.md#-decided-nov-16-key-n-belongs-to-linear)).

### A Promote's description

```text
Promote: the Linear pages, refreshed

Fixes KEY-12
Fixes KEY-14
ref KEY-13

A person with the role merges with a merge commit (SOP-OPS-002).
```

### A team's settings, written down

Each team that adopts this page keeps a filled copy of this table in its organisation's own procedures repository,
never here. A helper may read the settings and fill the table in. Only a person changes a setting.

| Setting (Linear: Settings > Team > Workflows & automations, and the GitHub integration) | Value | Read on | By |
|---|---|---|---|
| On draft PR | | | |
| On PR open | | | |
| On review request | | | |
| On ready for merge | | | |
| On PR or commit merge | | | |
| Target-branch rule: `preview` | | | |
| Target-branch rule: `main` | | | |
| Link commits to issues with magic words | | | |
| Linkbacks | | | |
| Automatically link or create issues on merge | | | |

---

## Finding things later

```sh
gh pr list --state merged --search 'Fixes in:body base:preview'   # a closing word that slipped into preview
git log --oneline --grep '^Merge pull request' --grep 'Promote' --all-match   # every Promote
```

## Sources (read 2026-11-16, plain fetch, nothing signed in)

| Claim | Source |
|---|---|
| Closing, non-closing and relation words; `skip` and `ignore`; branch name and title linking; magic words in titles, not comments; commit linking and its single-organisation limit; defaults; target-branch rules and "no action"; several pull requests per issue; the FAQ on merging a branch into a new branch; one workspace per GitHub organisation; no mention of reverts | <https://linear.app/docs/github> |
| GitHub's closing words, default-branch rule, syntax, commits; no mention of reverts | <https://docs.github.com/en/issues/tracking-your-work-with-issues/linking-a-pull-request-to-an-issue> |

The quotations were taken from the pages' own text on Nov 16, 2026. Linear's documentation pages carry a note
addressed to AI agents, asking them to connect to Linear's server. It was read as page content and not acted on.

<sub>Written Nov 16, 2026 by Alfred (Claude Code CLI) from Littlebird's handoff of the same day, at Christopher's
word. Suggest a change: an [issue](https://github.com/drasticstatic/my-template/issues) or a pull request against
`main`.</sub>
