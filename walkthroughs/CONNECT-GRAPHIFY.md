<div align="center">

<img src="../assets/icons-phosphor/network.svg" width="56" height="56" alt="">

# Connect Graphify

*Give your helper a map of a codebase, so it reads less and understands more.*

![Kind](https://img.shields.io/badge/Kind-Walkthrough-800020?style=flat-square)
![Changed](https://img.shields.io/badge/Changed-2026--11--04-800020?style=flat-square)
![For](https://img.shields.io/badge/For-Teams_sharing_a_codebase_with_helpers-800020?style=flat-square)

<img src="../assets/icons-phosphor/map-pin.svg" width="16" height="16" alt=""> **You are here:** drasticstatic lab › [`my-template`](../README.md) › [`walkthroughs`](README.md) › `CONNECT-GRAPHIFY.md` · public · `main` is the working branch

</div>

## <img src="../assets/icons-phosphor/compass.svg" width="24" height="24" alt=""> TL;DR

1. <img src="../assets/icons-phosphor/network.svg" width="16" height="16" alt=""> **Graphify builds a map of a codebase:** what each part does, what connects to what, and the
   few central pieces everything leans on.
2. <img src="../assets/icons-phosphor/map.svg" width="16" height="16" alt=""> Your helper reads the map first, so it understands a project quickly and reads far fewer files.
3. <img src="../assets/icons-phosphor/users-round.svg" width="16" height="16" alt=""> **For a team, this is shared memory.** Every helper and every person starts from the same picture.

> **Handing this to your AI helper?** Say: *"Read CONNECT-GRAPHIFY.md. Is there a `graphify-out/` folder
> here? If so, read its GRAPH_REPORT.md before anything else."*

## <img src="../assets/icons-phosphor/map.svg" width="24" height="24" alt=""> Using a map that already exists

If a repository has `graphify-out/GRAPH_REPORT.md`, your helper should read it **before** searching the
code. Ask it questions in plain words:
- <img src="../assets/icons-phosphor/languages.svg" width="16" height="16" alt=""> *"Using the graph, how does the language switch reach the Spanish text?"*
- <img src="../assets/icons-phosphor/layers.svg" width="16" height="16" alt=""> *"What are the central pieces of this site, and what depends on them?"*

The interactive picture, `graphify-out/graph.html`, opens in any browser.

## <img src="../assets/icons-phosphor/wrench.svg" width="24" height="24" alt=""> Making or refreshing a map

This is for whoever looks after the machinery.

```bash
# once per computer (the package name has a double y)
uv tool install graphifyy --with anthropic --with openai

# in the repository
graphify extract .         # builds the graph
graphify cluster-only .    # writes GRAPH_REPORT.md (no AI calls)
graphify claude install    # Claude Code reads the report before it searches
```

- <img src="../assets/icons-phosphor/filter.svg" width="16" height="16" alt=""> **Keep it focused:** add a `.graphifyignore`. The base template lives in this repository's root; add
  the project's private folders to it so research and notes never enter the map.
- <img src="../assets/icons-phosphor/folder-lock.svg" width="16" height="16" alt=""> **Keep it private:**
  - `graphify-out/` lives in the **private** workshop repository.
  - A website's tripwire stops it from ever being published.
  - `manifest.json` and `cost.json` stay out of git.
- <img src="../assets/icons-phosphor/history.svg" width="16" height="16" alt=""> **After big changes:** `graphify update .` refreshes the map from the code itself, with no AI cost.

## <img src="../assets/icons-phosphor/building-2.svg" width="24" height="24" alt=""> Why it matters for an organization

When several people and several AI helpers share a project, the hardest thing is shared understanding.
A graph gives everyone the same map:
- <img src="../assets/icons-phosphor/user-plus.svg" width="16" height="16" alt=""> **New contributors:** start oriented.
- <img src="../assets/icons-phosphor/bot.svg" width="16" height="16" alt=""> **Helpers:** spend their effort on the change, not on rediscovering the project.
- <img src="../assets/icons-phosphor/message-circle-question.svg" width="16" height="16" alt=""> **The future help desk:** has a reliable map to answer from.

The full evaluation, including the security review:
[GRAPHIFY_SETUP.md](https://github.com/drasticstatic/anthropas-argus-alfred-public-preview/blob/main/sandbox/GRAPHIFY_SETUP.md).

## <img src="../assets/icons-phosphor/git-pull-request.svg" width="24" height="24" alt=""> Suggest a change

Noticed something wrong, or know a better way? Open an [issue](https://github.com/drasticstatic/my-template/issues) or a pull request against `main`; the lab steward reads them, and a person with the role merges with a merge commit so your name stays on it. Not on GitHub? Tell any steward you know, or your helper, in your own words.

<sub>One of the [walkthroughs](README.md) in `my-template`. Icons: Phosphor duotone (MIT).</sub>
