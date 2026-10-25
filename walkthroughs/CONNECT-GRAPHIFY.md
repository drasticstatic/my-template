# 🕸️ Connect Graphify

**TL;DR:** Graphify builds a **map of a codebase**: what each part does, what connects to what, and the
few central pieces everything leans on.
- Your helper reads the map first, so it understands a project quickly and reads far fewer files.
- **For a team, this is shared memory.** Every helper and every person starts from the same picture.

> **Handing this to your AI helper?** Say: *"Read CONNECT-GRAPHIFY.md. Is there a `graphify-out/` folder
> here? If so, read its GRAPH_REPORT.md before anything else."*

## Using a map that already exists

If a repository has `graphify-out/GRAPH_REPORT.md`, your helper should read it **before** searching the
code. Ask it questions in plain words:
- *"Using the graph, how does the language switch reach the Spanish text?"*
- *"What are the central pieces of this site, and what depends on them?"*

The interactive picture, `graphify-out/graph.html`, opens in any browser.

## Making or refreshing a map

This is for whoever looks after the machinery.

```bash
# once per computer (the package name has a double y)
uv tool install graphifyy --with anthropic --with openai

# in the repository
graphify extract .         # builds the graph
graphify cluster-only .    # writes GRAPH_REPORT.md (no AI calls)
graphify claude install    # Claude Code reads the report before it searches
```

- **Keep it focused:** add a `.graphifyignore`. The base template lives in this repository's root; add
  the project's private folders to it so research and notes never enter the map.
- **Keep it private:**
  - `graphify-out/` lives in the **private** workshop repository.
  - A website's tripwire stops it from ever being published.
  - `manifest.json` and `cost.json` stay out of git.
- **After big changes:** `graphify update .` refreshes the map from the code itself, with no AI cost.

## Why it matters for an organization

When several people and several AI helpers share a project, the hardest thing is shared understanding.
A graph gives everyone the same map:
- **New contributors:** start oriented.
- **Helpers:** spend their effort on the change, not on rediscovering the project.
- **The future help desk:** has a reliable map to answer from.

The full evaluation, including the security review:
[GRAPHIFY_SETUP.md](https://github.com/drasticstatic/anthropas-argus-alfred-public-preview/blob/main/sandbox/GRAPHIFY_SETUP.md).
