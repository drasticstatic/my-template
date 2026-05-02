# my-template

> **Reusable repo scaffolding — `.gitignore`, `.augmentignore`, `CLAUDE.md`, sync workflows, gitexporter config, deploy scripts, and branch protection.**

[![License: MIT](https://img.shields.io/badge/license-MIT-lightgrey?style=flat-square)](LICENSE)

Use the **"Use this template"** button to create a new repo pre-loaded with this scaffolding, or copy individual files as needed.

---

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

## Related How-To Guides

Full setup walkthroughs live in the [`drasticstatic` profile repo](https://github.com/drasticstatic/drasticstatic):

- [`how-to-setup-GITEXPORTER.md`](https://github.com/drasticstatic/drasticstatic/blob/main/how-to-setup-GITEXPORTER.md) — GitExporter + sync-public.yml full pipeline
- [`how-to-establish-a-github-PROFILE-README.md`](https://github.com/drasticstatic/drasticstatic/blob/main/how-to-establish-a-github-PROFILE-README.md) — Profile README setup
- [`how-to-establish-cross_repo_CONTRIBUTORS_SECURITY_LICENSING.md`](https://github.com/drasticstatic/drasticstatic/blob/main/how-to-establish-cross_repo_CONTRIBUTORS_SECURITY_LICENSING.md) — Community health files at scale
- [`how-to-publish-react-apps-to-ghpages.md`](https://github.com/drasticstatic/drasticstatic/blob/main/how-to-publish-react-apps-to-ghpages.md) — CRA and Vite apps to GitHub Pages

---

*Maintained by [drasticstatic](https://github.com/drasticstatic)*
