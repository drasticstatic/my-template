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
