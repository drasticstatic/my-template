# .claude/settings.local.json — How It Works

This file is **auto-managed by Claude Code**. You do not normally hand-edit it.

---

## What It Is

`settings.local.json` stores per-project tool permissions for Claude Code. When Claude asks
to run a command and you click **"Always allow"**, Claude Code appends that permission to
this file. It accumulates over time — one entry per approved action.

**Location:** `.claude/settings.local.json` in the repo root.

---

## Format

```json
{
  "permissions": {
    "allow": [
      "Bash(git commit:*)",
      "Bash(python3:*)",
      "Read(//Users/yourname/code/**)",
      "mcp__toolname__action",
      "WebFetch(domain:example.com)"
    ]
  }
}
```

### Permission types

| Pattern | What it covers |
|---------|---------------|
| `Bash(command:*)` | Any invocation of `command` with any arguments |
| `Bash(exact command string)` | Only that exact command — added by one-off "Always allow" clicks |
| `Read(//path/**)` | Read access to any file under that path |
| `mcp__server__tool` | A specific MCP tool action |
| `WebFetch(domain:host.com)` | Fetch requests to that domain |

### Wildcards vs. specific strings

- **Wildcard** (`Bash(git commit:*)`) — covers all invocations, added manually or via housekeeping
- **Exact string** (`Bash(git commit -m "Add feature")`) — added by "Always allow" on a specific run

Over time, one-off exact strings accumulate. Periodically consolidate them into wildcards
covering the same scope — same permissions, much shorter file.

---

## Bootstrapping a New Repo

Rather than starting from zero and clicking "Always allow" for everything, seed the file
with the generic permissions your project will need:

```json
{
  "permissions": {
    "allow": [
      "Bash(python3:*)",
      "Bash(ls:*)",
      "Bash(find:*)",
      "Bash(sort:*)",
      "Bash(curl:*)",
      "Bash(cp:*)",
      "Bash(bash:*)",
      "Bash(git --version:*)",
      "Bash(git add:*)",
      "Bash(git commit:*)",
      "Bash(git push:*)",
      "Bash(git pull:*)",
      "Bash(git rm:*)",
      "Bash(git mv:*)",
      "Bash(git status:*)",
      "Bash(git log:*)",
      "Bash(git diff:*)",
      "Bash(git checkout:*)",
      "Bash(git -C *)",
      "Bash(gh:*)",
      "Bash(uv --version)",
      "Bash(uv sync:*)",
      "Bash(uv python *)",
      "Read(//Users/yourname/.claude/**)",
      "Read(//Users/yourname/code/**)"
    ]
  }
}
```

Then add repo-specific entries below — MCP tools, WebFetch domains, aliases — as you wire
them up.

---

## Privacy & Public Preview

`settings.local.json` is **project-local** — it contains paths and tool names specific to
your machine setup. It should almost never be fully public. In this ecosystem:

- **gitexporter**: exclude `".claude/settings.local.json"` specifically, not the entire `".claude/"` dir
  — this lets `.claude/skills/` be public while keeping permissions private
- **`.gitignore`**: leave tracked (so agents share the approved list across sessions),
  or gitignore if the repo is fully public and you don't want machine-specific paths committed

```json
{
  "ignoredPaths": [
    ".claude/settings.local.json",
    ".claude/memory/",
    ".claude/projects/"
  ]
}
```

Do NOT add `.claude/` as a blanket exclusion — that also hides the skills folder, which
is valuable to share publicly.

---

## When to Prune

Prune the file when:
- Many one-off exact strings reference paths that no longer exist (e.g. after moving a repo)
- The file has grown to 100+ entries and is hard to read
- You want to audit what permissions have accumulated

Replace clusters of specific strings with a single wildcard that covers them. The scope
should be equivalent or broader — never narrower.

---

## Reference

- Claude Code permission docs: `claude mcp --help`
- This ecosystem's live examples:
  - `trading-assistant/.claude/settings.local.json` — MCP-heavy (tradovate, tradingview, robinhood)
  - `anthropas-argus-alfred/.claude/settings.local.json` — lean, coordinator pattern
  - `divorce-custody-assistant/.claude/settings.local.json` — gwsdc alias + git ops
  - `pir-devine-news/.claude/settings.local.json` — gwspdn alias + WebFetch domains
