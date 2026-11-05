<div align="center">

<img src="../sop-template/repo/assets/icons/notebook-pen.svg" width="56" height="56" alt="">

# Connect WordPress *(groundwork)*

*Let your helper read and draft on a WordPress site, signed in as a user you can revoke at any time.*

![Kind](https://img.shields.io/badge/Kind-Walkthrough_(groundwork)-d9a441?style=flat-square)
![Changed](https://img.shields.io/badge/Changed-2026--11--04-d9a441?style=flat-square)
![For](https://img.shields.io/badge/For-The_team_that_runs_a_WordPress_site-d9a441?style=flat-square)

<img src="../sop-template/repo/assets/icons/map-pin.svg" width="16" height="16" alt=""> **You are here:** drasticstatic lab › [`my-template`](../README.md) › [`walkthroughs`](README.md) › `CONNECT-WORDPRESS.md` · public · `main` is the working branch

</div>

## <img src="../sop-template/repo/assets/icons/compass.svg" width="24" height="24" alt=""> TL;DR

1. <img src="../sop-template/repo/assets/icons/notebook-pen.svg" width="16" height="16" alt=""> **WordPress's official MCP Adapter lets AI helpers use a site's abilities** (posts, pages,
   media, plugins that opt in) through the open MCP standard.
2. <img src="../sop-template/repo/assets/icons/key-round.svg" width="16" height="16" alt=""> **Your helper signs in as a WordPress user**, with an *application password* you create for it. That
   keeps it to what that user may do, and you can revoke it any time.
3. <img src="../sop-template/repo/assets/icons/circle-dashed.svg" width="16" height="16" alt=""> This page is groundwork. The team that runs a WordPress site finishes it for that site.

> **Status:** groundwork, 2026-10-25. The PIR session owns the first real WordPress connection and will
> complete this guide from that experience.

## <img src="../sop-template/repo/assets/icons/workflow.svg" width="24" height="24" alt=""> How it fits together

1. <img src="../sop-template/repo/assets/icons/globe.svg" width="16" height="16" alt=""> **On the WordPress site:** install the MCP Adapter, which turns the site's abilities into MCP tools.
2. <img src="../sop-template/repo/assets/icons/user-plus.svg" width="16" height="16" alt=""> **Create a WordPress user for the helper** with only the role it needs (an *Editor* to draft posts,
   say, not an Administrator). Then create an **application password** for that user: **Users → Profile →
   Application Passwords**.
3. <img src="../sop-template/repo/assets/icons/link.svg" width="16" height="16" alt=""> **In your helper's tool:** add the server with Automattic's remote bridge:

```json
{
  "mcpServers": {
    "wordpress-mcp-server": {
      "command": "npx",
      "args": ["-y", "@automattic/mcp-wordpress-remote@latest"],
      "env": {
        "WP_API_URL": "https://yoursite.example/wp-json/mcp/mcp-adapter-default-server",
        "WP_API_USERNAME": "<the helper's user>",
        "WP_API_PASSWORD": "<its application password>"
      }
    }
  }
}
```

- <img src="../sop-template/repo/assets/icons/key-round.svg" width="16" height="16" alt=""> The application password goes into the tool's own config on your computer. **Never into a
  repository, a chat or a document.**
- <img src="../sop-template/repo/assets/icons/trash-2.svg" width="16" height="16" alt=""> Revoke it from the same WordPress screen whenever you like.

## <img src="../sop-template/repo/assets/icons/message-square.svg" width="24" height="24" alt=""> Good first requests

- <img src="../sop-template/repo/assets/icons/list-checks.svg" width="16" height="16" alt=""> *"List the ten most recent posts and their status."*
- <img src="../sop-template/repo/assets/icons/pencil-line.svg" width="16" height="16" alt=""> *"Draft a post from this outline and save it as a draft. Don't publish."*
- <img src="../sop-template/repo/assets/icons/search.svg" width="16" height="16" alt=""> *"Which pages mention our old address?"*

## <img src="../sop-template/repo/assets/icons/shield-check.svg" width="24" height="24" alt=""> Safety

- <img src="../sop-template/repo/assets/icons/user-round.svg" width="16" height="16" alt=""> **The helper's user is the boundary.** Give it the smallest role that does the job. Drafts, not
  publishing, to begin with.
- <img src="../sop-template/repo/assets/icons/hand-helping.svg" width="16" height="16" alt=""> **Keep a person on the publish button**, the same "rehearse first" spirit as the GitHub sites.

Official guide:
[Introducing the WordPress MCP Adapter](https://developer.wordpress.org/news/2026/02/from-abilities-to-ai-agents-introducing-the-wordpress-mcp-adapter/)
· Source: [github.com/WordPress/mcp-adapter](https://github.com/WordPress/mcp-adapter)

## <img src="../sop-template/repo/assets/icons/git-pull-request.svg" width="24" height="24" alt=""> Suggest a change

Noticed something wrong, or know a better way? Open an [issue](https://github.com/drasticstatic/my-template/issues) or a pull request against `main`; the lab steward reads them, and a person with the role merges with a merge commit so your name stays on it. Not on GitHub? Tell any steward you know, or your helper, in your own words.

<sub>One of the [walkthroughs](README.md) in `my-template`. Icons: Lucide (ISC).</sub>
