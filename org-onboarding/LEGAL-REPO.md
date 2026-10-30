# ⚖️ The `legal` repository: one private home per organisation for tax, filings and counsel's questions

**TL;DR:** every organisation the lab serves gets **one private repository named `legal`**, so that anyone who needs
the paperwork (an officer, a successor, a CPA, an attorney, a helper preparing questions) finds it in one place
instead of in a person's inbox. One repository, five folders, no nested children: the people who need it are the
least likely to enjoy a clever layout. There is no ISO or IEEE standard for this; the convention below is the lab's,
chosen on 2026-10-29, and it is the same in every organisation so a reader learns it once.

## Name and place

| | |
|---|---|
| Name | `legal`, lower-case, in the organisation's own GitHub account (`<org>/legal`) |
| Visibility | **private**, always; nothing in it is ever synced to a public twin |
| Who can read | the organisation's owners and the officers who need it (Treasurer, Secretary, President, or the foundation's founder); a helper only through a connector an owner approves |
| Why not nested children | a `tax` repo inside a `legal` parent is one more door between a Board member and the document; folders are enough until a folder outgrows the repo |
| Why not inside `proposals` or `board-of-directors` | proposals ask; `legal` keeps. Mixing them means a proposal's reader stumbles on a filing, or a filing gets a status badge |

## The five folders

```
legal/
├── README.md            what this is, who may read it, the calendar of what is due when
├── entity/              formation papers, bylaws, EIN letter, state registrations, officer roster with dates
├── tax/                 returns and the working papers behind them (990s, state filings, 1099s received/issued), one folder per year
├── filings/             everything sent to or received from a government that is not a tax return: annual reports, charity registrations, trademark filings
├── counsel/             questions prepared for a CPA or an attorney, their answers, engagement letters; the "not legal advice" line lives on every file here
└── policies/            the organisation's own written policies: conflict of interest, gift acceptance, treasury and digital-asset policy, document retention
```

`README.md` carries a **calendar table** (what is due, when, who files it, where the proof lands) and a **who-may-read**
table. Nothing else goes at the root.

## What never goes in it

- Secrets: no account numbers beyond the last four digits, no credentials, no keys, no seed phrases, no recovery files. A
  wallet's recovery file lives in the organisation's own cloud account, not in git.
- Members' personal data beyond officers' names and roles (fellowships: first names and last initials, as always).
- Anything a counsel has marked privileged, unless counsel says git is an acceptable place for it.

## How the lab's helpers use it

A helper may **prepare** (a question list, a calendar, a draft of a policy) and **file** (put a received document in
the right folder with the date). A helper never **answers** a tax or legal question; every prepared page says so.
The fleet's `tax-assistant` lane ("Beyond personal finances", 2026-10-29) is where the questions are drafted before
they land in an organisation's `counsel/`.

## Creating one (an owner's command)

```sh
gh repo create <org>/legal --private --description "⚖️ Tax, filings, counsel's questions and policies, in one private place" \
  --homepage "" && gh repo edit <org>/legal --add-topic legal --add-topic governance --add-topic nonprofit
```

Then copy this folder layout, write the calendar in `README.md`, and add `legal` to the connector the organisation's
helper uses only if an owner wants the helper reading it.

## Rolled out

| Organisation | `legal` | Notes |
|---|---|---|
| The Holy Earth Foundation | not yet | incorporation status still being confirmed with the founder; the entity folder starts with that answer |
| Psychedelics in Recovery® | not yet | a 501(c)(3); the Board's `TRADEMARKS.md` and bylaws would move or be mirrored here |
| Psanctuary / Psanctuary Church | not yet | counsel's securities questions (Ethereal Offering) belong in `counsel/` first |
| O-R-G | not yet | |
| drasticstatic (trading as a business) | not yet | trader-tax-status and entity questions from `tax-assistant` |

<sub>Convention set 2026-10-29. Related: [`README.md`](README.md) (the onboarding kit), [`../proposals-template/`](../proposals-template/) (proposals ask; `legal` keeps).</sub>
