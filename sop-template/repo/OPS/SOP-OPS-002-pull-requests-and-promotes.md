# SOP-OPS-002 · Pull requests and Promotes: who opens, who merges, merge not squash, getting the link

**Department:** OPS · **ID:** 002 · **Status:** draft (approved when tagged) · **Owner:** repository steward · **Last changed:** 2026-10-30

## Purpose
A pull request is how a change asks to move. Helpers may prepare everything up to the merge; a human merges. This procedure says how to open one, how to get the link without understanding git, and why the fleet merges with a merge commit and never squashes.

## Scope
Every fleet repository. Personal private repositories cannot enforce branch protection on the free plan, so here the rule is a working agreement enforced by permissions and habit, not by GitHub; organisation repositories can add a ruleset (`my-template/branch-protection/ruleset.json`).

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
