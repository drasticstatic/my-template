# Access, PATs and membership across the fleet

_Reusable guide for every organisation the lab serves. Drafted by Littlebird, 2026-10-30, at Christopher's request; placed here by Alfred. Link it from an onboarding page rather than copying it._


## Four things that are not the same

| Thing | What it does | What it cannot do |
|---|---|---|
| GitHub account | Identifies a person | Automatically join an organisation |
| Organisation membership / team / repository role | Grants specific access to specific organisation resources | Authenticate every external helper automatically |
| PAT or approved app credential | Authenticates a program within its permitted resources and actions | Grant access its owner lacks; reduce the human's underlying role |
| Approval to act | Authorises a particular task under the organisation's rules | Follow automatically from merely holding a credential |

Read public material without an account or token. Read private material by signing into an invited account. A PAT is not needed for ordinary browser reading. Membership in a GitHub organisation is not membership in the nonprofit or recovery fellowship, board office, a legal authority or a treasury mandate.

## Choose the smallest credential that fits

| Use | Preferred route | Limits |
|---|---|---|
| Human browsing | GitHub sign-in plus repository access | No PAT needed |
| Helper reading selected private repos | Approved GitHub App/OAuth connector with verified selection, or a supported fine-grained PAT | Read-only contents; no extra administration or signing |
| Same-repo Actions updates | Built-in GITHUB_TOKEN with minimum job permissions | Repository scoped; do not assume cross-repo access |
| Private source publishing approved files to public twin | A dedicated destination deploy key where appropriate | One destination per key; write only if publishing requires it |
| Long-lived org integration / several repo installations | GitHub App with selected repositories and permissions | Installation approval, revocation and audit trail |

Deploy keys are SSH repository credentials, not PATs, not people's browser invitations, and not treasury keys. For private-source publishing, the job can read its own source through checkout/GITHUB_TOKEN and write only the staged public-safe output through the destination's key. Public Actions logs must not disclose private inventories or failed secret checks' content. Avoid public jobs with broad private-source read credentials.

## PAT setup when one is actually necessary

1. Confirm the exact job, person, resource owner and repository access. Token capability is bounded by account permission AND token permission.
2. Prefer fine-grained PATs where supported. Each is limited to one user/organisation resource owner; separate organisation scopes intentionally rather than assuming one fine-grained token covers the whole fleet.
3. Select only needed repositories, Contents: Read-only for reading, required metadata, and no unrelated permissions. For writing, document the separate task and approvals first.
4. Set a bounded expiration. Obtain organisation approval/SSO authorisation when applicable; pending access is not completed access.
5. Install into the approved secret store or integration UI. Never paste the value into a chat, file, Issue, commit, screenshot, shell command history or proposal.
6. Test a named read, inspect effective permissions without destructive writes, record scope and expiry without secret values, and confirm who can revoke it.
7. Rotate/revoke on role changes, lost devices, suspected leaks or completion. Revocation does not erase material already downloaded.

Fine-grained PATs have documented gaps for outside/repository collaborators. Check current GitHub support rather than falling back to a broad classic `repo` token. A personal private repo allows write collaborators, not a true read-only collaborator. A read-only token on a write account does not turn that person into a read-only reader. Use an organisation-owned reading room when true Read is required.

## Organisation onboarding sequence

1. A person supplies their GitHub handle through an agreed private channel. Do not publish a membership roster merely because GitHub exposes some handles.
2. An authorised owner verifies the role and invites the account; the member accepts. Use the smallest base organisation permission, then explicit teams/repo grants.
3. Enable required 2FA; prefer phishing-resistant passkeys/security keys and safely held recovery methods. Never hand over recovery codes.
4. Add the appropriate team at Read unless more is needed. Inspect inherited roles: another team or base permission can give more access.
5. Verify as the intended member, not through an owner's credential. A successful owner read proves nothing about another member's access.
6. Add a helper only if wanted; use the credential selection table above. Explain who reviews changes and that helpers act on behalf of the person/organisation within authorised tasks.
7. Review permissions periodically and remove them when roles end. Distinguish invited, accepted, active membership, repo grant verified and helper test passed.

## PIR insert: Board reading room

The closed `psychedelicsinrecovery/board` team was created. Christopher supplied creation output with id 20428820, members_count 1 and repos_count 0. A live member lookup returned `drasticstatic` only. This does NOT demonstrate that the three intended repo grants or other members' invitations are complete. Team creation is not onboarding completion.

Intended Read targets: `tech-committee`, `public-relations`, `literature-committee`, owned by `psychedelicsinrecovery`. The steward should verify team associations, member state and effective access before promising Board-inbox links work. Use the confirmed handles of each actual Board member; do not guess identities or invite every interested person to the Board team.

A Board reader's steps:

1. Give the steward your GitHub handle and accept the organisation invitation.
2. Complete required account security, then accept/confirm the Board team assignment.
3. Open the Board inbox and one private link from each committee. Report the URL and error, never credentials, if something does not open.
4. Read in your browser without a PAT. Ask separately if you want a helper. Do not connect recovery member stories, private minutes or financial/legal material to a broader helper scope by default.

General contributor route: the appropriate committee/team approved by its officers, not the Board team. GitHub access does not confer Board status. Public observers can use public-safe twins without joining.

Steward verification commands, read-only (Fortuna may run with appropriate existing auth):

```sh
gh api orgs/psychedelicsinrecovery/teams/board
gh api --paginate orgs/psychedelicsinrecovery/teams/board/repos
gh api --paginate orgs/psychedelicsinrecovery/teams/board/members
```

If grants are absent, propose the authorised fixes; do not repeat team creation blindly or change anyone's permissions as a side effect of documentation. Check active/pending membership and the member's real experience as well as API association.

## Rollout targets for Fortuna

- Create `my-template/org-onboarding/ACCESS-AND-PATS.md` after checking current layout and house style.
- Cross-link from `org-onboarding/README.md`, `ONBOARDING.template.md`, `proposals-template/README.md` and the actual JOIN-AN-ORGANIZATION walkthrough; inspect current text before editing.
- Adapt a concise PIR access page in the actual private onboarding home, with public-safe newcomer steps where appropriate. Ask the proper officers to approve role assignments; do not publish private rosters.
- Link the same guide from each applicable deployed ONBOARDING/AGENTS page using a verified canonical URL. Log where rollout is complete; don't claim all fleet files changed until checked.
- Register an organisation-neutral For-badge colour distinct from PIR purple. Proposed shared value: slate `64748b`; remove 'the same violet' wording and update TONES.md plus template recipes together. Check contrast and look at a render before mass rollout. This is a proposed visual choice, not a previously decided standard.

## Sources

https://docs.github.com/en/account-and-profile/setting-up-and-managing-your-personal-account-on-github/managing-user-account-settings/permission-levels-for-a-personal-account-repository
https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens
