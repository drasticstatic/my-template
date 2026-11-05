<div align="center">

<img src="../assets/icons-phosphor/brain-circuit.svg" width="56" height="56" alt="">

# Ultra runs: ultracode and ultrareview, spent well

*Claude Code has two "go big" modes, and they're easy to mix up.*

![Kind](https://img.shields.io/badge/Kind-Pattern-800020?style=flat-square)
![Changed](https://img.shields.io/badge/Changed-2026--11--04-800020?style=flat-square)
![For](https://img.shields.io/badge/For-Anyone_with_three_free_runs_to_spend-800020?style=flat-square)

<img src="../assets/icons-phosphor/map-pin.svg" width="16" height="16" alt=""> **You are here:** drasticstatic lab › [`my-template`](../README.md) › [`walkthroughs`](README.md) › `ULTRA-RUNS.md` · public · `main` is the working branch

</div>

## <img src="../assets/icons-phosphor/compass.svg" width="24" height="24" alt=""> TL;DR

1. <img src="../assets/icons-phosphor/network.svg" width="16" height="16" alt=""> **Ultracode** makes your helper run *every* substantive task as a team of agents. It's a switch, it uses your
   plan's usage, and it has no free runs.
2. <img src="../assets/icons-phosphor/scan-search.svg" width="16" height="16" alt=""> **Ultrareview** sends a team of reviewers into the cloud to find and double-check bugs. It never edits code.
   Pro and Max accounts get **three free runs, once, ever**.
3. <img src="../assets/icons-phosphor/triangle-alert.svg" width="16" height="16" alt=""> **The trap:** ultrareview reviews the *difference* between your branch and `main`. If all the work is already
   on `main`, that difference is empty and the free run is gone. Stage a review first (below).

> **Handing this to your AI helper?** Say: *"Read ULTRA-RUNS.md. Help me stage a review for <repo> and tell me
> when it's ready. Don't start the review yourself."* (Helpers can't start an ultrareview; you do.)

## <img src="../assets/icons-phosphor/network.svg" width="24" height="24" alt=""> Ultracode

| | |
|---|---|
| Turn on | `/effort ultracode` (or in the `/effort` slider, press `Tab` to flip **Ultracode**, then `Enter`) |
| Turn off | `/effort ultracode off` |
| Effort | Works at whatever effort is set. Set it first (e.g. `/effort high`). `claude --effort ultracode` also sets `xhigh`. |
| Cost | Draws on your plan's usage limits; you'll reach session and weekly limits sooner. |
| Good for | Deep reconnaissance across many repos, audits, migrations, big polish passes. |

**Before you turn it on:**
1. <img src="../assets/icons-phosphor/git-branch.svg" width="16" height="16" alt=""> Everything committed and pushed; every repo you'll touch is synced.
2. <img src="../assets/icons-phosphor/book-marked.svg" width="16" height="16" alt=""> The repo has a `CLAUDE.md` with its rules. Every agent the run starts reads it, so this is where the rules
   that must never break go.
3. <img src="../assets/icons-phosphor/notebook-pen.svg" width="16" height="16" alt=""> A written brief: what to look at, what "done" means, what's out of scope.
4. <img src="../assets/icons-phosphor/link.svg" width="16" height="16" alt=""> Connected tools (MCP servers, the browser extension) signed in **before** the run, not during it.
5. <img src="../assets/icons-phosphor/eye.svg" width="16" height="16" alt=""> Approve edits by hand until you're ready, so the switch doesn't flip early.

### <img src="../assets/icons-phosphor/user-round.svg" width="20" height="20" alt=""> Who publishes: the main session, not the agents

**Publishing and repository creation run in the main session; subagents prepare.** In a multi-agent run, the
safety classifier refuses `gh repo create` (and can refuse a first push to a new public repository) when a
background agent attempts it, even where `~/.claude/settings.json` allows the command. Plan for it:

| Agents do | The main session does, with the person approving each prompt |
|---|---|
| write, commit and push to repositories that already exist; open pull requests | `gh repo create`, a repository's first public push, enabling Pages |
| stage a new repository in a scratch folder, with its commits and a `CREATE-AND-PUSH.sh` | run that script, then move the clone to its home |
| list the exact commands they could not run (`main_session_steps`) | run them in small batches and read each result back |
| prepare deploy-key and ruleset commands | generate keys, add deploy keys, set secrets, apply rulesets |

A run that ignores this ends with work that is staged but not live, and a list of refusals to replay by hand.
Write the brief so each agent returns its unfinished steps as exact commands.

## <img src="../assets/icons-phosphor/scan-search.svg" width="24" height="24" alt=""> Ultrareview

| | |
|---|---|
| Start | `/code-review ultra` (your branch vs `main`) or `/code-review ultra <PR number>` (a GitHub pull request) |
| Time | About 15–25 minutes, in the cloud |
| Free runs | Three, one-time per account. **A run you stop early, or that fails, still uses one.** |
| Output | Verified findings in your session. It doesn't change code. Add `--post` on a PR to post them there. |

### <img src="../assets/icons-phosphor/git-pull-request.svg" width="20" height="20" alt=""> Stage a review so the run sees the code

When the work is already on `main`, give the review a base that doesn't have the code yet:

```sh
git switch -c review/code-baseline main
git rm -r -q <the code folders to review>               # e.g. src/ scripts/ tests/ .github/ (main brings them back)
git commit -m "review baseline: main without the code under review (never merge)"
git push -u origin review/code-baseline
git switch main
gh pr create --draft --base review/code-baseline --head main \
  --title "Ultrareview target: <what> (do not merge)" --body "Review-only PR. Diff = the code under review."
gh pr diff <number> --name-only | wc -l                   # not zero, and only the files you meant
```

Then `/code-review ultra <number>`. The PR follows `main`, so it stays a valid review target as work lands.
Keep lockfiles, images and generated files in the baseline so the reviewers spend their attention on code.

### <img src="../assets/icons-phosphor/filter.svg" width="20" height="20" alt=""> Choosing what to spend the three on

Spend them on code that is **large, live, and hard to test by hand**: a site people use, contract or payment code,
CI that publishes. A good order is: recon first (what is where, and what's risky), then stage a PR per target,
then run the reviews one at a time and fix each one's findings before the next.

## <img src="../assets/icons-phosphor/git-pull-request.svg" width="24" height="24" alt=""> Suggest a change

Noticed something? Open an [issue](https://github.com/drasticstatic/my-template/issues) or a pull request against `main`,
changing this page; a steward reads it and a person with the role merges, with a merge commit, so your name stays on it.
An AI helper may do all of that up to the merge, signed as [the attribution spec](../AGENT-SYNC/README.md) says.
Not on GitHub? Tell any steward you know, or your helper, in your own words.

<sub>Plan limits, free-run counts and what a run costs are Anthropic's to set and change; check their own pages before relying on a number here. This is a description of how the modes behaved when written, not advice on what to spend. Part of the [walkthroughs](README.md). Icons: Phosphor duotone (MIT).</sub>
