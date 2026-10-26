/* ORG's arrival config, read by arrival.js. Shared by every ORG page: the entry portal, the
   AstroLog, and (by absolute URL) the drasticstatic ORG lab.

   Every fact here comes from ORG's own materials: orgspirituality.org (Community and About pages),
   the organization's .github profile, and brand-assets. Anything not published yet is marked as a
   placeholder rather than guessed. Strings shown in the welcome guide may hold simple HTML. */
(function () {
  var ROOT = "https://octagon-religious-research-group-org.github.io";
  var LOG = ROOT + "/changelog-astro-public";
  var SITE = "https://orgspirituality.org";
  var TELEGRAM = "https://t.me/+ccL8NUffhuU0ZGJh"; // the group chat orgspirituality.org/community links to
  // The octagon mark's eight wedge colors, clockwise from the top edge.
  var WEDGES = ["#5a43f0", "#9a4dff", "#d04ce8", "#e65aa8", "#f29a3a", "#e4d548", "#6fd84a", "#3ccfe0"];

  window.ARRIVAL = {
    org: {
      short: "ORG",
      name: "Octagon Religious-Research Group",
      motto: "Where science and spirituality meet.",
      about:
        "ORG is a member-governed spiritual and research community. Members propose beliefs and keep the ones most of them agree on, and together they plan octagon-shaped temples and research centers where spirituality and science are practiced side by side.",
      // The official mark, unmodified (brand-assets apple-touch-icon-180.png).
      mark: { src: ROOT + "/apple-touch-icon.png" },
      home: {
        label: "orgspirituality.org",
        href: SITE,
        text: "The official site: beliefs, community, research, and offerings. It's also where ORG decides. Every belief starts on one member's page, and becomes ORG's once most voting members agree. Votes never close, so any belief can be revisited.",
      },
      welcomeNote: null,
      welcomePlaceholder:
        "A few words of welcome from ORG's founder, Tripp Aardema, belong here. This space is left empty on purpose until he writes them.",
    },

    // Same key and shape as the O-R-G dApp preview, so a choice made there carries to the lab.
    // The legacy keys are what ORG's portal and AstroLog stored before the kit.
    storage: { key: "org-experience", legacy: { light: "org-light", motion: "org-motion" } },

    modes: [
      { id: "night", name: "Night Sanctuary", note: "Candle-lit indigo, warm gold, and aurora light.", swatch: ["#100e1c", "#e9be72"], dark: true },
      { id: "prism", name: "Prism Light", note: "Morning light through a prism, soft and bright.", swatch: ["#f5f3fa", "#6b4fa0"] },
      { id: "stone", name: "Stone & Lapis", note: "Temple stone veined with lapis and gold.", swatch: ["#ecebe6", "#22408a"] },
      {
        id: "day",
        name: "Follow the day",
        note: "Prism by morning, stone by afternoon, sanctuary by night.",
        shows: ["prism", "stone", "night"],
        // Prism's lilac by morning, lapis by afternoon, candle gold by night.
        ink: "linear-gradient(90deg, #c9b8ff 0 33.3%, #22408a 0 66.6%, #e9be72 0)",
        follows: function (d) {
          var h = d.getHours();
          return h >= 5 && h < 11 ? "prism" : h >= 11 && h < 17 ? "stone" : "night";
        },
      },
    ],
    defaultMode: "night",

    // ORG's motion styles. The cursor trail runs through the octagon's eight colors: faint on Gentle,
    // brighter on Vivid, where it also scatters little octagons. Cursor effects can be switched off
    // on their own, and they rest whenever motion is Still.
    motions: [
      { id: "still", name: "Still", icon: "pause", note: "Nothing moves unless you touch it." },
      {
        id: "gentle",
        name: "Gentle",
        icon: "wind",
        note: "The ink drifts slowly, and your pointer stirs it and leaves a faint trail of the octagon's colors.",
        trail: { colors: WEDGES, life: 440, width: 2.2, alpha: 0.5 },
      },
      {
        id: "vivid",
        name: "Vivid",
        icon: "sparkle",
        note: "Faster ink, a brighter trail, and little octagons scattering behind your pointer.",
        trail: { colors: WEDGES, life: 680, width: 3.6, alpha: 0.85, sparks: 0.45, sides: 8 },
      },
    ],
    defaultMotion: "gentle",
    stillMotion: "still",

    // The octagon mark's eight wedge colors, clockwise from the top edge. They color the guide's
    // progress octagon (eight steps, eight wedges) and the initials avatars.
    wedges: WEDGES,

    // Gravatar is used only for addresses at these domains. ORG hasn't published an org-domain role
    // address yet (placeholder), so for now everyone shows a GitHub picture or their initials.
    avatar: { shape: "octagon", roleDomains: ["orgspirituality.org"] },

    community: {
      name: "Telegram",
      icon: "telegram-logo",
      href: TELEGRAM,
      label: "Join ORG's Telegram group",
      text: "ORG's members talk in a Telegram group chat. The Community page on orgspirituality.org invites everyone there for more information and updates.",
      more: [
        'Prefer to ask one person first? ORG\'s About page lists Tripp on Telegram as <a href="https://t.me/Tripp_ORG">@Tripp_ORG</a>.',
      ],
    },

    // ── kit 1.1 (wave 5) ───────────────────────────────────────────────────────────────────────
    news: { sources: [LOG + "/latest.json"] },

    // ── kit 1.2 (wave 6): the interface half ─────────────────────────────────────────────────
    // Reading mode's light, plus round 2: text size steps beside the reading switch (these four are
    // the default; omit `sizes` to keep them) and a comfortable line length (measure: false hides it).
    reading: {
      light: "stone",
      sizes: [
        { id: "standard", name: "Standard", scale: 1 },
        { id: "large", name: "Large", scale: 1.125 },
        { id: "larger", name: "Larger", scale: 1.25 },
        { id: "largest", name: "Largest", scale: 1.4 },
      ],
    },

    // The navbar, drawn by <arrival-nav> on every page (portal and AstroLog). Links and dropdown
    // groups, an icon on each. When the bar runs short, the lowest `priority` folds into "More"
    // first (rightmost first among equals); below `fold` px the whole bar becomes a Menu button.
    // hrefs.<siteId> gives one site its own link (the portal's /map/); hideOn hides an item on a site
    // (no "Portal" link on the portal itself); open: "contact" | "community" opens that modal, with
    // href as the no-JS fallback. `note` is a line under the link in dropdowns and the Menu.
    nav: {
      label: "ORG",
      fold: 1100,
      items: [
        { id: "portal", label: "Portal", icon: "house-simple", href: ROOT + "/", hideOn: ["portal"], priority: 1, note: "ORG's front door on GitHub" },
        { id: "porch", label: "Porch", icon: "door-open", href: LOG + "/", exact: true, priority: 1, note: "The AstroLog's front door" },
        { id: "changelog", label: "Changelog", icon: "clock-counter-clockwise", href: LOG + "/changelog", priority: 3, note: "What changed, newest first" },
        { id: "library", label: "Library", icon: "books", href: LOG + "/library", priority: 2, note: "How it works" },
        { id: "ledger", label: "Ledger", icon: "scroll", href: LOG + "/ledger", priority: 2, note: "Every public change, in plain words" },
        { id: "map", label: "Map", icon: "map-trifold", href: LOG + "/map", hrefs: { portal: ROOT + "/map/" }, priority: 2, note: "Every place, with a picture of each" },
        {
          id: "involved",
          label: "Get involved",
          icon: "hand-heart",
          priority: 3,
          items: [
            { id: "community", label: "Community", icon: "users-three", href: TELEGRAM, open: "community", note: "Where members talk" },
            { id: "contact", label: "Reach out", icon: "envelope-simple", href: "mailto:org@orgspirituality.org", open: "contact", note: "Every way to reach ORG" },
            { id: "donate", label: "Donate", icon: "heart", href: ROOT + "/donate/", note: "Ways to give, and thanks by name" },
          ],
        },
        {
          id: "about",
          label: "About",
          icon: "info",
          priority: 1,
          items: [
            { id: "roadmap", label: "Roadmap", icon: "path", href: LOG + "/roadmap", note: "Where these pages are headed" },
            { id: "sustainability", label: "Sustainability", icon: "plant", href: LOG + "/sustainability", note: "What keeps them running" },
            { id: "home", label: "orgspirituality.org", icon: "globe-hemisphere-west", href: SITE, note: "The official site" },
            { id: "github", label: "GitHub", icon: "github-logo", href: "https://github.com/Octagon-Religious-Research-Group-ORG", note: "The organization and its code" },
          ],
        },
      ],
    },
    // The footer's link groups, drawn by <arrival-footer>. Items are nav ids or full links. Without
    // `groups`, the footer repeats the nav (its links, then each dropdown).
    footer: {
      groups: [
        { label: "Explore", icon: "compass", items: ["portal", "porch", "changelog", "library", "ledger", "map"] },
        { label: "Get involved", icon: "hand-heart", items: ["community", "contact", "donate", { id: "guide", label: "Welcome guide", icon: "signpost", href: "#welcome", open: "guide" }] },
        { label: "About this build", icon: "wrench", items: ["roadmap", "sustainability", "github"] },
      ],
      note: "Code MIT, words CC BY-SA 4.0. ORG's name and octagon mark belong to ORG.",
    },

    // One modal for every way to reach the org. kind: form | email | page | github | chat. A path
    // with `placeholder` (and no href) renders as a clearly marked slot: never invent a URL.
    // A plain click on any link to one of these hrefs opens the modal instead (intercept: false
    // turns that off). PIR's, for reference:
    //   { kind: "page", label: "PIR's contacts on GitHub", href: "https://github.com/psychedelicsinrecovery/.github/blob/main/CONTACTS.md" },
    //   { kind: "form", label: "The contact form", href: "https://www.psychedelicsinrecovery.org/contact/" },
    //   { kind: "form", label: "The service site's contact form", href: "https://service.psychedelicsinrecovery.org/contact/" },
    contact: {
      title: "Reach out",
      intro: "Every way to reach ORG. Pick whichever suits you.",
      paths: [
        { kind: "email", label: "org@orgspirituality.org", href: "mailto:org@orgspirituality.org", note: "ORG's main address." },
        { kind: "email", label: "webdev@orgspirituality.org", href: "mailto:webdev@orgspirituality.org", note: "About the websites, these pages included." },
        { kind: "email", label: "octagonreligiousresearchgroup@gmail.com", href: "mailto:octagonreligiousresearchgroup@gmail.com", note: "ORG's general inbox." },
        { kind: "form", label: "A contact page on orgspirituality.org", placeholder: "orgspirituality.org doesn't have a contact page yet (/contact is a 404). The addresses above reach the team." },
        { kind: "github", label: "ORG's CONTACTS.md", placeholder: "A contacts page on GitHub is planned." },
      ],
    },

    // Every place the community talks: kind discord | telegram | mighty | whatsapp | substack |
    // bespoke | forum | email, each with a `public` link (anyone can look) and a `join` link
    // (sign up / private). A platform with status: "soon", or with neither link, renders as
    // "coming soon". `bespoke` is the sneak-peek card for the org's own network + DAO (a direction,
    // never a date). The v1.0 keys (name, icon, href, label, text, more) still drive the guide's step.
    //   PIR:  { kind: "discord", name: "PIR's Discord", join: { href: "https://discord.gg/MyprTq8w95", label: "Join the Discord" } }
    //   THEF: { kind: "whatsapp", status: "soon", … }, { kind: "substack", status: "soon", … }
    //   psanctuarychurch: { kind: "mighty", public: { href: "https://psanctuary-member-community.mn.co/" },
    //                       join: { href: "https://psanctuary-member-community.mn.co/plans/" } }
    community: {
      name: "Telegram",
      icon: "telegram-logo",
      href: TELEGRAM,
      label: "See every way in",
      text: "ORG's members talk in a Telegram group chat. The Community page on orgspirituality.org invites everyone there for more information and updates.",
      more: ['Prefer to ask one person first? ORG\'s About page lists Tripp on Telegram as <a href="https://t.me/Tripp_ORG">@Tripp_ORG</a>.'],
      title: "Where we gather",
      platforms: [
        {
          id: "telegram",
          kind: "telegram",
          name: "ORG on Telegram",
          text: "The group chat orgspirituality.org/community links to.",
          // Whether "ORG (Public)" is truly public is still being asked (2026-10-13). Until then the
          // invite link is the sign-up path and the public slot shows "coming soon".
          join: { href: TELEGRAM, label: "Join the group chat", note: "An invite link to the group." },
        },
      ],
      bespoke: {
        title: "A network of our own",
        tag: "Sneak peek",
        text: "Further out, ORG would like a social space its members own, paired with its DAO.",
        points: ["Profiles and posts on open protocols like Lens and Farcaster.", "Proposals and votes in ORG's DAO.", "Privacy first."],
        note: "No dates. A direction, not a promise.",
      },
    },

    // The donate page (<org>.github.io/donate/, the kit's <arrival-donate>). give: the org's own
    // giving paths (link the org's page, not a payment processor directly). disclaimer: per org;
    // placeholder: true marks it as waiting for real wording. ledger.src: a contributors.json of
    // people who said yes to being named (empty is fine). The crypto slot stays empty until the
    // wallet module fills [data-arr-wallet-slot]: never put an address here.
    //   PIR's disclaimer (a placeholder until the Alex session writes it):
    //   { placeholder: true, title: "About giving to PIR", text: "PIR can't accept outside contributions,
    //     per its traditions, but it can accept donations, and other organizations have sponsored the
    //     journey. The full wording is being written." }
    donate: {
      give: [{ label: "Gifts and offerings", icon: "gift", href: SITE + "/offerings", action: "Visit the offerings page", note: "ORG's own page for gifts and offerings." }],
      disclaimer: { placeholder: true, title: "About giving", text: "ORG's wording about gifts belongs here. It's left as a placeholder until ORG writes it." },
      ledger: { src: ROOT + "/donate/contributors.json", title: "Contribution ledger", intro: "People who have given time, skills or gifts, and said yes to being thanked by name." },
      crypto: { text: "Giving from a crypto wallet is planned for this page. It isn't open yet." },
    },

    // v1.3 · give with crypto: the wallet module in the donate page's crypto slot (give/give.js,
    // beside arrival.js). Not to be confused with donate.give above (the org's giving links).
    //   reownProjectId  a Reown project ID (a public client ID; fine in code). Its allowlist on
    //                   dashboard.reown.com must include https://<org>.github.io, or the page shows
    //                   "Wallet connect isn't switched on for this site yet" (calmly, no red errors).
    //   chains          EVM networks the ETH address can receive on: mainnet, base, arbitrum,
    //                   optimism (sepolia for tests). List one only if the address really receives
    //                   there: a Safe, for instance, exists only on the networks it was deployed to.
    //   addresses       null until the org publishes a treasury address. With none, the page says
    //                   "Treasury address coming soon" and connecting is a labelled preview. Never
    //                   put a placeholder or example address here: the page would show it.
    //   note            the org's own words, after the safety line. social: false hides email and
    //                   social sign-in. claim.to: where "add your name" notes go (default: the
    //                   first email in contact.paths). words: any of give.js's strings.
    //   enabled: false  no module; the slot stays empty (PIR: no outside contributions, per its
    //                   traditions; its wording is being written in the A.L.E.X. session).
    give: {
      reownProjectId: "00b6a1cd528ff580f1fd845ed08b0187",
      chains: ["mainnet"],
      addresses: { eth: null, btc: null, sol: null },
      note: "",
    },

    // ── kit 1.4 (2026-10-22) ───────────────────────────────────────────────────────────────────
    // Essentials: Donate and the welcome guide appear in the footer, the More dropdown and the Menu
    // with no key at all (the More button now stays in the bar to hold them). Donate links the nav's
    // own "donate" item, else donate.href, else <portal>/donate/. Override a label or link, or opt out:
    //   essentials: { donate: { label: "Give" }, guide: false },   or   essentials: false
    // (Nothing to set for ORG: its nav already has a Donate item, and the kit adds the guide.)

    // The dock (the one-row strip at the bottom) gets edge fades and chevron buttons on the side with
    // more to show, so visitors can tell it scrolls. Only while it overflows; keyboard reachable;
    // instant under reduced motion. It finds .universal-footer .footer-inner and PIR's .dock .wrap;
    // `selector` names another strip, and data-arr-scroll on any element opts that one in.
    dock: { scroll: true },

    // A grouped dropdown: `groups` instead of (or after) `items`, each with a heading and a divider,
    // kept in the More panel and the Menu. The footer still lists it as one flat group. PIR's Foyers,
    // for reference (it replaces concierge.js's runtime separators and reordering):
    //   { id: "foyers", label: "Foyers", icon: "door-open", groups: [
    //       { label: "Committees", icon: "users-three", items: [ …GSR, PR, TechCom, LitCom, … ] },
    //       { label: "Infrastructure", icon: "wrench", items: [ …WordPress, GitHub, A.L.E.X. ] } ] }

    // Receipts and taxes: a calm section at the end of /donate/, shown only with this key, inside the
    // donate block above: donate.tax = { … }. With no fields it claims nothing: "Ask us for a
    // receipt…", deductibility "depends on the organization's status and your own situation", "This
    // isn't tax advice." Only the org's own published words may state a status:
    //   status      the org's legal status, as the org itself publishes it (never guessed)
    //   deductible  a sentence, or true / false for a plain one
    //   receipts    how receipts work, in the org's words
    //   note        anything else
    // ORG hasn't published a status, so its block would be just: tax: {}

    // A pledge of support: the kit's <arrival-pledge>, on a page of its own (/pledge/, from
    // portal/pledge.example.html). A visitor signs a short pledge with a wallet: an EIP-191 message,
    // free, nothing sent or recorded, checked in the tab and forgotten. No counts, ever, until pledges
    // are published as verifiable records. Uses give.reownProjectId unless reownProjectId is set here.
    //   text      the pledge itself, in the org's own plain words (what the wallet signs). Without it:
    //             "I support <org.name> and the people it serves."
    //   note      the org's own words after the fine print
    //   href      the page it lives on (so "/" search finds it)
    //   tokens    false hides the "Gratitude tokens (coming)" card; { text, href, label } rewords it
    //   bots      false hides "How you'll know these aren't bots"; { points: [] } rewords it
    //   verify    false hides the "verify a signature" tool
    //   enabled   false: nothing at all
    // Waiting on ORG's own words, so it stays off here:
    //   pledge: { text: "…", href: ROOT + "/pledge/" },

    // ── kit 1.5 (2026-10-26): languages ─────────────────────────────────────────────────────────
    // Two or more languages turn on the welcome's first step, "Your language · Tu idioma": a door per
    // language, each written in its own words. The kit's own words come from arrival/i18n/<id>.js
    // (Spanish ships with the kit), loaded only for a visitor who chooses it. Without this key the
    // kit is exactly v1.4: English only, no new step.
    //   languages: {
    //     list: [{ id: "en", name: "English" }, { id: "es", name: "Español" }],
    //     start: "browser",       // or "en" / "es": the language before the visitor chooses
    //     // base: "en",          // the language this file is written in (default: en)
    //     // route: function (lang, path) { return lang === "es" ? "/es" + path : path.replace(/^\/es/, ""); },
    //     //                      // only for a site with real translated pages; adds hreflang too
    //     // contentNote: false,  // hides the honest "this page's words are in English for now" line
    //   },
    // ORG's own words in Spanish. `text` swaps any English string from this file (an exact match);
    // `modes` and `motions` rename by id; `words` re-voices the kit (it wins over the kit's pack);
    // `config` is merged over this file for that language. reviewed: true once someone who speaks
    // Spanish as their own language has read the kit's pack and these words.
    //   i18n: {
    //     es: {
    //       reviewed: false,
    //       words: { enter: "Entrar a ORG" },
    //       text: { "Where science and spirituality meet.": "Donde la ciencia y la espiritualidad se encuentran.", "Porch": "Pórtico" },
    //       modes: { night: { name: "Santuario nocturno", note: "…" }, prism: { name: "Luz de prisma" } },
    //       motions: { still: { name: "Quieto" }, gentle: { name: "Suave" }, vivid: { name: "Vívido" } },
    //     },
    //   },
    // Waiting on ORG's choice of languages (and a Spanish read), so it stays off here.

    record: {
      intro: "ORG's AstroLog has two halves.",
      share:
        "Sharing one change? Every entry and every write-up has its own preview card. Paste its link into Telegram, iMessage or Discord and it arrives with its title, summary and who made it. The <strong>Copy a link</strong> button under each one does the copying.",
      changelog: {
        name: "The changelog",
        text: "Every notable change to ORG's websites, newest first. Each entry is a short summary with the full story underneath, filed under one of four areas: the live site, the API, ORG on GitHub, and previews and proposals.",
        href: LOG + "/changelog",
        label: "Read the changelog",
      },
      library: {
        name: "The library",
        text: "Longer write-ups on how the sites are built and how they fit together. The changelog says what changed; the library explains how it works.",
        href: LOG + "/library",
        label: "Open the library",
      },
    },

    sites: {
      portal: {
        name: "ORG on GitHub",
        what: "This is ORG's front door on GitHub: the same nine doors as the home page of orgspirituality.org, and the way into the AstroLog, where ORG keeps its record of what changed.",
      },
      astrolog: {
        name: "the ORG AstroLog",
        what: "The AstroLog is ORG's plain-language record of what changed on its websites, who made each change, and how the pieces fit together. It's the official record for the repositories in ORG's GitHub organization.",
      },
    },

    guide: {
      light: {
        text: "ORG's members are voting on three proposed looks for the website, drawn up by Renan Teixeira. Until they decide, every ORG page offers all three, and your choice follows you from page to page.",
      },
      motion: {
        text: "Behind each page is marbled ink that moves with your pointer. Choose how much it moves, and whether you'd like more contrast for reading.",
      },
      people: {
        text: "Every entry credits whoever did the work, named the way ORG's own profile names them.",
        fine: "Pictures come from public GitHub profiles. Anyone without one linked gets an octagon with their initials.",
      },
    },
    guideFinale: "You've lit all eight wedges of the octagon. Welcome to ORG.",

    words: {
      enter: "Enter ORG",
      cursorNote: "A trail of the octagon's colors behind your pointer, and ink that stirs as you move. Switch it off if you'd rather not.",
      pause: "Pause the ink",
      play: "Let the ink move",
      searchTip: "Anywhere on ORG's pages, any time: every change, write-up, person and page, including the AstroLog from the entry portal.",
    },

    search: {
      sources: [{ url: LOG + "/search.json" }],
      items: [
        { t: "ORG entry portal", k: "page", i: "house", h: ROOT + "/", pin: true, x: "home github io root nine doors" },
        { t: "orgspirituality.org", k: "official site", i: "globe-hemisphere-west", h: SITE, pin: true, x: "website main home" },
        { t: "About", k: "orgspirituality.org", i: "info", h: SITE + "/about", x: "charter founder tripp contact" },
        { t: "Community", k: "orgspirituality.org", i: "users-three", h: SITE + "/community", x: "meditation ceremony meetings" },
        { t: "Beliefs", k: "orgspirituality.org", i: "scales", h: SITE + "/beliefs", x: "vote majority" },
        { t: "Infrastructure", k: "orgspirituality.org", i: "buildings", h: SITE + "/infrastructure", x: "temples research centers octagon" },
        { t: "Join ORG", k: "orgspirituality.org", i: "hand-heart", h: SITE + "/join", x: "membership member apply sign in" },
        { t: "Research", k: "orgspirituality.org", i: "flask", h: SITE + "/research", x: "science studies" },
        { t: "Legal", k: "orgspirituality.org", i: "scroll", h: SITE + "/legal", x: "church religious" },
        { t: "Future ideas", k: "orgspirituality.org", i: "lightbulb", h: SITE + "/future-ideas", x: "future" },
        { t: "Gifts and offerings", k: "orgspirituality.org", i: "gift", h: SITE + "/offerings", x: "shop offerings donate" },
        { t: "ORG's Telegram group", k: "community", i: "telegram-logo", h: TELEGRAM, x: "chat talk community members" },
        { t: "ORG on GitHub", k: "link", i: "github-logo", h: "https://github.com/Octagon-Religious-Research-Group-ORG", x: "organization code repositories" },
        { t: "Brand assets and guidelines", k: "link", i: "seal-check", h: "https://github.com/Octagon-Religious-Research-Group-ORG/brand-assets", x: "logo octagon mark favicon" },
        { t: "Design directions: the three proposed looks", k: "proposal", i: "compass-tool", h: "https://org-new-look.netlify.app/", x: "renan night sanctuary prism light stone lapis vote" },
        { t: "drasticstatic ORG lab", k: "Christopher's lab", i: "flask", h: "https://drasticstatic.github.io/O-R-G-astro-public/", x: "dapp preview portfolio previews christopher" },
      ],
    },
  };
})();
