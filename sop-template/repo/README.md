# Standard operating procedures

A **proposal** asks for a decision; a **procedure** says how an approved thing is done, step by step, so a person or their
helper can do it without the author in the room. Files are named `SOP-[Department]-[ID]-[name].md`; approved versions are
git tags (`v1.0.0`…); until the first tag, every procedure here is a draft and says so.

| ID | Procedure | Department | Status |
|---|---|---|---|
| [SOP-OPS-001](OPS/SOP-OPS-001-how-a-change-travels.md) | How a change travels: preview, Promote, main, the public twin | OPS | draft |
| [SOP-OPS-002](OPS/SOP-OPS-002-pull-requests-and-promotes.md) | Pull requests and Promotes: who opens, who merges, merge not squash, getting the link | OPS | draft |
| [SOP-IT-001](IT/SOP-IT-001-vpn-dns-resolver-stalls.md) | VPN and DNS resolver stalls: how to tell, how to check, how to fix | IT | draft |
| [SOP-IT-002](IT/SOP-IT-002-reading-room-and-helper-access.md) | Reading room and helper access: browser first, a token only if needed | IT | draft |
| [SOP-IT-003](IT/SOP-IT-003-observer-dashboards-local-by-default.md) | Observer dashboards: local by default, remote access on purpose | IT | draft |

Departments: OPS (how work moves), IT (machines, networks, credentials, helpers), GOV (membership, roles, approvals), FIN (money), COM (communications). To add a procedure, copy `_template/SOP-DEPT-000-template.md` into the department folder with the next ID and add a row here. Related proposals are linked from each procedure's **Related** section.
