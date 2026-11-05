<div align="center">

<img src="../assets/icons-phosphor/shapes.svg" width="56" height="56" alt="">

# Connect Wix

*Let your helper read and help with a Wix site. You stay in charge of every change.*

![Kind](https://img.shields.io/badge/Kind-Walkthrough-800020?style=flat-square)
![Changed](https://img.shields.io/badge/Changed-2026--11--04-800020?style=flat-square)
![For](https://img.shields.io/badge/For-Anyone_who_manages_a_Wix_site-800020?style=flat-square)

<img src="../assets/icons-phosphor/map-pin.svg" width="16" height="16" alt=""> **You are here:** drasticstatic lab › [`my-template`](../README.md) › [`walkthroughs`](README.md) › `CONNECT-WIX.md` · public · `main` is the working branch

</div>

## <img src="../assets/icons-phosphor/compass.svg" width="24" height="24" alt=""> TL;DR

1. <img src="../assets/icons-phosphor/shapes.svg" width="16" height="16" alt=""> **The Wix MCP is Wix's own official connection for AI helpers.** Once connected, your helper can:
2. <img src="../assets/icons-phosphor/search.svg" width="16" height="16" alt=""> search Wix's documentation;
3. <img src="../assets/icons-phosphor/eye.svg" width="16" height="16" alt=""> read your site's content and business data (blog, bookings, events, CMS collections, store);
4. <img src="../assets/icons-phosphor/pencil-line.svg" width="16" height="16" alt=""> help you make changes.
5. <img src="../assets/icons-phosphor/hand-helping.svg" width="16" height="16" alt=""> **You stay in charge:** start by asking it to *read and suggest*, and approve any change yourself.

> **Handing this to your AI helper?** Say: *"Read CONNECT-WIX.md and help me connect my Wix site to you.
> Begin read-only: show me what you can see before you change anything."*

## <img src="../assets/icons-phosphor/bot.svg" width="24" height="24" alt=""> Pick your helper

<details open>
<summary><b>ChatGPT</b></summary>

1. Open the official **Wix plugin for ChatGPT**:
   <https://chatgpt.com/plugins/plugin_asdk_app_6947eaa4edd081919561e4ee3a2e5dcc>
2. Select **Connect** and sign in with the Wix account that manages your site.
3. In any chat, tag **@wix**: *"@wix list the pages on my site and the date each was last updated."*

**Tip:** keep Wix work inside your organization's ChatGPT **Project**, so it sits beside your other site
notes.

</details>

<details>
<summary><b>Claude (web and desktop)</b></summary>

1. Open **Settings → Connectors** and find the built-in **Wix** connector.
2. Select **Connect** and sign in with your Wix account.
3. Ask: *"Using Wix, show me my blog posts from this year."*

</details>

<details>
<summary><b>Claude Code, Cursor and other code tools</b></summary>

Add Wix's hosted server to the tool's MCP settings (for Claude Code: `~/.claude.json`, under
`"mcpServers"`):

```json
{
  "mcpServers": {
    "wix-mcp-remote": {
      "type": "http",
      "url": "https://mcp.wix.com/mcp"
    }
  }
}
```

The first time it's used, Wix asks you to sign in. Restart the tool, then check that it's connected.

</details>

## <img src="../assets/icons-phosphor/message-square.svg" width="24" height="24" alt=""> Good first requests

- <img src="../assets/icons-phosphor/map.svg" width="16" height="16" alt=""> *"@wix list every page on my site with its address. Mark the ones that link to the retreat portal."*
- <img src="../assets/icons-phosphor/type.svg" width="16" height="16" alt=""> *"@wix show me the FAQ page's text, and suggest clearer wording. Don't change it yet."*
- <img src="../assets/icons-phosphor/history.svg" width="16" height="16" alt=""> *"@wix which pages haven't been updated this year?"*
- <img src="../assets/icons-phosphor/scan-search.svg" width="16" height="16" alt=""> *"Compare my Wix FAQ with the FAQ on our retreat portal and list the differences."*

## <img src="../assets/icons-phosphor/shield-check.svg" width="24" height="24" alt=""> Safety, in plain words

- <img src="../assets/icons-phosphor/eye.svg" width="16" height="16" alt=""> **Read first, write second.** Ask your helper to show you a change before making it. Wix's own guidance:
  treat reviewing what the AI suggests as your responsibility.
- <img src="../assets/icons-phosphor/user-round.svg" width="16" height="16" alt=""> **Use the account that should be making changes.** If several people manage the site, decide together
  who connects it.
- <img src="../assets/icons-phosphor/folder-lock.svg" width="16" height="16" alt=""> **Nothing private goes on a public page.** The same never-publish rule as the GitHub sites applies here.

Official guides:
- [What is the Wix MCP?](https://www.wix.com/blog/what-is-the-wix-mcp)
- [About the Wix MCP (developers)](https://dev.wix.com/docs/sdk/articles/use-the-wix-mcp/about-the-wix-mcp)

## <img src="../assets/icons-phosphor/git-pull-request.svg" width="24" height="24" alt=""> Suggest a change

Noticed something wrong, or know a better way? Open an [issue](https://github.com/drasticstatic/my-template/issues) or a pull request against `main`; the lab steward reads them, and a person with the role merges with a merge commit so your name stays on it. Not on GitHub? Tell any steward you know, or your helper, in your own words.

<sub>One of the [walkthroughs](README.md) in `my-template`. Icons: Phosphor duotone (MIT).</sub>
