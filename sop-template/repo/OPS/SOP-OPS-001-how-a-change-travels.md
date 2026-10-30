# SOP-OPS-001 · How a change travels: preview, Promote, main, the public twin

**Department:** OPS · **ID:** 001 · **Status:** draft (approved when tagged) · **Owner:** repository steward · **Last changed:** 2026-10-30

## Purpose
So that anyone reading a page knows which copy they are looking at, and so that nothing reaches the public unless someone put its path on a list.

## Scope
Every repository in the fleet that has a `preview` branch (sites, drafting desks, Bushido). Organisation `proposals` repositories without a `preview` branch use pull requests into `main` directly; the public-twin rule still applies.

## Roles
| Role | Does |
|---|---|
| Author (person or helper) | edits on `preview`, opens the Promote pull request |
| Reviewer | reads on `preview`, comments |
| Merger (a human with the role) | merges the Promote; never a helper |
| Steward | keeps the allowlist and the deploy key |

## The road
```
edit → preview (rehearsal) → "Promote" pull request → main (live) → allowlist sync → public twin
```

## Steps
1. Make the change on `preview`. *You should see:* the commit on the `preview` branch on GitHub; nothing on `main` yet.
2. Open a pull request from `preview` to `main` titled `Promote: <what>` (SOP-OPS-002 says how, and how a helper does it for you). *You should see:* a pull request link.
3. A reviewer reads the pages on `preview` and comments. *You should see:* comments on the pull request, or a plain yes.
4. A human with the role merges with a **merge commit**, never squash (SOP-OPS-002 explains why). *You should see:* `main` carries every commit that was on `preview`, with each author's attribution intact.
5. If the repository has a public twin, the sync copies **only the paths on the allowlist** from `main` to the twin, after a tripwire check. *You should see:* the twin updated minutes later; nothing off the list.

## Verification
`git log origin/main..origin/preview` is empty after the merge; the public twin's tree contains exactly the allowlisted paths.

## Troubleshooting
| Symptom | Likely cause | What to do |
|---|---|---|
| The GitHub `main` link shows an old file while the local copy is new | the change is on `preview`; no Promote has been merged | open or merge the Promote (SOP-OPS-002) |
| A page is on `main` but not on the public twin | its path is not on the allowlist | add the path by pull request, on an officer's yes |
| The sync fails on the twin | the strict branch ruleset was applied to a twin that the sync force-pushes to | use the deletion-only ruleset for twins (`my-template/branch-protection/`) |

## Related
- Proposal: THEF 013 *Procedures beside proposals* (why the fleet writes SOPs and how they are approved)
- Proposal: THEF 012 *Your reading room, and how your helper joins you*
- `bushido-code/DEPLOY.md` (the topology this procedure describes), `my-template/branch-protection/README.md`, `my-template/workflow-templates/sync-public-allowlist.yml`
- SOP-OPS-002, SOP-IT-002

## Change log
| Date | Change | By |
|---|---|---|
| 2026-10-30 | Drafted from the Oct 29 topology and the Oct 30 delivery pass | Alfred (FortunaTradesARB session) |
