# SOP-GOV-001 · Board reading room membership

**Department:** GOV · **ID:** 001 · **Status:** draft (approved when tagged) · **Owner:** the organisation's officers; the steward executes · **Last changed:** 2026-10-31

> **Fill in once per organisation.** Every organisation in the fleet has a board of directors, and every board needs to read
> the work its committees keep in private repositories. Replace the placeholders below, delete this box, and keep the worked
> example at the end (or replace it with your own first run).
>
> | Placeholder | Means | Example (PIR®) |
> |---|---|---|
> | `<org>` | the organisation's GitHub login | `psychedelicsinrecovery` |
> | `<board-team>` | the closed team that holds the Board | `board` |
> | `<committee-repos>` | the private repositories the Board reads, space-separated | `tech-committee public-relations literature-committee` |
> | `<board-inbox>` | the page the Board opens first (a README that links one page per committee) | the `board` repository's README |
> | `<officers>` | who names Board members (by role) | the Board chair and secretary |

## Purpose
How a member of `<org>`'s board of directors is given **Read** on `<committee-repos>` through a closed GitHub team, how they accept, and how the steward verifies it from the member's side.

## Scope
`<org>`, for every board member and every committee repository the Board should read. **GitHub membership is not Board membership:** `<officers>` decide who sits on the Board; this procedure only opens the door for the people they name. Write access, treasury and credentials are out of scope.

## Roles
| Role | Does |
|---|---|
| `<officers>` | name the Board members, by confirmed GitHub handle |
| Steward (an organisation owner, or a helper preparing commands for one) | creates `<board-team>` once, grants Read, adds members, verifies |
| Member | accepts, reads, reports a link that does not open |

## Prerequisites
The committee repositories exist under `<org>` (not under a personal account: a personal private repository cannot give anyone read-only access, SOP-IT-002). The steward is an owner of `<org>`, or holds the commands for one.

## Steps: steward
1. Create the closed team once. *You should see:* the team page; `repos_count 0`, `members_count 1` at creation is normal (the creator).
   ```sh
   gh api -X POST orgs/<org>/teams -f name=<board-team> -f privacy=closed
   ```
2. Grant Read on each committee repository.
   ```sh
   for r in <committee-repos>; do gh api -X PUT orgs/<org>/teams/<board-team>/repos/<org>/$r -f permission=pull; done
   ```
   *You should see:* `gh api orgs/<org>/teams/<board-team>/repos --jq '.[].name'` lists each one.
3. Add each Board member by their confirmed handle, on an officer's yes.
   ```sh
   gh api -X PUT orgs/<org>/teams/<board-team>/memberships/<login>
   ```
   *You should see:* `state: pending` until they accept, then `active`.
4. Verify as a member would: ask one member to open `<board-inbox>` and one link per committee from their own account. An owner's successful read proves nothing about a member's access.

## Steps: member
1. Give the steward your GitHub handle privately.
2. Accept the organisation invitation (email, or the bell icon on GitHub); turn on two-factor authentication.
3. Accept the team assignment if GitHub asks.
4. Open `<board-inbox>` and one link from each committee; if one does not open, report the address and the error, never a credential.
5. Read in the browser. Bringing an AI helper is a separate request (SOP-IT-002).

## Verification
`gh api --paginate orgs/<org>/teams/<board-team>/members --jq '.[].login'` lists every named Board member; `gh api orgs/<org>/teams/<board-team>/invitations` is empty; each member has opened a committee link from their own account.

## Troubleshooting
| Symptom | Likely cause | What to do |
|---|---|---|
| Inbox links open for the owner but not for members | repositories not attached to the team, or members still pending | steps 2–3; wait for acceptance |
| A member sees more than Read | another team, or the organisation's base permission, grants it | inspect inherited roles under the organisation's settings; set the base permission to *No permission* |
| A committee repository is missing from the team | it was created after step 2 | run step 2 again for that repository; add it to `<committee-repos>` here |
| A member left the Board | the officers said so | `gh api -X DELETE orgs/<org>/teams/<board-team>/memberships/<login>`; their organisation membership is a separate decision |

## Worked example: Psychedelics in Recovery® (live state, read 2026-10-30)

> This is PIR's first run, kept as the example. It is **not** a template default; other organisations fill in their own.

- `<org>` = `psychedelicsinrecovery`, `<board-team>` = `board`, `<committee-repos>` = `tech-committee public-relations literature-committee`, `<board-inbox>` = the `board` repository's README.
- Read on 2026-10-30: the three committee repositories at Read on the `board` team, one active member, no pending invitations.
- The access guide's PIR insert (`my-template/org-onboarding/ACCESS-AND-PATS.md`) and the PIR desk proposal 002 *The Board reading room* are the background.

## Related
- SOP-IT-002 (reading room and helper access; the generic reading-room route)
- `my-template/org-onboarding/ACCESS-AND-PATS.md`
- Proposal: PIR desk 002 *The Board reading room* (the first organisation to run this)

## Change log
| Date | Change | By |
|---|---|---|
| 2026-10-30 | Drafted; PIR grants verified by read the same day (three repositories at Read, one member, no pending invitations) | Alfred |
| 2026-10-31 | Generalised for every organisation's board: placeholders, a fill-in box, PIR's live state moved to a marked worked example; member removal added | Alfred |
