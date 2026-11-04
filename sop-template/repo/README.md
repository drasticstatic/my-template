# <img src="assets/icons/scroll-text.svg" width="32" height="32" alt=""> Standard operating procedures

A **proposal** asks for a decision; a **procedure** says how an approved thing is done, step by step, so a person or their
helper can do it without the author in the room. Files are named `SOP-[Department]-[ID]-[name].md`; approved versions are
git tags (`v1.0.0`…); until the first tag, every procedure here is a draft and says so.

| ID | Procedure | Department | Status |
|---|---|---|---|
| [SOP-OPS-001](OPS/SOP-OPS-001-how-a-change-travels.md) | How a change travels: preview, Promote, main, the public twin | OPS | draft |
| [SOP-OPS-002](OPS/SOP-OPS-002-pull-requests-and-promotes.md) | Pull requests and Promotes: who opens, who merges, merge not squash, getting the link, the honest history | OPS | draft |
| [SOP-OPS-003](OPS/SOP-OPS-003-private-houses-everything-public-lanes-witness.md) | Private houses everything, public lanes witness: allowlists, the tripwires, the reading room's mechanics, icons that never go stale | OPS | draft |
| [SOP-IT-001](IT/SOP-IT-001-vpn-dns-resolver-stalls.md) | VPN and DNS resolver stalls: how to tell, how to check, how to fix | IT | draft |
| [SOP-IT-002](IT/SOP-IT-002-reading-room-and-helper-access.md) | Reading room and helper access: browser first, a token only if needed | IT | draft |
| [SOP-IT-003](IT/SOP-IT-003-observer-dashboards-local-by-default.md) | Observer dashboards: local by default, remote access on purpose | IT | draft |
| [SOP-GOV-001](GOV/SOP-GOV-001-board-reading-room-membership.md) | Board reading room membership: a closed team with Read on the committee repositories | GOV | draft |
| [SOP-GOV-002](GOV/SOP-GOV-002-github-collaboration.md) | GitHub collaboration: organisations, owners and members, base permission none, teams, issues, discussions, pull requests, projects, Pages | GOV | draft |
| [SOP-COM-001](COM/SOP-COM-001-new-to-github-your-first-hour.md) | New to GitHub: your first hour (your own account and password, the invitation, five words, the reading room, a helper, the welcome deck) | COM | draft |

**New here?** Start with **SOP-COM-001**, then SOP-OPS-001.

Departments: OPS (how work moves), IT (machines, networks, credentials, helpers), GOV (membership, roles, approvals), FIN (money), COM (communications). To add a procedure, copy `_template/SOP-DEPT-000-template.md` into the department folder with the next ID and add a row here. Related proposals are linked from each procedure's **Related** section.

**PDFs.** Every `<DEPT>/SOP-*.md` is rendered to `pdf/<DEPT>/SOP-*.pdf` (Letter, in this organisation's tone) by
[`.github/workflows/pdf.yml`](.github/workflows/pdf.yml) on each push to `main`, committed back by the Actions bot; run
`sh scripts/render-pdfs.sh` for the same result locally. Set the four tone shades at the top of both files once.

**Lucid.** Every procedure carries a Lucide icon beside each idea (from [`assets/icons/`](assets/icons/), ISC) and a
Mermaid diagram where a picture explains the mechanism; the PDF pipeline draws the diagrams as SVG before printing
([`scripts/mermaid-prerender.sh`](scripts/mermaid-prerender.sh)). The standard is `my-template/LUCID.md`.

**Legend.** [`LEGEND.md`](LEGEND.md) says how each of the organisation's repositories is guarded (protection, `preview`,
merge methods, Pages, public twins); regenerate it with `sh scripts/legend.sh <owner>`.

**Images.** A picture goes in at the size it is seen. Nothing over 15 MB is committed or uploaded (the public-lane
scanner refuses it, so the `pre-commit` hook refuses it first and
[`.github/workflows/image-size-check.yml`](.github/workflows/image-size-check.yml) fails the pull request); over 2 MB
both print the `pngquant` line to shrink it. Before adding a picture, a helper follows the skill
`my-template/.claude/skills/compress-images.md`: `sh scripts/shrink-images.sh --check <files>`, then
`shrink-images.sh` on anything over 2 MB (`--no-quantise` for a photograph that must keep its colours).
