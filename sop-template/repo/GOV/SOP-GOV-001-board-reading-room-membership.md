# SOP-GOV-001 · Board reading room membership

**Department:** GOV · **ID:** 001 · **Status:** draft (approved when tagged) · **Owner:** the organisation's officers; the steward executes · **Last changed:** 2026-10-30

## Purpose
How a Board member is given Read on the committee repositories through a closed GitHub team, how they accept, and how the steward verifies it from the member's side.

## Scope
Organisations that keep committee work in private repositories and want Board members to read it. First used for PIR® (`psychedelicsinrecovery/board` → `tech-committee`, `public-relations`, `literature-committee`). GitHub membership is not Board membership; the officers decide who sits on the Board.

## Roles
| Role | Does |
|---|---|
| Officers | name the Board members |
| Steward | creates the team once, grants Read, adds members, verifies |
| Member | accepts, reads, reports a link that does not open |

## Steps: steward
1. Create the closed team once. *You should see:* the team page; `repos_count 0`, `members_count 1` at creation is normal.
   ```sh
   gh api -X POST orgs/<org>/teams -f name=board -f privacy=closed
   ```
2. Grant Read on each committee repository.
   ```sh
   for r in tech-committee public-relations literature-committee; do gh api -X PUT orgs/<org>/teams/board/repos/<org>/$r -f permission=pull; done
   ```
   *You should see:* `gh api orgs/<org>/teams/board/repos` lists the three.
3. Add each Board member by their confirmed handle, on an officer's yes.
   ```sh
   gh api -X PUT orgs/<org>/teams/board/memberships/<login>
   ```
   *You should see:* `state: pending` until they accept, then `active`.
4. Verify as a member would (ask one member to open the Board inbox and one link per committee). An owner's successful read proves nothing about a member's access.

## Steps: member
1. Give the steward your GitHub handle privately. 2. Accept the organisation invitation; turn on two-factor authentication. 3. Accept the team assignment. 4. Open the Board inbox and one link from each committee; report the address and the error if one does not open, never a credential. 5. Read in the browser; a helper is a separate request (SOP-IT-002).

## Verification
`gh api --paginate orgs/<org>/teams/board/members` lists every named Board member as active; each has opened a committee link from their own account.

## Troubleshooting
| Symptom | Likely cause | What to do |
|---|---|---|
| Inbox links open for the owner but not for members | repositories not attached to the team, or members still pending | steps 2–3; wait for acceptance |
| A member sees more than Read | another team or the base permission grants it | inspect inherited roles under the organisation's settings |

## Related
- Proposal: PIR desk 002 *The Board reading room*
- `my-template/org-onboarding/ACCESS-AND-PATS.md` (PIR insert), SOP-IT-002

## Change log
| Date | Change | By |
|---|---|---|
| 2026-10-30 | Drafted; PIR grants verified by read the same day (three repositories at Read, one member, no pending invitations) | Alfred (FortunaTradesARB session) |
