---
name: gitexporter-actions-replacement
description: Actions-based sync pipeline replacing broken gitexporter/nodegit — proven pattern, pitfalls, and the dpnelson reference
metadata:
  type: reference
---

# GitExporter → GitHub Actions Sync Pipeline

### Replacing the broken nodegit/gitexporter pipeline with a pure-GitHub-Actions alternative

*Proven working: iamoneself, findyourfeathers (2026-06-17)*
*Reference: dpnelson (working since earlier)*
*Template doc: /Users/christopherwilson/code/my-template/GITEXPORTER-TO-ACTIONS-SYNC.md*

---

## The Problem

`gitexporter` depends on `nodegit` (a native C binding for libgit2). As of 2026, nodegit fails to compile on modern macOS/Node because:

1. **`cmake` not installed** by default on macOS (needs `brew install cmake`)
2. Even with cmake, the node-gyp build chain for nodegit is fragile — breaks across Node 20/22/23
3. This blocks **all repos** in the ecosystem from syncing private → public preview
4. The failure is **silent** — gitexporter exits with code 1 and no output, making it hard to diagnose

### Discovery journey

- Initially tried Node 22 → nodegit build failed silently
- Switched to Node 20 via nvm → same silent failure
- Tried installing nodegit globally (`npm install -g nodegit@0.28.0-alpha.38`) → still failed
- Investigated build logs: missing `cmake` on macOS, plus node-pre-gyp deprecation cascade
- Realized ALL public preview repos across the ecosystem were stale (anthropas-argus-alfred-public-preview included)
- Discovered dpnelson's `sync-public.yml` already solved this — it doesn't use gitexporter at all, just a GitHub Action with git clone + cp + push

---

## The Solution

Two-workflow pipeline, no native deps:

```
┌─────────────────────┐         ┌──────────────────────────┐
│   Private Repo      │         │   Public Preview Repo    │
│   (source + secrets)│         │   (GitHub Pages host)   │
│                     │         │                          │
│  sync-public.yml    │ ──────► │  deploy.yml              │
│  (on push to main)  │  push   │  (on push to main)       │
│                     │  source │                          │
│  1. Clones public   │  files  │  1. npm ci + build       │
│  2. cp source files │         │  2. deploy ./out → Pages  │
│  3. pushes to public│         │                          │
└─────────────────────┘         └──────────────────────────┘
```

### Why This Works

- **No native dependencies** — pure shell + git, runs on GitHub's ubuntu-latest
- **Selective cp** — explicit list of what gets copied (denylist by omission, not by filter)
- **Automatic on every push** — no manual gitexporter commands needed
- **Auditable** — every sync shows up in both repos' Actions history
- **Works across all Node versions** — no nodegit compilation issues

---

## Pipeline Files (dpnelson Proven Pattern)

### sync-public.yml (lives in private repo)

Triggers on push to `main`. Copies source files to the public preview repo:

```yaml
name: Sync to Public Preview

on:
  push:
    branches: [main]
  workflow_dispatch:

permissions:
  contents: write          # ← CRITICAL: must be "write", not "read"

jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout private repo
        uses: actions/checkout@v4
        with:
          fetch-depth: 0  # NO persist-credentials: false — it breaks auth

      - name: Clone public preview repo
        run: |
          git clone https://x-access-token:${{ secrets.PUBLIC_REPO_TOKEN }}@github.com/OWNER/PUBLIC-REPO.git _public
          cd _public
          git config --global user.name "github-actions[bot]"
          git config --global user.email "github-actions[bot]@users.noreply.github.com"

      - name: Clean and copy public files
        run: |
          cd _public
          # Remove everything except .git, .nojekyll, .github
          find . -maxdepth 1 \
            ! -name '.' \
            ! -name '.git' \
            ! -name '.nojekyll' \
            ! -name '.github' \
            -exec rm -rf {} +

          cd ..
          # Selective cp — only public-facing source files
          cp -r src _public/
          cp -r public _public/
          cp package.json package-lock.json next.config.ts tsconfig.json postcss.config.mjs eslint.config.mjs next-env.d.ts README.md _public/ 2>/dev/null || true
          touch _public/.nojekyll

      - name: Commit and push
        run: |
          cd _public
          git add -A
          git diff --staged --quiet || git commit -m "Sync from private repo"
          git push origin main
```

### deploy.yml (lives in public preview repo)

Triggers on push to `main` (which happens when sync-public.yml pushes). Builds and deploys to GitHub Pages:

```yaml
name: Deploy to GitHub Pages

on:
  push:
    branches: [main]
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: "pages"
  cancel-in-progress: false

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: "22"
          cache: "npm"

      - name: Install dependencies
        run: npm ci

      - name: Build static site
        run: npm run build
        env:
          NODE_ENV: production

      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: ./out

  deploy:
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    needs: build
    steps:
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
```

---

## Pitfalls & Lessons Learned (Full Troubleshooting Journey)

| # | Pitfall | Symptom | Fix | Discovered when |
|---|---------|---------|-----|-----------------|
| 1 | `permissions: contents: read` | 403 "Write access to repository not granted" | Use `permissions: contents: write` | iamoneself sync attempt 1 |
| 2 | `persist-credentials: false` on checkout | "could not read Username for 'https://github.com'" | Don't use it — dpnelson doesn't need it | iamoneself sync attempt 2 |
| 3 | `git config` without `--global` | "Author identity unknown" in commit step | Use `--global` (persists across steps in Actions) | iamoneself sync attempt 2 |
| 4 | Not preserving `.github/` in find cleanup | deploy.yml wiped every sync cycle | Add `! -name '.github'` to the find command | FYF deploy broke after sync |
| 5 | Public preview repo is empty (no HEAD) | "could not parse HEAD" on git clone | Seed with initial README commit via GitHub API | FYF sync — freshly created repo |
| 6 | `package-lock.json` missing from sync | Deploy build fails ("Dependencies lock file not found") | Include in cp list | FYF deploy attempt |
| 7 | PAT missing `workflow` scope | 403 on push with Actions enabled | Add `workflow` scope to classic token | iamoneself sync attempt 1 |
| 8 | FYF public preview repo was private | "plan does not support GitHub Pages" | Make it public (free plan requires it) | FYF Pages enable attempt |
| 9 | Building in sync workflow | Turbopack can't find `@tailwindcss/postcss` on CI | Don't build in sync — build belongs in deploy.yml | iamoneself + FYF build failures |
| 10 | Using rsync instead of cp | Overly complex exclude patterns, edge cases | Use selective `cp` like dpnelson — simpler and proven | After multiple rsync iterations |
| 11 | `git config` set inside `cd _public` per-step | Config doesn't persist to next step | Use `--global` flag which persists across shell steps | Commit step couldn't identify author |
| 12 | actions/checkout@v4 GITHUB_TOKEN overrides PAT | Git push goes to wrong repo URL | Don't use `persist-credentials: false` — actually the `contents: write` permission was the real fix | Confused 403 on wrong repo URL |

### The 5 iterations (what actually happened)

1. **Attempt 1**: rsync-based, `contents: read`, build in sync → 403 "Write access not granted"
2. **Attempt 2**: Added `persist-credentials: false`, `--global` git config → "could not read Username" (went too far — no auth at all)
3. **Attempt 3**: Removed `persist-credentials: false`, `contents: write` → still 403 (PAT didn't have `workflow` scope)
4. **Attempt 4**: Added `workflow` scope to PAT, re-ran → PAT couldn't push to public preview (checkout's GITHUB_TOKEN was interfering)
5. **Attempt 5**: Matched dpnelson pattern exactly (cp not rsync, contents: write, no persist-credentials hack) → **SUCCESS** ✅

The real root causes were: `permissions: contents: write` and PAT `workflow` scope. Everything else was a red herring introduced by over-engineering.

---

## Token Setup (Classic PAT)

For each repo pair, create a classic PAT with these scopes:
- `repo` — Full control of private repositories (includes `repo:status`, `repo_deployment`, `public_repo`, `repo:invite`, `security_events`)
- `workflow` — Update GitHub Action workflows

Then add as secret:
```bash
gh secret set PUBLIC_REPO_TOKEN --repo OWNER/PRIVATE-REPO
```

**Token list (ecosphere):**
| Token | Scopes | Status |
|-------|--------|--------|
| iamoneself-sync | repo, workflow | ✅ Working |
| findyourfeathers-sync | repo, workflow | ✅ Working |
| dpnelson-sync | repo | ⚠️ Needs `workflow` scope added |
| alfred-public-preview-sync | repo | ⚠️ Needs `workflow` scope added |
| divorce-custody-sync | repo | ⚠️ Needs `workflow` scope added |
| trading-bot-sync | repo, workflow | ✅ Has workflow |
| wilson-lawn-sync | repo, workflow | ✅ Has workflow |
| pir-devine-news-auth | public_repo | ❌ Expired May 2026 |
| pir-devine-news-sync | repo | ⚠️ Needs `workflow` scope added |
| trading-assistant-sync | repo | ⚠️ Needs `workflow` scope added |
| astro-public-sync | repo, workflow | ✅ Working (`gratitude-token-project_astro` → `_astro-public`) |
| littlebird-sync | repo, workflow | ⏳ Pending — Christopher to create + `gh secret set PUBLIC_REPO_TOKEN --repo drasticstatic/littlebird-ambassador` |

---

## Denylist Reference

The selective `cp` in `sync-public.yml` implements a denylist by omission — only explicitly listed files get copied. This mirrors what `gitexporter.config.json`'s `ignoredPaths` did:

| Pattern | Why excluded |
|---------|-------------|
| `CLAUDE.md` | Agent instructions, private |
| `.github/` | Workflows stay private only (deploy.yml lives in public repo already) |
| `setup/` | Setup docs, credentials |
| `firecrawls/` | Raw crawl data |
| `backups/` | Backup files |
| `scripts/` | Operational scripts |
| `specs/` | Internal specs |
| `graphify-out/` | Knowledge graph |
| `.claude/` | Claude memory/settings |
| `AGENTS.md` | Agent config |
| `PENDING-TASKS.md` | Task tracking |
| `gitexporter.config.json` | Pipeline config |
| `.env*` | Secrets |
| `node_modules/` | Dependencies |
| `out/`, `.next/` | Build artifacts (deploy.yml builds fresh) |
| `.DS_Store` | macOS junk |

### gitexporter.config.json — Keep or Retire?

Keep the file for **documentation purposes** — it defines the denylist contract. But the actual syncing is now done by `sync-public.yml`'s selective `cp`. If you update one, update the other.

Future option: have `sync-public.yml` read from `gitexporter.config.json` programmatically so there's a single source of truth.

---

## Setup Checklist (per repo)

- [ ] Create public preview repo on GitHub (must be **public** for free plan Pages)
- [ ] Seed initial commit (README.md) via GitHub API if empty
  ```bash
  README_B64=$(printf '%s' "# Repo Name — Public Preview" | base64)
  gh api repos/OWNER/PUBLIC-REPO/contents/README.md \
    -X PUT -f message="Initial commit" -f content="$README_B64"
  ```
- [ ] Enable GitHub Pages → Source: GitHub Actions
  ```bash
  gh api repos/OWNER/PUBLIC-REPO/pages -X POST -f build_type=workflow -f source.branch=main -f source.path=/
  ```
- [ ] Create classic PAT with `repo` + `workflow` scopes
- [ ] Add PAT as `PUBLIC_REPO_TOKEN` secret in private repo
  ```bash
  gh secret set PUBLIC_REPO_TOKEN --repo OWNER/PRIVATE-REPO
  ```
- [ ] Add `sync-public.yml` to private repo's `.github/workflows/`
- [ ] Push `deploy.yml` to public preview repo's `.github/workflows/` via API
  ```bash
  DEPLOY_B64=$(base64 < deploy.yml)
  gh api repos/OWNER/PUBLIC-REPO/contents/.github/workflows/deploy.yml \
    -X PUT -f message="Add deploy workflow" -f content="$DEPLOY_B64"
  ```
- [ ] Verify `next.config.ts` has correct `basePath` for the public preview URL
- [ ] Push to private repo → watch both workflows go green
- [ ] Keep `gitexporter.config.json` for documentation but pipeline no longer depends on it

---

## Update — 2026-08-22: Fleet confirmation sweep + a new pitfall

Prompted by Christopher noticing a failed public-sync email during an unrelated fleet-wide Dependabot
triage pass (same day). Two things came out of it:

### Token table above was stale, not actually broken

Re-checked all 5 repos this doc's Token Setup table flagged as "⚠️ Needs `workflow` scope added"
(`dpnelson`, `anthropas-argus-alfred`, `divorce-custody-assistant`, `pir-devine-news`,
`trading-assistant`). Every one of them is green end-to-end today — both the private repo's
`sync-public.yml` *and* the corresponding public repo's Pages deploy. The table reflected an earlier
provisioning snapshot, not current reality. Lesson: this doc's proven-working state can drift out from
under its own tables — worth a periodic re-check rather than trusting the table at face value.

### Pitfall #13: npm version mismatch causes false `EBADPLATFORM` in injected deploy workflows

**Symptom:** `wilson-lawn-ai-assist-public`'s "Build and Deploy to GitHub Pages" run failed 5 times in a
row with:
```
npm error code EBADPLATFORM
npm error notsup Unsupported platform for @esbuild/aix-ppc64@0.28.2: wanted {"os":"aix","cpu":"ppc64"} (current: {"os":"linux","cpu":"x64"})
```
during `npm ci` — a completely unrelated architecture's optional dependency, which `npm ci` should
silently skip.

**Root cause:** `package-lock.json` had just been regenerated locally with npm 11.12.1 (during the
same day's Dependabot PR triage — several lockfile-conflict rebases needed a full
`rm package-lock.json && npm install` regen). The injected `deploy.yml`'s `actions/setup-node@v4`
pins `node-version: "20"`, which bundles **npm 10.8.2**. npm 10.8.x mis-parses the optional-dependency
platform metadata that npm 11.x writes, and instead of skipping the foreign-platform package, throws
`EBADPLATFORM` on it. Confirmed by reproducing locally: `npm ci` on the exact same lockfile succeeds
with npm 11.12.1, fails under npm 10.8.2's behavior.

**Fix:** added `- run: npm install -g npm@11` as a step between `actions/setup-node@v4` and `npm ci` in
the injected `deploy.yml` template (inside `wilson-lawn-ai-assist`'s `sync-public.yml` heredoc). Pins
the npm version explicitly rather than relying on whatever a given Node major happens to bundle.

**How to apply going forward:** any repo whose sync pipeline regenerates `package-lock.json` on a
machine with a newer npm than the deploy workflow's pinned Node version bundles is at risk of this same
false-positive `EBADPLATFORM`. Either (a) pin an explicit npm version in the deploy workflow that's
`>=` whatever generated the lockfile, or (b) bump the deploy workflow's Node version so its bundled npm
matches more closely. The `iamoneself`/`findyourfeathers` variant of this pipeline (Node 22 in its
build step, not Node 20) hasn't hit this — worth aligning `wilson-lawn-ai-assist`'s pinned Node version
up from 20 at some point too, not just papering over it with an npm pin.

### On GitExporter's badge/branding (open question, not yet decided)

Christopher asked whether GitExporter (the tool) still has portfolio value given it's fully dead here.
Current framing across repo READMEs — "Synced via GitExporter" badges linking to the upstream tool — is
now misleading: none of these repos actually depend on it anymore. Proposed but **not yet applied**:
reword badges to something like "Actions-based Sync Pipeline (GitExporter-inspired)," and consider
publishing a trimmed version of this doc's pitfalls/iterations table as a standalone writeup — the
"broken native-dependency tool → built a dependency-free Actions replacement" story is a stronger
portfolio artifact than the tool name itself. Holding until Christopher picks a direction.
