<div align="center">

<img src="sop-template/repo/assets/icons/tags.svg" width="56" height="56" alt="">

# Names policy: names may be public, contents stay private

*What a visitor may see, what never leaves the house, and how the safety checks know the difference.*

![Policy](https://img.shields.io/badge/Policy-names-d9a441?style=flat-square)
![Decided](https://img.shields.io/badge/Decided-2026--11--01-334155?style=flat-square)
![Steward](https://img.shields.io/badge/Steward-the_lab_steward-8a6a2a?style=flat-square)
![For](https://img.shields.io/badge/For-Every_writer_and_helper-64748b?style=flat-square)

</div>

## <img src="sop-template/repo/assets/icons/compass.svg" width="24" height="24" alt=""> TL;DR

1. <img src="sop-template/repo/assets/icons/tags.svg" width="16" height="16" alt=""> **Every repository's name may appear publicly.** A private repository's name in a public page, a legend or a deck is fine. *"Nothing to hide"* (the lab steward, 2026-11-01).
2. <img src="sop-template/repo/assets/icons/folder-lock.svg" width="16" height="16" alt=""> **Contents stay private.** What is inside a private repository reaches the public only through an allowlist, after a tripwire (SOP-OPS-003).
3. <img src="sop-template/repo/assets/icons/shield-alert.svg" width="16" height="16" alt=""> **Some things never go public, on any list:** secrets, personal data, filings (below).
4. <img src="sop-template/repo/assets/icons/scan-search.svg" width="16" height="16" alt=""> **The security monitor checks against this page:** a private repository's *name* in public is not a finding; its *contents* are.
5. <img src="sop-template/repo/assets/icons/fingerprint.svg" width="16" height="16" alt=""> **Real hardware identifiers stay out of docs,** private docs included. Write a placeholder ([below](#-hardware-identifiers)).

## <img src="sop-template/repo/assets/icons/workflow.svg" width="24" height="24" alt=""> The line

```mermaid
flowchart LR
  subgraph PUBLIC["May be public"]
    N["Repository names<br/>(private ones too)"]
    O["Organisation names,<br/>colours, banners"]
    L["Legends: which repository<br/>has preview, Pages, a twin"]
    R["Allowlisted pages<br/>that passed the tripwire"]
  end
  subgraph PRIVATE["Stays private"]
    C["Contents of private repositories:<br/>drafts, notes, agent lanes, logs"]
    S["Secrets: keys, tokens,<br/>wallets, recovery codes"]
    P["Personal data: addresses,<br/>health, family, donors"]
    F["Filings: entity, tax,<br/>government, counsel"]
  end
  C -->|"allowlist + tripwire<br/>+ an officer's yes"| R
  S -. "never" .-x R
  P -. "never" .-x R
  F -. "never" .-x R
```

## <img src="sop-template/repo/assets/icons/globe.svg" width="24" height="24" alt=""> May be public

| What | Example | Why it is safe |
|---|---|---|
| **Any repository's name**, private ones included | `reading-room`, `proposals`, `ops-standard-operating-procedures`, a lab desk's name | a name says *that* something exists, not what it says; the door stays locked |
| **Organisation names, colours, banners, profiles** | the families in [`TONES.md`](proposals-template/TONES.md) | they are how visitors recognise a house |
| **A legend of every repository** | `scripts/legend.sh` output, private rows included | it shows how each repository is guarded, not what it holds |
| **A link to a private page** | the reading room's link in a welcome deck | a visitor without access sees a 404; a member sees the page |
| **Pages that passed the allowlist and the tripwire** | a public reading room, a public procedures twin | an officer listed them, and a machine or a person read every file |

> Before 2026-11-01 the lab kept private repository names out of public pages by habit (for example in `legend.sh --public-only`
> and in this template's examples). That habit is no longer required. `--public-only` stays available for a page that
> should list only what a visitor can open.

## <img src="sop-template/repo/assets/icons/folder-lock.svg" width="24" height="24" alt=""> Stays private

**Contents** of private repositories, unless an allowlist carries a page out:
- drafts, decisions not yet taken, meeting notes;
- agent coordination lanes (`AGENT-SYNC/`, `created-by-*`), handoffs, prompts, plans;
- `logs/` (session timelines; there is no public counterpart, ever);
- `CLAUDE.md`, `AGENTS.md`, `PENDING-TASKS.md` (the tripwire refuses them by name).

## <img src="sop-template/repo/assets/icons/shield-alert.svg" width="24" height="24" alt=""> Never public, on any list

| Kind | Examples | Enforced by |
|---|---|---|
| **Secrets** | private keys, tokens (`ghp_…`, `github_pat_…`), API keys, `.env` files, wallets, keystores, seed phrases, recovery codes, deploy keys' private halves | the commit-time secret scan, the sync tripwire's credential patterns, file-name refusals |
| **Personal data** | home addresses, phone numbers, dates of birth, health or recovery details, family and custody matters, donors' identities, account numbers longer than the last four digits | the public-lane tripwire's sensitive-shape scan stops the file. An officer may attest a **false alarm** (a public office address, a policy that names the word "donor"); attesting a person's private details is never allowed, whatever the machine would accept |
| **A person's account security** | that a named person's account has no two-factor login, uses text-message codes, or is otherwise easy to break into | **no machine catches this:** it holds no password or number, only a weakness. Write it only in that person's own note (a desk proposal addressed to them), never in a procedure, a legend or a shared page; procedures say "a member" and point to the note. *Learned 2026-11-01, from the "You should know" plugin's heads-up about PIR's board procedure.* |
| **Filings** | entity papers, EIN letters, tax returns and working papers, government filings, counsel's questions and answers | the tripwire refuses `entity/`, `tax/`, `filings/` and `counsel/` **by path**, whatever an allowlist says |

| **Hardware identifiers** | serial numbers, hardware and provisioning UUIDs | see [below](#-hardware-identifiers). **No machine catches this reliably:** a serial looks like any other short code |

If one of these is found in public: **stop**, tell the steward, rotate any secret first (a deleted commit is still in
someone's clone), then remove it. Never paste the secret into the report.

## <img src="sop-template/repo/assets/icons/fingerprint.svg" width="24" height="24" alt=""> Hardware identifiers

> **TL;DR.** A page about a machine needs its model, not its unit. Write `iMac, 2024`, or a placeholder such as `<SERIAL-NUMBER>`, and leave the real number out.

**The rule.** A real serial number, hardware UUID or provisioning UDID doesn't go in a document, a procedure, a proposal, a log or a chat that gets pasted into one. That holds for private pages too, because private pages get offered to readers later, and git history keeps what the current page no longer shows.

**Why.**

- **It points at one physical machine, for that machine's whole life.** Nobody can change it afterwards.
- **It is a lookup key.** Apple's [Check Coverage](https://checkcoverage.apple.com/) page takes a serial number and shows that device's coverage.
- **It lends a stranger credibility.** Someone who can quote your serial number sounds like support. That is our judgment, not a documented attack.
- **The page never needed it.** Nothing a reader does with a guide depends on which unit it was written on.

**What it isn't.** It isn't a password. It unlocks nothing: knowing one opens no account and no file. It also rotates nothing: there is no new number to issue. So don't treat a slip like a leaked key. There is nothing to revoke, and no alarm to raise.

**How it gets in.** Mostly by pasting a machine report. `system_profiler SPHardwareDataType` prints `Serial Number (system)`, `Hardware UUID` and `Provisioning UDID` among its lines (read on macOS 15.4, 2026-11-03). Filter before you paste, or before a script saves it:

```sh
system_profiler SPHardwareDataType | grep -viE 'serial|hardware uuid|provisioning udid'
```

*You should see:* the model, chip and memory lines, with those three gone.

**If you find one.**

1. <img src="sop-template/repo/assets/icons/file-check.svg" width="16" height="16" alt=""> Replace it with a placeholder in the current file, and in any PDF made from it.
2. <img src="sop-template/repo/assets/icons/message-circle-question.svg" width="16" height="16" alt=""> Tell the steward the file and the line, never the number.
3. <img src="sop-template/repo/assets/icons/history.svg" width="16" height="16" alt=""> Leave history alone unless the steward decides otherwise. On a public repository, treat the number as already copied. On a private one, ask whether its history could ever travel: an allowlist sync copies files, not history, while a history export or making the repository public would carry it.

**Where the real number does belong:** your own records of the machine, such as a password manager note, for warranty or a stolen-device report.

## <img src="sop-template/repo/assets/icons/scan-search.svg" width="24" height="24" alt=""> For the security monitor and for helpers

- A **private repository's name** in a public file: **not a finding.** Do not open a pull request to hide it.
- A private repository's **contents** in a public file without an allowlist line: **a finding.** Name the file and the line, not the content.
- Anything in *Never public*: **a finding, urgent,** whatever the allowlist says. A hardware identifier is a finding too, but not an emergency: nothing needs rotating.
- **Kenney's Home base deck** is the worked example of the boundary: its *name* may be mentioned anywhere; the deck itself stays members-only in the THEF reading room. Public `.github/decks/` folders carry only welcome decks.

## <img src="sop-template/repo/assets/icons/history.svg" width="24" height="24" alt=""> Change log

| Date | Change | By |
|---|---|---|
| 2026-11-01 | Written from the lab steward's decision ("every repository name may appear publicly; contents stay private") | Alfred |
| 2026-11-01 | *Never public*: a person's account security, the weakness no scan can see; it lives only in that person's own note | Alfred |
| 2026-11-03 | Hardware identifiers stay out of docs: a placeholder, the why, and the plain note that one unlocks nothing and rotates nothing | Alfred |

<sub>Related: [LUCID.md](LUCID.md), [ENTITIES.md](ENTITIES.md), SOP-OPS-003 *Private houses everything, public lanes witness* ([`sop-template/repo/OPS/`](sop-template/repo/OPS/)), [`walkthroughs/SECRET-SCAN.md`](walkthroughs/SECRET-SCAN.md). Icons: Lucide (ISC).</sub>
