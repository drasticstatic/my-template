# SOP-GOV-002 · GitHub collaboration: organisations, teams, issues, discussions, pull requests, projects, Pages

![SOP](https://img.shields.io/badge/SOP-GOV--002-d9a441?style=flat-square)
![Status](https://img.shields.io/badge/Status-draft-334155?style=flat-square)
![Changed](https://img.shields.io/badge/Changed-2026--11--01-8a6a2a?style=flat-square)
![For](https://img.shields.io/badge/For-Stewards_and_members-64748b?style=flat-square)

**Department:** GOV · **ID:** 002 · **Status:** draft (approved when tagged) · **Owner:** the organisation's owners; the steward executes · **Last changed:** 2026-11-01

## <img src="../assets/icons/compass.svg" width="24" height="24" alt=""> Purpose
One page that says what each GitHub collaboration tool is for in this organisation, who may use it, and how access is decided: by **teams**, with the organisation's **base permission set to No permission**, so that a private repository is read only by the people a team names.

## <img src="../assets/icons/map.svg" width="24" height="24" alt=""> Scope
The organisation's GitHub space: owners, members, outside collaborators, teams, and the tools on each repository. Not credentials (SOP-IT-002), not the road a change travels (SOP-OPS-001/002), not board membership itself (SOP-GOV-001).

## <img src="../assets/icons/users.svg" width="24" height="24" alt=""> Roles
| Role | Does |
|---|---|
| <img src="../assets/icons/key-round.svg" width="16" height="16" alt=""> Owner | full control: settings, billing, base permission, teams, invitations. Two or more, so no single person is a point of failure |
| <img src="../assets/icons/user-round.svg" width="16" height="16" alt=""> Member | belongs to the organisation; reads and writes **only** what their teams grant (base permission none) |
| <img src="../assets/icons/users-round.svg" width="16" height="16" alt=""> Team maintainer | adds and removes people in one team, on an officer's yes |
| <img src="../assets/icons/handshake.svg" width="16" height="16" alt=""> Outside collaborator | not a member; granted one repository at a time; use sparingly |
| <img src="../assets/icons/bot.svg" width="16" height="16" alt=""> Helper | works through a person's own access or an approved connection; opens pull requests, never merges |

## <img src="../assets/icons/workflow.svg" width="24" height="24" alt=""> How access is decided

```mermaid
flowchart TB
  O["Owners<br/>(see and change everything)"]
  M["Members<br/>(base permission: none)"]
  subgraph TEAMS["Teams decide access"]
    R["readers<br/>Read"]
    B["board<br/>Read"]
    S["stewards<br/>Write"]
  end
  subgraph REPOS["Repositories"]
    RR["reading-room<br/>(private)"]
    CM["committee repositories<br/>(private)"]
    PR["proposals · procedures<br/>(private)"]
    PUB["reading-room-public · .github<br/>(public: everyone)"]
  end
  M --> R & B & S
  R --> RR
  B --> CM
  S --> PR
  O -. "all" .-> REPOS
  M -. "no team, no access<br/>(except public)" .-> PUB
```

### <img src="../assets/icons/lock.svg" width="20" height="20" alt=""> Base permission: No permission, and why
The **base permission** is what every member gets on every repository before any team is counted. GitHub's default for a new organisation is **Read**: every member can read every private repository. That quietly defeats a readers team or a board team, because a member outside the team can read the repository anyway.

The fleet sets it to **No permission**:
- <img src="../assets/icons/shield-check.svg" width="16" height="16" alt=""> **Teams become the truth.** A member reads a private repository only through a team that names it; a page that lists a team's repositories lists exactly who can read them.
- <img src="../assets/icons/users.svg" width="16" height="16" alt=""> **Owners are unaffected.** They keep full access.
- <img src="../assets/icons/globe.svg" width="16" height="16" alt=""> **Public repositories stay public** to everyone, signed in or not.
- <img src="../assets/icons/triangle-alert.svg" width="16" height="16" alt=""> **Before switching, put every member in a team** that grants what they need. A member in no team loses access to every private repository the moment it changes. Hold the switch for that organisation until they are placed.

> [!NOTE]
> **Where the heads-up came from.** The session's "You should know" reader (SOP-IT-003 describes it) pointed out on
> 2026-11-01 that the fleet's organisations still had base permission **Read**, so the readers and board teams were not
> actually gating anything for members. The lab steward switched the organisations to **No permission** the same day,
> holding one until its member was placed in a team.

**Set it** (an owner's action; settings → Member privileges → Base permissions, or):
```sh
gh api orgs/<org> --jq .default_repository_permission                       # read it first
gh api -X PATCH orgs/<org> -f default_repository_permission=none            # then set it
```
*You should see:* `none` when you read it again.

## <img src="../assets/icons/layers.svg" width="24" height="24" alt=""> The tools, one by one

| Tool | Use it for | Who | Notes |
|---|---|---|---|
| <img src="../assets/icons/building-2.svg" width="16" height="16" alt=""> **Organisation** | the house: its people, teams and repositories under one name | owners | free plan; GitHub for Nonprofits gives Team free once incorporation is confirmed |
| <img src="../assets/icons/users-round.svg" width="16" height="16" alt=""> **Teams** | who reads or writes what: `readers`, `board`, `stewards`, one per committee | owners, team maintainers | **closed** (visible to members) is the default; **secret** only when the team's existence is itself private |
| <img src="../assets/icons/message-square.svg" width="16" height="16" alt=""> **Issues** | one question, task or decision per thread; "yes / not yet" on a proposal | anyone with Read on the repository | title with the proposal or SOP number; close it when answered |
| <img src="../assets/icons/message-circle-question.svg" width="16" height="16" alt=""> **Discussions** | open conversation that is not a task: ideas, introductions, Q&A | members, when switched on | switch on per repository (Settings → Features) or for the organisation; move a discussion to an issue when it becomes a task |
| <img src="../assets/icons/git-pull-request.svg" width="16" height="16" alt=""> **Pull requests** | a change asking to move (`preview` → `main` is a **Promote**) | helpers and members open; a person with the role merges | **merge commit only**, never squash (SOP-OPS-002) |
| <img src="../assets/icons/square-kanban.svg" width="16" height="16" alt=""> **Projects** | a board of issues and pull requests across repositories: what is waiting, moving, done | members | optional; a board is a view, the issues stay the truth |
| <img src="../assets/icons/globe.svg" width="16" height="16" alt=""> **Pages** | a website from a repository: the public reading room, a site's live and rehearsal lanes | owners switch it on | on the free plan Pages publishes from **public** repositories, and a Pages site is **public**; members-only sites need Enterprise Cloud |
| <img src="../assets/icons/presentation.svg" width="16" height="16" alt=""> **The `.github` profile** | the organisation's front door: banner, welcome deck, links | owners | public; carries only welcome decks and links |

## <img src="../assets/icons/list-checks.svg" width="24" height="24" alt=""> Steps: steward, once per organisation
1. Two owners at least. *You should see:* two names under People → Role: Owner.
2. Create the teams (closed): `gh api -X POST orgs/<org>/teams -f name=readers -f privacy=closed` (and `board`, `stewards` as needed). *You should see:* each on the Teams page.
3. Grant each team its repositories (SOP-GOV-001 and SOP-IT-002 have the commands; `permission=pull` is Read, `push` is Write).
4. Place every member in at least one team. *You should see:* `gh api --paginate orgs/<org>/members --jq '.[].login'` and the union of the teams' members agree.
5. Set the base permission to none (above). *You should see:* `none`.
6. Set merge commits only on the proposals and procedures repositories (SOP-OPS-002). Switch on Discussions where people want them.
7. Ask one member (not an owner) to open one private link they should see and one they should not. *You should see:* the first opens, the second is a 404.

## <img src="../assets/icons/circle-check.svg" width="24" height="24" alt=""> Verification
`gh api orgs/<org> --jq .default_repository_permission` prints `none`; every member is in a team; a member's own test (step 7) matches the teams page.

## <img src="../assets/icons/wrench.svg" width="24" height="24" alt=""> Troubleshooting
| Symptom | Likely cause | What to do |
|---|---|---|
| A member suddenly sees 404 on a repository they used to read | base permission switched to none and they are in no team that grants it | add them to the right team; never switch the base back to Read to "fix" one person |
| A member reads a repository no team grants | base permission is still Read, or they are an outside collaborator on it | read the base permission; check the repository's Collaborators page |
| Discussions tab missing | not switched on | Settings → Features → Discussions |
| Pages on a private repository will not switch on | the free plan publishes Pages only from public repositories | publish from the public twin instead (SOP-OPS-003) |

## <img src="../assets/icons/book-marked.svg" width="24" height="24" alt=""> Related
- SOP-COM-001 *New to GitHub: your first hour* · SOP-GOV-001 *Board reading room membership* · SOP-IT-002 *Reading room and helper access*
- SOP-OPS-002 *Pull requests and Promotes* · SOP-OPS-003 *Private houses everything, public lanes witness*
- `my-template/walkthroughs/ORG-SECURITY-SETTINGS.md`, `my-template/NAMES-POLICY.md`

## <img src="../assets/icons/history.svg" width="24" height="24" alt=""> Change log
| Date | Change | By |
|---|---|---|
| 2026-11-01 | Drafted: the tools one by one, access by teams, base permission none and why (the "You should know" heads-up) | Alfred |
