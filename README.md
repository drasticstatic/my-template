# my-template

> **Reusable repo scaffolding — `.gitignore`, `.augmentignore`, `CLAUDE.md`, sync workflows, gitexporter config, deploy scripts, and branch protection rulesets.**

[![Use this template](https://img.shields.io/badge/Use_this_template-2ea44f?style=flat)](https://github.com/drasticstatic/my-template/generate)
[![License: MIT](https://img.shields.io/badge/license-MIT-lightgrey?style=flat)](https://github.com/drasticstatic/.github)

Click **Use this template** above (or the green button at the top of this page) to create a new repo pre-loaded with all scaffolding. Or copy individual files as needed.

---

## ✅ New Repo Checklist

Don't skip this — it's the step that gets missed most often (see `anthropas-argus-alfred`, which shipped without it for months):

1. **License, security & contributors** — follow [`how-to-establish-cross_repo_CONTRIBUTORS_SECURITY_LICENSING.md`](https://github.com/drasticstatic/drasticstatic/blob/main/how-to-establish-cross_repo_CONTRIBUTORS_SECURITY_LICENSING.md) end to end: a real `LICENSE` file in every *public* repo (the global `.github` fallback covers `SECURITY.md`/`CONTRIBUTING.md`, but **not** `LICENSE` — that one is per-repo, always), an accurate README License section (especially if this repo has a private-source + public-preview pair — the same README gets copied to both, so word it so it's true in either context), and topics/description set via `gh repo edit`.
2. Fill in `CLAUDE.md` and `.github/dependabot.yml` for the new repo's stack.
3. Wire up the sync workflow (allowlist or excludelist) if this repo has a public-preview counterpart.

## What's Included

| File | Purpose |
|------|---------|
| `.gitignore` | Master ignore rules — secrets, OS files, build artifacts, Node, Python, Solidity, React/Vite |
| `.augmentignore` | Controls what Augment Code indexes — includes dependency context, excludes noise |
| `CLAUDE.md` | Stub for Claude Code CLI persistent instructions — fill in per-repo |
| `.github/dependabot.yml` | Grouped Dependabot version updates — npm + GitHub Actions |
| `workflow-templates/sync-public-allowlist.yml` | Sync private → public via **allowlist** (strict — everything private by default) — copy to `.github/workflows/` in your repo |
| `workflow-templates/sync-public-excludelist.yml` | Sync private → public via **exclude list** (open — everything public except named paths) — copy to `.github/workflows/` in your repo |
| `gitexporter.config.json` | Local gitexporter config — selective commit-history-preserving public preview |
| `scripts/deployTest.sh` | Deploy a dated static snapshot of a Vite app to a new GitHub Pages repo |
| `scripts/syncDocs.sh` | Selectively rsync documentation from a private repo to a public docs repo |
| `branch-protection/ruleset.json` | GitHub branch protection ruleset — prevents force-push and deletion on `main` |

---

## Workflow Patterns

### Sync to public repo — which model to use?

| Model | Use when | File |
|-------|----------|------|
| **Allowlist** | Most content is private; a small set is safe to publish | `sync-public-allowlist.yml` |
| **Exclude list** | Most content is public; a named set must stay private | `sync-public-excludelist.yml` |

Both use `git filter-repo --invert-paths` under the hood. The allowlist model adds a validation step that fails CI if an unclassified root-level path appears — forces an explicit privacy decision on every new file.

### gitexporter vs sync-public.yml

| Tool | Mechanism | History |
|------|-----------|---------|
| `sync-public.yml` (GitHub Actions) | Runs on push, rewrites and force-pushes to public repo | Preserved via filter-repo |
| `gitexporter` | Local CLI tool, run manually | Preserved — traverses full commit tree |

Use `sync-public.yml` for automated continuous sync. Use `gitexporter` for a one-time or on-demand local preview before the workflow is set up.

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

## Related How-To Guides

Full setup walkthroughs live in the [`drasticstatic` profile repo](https://github.com/drasticstatic/drasticstatic):

- [`how-to-setup-GITEXPORTER.md`](https://github.com/drasticstatic/drasticstatic/blob/main/how-to-setup-GITEXPORTER.md) — GitExporter + sync-public.yml full pipeline
- [`how-to-establish-a-github-PROFILE-README.md`](https://github.com/drasticstatic/drasticstatic/blob/main/how-to-establish-a-github-PROFILE-README.md) — Profile README setup
- [`how-to-establish-cross_repo_CONTRIBUTORS_SECURITY_LICENSING.md`](https://github.com/drasticstatic/drasticstatic/blob/main/how-to-establish-cross_repo_CONTRIBUTORS_SECURITY_LICENSING.md) — Community health files at scale
- [`how-to-publish-react-APPS-to-ghPAGES.md`](https://github.com/drasticstatic/drasticstatic/blob/main/how-to-publish-react-APPS-to-ghPAGES.md) — CRA and Vite apps to GitHub Pages
- [`how-to-setup-BRANCH-PROTECTION-and-TOPICS.md`](https://github.com/drasticstatic/drasticstatic/blob/main/how-to-setup-BRANCH-PROTECTION-and-TOPICS.md) — Branch protection rulesets and GitHub topics via `gh api`

---

*Maintained by [drasticstatic](https://github.com/drasticstatic)*
