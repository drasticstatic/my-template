# SOP-OPS-002 · Pull requests and Promotes: who opens, who merges, merge not squash, getting the link

**Department:** OPS · **ID:** 002 · **Status:** draft (approved when tagged) · **Owner:** repository steward · **Last changed:** 2026-10-31

## Purpose
A pull request is how a change asks to move. Helpers may prepare everything up to the merge; a human merges. This procedure says how to open one, how to get the link without understanding git, and why the fleet merges with a merge commit and never squashes.

## Scope
Every fleet repository. Private repositories cannot enforce branch protection on the free plan (personal or organisation; the legend below has the detail), so there the rule is a working agreement enforced by permissions and habit, not by GitHub; public repositories, and private organisation repositories once the organisation is on Team, can add a ruleset (`my-template/branch-protection/ruleset.json`).

## Roles
| Role | Does |
|---|---|
| Helper (Claude Code CLI, Littlebird, any agent) | commits on the working branch, opens the pull request, writes the description, posts the link; **does not merge** |
| Human with the merge role | reads, merges with a merge commit |
| Officer | decides repository settings (merge methods, rulesets) |

## Prerequisites
A GitHub account signed in; for a helper, an authorised connection (SOP-IT-002). The repository's working branch is known (`preview` where it exists, otherwise a short-lived branch).

## Steps: getting a pull request link
1. **Ask your helper**: "open the Promote for <repository>" or "open a pull request for this change". *You should see:* a link of the form `https://github.com/<owner>/<repo>/pull/<n>`.
2. In the terminal, the helper runs:
   ```sh
   gh pr create --base main --head preview --title "Promote: <what>" --body "<what moves and why>"
   ```
   *You should see:* the same link printed.
3. In the browser: open the repository, click **Pull requests**, then the one with your title. *You should see:* **Files changed** lists exactly the pages you expect.
4. Read the pages on `preview` (the **Files changed** tab shows the differences; the branch itself shows the whole page).
5. Merge with **Create a merge commit**. Do not choose **Squash and merge**. *You should see:* "Pull request successfully merged"; `main` now carries each commit from `preview`.

## Why merge, never squash
Every commit in this fleet carries who made it and under which session (`Co-Authored-By` and the session trailer). A squash folds many commits into one and erases that record; a merge commit keeps it. The Holy Earth Foundation's repositories are set to merge only; other organisations should match. An officer sets it with:
```sh
gh api -X PATCH repos/<owner>/<repo> -F allow_squash_merge=false -F allow_rebase_merge=false -F allow_merge_commit=true
```
(As of 2026-10-30 the API still reported squash allowed on `theholyearthfoundation/proposals` and `drasticstatic/proposals-thef`; the setting above closes it.)

**Merge commits only, set on 2026-10-31** (squash and rebase off, merge commit on; read back from the API the same day) on these twelve:

| Kind | Repositories |
|---|---|
| Proposals (7) | `theholyearthfoundation/proposals`, `drasticstatic/proposals-thef`, `drasticstatic/proposals-dappu`, `psychedelicsinrecovery/proposals`, `psanctuary/proposals`, `psanctuarychurch/proposals`, `Octagon-Religious-Research-Group-ORG/proposals` |
| Procedures (5) | the `ops-standard-operating-procedures` repositories of THEF, the lab desk (`-thef`), PIR, Psanctuary and O-R-G |

**No attribution was lost before the setting changed.** The five earlier Promotes (`proposals-thef` #1 and #2, `bushido-code` #1, `iamoneself-retreats` #15, `david-amaringo` #17) were each checked on 2026-10-31: every merge commit has two parents, so every commit from `preview` reached `main` with its own author and trailers.

## Legend: what is protected, and what runs on pull requests
GitHub's free plan decides much of this, so the rule depends on what kind of repository you are in. Find your row.

| Repository type | Branch protection or ruleset | Runs on pull requests? | Merge method | Who merges |
|---|---|---|---|---|
| **Private, personal account** (a lab desk such as `proposals-thef`, Bushido, a bot) | **none possible** on the free plan (GitHub answers "Upgrade to GitHub Pro"); the rule is kept by habit and by who holds write | where a `preview` branch exists: yes, every change reaches `main` by a Promote. Working repositories without `preview` take the owner's commits on `main` directly | merge commit | the owner |
| **Private, organisation** (`proposals`, `ops-standard-operating-procedures`, a site workshop) | **not on the free plan either**: GitHub refuses rulesets on private repositories until the organisation is on Team (GitHub for Nonprofits gives Team free once incorporation is confirmed). Until then, permissions and habit | yes: helpers open the pull request (from `preview`, or a short-lived branch where there is no `preview`); a human merges | merge commit only (the twelve above) | a human with the merge role, never a helper |
| **Public, organisation or personal** (`.github`, `my-template`, a profile or docs site) | **ruleset available**: the strict one, `my-template/branch-protection/ruleset.json` (no deletion, no force-push) | site repositories whose working branch is `main`: a short-lived branch and a pull request. Template and profile repositories: the owner's commits on `main` | merge commit | the owner or a human with the role |
| **Public twin** (names ending `-public`, `-public-preview`, `-publish-preview`) | **deletion-only ruleset**: the sync or the site build force-pushes into it, so a no-force-push rule would break publishing (`my-template/branch-protection/`) | **never.** Nobody edits a twin by hand; change the source repository's allowlist or content instead | none: it only receives | the workflow |
| **Site with lanes** (a private workshop with `preview`, feeding a rehearsal twin and a live twin; SOP-OPS-001) | as its row above (private organisation) for the workshop; deletion-only on both twins | yes: every change is a Promote from `preview`; CI flags anything else reaching `main` | merge commit | a human with the role; merging rebuilds the live site |

**The per-repository legend** is generated, not typed: `sh scripts/legend.sh <owner> [<owner>...]` prints one table per owner (visibility, default branch, whether a `preview` branch exists, rulesets, merge methods allowed, Pages, whether it is a public twin). It only reads. Use `--public-only` for anything that will be seen by visitors; private repository names stay in the organisation's private notes. `LEGEND.md` beside this repository's README says how to read and regenerate it.

## What changed for helpers in October 2026
Claude Code CLI sessions in the fleet were given permission to do everything up to the merge: edit, commit, push the working branch, render, open the pull request and post its link. The merge itself waits for a human with the role. Littlebird works the same way through her own connection. A helper that cannot push (network, permissions) says so and hands back the commands.

## Verification
The pull request page shows **Merged** with a merge commit; `git log --merges -1 origin/main` shows it; the authors of the merged commits are unchanged.

## Troubleshooting
| Symptom | Likely cause | What to do |
|---|---|---|
| "not fast-forward" when the helper pushes | someone (or a workflow, such as the PDF renderer) committed to the branch meanwhile | `git pull --rebase --autostash`, then push again; never force |
| The merge button offers only "Squash and merge" | the repository's merge methods were changed | an officer restores merge commits with the command above |
| The helper's push or `gh` hangs | the network resolver is stalling (SOP-IT-001) | wait, or switch DNS; the helper hands back the commands |
| A pull request from a helper carries no attribution | the commit hook was not installed in that clone | `sh scripts/install-hooks.sh` in the clone; amend before pushing if not yet pushed |

## Related
- SOP-OPS-001 (the road), SOP-IT-001 (resolver stalls), SOP-IT-002 (helper access)
- Proposal: THEF 013 *Procedures beside proposals*; `my-template/AGENT-SYNC/README.md` (the attribution spec)

## Change log
| Date | Change | By |
|---|---|---|
| 2026-10-30 | Drafted after the first Promotes on `proposals-thef` and `bushido-code` | Alfred (FortunaTradesARB session) |
| 2026-10-31 | Merge commits only on the twelve proposals and procedures repositories (one PATCH each, read back); the five earlier Promotes verified as two-parent merges; the legend by repository type; `scripts/legend.sh` | Alfred (FortunaTradesARB session) |
