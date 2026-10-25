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

**Kit version:** 1.4.0.

---

## ✨ A 60-second tour

| | What a visitor finds | Where it comes from |
|---|---|---|
| 🌗 | **"Choose how you arrive":** a first-visit welcome to pick light, motion and contrast. It respects the OS's own reduced-motion and contrast wishes | `arrival/arrival.js` |
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

## 🐇 Down the rabbit hole

Curious how all of this came to be? Every wave, every gotcha, every porting checklist and every decision is
kept word for word in **[docs/JOURNEY.md](docs/JOURNEY.md)**: from the first two AstroLogs (2026-09-23) to
the splash, the language pickers and the giving pages that grew from them.

Sites built with the kit can point their developers here with a quiet **"How this site was made"** link,
as I Am One Self does in its footer Navigator.

## 📚 More

- [docs/REFERENCE.md](docs/REFERENCE.md): the convention, the frontmatter schema, commit priority, where an
  org's public repo lives, and full setup.
- [docs/JOURNEY.md](docs/JOURNEY.md): the build log, wave by wave.
- [../walkthroughs/](../walkthroughs/): joining an organisation and connecting your AI tools.
