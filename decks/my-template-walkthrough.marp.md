---
marp: true
theme: default
paginate: true
size: 16:9
title: my-template, walked through
description: The path a new repository walks, for a new person and their AI helper.
style: |
  section { background: #0f172a; color: #e2e8f0; font-family: "Helvetica Neue", Helvetica, Arial, sans-serif; font-size: 25px; padding: 52px 64px 56px; border-left: 10px solid #d9a441; }
  section::after { color: #94a3b8; font-size: 0.6em; }
  section h1 { color: #d9a441 !important; border-bottom: 2px solid #8a6a2a; padding-bottom: 8px; font-size: 1.45em; margin-bottom: 0.45em; }
  section h2 { color: #f1d28a !important; font-size: 1.1em; margin: 0.2em 0 0.4em; }
  h3 { color: #e8c879; }
  strong { color: #f1d28a; }
  em { color: #cbd5e1; }
  a { color: #f1d28a; text-decoration: underline; text-decoration-color: #8a6a2a; }
  code { background: #334155; color: #f8e3b0; padding: 1px 6px; border-radius: 4px; font-size: 0.82em; }
  pre { background: #1e293b; color: #f8e3b0; border: 1px solid #334155; border-radius: 8px; padding: 12px 16px; font-size: 0.68em; line-height: 1.35; }
  pre code { background: transparent; color: inherit; padding: 0; font-size: 1em; }
  pre .hljs-comment { color: #94a3b8; font-style: normal; }
  table { border-collapse: collapse; width: 100%; font-size: 0.72em; }
  section table th { background: #334155; color: #f1d28a; padding: 6px 10px; text-align: left; border: 1px solid #475569; }
  section table td { background: #1e293b; color: #e2e8f0; padding: 5px 10px; border: 1px solid #334155; }
  blockquote { border-left: 4px solid #d9a441; background: #1e293b; color: #e2e8f0; padding: 8px 16px; margin: 0.6em 0; font-style: normal; }
  ul, ol { margin-top: 0.2em; }
  li { margin: 0.18em 0; }
  .small { font-size: 0.66em; color: #94a3b8; }
  .stop { display: inline-block; min-width: 1.6em; height: 1.6em; line-height: 1.6em; border-radius: 50%; text-align: center; background: #d9a441; color: #0f172a; font-weight: 700; font-size: 0.8em; margin-right: 0.35em; }
  .sw { display: inline-block; width: 0.95em; height: 0.95em; border-radius: 3px; vertical-align: -0.12em; margin-right: 1px; }
  .amber1 { background: #d97706 } .amber2 { background: #6b4f1d } .amber3 { background: #b45309 } .amber4 { background: #fef3c7 }
  .purple1 { background: #5b2bb5 } .purple2 { background: #3b1f6e } .purple3 { background: #7c3aed } .purple4 { background: #ede9fe }
  .teal1 { background: #0d9488 } .teal2 { background: #134e4a } .teal3 { background: #0f766e } .teal4 { background: #ccfbf1 }
  .blue1 { background: #2563eb } .blue2 { background: #1e3a8a } .blue3 { background: #1d4ed8 } .blue4 { background: #dbeafe }
  .emerald1 { background: #059669 } .emerald2 { background: #064e3b } .emerald3 { background: #047857 } .emerald4 { background: #d1fae5 }
  .magenta1 { background: #ec4899 } .magenta2 { background: #9d174d } .magenta3 { background: #be185d } .magenta4 { background: #fce7f3 }
  .brass1 { background: #d9a441 } .brass2 { background: #334155; outline: 1px solid #64748b } .brass3 { background: #8a6a2a } .brass4 { background: #f1f5f9 }
  .slate { background: #64748b }
  .rail { display: flex; height: 14px; margin: 18px 0 0; border-radius: 3px; overflow: hidden; }
  .rail span { flex: 1; }
  section.lead { border-left: none; background: linear-gradient(135deg, #1e293b 0%, #0f172a 70%); justify-content: center; }
  section.lead h1 { border: none; font-size: 2.3em; color: #f8fafc !important; margin-bottom: 0.1em; }
  section.lead h2 { color: #f1d28a !important; font-size: 1.15em; font-weight: 400; }
  section.lead .kicker { color: #d9a441; letter-spacing: 0.25em; font-size: 0.6em; font-weight: 700; }
---

<!-- _class: lead -->
<!-- _paginate: false -->

<span class="kicker">DRASTICSTATIC LAB · TEMPLATE</span>

# my-template, walked through

## The path a new repository walks, laid out once: for a new person, and the AI helper beside them

<span class="small">Eight stops, the footer every commit carries, the coordination lanes, the private and public halves, proposals and procedures in every organisation's colour, and how a change travels. Source: [github.com/drasticstatic/my-template](https://github.com/drasticstatic/my-template).</span>

<div class="rail"><span class="amber1"></span><span class="purple1"></span><span class="teal1"></span><span class="blue1"></span><span class="emerald1"></span><span class="magenta1"></span><span class="brass1"></span></div>

---

# Who this is for, and how to read it

- **You**, if you are starting a repository in this fleet or joining an organisation it serves.
- **Your helper** (Claude, Codex, Augment, any of them), which will read the same files you do.
- Every slide points at a real page. The deck shows the **order**; the pages hold the detail.

> Read it once top to bottom. After that, jump to the stop you need. The README is the same path in text: [`README.md`](https://github.com/drasticstatic/my-template#the-path).

<span class="small">Nothing here is secret. The template is public on purpose; the private halves it describes live in each organisation's own repositories.</span>

---

# The path at a glance

| | Stop | What you leave with |
|---|---|---|
| <span class="stop">1</span> | Two commands, every clone | the commit hook switched on, the right lanes for this repo |
| <span class="stop">2</span> | Decide visibility before the first commit | private, public, or private with a public twin |
| <span class="stop">3</span> | License, security, contributors, topics | a true `LICENSE`, a README that stays true on both halves |
| <span class="stop">4</span> | Let the helpers read the map | `AGENTS.md`, a graph of the repo, the footer |
| <span class="stop">5</span> | Publish the safe half | an allowlist or exclude-list sync workflow |
| <span class="stop">6</span> | Proposals, in your colour | a `proposals` repo that renders PDFs on every push |
| <span class="stop">7</span> | People, and their helpers | the walkthroughs and the onboarding kit |
| <span class="stop">8</span> | A folder of repos | a light parent with independent children |

---

# <span class="stop">1</span> Two commands, every clone

```sh
sh scripts/install-hooks.sh        # switch on the commit-attribution hook
sh scripts/scaffold-agent-sync.sh  # make the coordination lanes this repo's visibility allows
```

And at the **start of every session**, before reading deeply or editing:

```sh
git pull --rebase --autostash
```

- Git will not carry hooks for you, on purpose: a committed hook does nothing until a person points the clone at it.
- Several people and helpers push to the same repositories, some of them unattended. A stale clone fails at push time, when the tempting fix is a force-push that throws away someone else's work. `--autostash` makes the pull safe on a dirty tree.

---

# <span class="stop">2</span> Decide visibility, <span class="stop">3</span> make it true

**Stop 2.** Choose before the first commit, because un-publishing is not something deletion can do.

| The repo is | It gets |
|---|---|
| private | `AGENT-SYNC/`, `logs/`, and optionally `AGENT-SYNC_PUBLIC/` for what may reach a twin |
| public | `AGENT-SYNC_PUBLIC/` only; never `logs/` |
| private with a public twin | the above, plus a twin named `<repo>-public-preview`, wired at Stop 5 |

**Stop 3.** A real `LICENSE` in every public repository (the shared `.github` fallback covers `SECURITY.md` and `CONTRIBUTING.md`, never the licence), a licence section that stays true on both halves of a pair, and a description and topics with `gh repo edit`. Then `CLAUDE.md` and `.github/dependabot.yml`.

---

# <span class="stop">4</span> Let the helpers read the map

- `./scripts/init-graphify.sh` builds a keyless map of the repository that a helper can query instead of reading every file.
- `AGENTS.md`, written from [`org-onboarding/AGENTS.template.md`](https://github.com/drasticstatic/my-template/blob/main/org-onboarding/AGENTS.template.md), tells every helper the house rules in one place.
- `CLAUDE.md` adds what is specific to Claude Code; the two stay in step.
- From here on, **every commit carries the footer** (next slides).

> A helper that has read `AGENTS.md` knows: sync first, commit only the files it changed, never force-push, never merge its own Promote.

---

# <span class="stop">5</span> Publish the safe half, <span class="stop">6</span> proposals

**Stop 5.** Copy one sync workflow into `.github/workflows/`:

| Model | Use when | Default |
|---|---|---|
| **allowlist** | most of the repo is private | everything private; named paths published |
| **exclude list** | most of the repo is public | everything published; named paths held back |

Any new root-level path is classified in the **same commit** that introduces it. The allowlist model fails CI until you do.

**Stop 6.** Copy `proposals-template/repo/` into a private `proposals` repository. It opens with **000 Start here**, renders a PDF on every push, keeps one child folder per site repository, and wears the organisation's colour family.

---

# <span class="stop">7</span> People and helpers, <span class="stop">8</span> a folder of repos

**Stop 7.** [`walkthroughs/`](https://github.com/drasticstatic/my-template/tree/main/walkthroughs): joining an organisation, connecting Littlebird, Firecrawl, Google Drive, Wix and WordPress, security settings, secret scans, ultra runs. [`org-onboarding/`](https://github.com/drasticstatic/my-template/tree/main/org-onboarding): the kit every organisation's `.github` carries, the hook-in note on the members' page, and the `legal` repository every organisation gets.

**Stop 8.** [`NESTED-REPOS-GUIDE.md`](https://github.com/drasticstatic/my-template/blob/main/NESTED-REPOS-GUIDE.md): a light parent folder that git tracks, with independent child repositories it ignores. No submodules.

```
my-org/                    ← the parent: README, CLAUDE.md, a map of the children
├── .gitignore             ← lists each child, so the parent never swallows it
├── site/                  ← its own repository, its own history
└── proposals/             ← its own repository, its own history
```

---

# Hooks and trailers: who wrote this, on what

Every commit ends with two trailer lines:

```
Co-Authored-By: <Agent> · <Engine> · <Provider> [<Model>]                 # direct
Co-Authored-By: <Agent> · <Engine> · <Gateway> · <Provider> [<Model>]     # proxied
Claude-Session: <the full session URL>                                    # or Cosmos-Session:, per platform
```

- **Agent** is the seat (Alfred, Kavanah, Fortuna, …), **Engine** the harness, **Provider** who ran the weights, **Model** in square brackets. A **Gateway** appears only when something routed the request.
- The separator is the middle dot ` · `. The session trailer is its **own line**; folded onto the first, git stops reading it as a trailer.
- `.githooks/commit-msg` rejects a commit without them. People committing by hand use `--no-verify`; helpers never do.

<span class="small">Why: when a commit later turns out to be subtly wrong, the first useful question is which model produced it. Single source: <a href="https://github.com/drasticstatic/my-template/blob/main/AGENT-SYNC/README.md">AGENT-SYNC/README.md</a>.</span>

---

# Gitmoji: the subject line

```
:sparkles: feat(scope): what the change does
```

| `:sparkles:` feat | `:bug:` fix | `:memo:` docs | `:white_check_mark:` test |
|---|---|---|---|
| `:lock:` security | `:recycle:` refactor | `:wrench:` config | `:rocket:` deploy |
| `:bookmark:` release | `:rewind:` revert | `:truck:` move | `:construction:` wip |

- **The alias, not the glyph.** `:sparkles:` is plain text: it reads the same in every terminal, log and email, and `git log --grep '^:bug:'` just works. GitHub draws the glyph anyway.
- **Warn-only.** A subject that does not follow it still lands, with a one-line hint from `.githooks/gitmoji-check.sh`. The footer is still enforced.

<span class="small">Single source: <a href="https://github.com/drasticstatic/my-template/blob/main/GITMOJI.md">GITMOJI.md</a>.</span>

---

# AGENT-SYNC: one lane per creator

```
AGENT-SYNC/                       private repos only; never reaches a public twin
├── created-by-alfred/            what Alfred wrote, for whoever it is addressed to
├── created-by-christopher/
├── created-by-kavanah/
├── created-by-Littlebird/        the observer's notes, marked as observer-generated
└── …                             one folder per agent that writes here
AGENT-SYNC_PUBLIC/                the only lane a public repo gets; assume every word is public
logs/                             the session timeline; private only, no public counterpart
```

- A file lives in its **creator's** folder and is **named for its recipient**: `created-by-alfred/prompts/2026/10-Oct/KAVANAH_PROMPT_20261031.md`.
- Nobody writes into another agent's file. You answer by writing your own.
- Public lanes link to private material **by pointer**, never by copying it in.

---

# Private → public: two halves of one repository

```
  private source  (the workshop: drafts, AGENT-SYNC/, logs/, everything)
        │
        │  sync workflow on every push to main
        │  allowlist: only named paths   ·   exclude list: all but named paths
        │  git filter-repo, then a tripwire that fails on anything unclassified
        ▼
  <repo>-public-preview   (the public twin: only what was meant for visitors)
```

- The twin is **generated**. Never edit it by hand: change the source or its allowlist, and the next sync carries it.
- The workflow pushes with a per-twin **deploy key**. Until that secret exists the workflow says so and stops cleanly.
- `gitexporter` is retired. Its config file stays as a readable manifest of what is meant to be public.

---

# Proposals and procedures, one colour each

| Organisation | Family | Primary · Deep · Mid · Tint |
|---|---|---|
| The Holy Earth Foundation | amber | <span class="sw amber1"></span><span class="sw amber2"></span><span class="sw amber3"></span><span class="sw amber4"></span> `d97706` |
| Psychedelics in Recovery | purple | <span class="sw purple1"></span><span class="sw purple2"></span><span class="sw purple3"></span><span class="sw purple4"></span> `5b2bb5` |
| Psanctuary · Ethereal Offering | teal | <span class="sw teal1"></span><span class="sw teal2"></span><span class="sw teal3"></span><span class="sw teal4"></span> `0d9488` |
| Psanctuary Church | blue | <span class="sw blue1"></span><span class="sw blue2"></span><span class="sw blue3"></span><span class="sw blue4"></span> `2563eb` |
| O-R-G | emerald | <span class="sw emerald1"></span><span class="sw emerald2"></span><span class="sw emerald3"></span><span class="sw emerald4"></span> `059669` |
| Taylor'd Wraps | magenta | <span class="sw magenta1"></span><span class="sw magenta2"></span><span class="sw magenta3"></span><span class="sw magenta4"></span> `ec4899` |
| the drasticstatic lab | brass on slate | <span class="sw brass1"></span><span class="sw brass2"></span><span class="sw brass3"></span><span class="sw brass4"></span> `d9a441` |
| **For** (everyone, the same) | slate | <span class="sw slate"></span> `64748b` |

<span class="small">The same shape everywhere (TL;DR first, a decisions log, a PDF beside the markdown); the colour says whose it is before a word is read. Register: <a href="https://github.com/drasticstatic/my-template/blob/main/proposals-template/TONES.md">TONES.md</a>.</span>

---

# Procedures beside proposals

- A **proposal** asks: *should we?* A **procedure** (SOP) records: *this is how we do it now.*
- [`sop-template/repo/`](https://github.com/drasticstatic/my-template/tree/main/sop-template/repo) becomes an organisation's `ops-standard-operating-procedures`: `<DEPT>/SOP-<DEPT>-<ID>-<name>.md`, a draft until the officers tag an approved version.
- Every push renders each SOP to `pdf/<DEPT>/…pdf` in the organisation's four shades. The header carries the badge row: SOP id in the primary, status in the deep, date in the mid, **For** in the shared slate.

| Shipped with the template | Says |
|---|---|
| SOP-OPS-001 | how a change travels; the two things called *preview* |
| SOP-OPS-002 | pull requests and Promotes; merge commits only |
| SOP-GOV-001 | the board's reading room and its membership |
| SOP-IT-001 · 002 · 003 | resolver stalls · reading room and helper access · observer dashboards local by default |

---

# How a change travels

```
  edit  ──→  preview  (the rehearsal: read it, comment on it)
                │
                │  "Promote: <what>"  pull request from preview into main
                │  a person with the role merges it, with a merge commit
                ▼
              main  (the live copy)
                │
                │  the sync workflow, automatic
                ▼
          the public twin  (only the pages marked public)
```

- **Merge commits only.** Squash and rebase are switched off, so every author's footer survives the merge.
- **A helper opens the Promote; a person merges it.** Helpers never merge, never force-push, never rewrite history.
- A site with **lanes** builds a rehearsal website from `preview` and the live one from `main`: the same Promote moves both. SOP-OPS-001 tells them apart.

---

# Where to start

| You are… | Open |
|---|---|
| starting a new repository | Stop 1, then the checklist in the README |
| joining an organisation, or its helper | [`walkthroughs/`](https://github.com/drasticstatic/my-template/tree/main/walkthroughs) and [`org-onboarding/`](https://github.com/drasticstatic/my-template/tree/main/org-onboarding) |
| writing a proposal | [`proposals-template/`](https://github.com/drasticstatic/my-template/tree/main/proposals-template) and [`TONES.md`](https://github.com/drasticstatic/my-template/blob/main/proposals-template/TONES.md) |
| writing a procedure | [`sop-template/`](https://github.com/drasticstatic/my-template/tree/main/sop-template) |
| welcoming someone to an organisation | [`decks-template/`](https://github.com/drasticstatic/my-template/tree/main/decks-template): this deck's sibling, in their colour |
| an AI helper | [`AGENTS.md`](https://github.com/drasticstatic/my-template/blob/main/AGENTS.md), then [`AGENT-SYNC/README.md`](https://github.com/drasticstatic/my-template/blob/main/AGENT-SYNC/README.md) |

> Questions go where the work is: an issue on the repository, or a comment on the Promote.

<div class="rail"><span class="amber1"></span><span class="purple1"></span><span class="teal1"></span><span class="blue1"></span><span class="emerald1"></span><span class="magenta1"></span><span class="brass1"></span></div>
