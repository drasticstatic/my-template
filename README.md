# my-template

> **Reusable repo scaffolding — ignore rules, agent guidance files, commit-attribution hooks, cross-agent coordination lanes, private→public sync workflows, deploy scripts, and branch protection rulesets.**

[![Use this template](https://img.shields.io/badge/Use_this_template-2ea44f?style=flat)](https://github.com/drasticstatic/my-template/generate)
[![License: MIT](https://img.shields.io/badge/license-MIT-lightgrey?style=flat)](https://github.com/drasticstatic/.github)

Click **Use this template** above (or the green button at the top of this page) to create a new repo pre-loaded with all scaffolding. Or copy individual files as needed.

---

## Two commands per clone

Everything else here is optional. These are not:

```sh
sh scripts/install-hooks.sh        # activate the commit-attribution hook
sh scripts/scaffold-agent-sync.sh  # create the right coordination lanes for this repo's visibility
```

Both write local or first-time state that cannot be committed on your behalf. Git deliberately
refuses to version-control hooks — a repo that shipped code which ran automatically on `git commit`
would be an attack vector — so a committed hook is inert until a human points the clone at it.

And at the **start of every session**, before reading deeply or editing:

```sh
git pull --rebase --autostash
```

Several agents and a human push to these repos, including unattended ones. A stale clone does not
fail early; it fails at push time as a non-fast-forward rejection, after the work is done, when the
tempting fix is a force-push that discards someone else's commit. `--autostash` makes this safe on a
dirty tree.

---

## ✅ New Repo Checklist

Don't skip this — it's the step that gets missed most often (see `anthropas-argus-alfred`, which shipped without it for months):

0. **Run the two commands above.** Then decide visibility *before* the first commit, because
   `AGENT-SYNC/` and `logs/` must never exist in a public repo and un-publishing is not a thing
   deletion can do — see [`AGENT-SYNC_PUBLIC/README.md`](./AGENT-SYNC_PUBLIC/README.md).
1. **License, security & contributors** — follow [`how-to-establish-cross_repo_CONTRIBUTORS_SECURITY_LICENSING.md`](https://github.com/drasticstatic/drasticstatic/blob/main/how-to-establish-cross_repo_CONTRIBUTORS_SECURITY_LICENSING.md) end to end: a real `LICENSE` file in every *public* repo (the global `.github` fallback covers `SECURITY.md`/`CONTRIBUTING.md`, but **not** `LICENSE` — that one is per-repo, always), an accurate README License section (especially if this repo has a private-source + public-preview pair — the same README gets copied to both, so word it so it's true in either context), and topics/description set via `gh repo edit`.
2. Fill in `CLAUDE.md` and `.github/dependabot.yml` for the new repo's stack.
3. Wire up the sync workflow (allowlist or excludelist) if this repo has a public-preview counterpart.
4. Run `./scripts/init-graphify.sh` from the new repo's root — deploys `.graphifyignore` and wires
   the Claude Code hook (both free/keyless). See `workflow-templates/GRAPHIFY_SETUP.md` for the
   pointer to the full guide and the keyed extraction step.

## What's Included

| File | Purpose |
|------|---------|
| `.gitignore` | Master ignore rules — secrets, OS files, build artifacts, Node, Python, Solidity, React/Vite |
| `.augmentignore` | Controls what Augment Code indexes — includes dependency context, excludes noise |
| `CLAUDE.md` | Claude Code CLI persistent instructions — fill in per-repo |
| `AGENTS.md` | Cross-harness agent instructions (Codex, Cursor, Copilot and others read this) — keep in step with `CLAUDE.md` |
| `.githooks/commit-msg` | Enforces the commit-attribution footer; inert until `scripts/install-hooks.sh` runs |
| `AGENT-SYNC/` | Cross-agent coordination lanes — **private repos only** |
| `AGENT-SYNC_PUBLIC/` | Coordination safe to publish — the only lane a public repo gets |
| `logs/` | Chronological session timeline — **private repos only**, no public counterpart exists |
| `scripts/install-hooks.sh` | Points this clone at `.githooks/` (one-time, per clone) |
| `scripts/scaffold-agent-sync.sh` | Detects repo visibility and creates the correct lanes |
| `.github/dependabot.yml` | Grouped Dependabot version updates — npm + GitHub Actions |
| `workflow-templates/sync-public-allowlist.yml` | Sync private → public via **allowlist** (strict — everything private by default) — copy to `.github/workflows/` in your repo |
| `workflow-templates/sync-public-excludelist.yml` | Sync private → public via **exclude list** (open — everything public except named paths) — copy to `.github/workflows/` in your repo |
| `gitexporter.config.json` | **Deprecated** — kept as a documentation manifest of what is public. Do not run it; the sync workflows own this now |
| `scripts/deployTest.sh` | Deploy a dated static snapshot of a Vite app to a new GitHub Pages repo |
| `scripts/syncDocs.sh` | Selectively rsync documentation from a private repo to a public docs repo |
| `scripts/init-graphify.sh` | Deploy `.graphifyignore` + install the Claude Code hook (keyless graphify setup) |
| `branch-protection/ruleset.json` | GitHub branch protection ruleset — prevents force-push and deletion on `main` |

---

## Workflow Patterns

### Sync to public repo — which model to use?

| Model | Use when | File |
|-------|----------|------|
| **Allowlist** | Most content is private; a small set is safe to publish | `sync-public-allowlist.yml` |
| **Exclude list** | Most content is public; a named set must stay private | `sync-public-excludelist.yml` |

Both use `git filter-repo --invert-paths` under the hood. The allowlist model adds a validation step that fails CI if an unclassified root-level path appears — forces an explicit privacy decision on every new file.

Whichever model a repo uses, **any new root-level entry must be classified in `sync-public.yml` in
the same commit that introduces it.** Under the allowlist model CI enforces this; under the exclude
list nothing will stop you, which is precisely why the habit has to be the same in both.

### gitexporter is deprecated

`gitexporter` was the original local path to a public preview. It is no longer used anywhere in this
fleet — **do not run `npx gitexporter`.** The GitHub Actions workflows own the pipeline end to end,
and a manual local export competing with them produces divergent history on the mirror.

`gitexporter.config.json` is retained deliberately, as a readable manifest of which paths are
intended to be public. Treat it as documentation, not as a tool.

---

## Making Your Own Repo a Template

Once you've customised this scaffolding for your own use, you can share it the same way — mark your repo as a GitHub Template Repository so others get the green **"Use this template"** button too.

**Via GitHub CLI (one command):**
```bash
gh api repos/YOUR_USERNAME/YOUR_REPO --method PATCH --field is_template=true
```

**Via UI:** Repo → Settings → General → check **Template repository**

Then add this badge to your README (swap in your own repo URL):
```markdown
[![Use this template](https://img.shields.io/badge/Use_this_template-2ea44f?style=flat)](https://github.com/YOUR_USERNAME/YOUR_REPO/generate)
```

The `/generate` path takes visitors directly to the "create repo from template" screen — useful to link from docs, READMEs, or share with peers.

---

## Agent coordination and commit attribution

Every commit in this fleet carries a footer naming the agent, the harness, who ran the weights, and
which model:

```
Co-Authored-By: <Agent> · <Engine> · <Provider> [<Model>]                  # direct
Co-Authored-By: <Agent> · <Engine> · <Gateway> · <Provider> [<Model>]      # proxied
<Platform>-Session: <full session URL>
```

The reason is narrow and practical: when a commit later turns out to be subtly wrong, the first
useful question is which model produced it, and a footer that flattens every route into `Anthropic`
destroys that signal *silently*, because the line still reads correctly.

**[`AGENT-SYNC/README.md`](./AGENT-SYNC/README.md) is the single source of truth** for the field
definitions, the engine roster, and the coordination-lane convention. It is deliberately the only
copy — an earlier second copy in `scripts/README.md` went stale and spent a release teaching the
wrong thing. If you need to state the convention somewhere, link it instead.

---

## Related How-To Guides

Full setup walkthroughs live in the [`drasticstatic` profile repo](https://github.com/drasticstatic/drasticstatic):

- [`how-to-setup-GITEXPORTER.md`](https://github.com/drasticstatic/drasticstatic/blob/main/how-to-setup-GITEXPORTER.md) — GitExporter + sync-public.yml full pipeline
- [`how-to-establish-a-github-PROFILE-README.md`](https://github.com/drasticstatic/drasticstatic/blob/main/how-to-establish-a-github-PROFILE-README.md) — Profile README setup
- [`how-to-establish-cross_repo_CONTRIBUTORS_SECURITY_LICENSING.md`](https://github.com/drasticstatic/drasticstatic/blob/main/how-to-establish-cross_repo_CONTRIBUTORS_SECURITY_LICENSING.md) — Community health files at scale
- [`how-to-publish-react-APPS-to-ghPAGES.md`](https://github.com/drasticstatic/drasticstatic/blob/main/how-to-publish-react-APPS-to-ghPAGES.md) — CRA and Vite apps to GitHub Pages
- [`how-to-setup-BRANCH-PROTECTION-and-TOPICS.md`](https://github.com/drasticstatic/drasticstatic/blob/main/how-to-setup-BRANCH-PROTECTION-and-TOPICS.md) — Branch protection rulesets and GitHub topics via `gh api`

---

*Maintained by [drasticstatic](https://github.com/drasticstatic)*
