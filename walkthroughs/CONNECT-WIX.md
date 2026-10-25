# 🎨 Connect Wix

**TL;DR:** the **Wix MCP** is Wix's own official connection for AI helpers. Once connected, your helper
can:
- search Wix's documentation;
- read your site's content and business data (blog, bookings, events, CMS collections, store);
- help you make changes.

**You stay in charge:** start by asking it to *read and suggest*, and approve any change yourself.

> **Handing this to your AI helper?** Say: *"Read CONNECT-WIX.md and help me connect my Wix site to you.
> Begin read-only: show me what you can see before you change anything."*

## Pick your helper

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

## Good first requests

- *"@wix list every page on my site with its address. Mark the ones that link to the retreat portal."*
- *"@wix show me the FAQ page's text, and suggest clearer wording. Don't change it yet."*
- *"@wix which pages haven't been updated this year?"*
- *"Compare my Wix FAQ with the FAQ on our retreat portal and list the differences."*

## Safety, in plain words

- **Read first, write second.** Ask your helper to show you a change before making it. Wix's own guidance:
  treat reviewing what the AI suggests as your responsibility.
- **Use the account that should be making changes.** If several people manage the site, decide together
  who connects it.
- **Nothing private goes on a public page.** The same never-publish rule as the GitHub sites applies here.

Official guides:
- [What is the Wix MCP?](https://www.wix.com/blog/what-is-the-wix-mcp)
- [About the Wix MCP (developers)](https://dev.wix.com/docs/sdk/articles/use-the-wix-mcp/about-the-wix-mcp)
