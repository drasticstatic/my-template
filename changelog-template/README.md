# 🌌 AstroLog and the arrival kit

**TL;DR:** two things that work together for any community or foundation on GitHub:
- **AstroLog:** a public-safe changelog site. Write a markdown entry, and a calm, searchable page appears;
  private source never leaves the private repo.
- **The arrival kit:** one stylesheet and one script per organisation, which welcomes every visitor the
  same gentle way across all of its sites: their light, their motion, a welcome guide, search, who made
  what, and a way to give.

**In use by:**
- Psychedelics in Recovery
- The Holy Earth Foundation
- Octagon Religious Research Group
- Psanctuary and Psanctuary Church

**Kit version:** 1.5.1.

---

## ✨ A 60-second tour

| | What a visitor finds | Where it comes from |
|---|---|---|
| 🌗 | **"Choose how you arrive":** a first-visit welcome to pick light, motion and contrast. It respects the OS's own reduced-motion and contrast wishes | `arrival/arrival.js` |
| 🗣️ | **"Your language · Tu idioma":** with two or more languages, the welcome opens with a door per language, each in its own words. The kit speaks Spanish, Portuguese, French and German out of the box, and says honestly which words aren't translated yet | `arrival/i18n/` |
| 🧭 | **A welcome guide:** what the site is, how to search, who made the changes, where the community talks | `arrival/arrival.js` |
| 🔎 | **Press `/` to search** everything, across the portal and its AstroLog | `search.json` from each site |
| 🧑‍🤝‍🧑 | **Real faces:** contributor avatars, and personal emails are never hashed into a page | `<arrival-avatar>` |
| 📖 | **Reading mode**, **what's new since your last visit**, and **the ledger**: a calm record of public commits, labelled by priority and by which AI helped | `arrival/ledger/` |
| 🌠 | **A star chart** of every site in the family, and designed **social cards** for each entry | `arrival/astro/`, `arrival/og/` |
| 💛 | **Give, gently:** crypto giving through Reown with a QR for phones, receipts and tax notes, and a pledge of support. Nothing appears until an org has real addresses | `arrival/give/`, `arrival/pledge/` |
| 🦶 | **One footer everywhere**, with Donate and the welcome guide always present | `arrival/arrival.css` |

## 🚀 Adopt it in five steps

1. **Copy a working site, not the parts.** Start from an existing AstroLog (for example
   `theholyearthfoundation/changelog-astro`) rather than assembling the template by hand.
2. **Write entries** with the frontmatter in [docs/REFERENCE.md](docs/REFERENCE.md) (title, date, priority,
   TL;DR). The commit-priority emoji (🚨 🔥 ⚡ 🍃) shows up as a badge in the ledger.
3. **Describe your org once** in [`arrival/org.example.js`](arrival/org.example.js): name, colours, the
   steps of the welcome guide, contact, giving. Copy `arrival.js` and `arrival.css` to
   `<org>.github.io/arrival/` **unchanged**; every customisation is configuration.
4. **Publish safely** with the private→public sync
   ([`../workflow-templates/sync-public-allowlist.yml`](../workflow-templates/sync-public-allowlist.yml)):
   the site builds, the source is stripped, and only the finished HTML reaches the public repo.
5. **Verify** with the `arrival/verify*.example.mjs` scripts (keyboard, contrast, storage blocked,
   reduced motion) before you announce it.

| Folder | What's inside |
|---|---|
| [`arrival/`](arrival/) | The kit: `arrival.js`, `arrival.css`, `org.example.*`, giving, pledge, ledger, social cards, portal pages, verify scripts |
| [`arrival/astro/`](arrival/astro/) | Astro pieces for an AstroLog: base layout, search and feeds, the map, the ledger page |
| [`arrival/docs/`](arrival/docs/) | Roadmap and sustainability page templates |
| `content.config.ts`, `index.astro`, `[slug].astro` | The content-collection pattern: markdown in, pages out |

## 🗣️ Languages (kit 1.5)

**Turn it on** with two keys in `org.js`. Without them the kit is exactly 1.4: English only, no new step.

```js
languages: { list: [{ id: "en", name: "English" }, { id: "es", name: "Español" }], start: "en" },
i18n: { es: { reviewed: false, text: { "Get involved": "Participa" }, words: { enter: "Entrar" } } },
```

- **Which language comes first.** `start: "en"` (or any listed id) opens every visitor in that
  language, with the others one tap away in the welcome's first row. `start: "browser"` follows the
  visitor's browser instead. The family's sites are English first (`start: "en"`); a site whose people
  mostly speak another language starts in it.
- **The kit's own words** (the welcome, drawer, guide, search, giving and pledge) come from a pack
  in `arrival/i18n/`: Spanish (`es.js`), Portuguese (`pt.js`), French (`fr.js`) and German (`de.js`).
  A pack loads only for a visitor who chooses its language. Any other id works too: add
  `i18n/<id>.js`, and `node arrival/verify-i18n.mjs` checks that every pack carries every word. All
  four ship with `reviewed: false`, until someone who speaks the language as their own has read it.
- **An org's own words** go in `i18n.<lang>`: `text` swaps any string from `org.js` by exact match;
  `modes` and `motions` rename by id; `config` merges over `org.js`. That includes the org's own
  `words` overrides (its "Enter ORG", its search tip): a translated one wins over the kit's generic
  pack word.
- **Static page markup stays as written.** A footer bar or hero written straight into the HTML isn't
  in `org.js`, so the honest content note covers it.
- **Three honest tiers for page content:**
  1. A site with real translated pages gives `languages.route`. The kit takes visitors to the twin
     page and adds `hreflang`.
  2. Otherwise the page keeps its words. One quiet line says so ("Menús en español; las palabras de
     esta página siguen en inglés por ahora") in the welcome and the drawer, once per visit as a note,
     and wherever a page puts `<arrival-langnote>`. No machine-translation widget.
  3. Names and marks carry `translate="no"`.
- **Reviewed, not assumed.** A pack ships with `reviewed: false`, and the kit shows a small "Traducción en
  revisión" until the org's own people read it and set `reviewed: true`.
- **An open invitation.** Under that mark, in any language but English, one quiet line asks for help:
  "Spot a better way to say something? If you can help with translation, please *reach out*…" The link
  opens the org's contact window (`contact`), or else follows `org.home`. The words are `helpTranslate`
  (with a `{reachOut}` slot) and `helpReachOut`: each pack carries its own, and an org re-voices them in
  `i18n.<lang>.words`.
- `<html lang>` keeps describing the page's own words. The kit's menus and dialogs carry their own
  `lang`, so a screen reader voices each part in its own language. `data-lang` on `<html>` holds the
  choice.

## 🧪 The practice wallet (kit 1.5.1)

**TL;DR:** visitors without a wallet can still feel how the pledge works. Beside "Connect a wallet" sits
**"Try it with a practice wallet"**: a throwaway key made in their tab, just for signing practice.
Nothing is sent, and nothing is saved.

- **Ephemeral:** the key is made with the same pinned @noble code that checks signatures, held in
  memory only, and wiped on "End practice", reload or close. There's no storage of any kind.
- **Signs, and nothing else:** it signs the pledge exactly as `personal_sign` does, and the normal
  check verifies it. It never loads the wallet layer, so there's no AppKit and no RPC, and it can't
  send a transaction.
- **Clearly practice:** "(practice)" on the sign button, its own "✓ Signed. This is exactly what a
  real wallet does" panel, and no "Copy my signed pledge". Its address and signature are never shown.
- **A real wallet wins:** connecting one ends the practice.
- **On by default** wherever the pledge is. `pledge: { practice: false }` hides it. Its words are in
  every language pack.

## 🐇 Down the rabbit hole

Curious how all of this came to be? Every wave, every gotcha, every porting checklist and every decision is
kept word for word in **[docs/JOURNEY.md](docs/JOURNEY.md)**: from the first two AstroLogs (2026-09-23) to
the splash, the giving pages and the languages that grew from them.

Sites built with the kit can point their developers here with a quiet **"How this site was made"** link,
as I Am One Self does in its footer Navigator.

## 📚 More

- [docs/REFERENCE.md](docs/REFERENCE.md): the convention, the frontmatter schema, commit priority, where an
  org's public repo lives, and full setup.
- [docs/JOURNEY.md](docs/JOURNEY.md): the build log, wave by wave.
- [../walkthroughs/](../walkthroughs/): joining an organisation and connecting your AI tools.
