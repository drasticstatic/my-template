# 🎨 Tones: one colour family per organisation

Every proposal in the fleet wears the same shape (TL;DR first, icons beside ideas, a decisions log, a PDF for human
eyes) so a reader learns it once. The **tone** is what tells them *whose* it is before they read a word: the badge
colours in the header and the heading colour in the PDF. One family per organisation; nothing else changes.

| Organisation | Tone | Primary | Deep | Where its proposals live |
|---|---|---|---|---|
| **The Holy Earth Foundation** (the `proposals` repo, I Am One Self, Bushido Software / Escape Trainer) | Amber | `d97706` | `6b4f1d` | `theholyearthfoundation/proposals`; drafts in `bushido-code/proposals/` |
| **Psychedelics in Recovery®** (org-wide, committees, the Board's inbox) | Purple | `5b2bb5` | `3b1f6e` | `psychedelicsinrecovery/proposals`; committee `proposals/` folders |
| **Taylor'd Wraps** (a lab gift) | Magenta | `ec4899` | `9d174d` | `taylordwraps/proposals/` (private) |
| **Ethereal Offering** (gratitude-token-project, `_astro`, `_docs`) | Teal | `0d9488` | `134e4a` | `gratitude-token-project_astro/proposals/` (private) |
| **drasticstatic lab** (trading-assistant, fortuna-vision, the DEX-arb bot, my-template) | Brass on slate | `d9a441` | `334155` | each repo's `proposals/` when one exists |
| **david-amaringo** | *not yet chosen* (Spanish first; David's word on his colours) | | | |
| **Psanctuary** (when `_astro` migrates there) | *not yet chosen* | | | |

The "For" badge is the one colour shared across every organisation: **`6d28d9`** (so "For Kenney" looks the same
whichever repo says it). Status badges use the deep colour; the proposal number uses the primary.

## Badges (the header)

```markdown
![Proposal](https://img.shields.io/badge/Proposal-001-PRIMARY?style=flat-square)
![Status](https://img.shields.io/badge/Status-draft-DEEP?style=flat-square)
![Date](https://img.shields.io/badge/Date-2026--10--29-DEEP?style=flat-square)
![For](https://img.shields.io/badge/For-Name-6d28d9?style=flat-square)
```

## The PDF (headings and rules)

The render script (`proposals/scripts/render-pdfs.sh`, or the `pdf.yml` workflow) takes the tone as two variables and
adds this CSS, so the printed page carries the family too:

```css
h1 { color: #DEEP }
h2 { color: #DEEP; border-bottom: 2px solid #PRIMARY; padding-bottom: 4px }
a  { color: #PRIMARY }
blockquote { border-left: 4px solid #PRIMARY }
```

Body text stays black on white: the tone is a frame, not a wash. Run `TONE_PRIMARY=5b2bb5 TONE_DEEP=3b1f6e sh
proposals/scripts/render-pdfs.sh` to render in another family, or set the defaults at the top of the script once per
repo.

## Adding an organisation

Pick a family no neighbour uses (the table is the register), add the row here, set the two defaults in that repo's
render script, and use the badge recipe above in its `_template/README.md`. Decks (Marp) follow the same family:
title slide and H1 in the deep colour, accents in the primary.

<sub>Register started 2026-10-29. Related: [`README.md`](README.md) (the template), [`../walkthroughs/MARKDOWN-BESIDE-PDF.md`](../walkthroughs/MARKDOWN-BESIDE-PDF.md) (why every PDF ships with its markdown).</sub>
