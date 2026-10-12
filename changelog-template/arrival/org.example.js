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
