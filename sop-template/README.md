# 📋 SOP template — procedures beside proposals, the ISO/IEEE way

**TL;DR:** a ready-to-copy `ops-standard-operating-procedures` repository. A **proposal** asks for a decision; a
**standard operating procedure (SOP)** says how an approved thing is done, step by step, so a person or
their helper can do it without the author in the room. Every fleet organisation gets one SOP repository
beside its `proposals`; the lab keeps a drafting desk per organisation (`-<org>`), and a public twin
(`-<org>-public`) carries only allowlisted procedures.

| | What's in [`repo/`](repo/) | |
|---|---|---|
| 🏠 | [`README.md`](repo/README.md) | The index: the SOP table by department, how an SOP is shaped, how versions are approved |
| 🌱 | [`_template/SOP-DEPT-000-template.md`](repo/_template/SOP-DEPT-000-template.md) | The skeleton to copy for each new procedure |
| 🧭 | [`OPS/`](repo/OPS/) · [`IT/`](repo/IT/) · [`GOV/`](repo/GOV/) | Departments, one folder each; the universal procedures ship with the template |

## Naming: `SOP-[Department]-[ID]-[name].md`

`SOP-OPS-001-how-a-change-travels.md`, `SOP-IT-001-vpn-dns-resolver-stalls.md`, `SOP-GOV-001-board-reading-room-membership.md`.
Department codes: **OPS** (how work moves: branches, pull requests, publishing), **IT** (machines, networks, credentials, helpers),
**GOV** (membership, roles, approvals), **FIN** (money, treasury, reconciliation), **COM** (communications, sites). Three-digit IDs
per department, never reused. The file lives in its department's folder.

## Versioning: tags are approvals

A procedure's text changes by pull request like anything else (`preview` → Promote → `main` where the repository uses
`preview`). An **approved** version is marked with a git tag and a GitHub Release: `v1.0.0` is the first approved set,
`v1.1.0` adds or revises a procedure, `v2.0.0` changes how the repository itself works. Until a tag exists, every SOP is
a draft and says so in its header. Tagging is an officer's action; a helper prepares the release notes.

## Shape of an SOP

Purpose · Scope · Roles · Prerequisites · Steps (numbered, one action each, what you should see after each) ·
Verification · Troubleshooting (a table that grows) · Related (proposals and other SOPs) · Change log.

## Adopt it in five steps

1. **Copy** `repo/` into a folder named `ops-standard-operating-procedures`, `git init`, keep the universal SOPs.
2. **Rename** the index for your organisation; delete departments you do not need yet.
3. **Create the private repository and push** (an owner's action): `gh repo create <org>/ops-standard-operating-procedures --private --source . --push`.
4. **Write your first own procedure** by copying `_template/` into its department folder with the next ID; add it to the index.
5. **Tag `v1.0.0`** when the officers approve the set; from then on, a changed procedure is a new minor tag.

Or ask your AI helper: *"Read my-template/sop-template/README.md and set up an SOP repository for our organisation."*
