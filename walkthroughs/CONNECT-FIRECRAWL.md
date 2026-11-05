<div align="center">

<img src="../assets/icons-phosphor/flame.svg" width="56" height="56" alt="">

# Connect Firecrawl

*Let your AI helper read whole websites as clean text, for research and site refreshes.*

![Kind](https://img.shields.io/badge/Kind-Walkthrough-800020?style=flat-square)
![Changed](https://img.shields.io/badge/Changed-2026--11--04-800020?style=flat-square)
![For](https://img.shields.io/badge/For-Anyone_connecting_a_helper-800020?style=flat-square)

<img src="../assets/icons-phosphor/map-pin.svg" width="16" height="16" alt=""> **You are here:** drasticstatic lab › [`my-template`](../README.md) › [`walkthroughs`](README.md) › `CONNECT-FIRECRAWL.md` · public · `main` is the working branch

</div>

## <img src="../assets/icons-phosphor/compass.svg" width="24" height="24" alt=""> TL;DR

1. <img src="../assets/icons-phosphor/flame.svg" width="16" height="16" alt=""> **Firecrawl lets your AI helper read whole websites as clean text, in one request.**
2. <img src="../assets/icons-phosphor/filter.svg" width="16" height="16" alt=""> It handles pages that need JavaScript and strips menus and cookie banners.
3. <img src="../assets/icons-phosphor/map.svg" width="16" height="16" alt=""> It can map every page of a site.
4. <img src="../assets/icons-phosphor/scan-search.svg" width="16" height="16" alt=""> It's how a foundation refreshes its own website copy or researches others.
5. <img src="../assets/icons-phosphor/link.svg" width="16" height="16" alt=""> **Connect it once in the helper you use.** The free tier covers ordinary use.

> **Handing this to your AI helper?** Say: *"Read CONNECT-FIRECRAWL.md and help me connect Firecrawl to
> you. Stop and ask me before anything that needs a login or a key."*

## <img src="../assets/icons-phosphor/bot.svg" width="24" height="24" alt=""> Pick your helper

<details open>
<summary><b>ChatGPT and Codex</b></summary>

1. Open Firecrawl's official plugin:
   <https://chatgpt.com/plugins/plugin_asdk_app_6a314a73f8ac819195b0d55e36b9c609?q=firecrawl>
2. Select **Connect** and sign in to Firecrawl (or create a free account).
3. In a chat, mention Firecrawl: *"Use Firecrawl to read https://example.org and summarise it."*

</details>

<details>
<summary><b>Claude (web and desktop)</b></summary>

1. Open the Firecrawl connector: <https://claude.ai/directory/connectors/firecrawl>
2. Select **Connect** and sign in to Firecrawl.
3. Ask: *"Use Firecrawl to map https://example.org and list its pages."*

</details>

<details>
<summary><b>Claude Code, Cursor and other code tools</b></summary>

Add Firecrawl's hosted server. It signs you in through your browser, so no key is stored in a file:

```json
{
  "mcpServers": {
    "firecrawl": {
      "type": "http",
      "url": "https://mcp.firecrawl.dev/v2/mcp-oauth"
    }
  }
}
```

**Claude Code:** user-level servers live in `~/.claude.json` under `"mcpServers"` (not in
`settings.json`). Restart Claude Code afterwards, then check `/mcp`.

**Prefer an API key?** Use `https://mcp.firecrawl.dev/v2/mcp` with your key as a bearer token, set in the
tool's own secure settings or environment. Never put it in a repository.

</details>

## <img src="../assets/icons-phosphor/message-square.svg" width="24" height="24" alt=""> What to ask once it's connected

- <img src="../assets/icons-phosphor/map.svg" width="16" height="16" alt=""> *"Map https://www.example.org and list every page with its title."*
- <img src="../assets/icons-phosphor/folder-lock.svg" width="16" height="16" alt=""> *"Crawl the site and save each page as markdown in `firecrawls/YYYY-MM-DD/`. That folder is private and
  never published."*
- <img src="../assets/icons-phosphor/history.svg" width="16" height="16" alt=""> *"Compare today's crawl with the last one and tell me what changed."*

## <img src="../assets/icons-phosphor/book-open.svg" width="24" height="24" alt=""> Good to know

- <img src="../assets/icons-phosphor/gift.svg" width="16" height="16" alt=""> **Free tier:** ample for a small site's refresh. A whole-site crawl of about 20 pages uses about 20
  credits. Firecrawl also offers limited **keyless** search and scrape for trying it out.
- <img src="../assets/icons-phosphor/key-round.svg" width="16" height="16" alt=""> **The key, if you use one, only reaches Firecrawl.** It can't touch your email, Drive or GitHub.
- <img src="../assets/icons-phosphor/folder-lock.svg" width="16" height="16" alt=""> **Research stays private:** crawls go in the repository's private `firecrawls/` folder. The tripwire
  stops them from ever reaching the published site.
- <img src="../assets/icons-phosphor/hand-heart.svg" width="16" height="16" alt=""> **Be a good neighbour:** crawl your own sites freely; for others', keep it occasional and respect their
  terms.

Official setup guide: <https://docs.firecrawl.dev/mcp-server>

## <img src="../assets/icons-phosphor/git-pull-request.svg" width="24" height="24" alt=""> Suggest a change

Noticed something wrong, or know a better way? Open an [issue](https://github.com/drasticstatic/my-template/issues) or a pull request against `main`; the lab steward reads them, and a person with the role merges with a merge commit so your name stays on it. Not on GitHub? Tell any steward you know, or your helper, in your own words.

<sub>One of the [walkthroughs](README.md) in `my-template`. Icons: Phosphor duotone (MIT).</sub>
