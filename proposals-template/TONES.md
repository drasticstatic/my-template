# 🎨 Tones: one colour family per organisation, four shades each

Every proposal in the fleet wears the same shape (TL;DR first, icons beside ideas, a decisions log, a PDF for human
eyes) so a reader learns it once. The **tone** is what tells them *whose* it is before they read a word: the badge
colours in the header, the icon strokes, and the heading colours in the PDF. One family per organisation; nothing
else changes. Each family is **four shades**, so a page carries a gradient of one hue rather than a wash of it.

| Organisation | Tone | Primary | Deep | Mid | Tint | Where its proposals live |
|---|---|---|---|---|---|---|
| **The Holy Earth Foundation** (the `proposals` repo, I Am One Self, Bushido Software / Escape Trainer) | Amber | `d97706` | `6b4f1d` | `b45309` | `fef3c7` | `theholyearthfoundation/proposals`; drafts in `drasticstatic/proposals-thef` |
| **Psychedelics in Recovery®** (org-wide, committees, the Board's inbox) | Purple | `5b2bb5` | `3b1f6e` | `7c3aed` | `ede9fe` | `psychedelicsinrecovery/proposals`; committee `proposals/` folders |
| **Psanctuary** and **Ethereal Offering** (gratitude-token-project, `_astro`, `_docs`) | Teal | `0d9488` | `134e4a` | `0f766e` | `ccfbf1` | `gratitude-token-project_astro/proposals/` now; the Psanctuary org when it migrates |
| **Psanctuary Church** | Emerald (teal's greener sibling, so the church and the sanctuary read as kin) | `059669` | `064e3b` | `047857` | `d1fae5` | when its proposals repo exists |
| **Taylor'd Wraps** (a lab gift) | Magenta | `ec4899` | `9d174d` | `be185d` | `fce7f3` | `taylordwraps/proposals/` (private) |
| **david-amaringo** | Rainbow (David's art theme; the six hues cycle through the headings, see below) | `dc2626 ea580c ca8a04 16a34a 2563eb 7c3aed` | | | | when his proposals folder exists; THEF's 006 is his today, in amber |
| **drasticstatic lab** (trading-assistant, fortuna-vision, the DEX-arb bot, my-template, `pir-devine-news`, the `pir`/`psanctuary`/`O-R-G` parents) | Brass on slate, **plus the accent of the organisation a proposal serves** | `d9a441` | `334155` | `8a6a2a` | `f1f5f9` | each repo's `proposals/` when one exists |
| **O-R-G** | *not yet chosen* | | | | | |

The "For" badge is the one colour shared across every organisation: **`6d28d9`** (so "For Kenney" looks the same
whichever repo says it). Semantic icon colours are shared too and never retoned: green `15803d` ready, red `b91c1c`
blocked, purple `6d28d9` from-you, grey `4b5563` idle.

## Where each shade goes

| Shade | Badges | Icons | PDF |
|---|---|---|---|
| **Primary** | the proposal number | every stroke (`retone-icons.sh`) | the rule under each H2, horizontal rules, links (unless an accent is set) |
| **Deep** | status | | H1 and H2 text, table-head text |
| **Mid** | date | the darker fill on the status icons | H3 and H4, `<details>` summaries, footnotes |
| **Tint** | | | the wash behind block quotes and table heads |
| **Accent** (lab repos only) | | | links and the quote bar take the *served* organisation's primary: `TONE_ACCENT=5b2bb5` for a `pir-devine-news` proposal, `d97706` for one that serves THEF. Headings stay brass on slate, so the lab is still the author and the hue says who it is for |

Body text stays black on white: the tone is a frame, not a wash.

## Badges (the header)

```markdown
![Proposal](https://img.shields.io/badge/Proposal-001-PRIMARY?style=flat-square)
![Status](https://img.shields.io/badge/Status-draft-DEEP?style=flat-square)
![Date](https://img.shields.io/badge/Date-2026--10--29-MID?style=flat-square)
![For](https://img.shields.io/badge/For-Name-6d28d9?style=flat-square)
```

## Icons

The icon set ships amber. Once per repo: `sh proposals/scripts/retone-icons.sh PRIMARY MID` rewrites the strokes
and the darker fill, leaving the semantic colours alone. (Taylor'd and Ethereal Offering were retoned 2026-10-29;
before that their icons were still amber while their badges had moved.)

## The PDF

`proposals/scripts/render-pdfs.sh` (and the `pdf.yml` workflow) takes the family as variables and adds:

```css
h1 { color: #DEEP }
h2 { color: #DEEP; border-bottom: 2px solid #PRIMARY; padding-bottom: 4px }
h3, h4 { color: #MID }
a  { color: #ACCENT }                                   /* ACCENT defaults to PRIMARY */
blockquote { border-left: 4px solid #ACCENT; background: #TINT; padding: 6px 14px; margin-left: 0 }
th { background: #TINT; color: #DEEP }
details > summary { font-weight: 600; color: #MID }
hr { border: 0; border-top: 1px solid #PRIMARY; opacity: .45 }
```

`TONE=rainbow sh proposals/scripts/render-pdfs.sh` renders David's family: the H1 is a six-hue gradient, the H2s
cycle red, orange, yellow, green, blue, violet in order, rules are a gradient, and links are the blue. Badges for a
rainbow proposal take the six hues in order (number red, status orange, date yellow, "For" stays `6d28d9`).

Run `TONE_PRIMARY=5b2bb5 TONE_DEEP=3b1f6e TONE_MID=7c3aed TONE_TINT=ede9fe sh proposals/scripts/render-pdfs.sh` to
render in another family, or set the defaults at the top of the script once per repo.

## Decks (Marp)

`proposals/decks/*.marp.md` follow the same family: title slide and H1 in the primary on a dark ground, H2 in a
lighter primary, accents in the mid, and `section h1 { … !important }` so the default theme does not win. Render
with node on PATH and `CHROME_PATH` set, or Marp hangs (`walkthroughs/MARKDOWN-BESIDE-PDF.md`).

## Adding an organisation

Pick a family no neighbour uses (the table is the register), add the row here with its four shades, set the defaults
in that repo's render script, retone its icons, and use the badge recipe above in its `_template/README.md`.

<sub>Register started 2026-10-29; four shades, the lab accent, rainbow, Psanctuary and Psanctuary Church added the same night. Related: [`README.md`](README.md) (the template), [`../walkthroughs/MARKDOWN-BESIDE-PDF.md`](../walkthroughs/MARKDOWN-BESIDE-PDF.md) (why every PDF ships with its markdown).</sub>
