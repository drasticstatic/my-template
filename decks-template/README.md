# decks-template: a welcome deck for any organisation

`welcome.marp.md` is a newcomer's first walk through an organisation in **seven numbered stops**, in the
style of its sibling [`../decks/my-template-walkthrough.marp.md`](../decks/my-template-walkthrough.marp.md):
your first hour (your own account and password, two-factor, the invitation), five words, proposals,
procedures, the reading room and your helper, how a change travels (`preview` → Promote → `main` → public
twin), and how to answer. It follows SOP-COM-001 *New to GitHub: your first hour* and the clarity standard
in [`../LUCID.md`](../LUCID.md): a Lucide icon beside each idea, drawn inline so the deck needs no files beside it.

The deck sits on the walkthrough's slate ground for every family, and wears the organisation's colour
family from [`TONES.md`](../proposals-template/TONES.md) in the left rule, the numbered stops, the rule
under each heading, the icons and the colour strip. Headings, links and icons mix the **primary** with
white, so every family reads on slate, purple and blue included; no colour is hand-tuned.

**See it filled:** [`example/welcome.marp.pdf`](example/welcome.marp.pdf) ([html](example/welcome.marp.html),
[markdown](example/welcome.marp.md)) is the template filled for "Your Organisation" in amber, with
placeholder addresses: a look at the result, not a deck to send.

## The placeholders

| Placeholder | Takes | Example (THEF) |
|---|---|---|
| `{{ORG_NAME}}` | the organisation's name as people say it | `The Holy Earth Foundation` |
| `{{TONE_PRIMARY}}` | the family's primary, bare hex, no `#` | `d97706` |
| `{{TONE_DEEP}}` | the deep shade | `6b4f1d` |
| `{{TONE_MID}}` | the mid shade | `b45309` |
| `{{TONE_TINT}}` | the tint | `fef3c7` |
| `{{READING_ROOM_URL}}` | where members read: the private `<org>/reading-room` | `https://github.com/<org>/reading-room` |
| `{{SOP_PUBLIC_URL}}` | the procedures' public twin, or the private SOP repository until a twin exists | `https://github.com/<org>/ops-standard-operating-procedures-public` |
| `{{PROPOSALS_URL}}` | the organisation's proposals repository | `https://github.com/<org>/proposals` |
| `{{ACCESS_CONTACT}}` | who to ask for access: **a role and a route**, never a private address | `a steward, through an issue on the members' page` |

Every shade is in the TONES.md table. The deck goes in public places (the organisation's public
`.github/decks/`), so every value must be safe for a visitor to read.

## Fill it

From the repository that will hold the deck (usually the organisation's public `.github`):

```sh
mkdir -p decks
sed -e 's|{{ORG_NAME}}|The Holy Earth Foundation|g' \
    -e 's|{{TONE_PRIMARY}}|d97706|g' -e 's|{{TONE_DEEP}}|6b4f1d|g' \
    -e 's|{{TONE_MID}}|b45309|g'     -e 's|{{TONE_TINT}}|fef3c7|g' \
    -e 's|{{READING_ROOM_URL}}|https://github.com/<org>/reading-room|g' \
    -e 's|{{SOP_PUBLIC_URL}}|https://github.com/<org>/ops-standard-operating-procedures-public|g' \
    -e 's|{{PROPOSALS_URL}}|https://github.com/<org>/proposals|g' \
    -e 's|{{ACCESS_CONTACT}}|a steward, through an issue on the members'"'"' page|g' \
    path/to/my-template/decks-template/welcome.marp.md > decks/welcome.marp.md
grep -c '[{][{]' decks/welcome.marp.md    # 0 means every placeholder is filled
```

A value containing `|` or `&` needs a backslash before it (`\|`, `\&`), because `sed` reads them as
syntax. Then read the filled deck once and change the words where the organisation differs (a
reading room that does not exist yet, a different first SOP). The structure is a starting point;
the words should be theirs.

## Render it

Marp needs node on `PATH` and Chrome named, or it hangs looking for a browser
([`walkthroughs/MARKDOWN-BESIDE-PDF.md`](../walkthroughs/MARKDOWN-BESIDE-PDF.md)):

```sh
export CHROME_PATH="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
cd decks
marp --no-stdin --html --allow-local-files welcome.marp.md -o welcome.marp.html
marp --no-stdin --html --allow-local-files welcome.marp.md --pdf -o welcome.marp.pdf
```

- `--html` keeps the inline icons, the numbered stops, the colour strip (`<div class="rail">`) and the small print; without it Marp drops them.
- `--no-stdin` stops Marp waiting on standard input when it runs from a script or a helper's shell.
- **Look at the PDF pages before calling it done.** A long organisation name or URL can wrap a
  title or a table cell; shorten the words rather than shrinking the type.

Commit the three files together (`welcome.marp.md`, `.html`, `.pdf`), the markdown beside the PDF as
everywhere else in the fleet, and link the deck from the organisation's `.github` profile README.

<sub>Added 2026-10-31 with the my-template walkthrough deck; redesigned 2026-11-01 in the walkthrough's style (seven stops, inline Lucide icons, SOP-COM-001's first hour). Related: [`../proposals-template/TONES.md`](../proposals-template/TONES.md) (the families), [`../sop-template/`](../sop-template/) (the procedures the deck points at).</sub>
