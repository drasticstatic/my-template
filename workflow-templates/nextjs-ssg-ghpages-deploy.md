# Next.js SSG Deploy to GitHub Pages — Build + Deploy Workflow

> **The critical pattern**: Build in the **private repo** context, deploy the built output to the **public repo**. Never let the public repo run its own workflow.

---

## The Problem We Solved

When syncing a Next.js static site (`output: 'export'`) to a GitHub Pages public preview repo, the naïve approach copies **source files** — but the public repo then has no `package-lock.json`, no `node_modules`, and no build output. If the workflow YAML also gets copied to the public repo, it re-triggers on every push to the public repo, running in the wrong context and failing.

Symptoms:
- `Error: Dependencies lock file is not found in /home/runner/work/REPO/REPO`
- `Node 20 is being deprecated`
- Pagefind search returns "Search index failed to load" (the index never gets built or deployed)
- Infinite workflow loops (push to private → triggers sync → pushes to public → public workflow triggers → fails → but loop keeps consuming minutes)

---

## The Fixed Pattern

### Architecture

```
Private Repo (source + secrets)          Public Repo (GitHub Pages host)
github.com/OWNER/PRIVATE-REPO    →→→    github.com/OWNER/PUBLIC-REPO
        │                                        │
        │  GitHub Actions workflow               │  NO WORKFLOW HERE
        │  runs in PRIVATE context               │  (just static files)
        │  npm ci + npm run build                │
        └────────── copies out/* ──────────────► └── GitHub Pages serves /out
```

### Key Rules

1. **Workflow lives ONLY in the private repo** — never in the public one
2. **Public repo is a deploy-only bucket** — it contains built HTML/JS/CSS + Pagefind index, no source code
3. **Node 22** (Node 20 deprecated Sept 2025 on GitHub Actions)
4. **Clean step removes EVERYTHING except `.git`** — including `.github/` (this is what broke us)
5. **`touch .nojekyll`** — prevents GitHub Pages from processing with Jekyll

---

## Workflow Template

```yaml
name: Deploy to GitHub Pages

on:
  push:
    branches: [main]
  workflow_dispatch:

permissions:
  contents: write

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout private repo
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: "22"   # Node 20 is DEPRECATED — use 22+
          cache: "npm"

      - name: Install dependencies
        run: npm ci            # NOT npm install — requires package-lock.json

      - name: Build static site
        run: npm run build     # Must produce output in a known dir (e.g. /out)

      - name: Clone public repo
        run: |
          git clone https://x-access-token:${{ secrets.PUBLIC_REPO_TOKEN }}@github.com/OWNER/PUBLIC-REPO.git _public
          cd _public
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"

      - name: Deploy built site
        run: |
          cd _public

          # Remove EVERYTHING except .git — no .github/, no source, no old workflows
          find . -maxdepth 1 \
            ! -name '.' \
            ! -name '.git' \
            -exec rm -rf {} +

          # Copy the built static output (includes Pagefind index if using it)
          cp -r ../out/* ./
          touch .nojekyll

      - name: Commit and push
        run: |
          cd _public
          git add -A
          git diff --staged --quiet || git commit -m "Deploy built site"
          git push origin main
```

---

## Pagefind — Static Search Engine

If your site uses [Pagefind](https://pagefind.app) for client-side search:

### Build script

```json
{
  "scripts": {
    "build": "next build && npx -y pagefind --site out && cp -r out/pagefind public/pagefind 2>/dev/null; echo 'Done'"
  }
}
```

The `cp -r out/pagefind public/pagefind` step copies the search index to `public/` so `next dev` can serve it locally. Without this, dev mode has no Pagefind files.

### .gitignore

```
public/pagefind/
```

The Pagefind index is a build artifact — it gets regenerated on every build. Never commit it.

### Client-side loading pattern

```tsx
useEffect(() => {
  const isDev = typeof window !== "undefined" &&
    (window.location.hostname === "localhost" || window.location.hostname.includes("127.0.0.1"));
  const basePath = isDev ? "" : "/YOUR-GH-PAGES-SUBPATH";
  const scriptSrc = `${basePath}/pagefind/pagefind.js`;

  if ((window as any).pagefind) {
    (window as any).pagefind.init().then(setPagefind);
    return;
  }

  const script = document.createElement("script");
  script.src = scriptSrc;
  script.onload = () => {
    const pf = (window as any).pagefind;
    if (pf) pf.init().then(setPagefind);
  };
  document.head.appendChild(script);
}, []);
```

Key: `basePath` must match your GitHub Pages subpath (e.g. `/iamoneself-public-preview`). Dev mode uses `""` since `public/pagefind/` is served at root.

### Making modal content searchable

Modals (Framer Motion AnimatePresence) don't exist in the DOM at build time. Add a hidden `data-pagefind-body` div:

```tsx
<div className="hidden" data-pagefind-body aria-hidden>
  <h2>Modal Title</h2>
  <p>Modal content here — same data as the visual modal, rendered as semantic HTML.</p>
</div>
```

Pagefind indexes this hidden div at build time. Search results link to the page where the modal lives.

---

## Updating Old Repos

If you have a repo that was using the **old pattern** (copying source files to the public repo, or using `git-filter-repo` with a denylist), here's the migration path:

### Step 1: Identify the current pattern

| Old Pattern | Symptom | Fix |
|-------------|---------|-----|
| Copies source to public repo | Public repo has `package.json`, `src/`, `.github/` | Switch to build+deploy pattern above |
| `git-filter-repo` denylist | Public repo has filtered source but no build output | Add build step before push, deploy `out/*` only |
| `.github/` in public repo | Workflow re-triggers in wrong context | Clean step must remove `.github/` |
| Node 20 in workflow | Deprecation warning / failure | Change to `node-version: "22"` |

### Step 2: Add the build step

If your workflow currently does:
```yaml
# BAD — copies source, no build
- run: cp -r src _public/ && cp -r public _public/
```

Replace with:
```yaml
# GOOD — builds first, deploys output
- run: npm ci
- run: npm run build
- run: cp -r out/* _public/
```

### Step 3: Remove `.github/` from the clean step

If your clean step preserves `.github/`:
```yaml
# BAD — .github/ in public repo causes re-trigger
find . -maxdepth 1 ! -name '.github' ! -name '.git' -exec rm -rf {} +
```

Change to:
```yaml
# GOOD — public repo is a pure deploy target
find . -maxdepth 1 ! -name '.git' -exec rm -rf {} +
```

### Step 4: Delete stale workflows from the public repo

After the first successful deploy with the new pattern, manually check the public repo for leftover `.github/workflows/` files. The first deploy with the fixed clean step will remove them automatically.

### Step 5: Verify

1. Push to `main` on the private repo
2. Check GitHub Actions — workflow should succeed
3. Check the public repo — should contain only built output files (HTML, JS, CSS, Pagefind index, `.nojekyll`)
4. Check GitHub Pages — site should be live and search should work

---

## next.config.ts for GitHub Pages

```ts
import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  output: "export",   // Static Site Generation
  basePath: process.env.NODE_ENV === "production" ? "/YOUR-REPO-NAME" : "",
  images: { unoptimized: true },  // Required for static export
  trailingSlash: true,
};

export default nextConfig;
```

The `basePath` must match your GitHub Pages URL subpath. Dev mode uses `""`.

---

## Checklist for New Repos

- [ ] Private repo has `.github/workflows/deploy.yml` (the workflow above)
- [ ] Public repo has NO `.github/` directory
- [ ] `secrets.PUBLIC_REPO_TOKEN` set in private repo (personal access token with repo scope)
- [ ] `next.config.ts` has correct `basePath` for GitHub Pages
- [ ] `package.json` build script includes Pagefind (if using search): `next build && npx -y pagefind --site out`
- [ ] `public/pagefind/` in `.gitignore`
- [ ] `.nojekyll` present in public repo (prevents Jekyll processing)
- [ ] Node version in workflow is 22+ (not 20)

---

## Evolved Pattern (2026-07) — Subdomain / Custom Domain + Env-Driven `basePath` + GitHub Pages Actions Deploy

> Live-proven on **iamoneself.com** → deployed to the custom subdomain **`retreats.iamoneself.com`** (private repo `iamoneself` → public repo `iamoneself-public-preview`, served via GitHub Pages). This section SUPPLEMENTS the base pattern above and **SUPERSEDES** three earlier claims, flagged inline below.

### Why the evolution

Three things the base pattern above did not cover, all of which bit us in production:

1. A **custom domain** (subdomain) serves the site at the **repo ROOT**, not a subpath. The base pattern hardcoded `basePath: "/YOUR-REPO-NAME"` for production — on a custom domain that bakes the subpath into every asset URL, so every `/_next/…`, `/favicon.svg`, image, and Pagefind path 404s → a **blank white page with unstyled lucide SVG icons and default-blue links but no CSS/hydration**. (The classic "assets 404" blank page.)
2. The clean step's `find … -exec rm -rf {} +` wipes **everything but `.git`** — including the `CNAME` file that *is* the GitHub Pages custom-domain binding. Every deploy silently **detached the custom domain** until `CNAME` was re-created.
3. The base pattern said "NO WORKFLOW HERE" in the public repo. The modern GitHub Pages **Actions deploy** (`actions/deploy-pages`) actually *requires* a workflow in the public repo — the private sync workflow pushes built output, and a public-repo Pages-deploy workflow is what hands it to Pages.

### 1. Add a custom domain (subdomain) — `CNAME` + DNS + HTTPS

**In the deploy step** (the `sync-public.yml` job that copies `out/*` into the public repo), re-create the `CNAME` *every deploy*, right after `.nojekyll`:

```yaml
- name: Deploy built site to public preview
  run: |
    cd _public
    find . -maxdepth 1 ! -name '.' ! -name '.git' -exec rm -rf {} +
    cp -r ../out/* ./
    cp -r ../out/.nojekyll . 2>/dev/null || true
    touch .nojekyll

    # CNAME IS the GitHub Pages custom-domain binding. The find … -exec rm above
    # wipes it every deploy → detach the domain → re-create it so it stays bound.
    echo "retreats.iamoneself.com" > CNAME
```

The `CNAME` file contains exactly one line: the **bare hostname** (`retreats.iamoneself.com`), no protocol, no trailing slash. GitHub Pages reads it on each deploy to know which custom domain to serve.

**DNS (do this once, in your registrar / DNS provider):**
- **Subdomain** (this case — `retreats.iamoneself.com`): add a **`CNAME` record** → `retreats` points to `DRATICSTATIC.github.io` (use `<OWNER>.github.io`, i.e. the account/org that owns the Pages site). CNAME flattening at the apex is not needed for a subdomain.
- **Apex/root domain** (e.g. `iamoneself.com` itself, if you ever move up): add **A records** pointing to GitHub's Pages IPs — `185.199.108.153`, `185.199.109.153`, `185.199.110.153`, `185.199.111.153`.

**GitHub Pages settings (public repo → Settings → Pages):**
- **Source = "GitHub Actions"** (NOT "Deploy from a branch") — see §3 below.
- **Custom domain field** = the hostname from `CNAME` (GitHub usually picks it up from the file; set + Save to be sure).
- After DNS resolves + the deploy runs, GitHub auto-provisions a TLS certificate via **Let's Encrypt** (a minute or two). Once it issues, tick **Enforce HTTPS**. Keep Enforce HTTPS on — the cert auto-renews.

### 2. Env-driven `basePath` — SUPERSEDES the hardcoded-ternary `next.config.ts` above

The `next.config.ts` example near the top of this doc uses `basePath: process.env.NODE_ENV === "production" ? "/YOUR-REPO-NAME" : ""`. That brittle ternary assumes production = subpath deploy, which is false for a custom domain. **Replace it with an env-var-driven approach** so flipping between a root-served custom domain and a `github.io/<repo>` subpath deploy is ONE build variable, not a code edit.

**`next.config.ts`:**

```ts
import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  output: "export",
  // Env-driven: "" (default) = root-served = correct for a custom domain + for
  // local dev. Set NEXT_PUBLIC_BASE_PATH=/YOUR-REPO-NAME ONLY for the
  // github.io/<repo> project-URL subpath deploy.
  basePath: process.env.NEXT_PUBLIC_BASE_PATH ?? "",
  images: { unoptimized: true },
  trailingSlash: true,
};

export default nextConfig;
```

**`src/lib/utils.ts` — single helper every asset path reads:**

```ts
/**
 * Next.js inlines NEXT_PUBLIC_* at build time, so this returns the same value
 * in the browser as at build/SSR. Default "" = root-served = correct for local
 * dev AND the custom domain. Set NEXT_PUBLIC_BASE_PATH=/YOUR-REPO-NAME only for
 * the github.io project-URL subpath deploy.
 */
export function getBasePath() {
  return process.env.NEXT_PUBLIC_BASE_PATH ?? "";
}
```

**Collapse ALL inline `isDev ? "" : "/subpath"` / `NODE_ENV === "production" ? …` ternaries** through `getBasePath()`. In the iamoneself arc this was 11 sites across `next.config.ts`, `layout.tsx` (favicon), `Navbar.tsx`, `Footer.tsx` (compass images), `GuideModal.tsx` + `AIFormHelper.tsx` (Pagefind loader + `resolveUrl`), `not-found.tsx` (Pagefind loader + help-text code blocks). **Including the Pagefind loader** shown earlier in this doc — replace its `const basePath = isDev ? "" : "/YOUR-GH-PAGES-SUBPATH"` with `const basePath = getBasePath();`. Leave intact only genuine `https://github.com/OWNER/REPO` repo links (those are repo URLs, not site paths).

**Result:** flipping the deploy target is now a single env var. For the custom-domain deploy: no var (defaults to `""`). For the `github.io` subpath deploy: set `NEXT_PUBLIC_BASE_PATH=/iamoneself-public-preview` in the build environment. No code changes either way.

### 3. Two-workflow Pages deploy — SUPERSEDES rule "NO WORKFLOW HERE"

The public repo now carries ONE workflow — the **Pages deploy** — which the private sync workflow copies in. (The private repo keeps the sync workflow; the public repo never runs the *sync* workflow. "No sync/build workflow in the public repo" still holds.)

**Private repo: `.github/workflows/sync-public.yml`** — builds + pushes built output to the public repo (this is the workflow already shown above, with the `CNAME` echo from §1 added, plus one new line near its end):

```yaml
          # Copy the GitHub Pages DEPLOY workflow into the public repo so
          # actions/deploy-pages actually publishes what we just pushed.
          mkdir -p .github/workflows
          cp ../.github/pages-deploy-workflow.yml .github/workflows/deploy-pages.yml
```

**Private repo: `.github/pages-deploy-workflow.yml`** — the canonical GitHub Pages Actions deploy (this is the file synced INTO the public repo as `deploy-pages.yml`):

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
  group: pages
  cancel-in-progress: false

jobs:
  deploy:
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      - name: Setup Pages
        uses: actions/configure-pages@v5
      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: '.'
      - name: Deploy
        id: deployment
        uses: actions/deploy-pages@v4
```

**Public repo Settings → Pages → Source = "GitHub Actions"** (not "Deploy from a branch"). `deploy-pages.yml` is what fulfill that source — it uploads the repo root as the Pages artifact and calls `actions/deploy-pages`. Without it, the pushed built output just sits in the public repo and Pages has nothing to publish.

### 4. The two production gotchas, restated as the checklist items they became

| Symptom | Root cause | Fix |
|---|---|---|
| Blank white page, lucide icons render but unstyled, links default-blue, no CSS/JS/hydration | Prod `basePath` baked `/repo-name` into asset URLs; custom domain serves at repo root → every asset 404s | Env-driven `basePath = ""` for the custom domain (§2) |
| Custom domain detaches / "404 There isn't a GitHub Pages site here" after a deploy | `find -exec rm` clean step wipes `CNAME` every deploy | `echo "host" > CNAME` in every deploy (§1) |
| Built output in public repo but Pages never updates / site stale | Public repo Pages Source = "Deploy from a branch", not "GitHub Actions" | Source = "GitHub Actions" + the `deploy-pages.yml` workflow (§3) |

### 5. Checklist deltas for repos using a custom domain

On top of the "Checklist for New Repos" above, add:
- [ ] `CNAME` file re-created every deploy (one bare-hostname line) — not left to survive the clean step
- [ ] DNS: subdomain = `CNAME → <owner>.github.io`; apex = A records → GitHub Pages IPs
- [ ] `basePath` is env-driven (NEXT_PUBLIC_BASE_PATH, default `""`); NO production ternary
- [ ] All inline `isDev/NODE_ENV` basePath ternaries collapsed through `getBasePath()` (incl. the Pagefind loader)
- [ ] Private repo carries `.github/pages-deploy-workflow.yml`; `sync-public.yml` copies it to `public/.github/workflows/deploy-pages.yml`
- [ ] Public repo Pages **Source = "GitHub Actions"**
- [ ] GitHub Pages custom-domain field set to the `CNAME` hostname; **Enforce HTTPS** on after the Let's Encrypt cert issues
