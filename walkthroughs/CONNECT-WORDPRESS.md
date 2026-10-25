# 📝 Connect WordPress *(groundwork)*

**TL;DR:** WordPress's official **MCP Adapter** lets AI helpers use a site's abilities (posts, pages,
media, plugins that opt in) through the open MCP standard.
- **Your helper signs in as a WordPress user**, with an *application password* you create for it. That
  keeps it to what that user may do, and you can revoke it any time.
- This page is groundwork. The team that runs a WordPress site finishes it for that site.

> **Status:** groundwork, 2026-10-25. The PIR session owns the first real WordPress connection and will
> complete this guide from that experience.

## How it fits together

1. **On the WordPress site:** install the MCP Adapter, which turns the site's abilities into MCP tools.
2. **Create a WordPress user for the helper** with only the role it needs (an *Editor* to draft posts,
   say, not an Administrator). Then create an **application password** for that user: **Users → Profile →
   Application Passwords**.
3. **In your helper's tool:** add the server with Automattic's remote bridge:

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

- The application password goes into the tool's own config on your computer. **Never into a
  repository, a chat or a document.**
- Revoke it from the same WordPress screen whenever you like.

## Good first requests

- *"List the ten most recent posts and their status."*
- *"Draft a post from this outline and save it as a draft. Don't publish."*
- *"Which pages mention our old address?"*

## Safety

- **The helper's user is the boundary.** Give it the smallest role that does the job. Drafts, not
  publishing, to begin with.
- **Keep a person on the publish button**, the same "rehearse first" spirit as the GitHub sites.

Official guide:
[Introducing the WordPress MCP Adapter](https://developer.wordpress.org/news/2026/02/from-abilities-to-ai-agents-introducing-the-wordpress-mcp-adapter/)
· Source: [github.com/WordPress/mcp-adapter](https://github.com/WordPress/mcp-adapter)
