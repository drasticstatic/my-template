# React (CRA) + Hardhat — Build & Deploy to GitHub Pages (single-repo)

> **Pattern:** one repo, public. A `deploy.yml` builds the React app and deploys the built
> output to **the same repo's** GitHub Pages. **No** private→public mirror, **no**
> `sync-public.yml`, **no** `PUBLIC_REPO_TOKEN`.
>
> **Use for:** public learning / showcase repos where the whole repo is meant to be shared, and the
> only goal is a live hosted demo on a `*.github.io` URL. Worked example in this ecosystem:
> the `dappu` web3-bootcamp repos — `amm`, `crowdsale`, `dao`, `nft_dappu-punks`, `hardhat_example`.
>
> **Not the same as:** `nextjs-ssg-ghpages-deploy.md` (that's a *two-repo* Next.js pattern — build in
> private, deploy built output to a separate public repo). And **not the same as** `sync-public-*.yml`
> (those mirror a private repo to a public-preview repo). See §4 for when to use which.

---

## 1. What this pipeline does

You have a public React app (built with `react-scripts` / CRA, often alongside `hardhat` for the
web3 repos). You want it live at `https://<user>.github.io/<repo>/`. The whole repo is public and
shared as a teaching artifact, so there's nothing to filter — you just need CI to build it and push
the build to Pages.

```
┌─────────────────────────────┐
│   Public repo (single)      │
│   github.com/OWNER/REPO     │
│                             │
│   push to main              │
│        │                    │
│        ▼                    │
│   deploy.yml (this pattern) │
│   1. npm ci                 │
│   2. npm run build → ./build│
│   3. upload ./build artifact│
│   4. actions/deploy-pages   │
│        │                    │
│        ▼                    │
│   GitHub Pages serves /build │
│   (https://USER.github.io/…)│
└─────────────────────────────┘
```

One repo, one workflow, no token, no second repo. That simplicity is the whole point — but it only
works when **everything in the repo is fit for public view**, because the repo itself *is* the
host. If anything must stay private, you do **not** use this pattern; you use
`sync-public.yml` (see §4).

---

## 2. The working template (from `dappu/amm`)

Drop this at `.github/workflows/deploy.yml` in the public repo. This is the concrete file already
running on `amm`/`crowdsale`/`dao`/`nft_dappu-punks` — adjust paths/secrets, don't reinvent it.

```yaml
name: Build and Deploy to GitHub Pages

on:
  push:
    branches: ["main"]
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
          node-version: "20"        # CRA/Hardhat bootcamp repos run fine on 20
          cache: "npm"

      - name: Install dependencies
        run: npm ci --legacy-peer-deps   # ← legacy-peer-deps: web3 deps conflict brazenly

      - name: Build
        run: npm run build
        env:
          REACT_APP_INFURA_KEY: ${{ secrets.INFURA_API_KEY }}  # inject as REACT_APP_* at build
          CI: false    # ← CRA treats warnings as errors under CI:true; the bootcamp apps warn

      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: ./build             # ← CRA writes to ./build (NOT Next's ./out)

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

### Annotated — why each non-obvious line
- `permissions: pages: write` + `id-token: write` — **required** by `actions/deploy-pages`.
- `concurrency: group: "pages"` — one Pages deploy at a time; `cancel-in-progress: false` lets the
  in-flight run finish rather than thrashing.
- `npm ci --legacy-peer-deps` — the web3 dependency tree (hardhat + its transitive deps) routinely
  produces `ERESOLVE` peer conflicts under plain `npm ci`. `--legacy-peer-deps` mirrors npm v6's
  lenient resolver. If your repo's deps are clean, you can drop it — but the dappu repos need it.
- `CI: false` — `react-scripts build` runs ESLint and **fails the build on warnings** when `CI=true`
  (the default on Actions). The bootcamp apps have warnings; `CI: false` lets them ship. Clean this
  up if you want warnings to gate.
- `REACT_APP_INFURA_KEY` — CRA only embeds env vars prefixed `REACT_APP_` into the bundle. Whatever
  runtime config the app needs must be a build-time `REACT_APP_*` secret here.
- `path: ./build` — CRA's output dir. If you later move a repo to Vite (`vite build` → `./dist`)
  or Next (`export` → `./out`), change this path accordingly — **this is the #1 footnote** when
  porting the same workflow across build tools.

---

## 3. The `homepage` field — the one config you MUST set or the app loads blank

CRA serves the app from `https://<user>.github.io/<repo>/` (a subpath, not domain root). Without
telling it so, asset paths resolve to `/static/js/…` (domain root) and the deployed app loads
**blank** with 404s in the console.

In the repo's `package.json`:
```json
{
  "homepage": "https://drasticstatic.github.io/<repo>"
}
```
CRA reads `"homepage"` and rewrites asset URLs to `/<repo>/static/js/…` — exactly what GitHub Pages
expects at that subpath. **Forget this field and the site looks deployed-but-broken.** (If the repo
later moves to Vite, the equivalent is `base` in `vite.config.ts` — see the `trading-bot` example
in §4.)

Also required, one time, on the repo itself: **enable GitHub Pages → Source: GitHub Actions.**
```bash
gh api repos/drasticstatic/<repo>/pages -X POST \
  -f build_type=workflow -f source.branch=main -f source.path=/
```
If `pages` already exists, `POST` 409s — use `PUT`, or just check
`gh api repos/drasticstatic/<repo>/pages`. **As of 2026-07-17, `dappu/amm`'s Pages was *not*
enabled** (the `deploy.yml` exists but Pages source isn't set, so nothing deploys even on a green
run). If you resurrect one of these repos and the run goes green but nothing's live, **this is why**.

---

## 4. When to use this vs `sync-public.yml` vs a custom showcase repo

Not all non-Next.js React repos take this single-repo pattern. Three cases live in this ecosystem:

### Case A — single-repo public demo (THIS doc)
Everything public, share it on its own ghpages URL. Use `deploy.yml` only. **Examples:** the public
`dappu` learning repos (`amm`, `crowdsale`, `dao`, `nft_dappu-punks`). These have **no**
public-preview mirror and **no** `sync-public.yml`.

### Case B — private repo, showcase only the front-end (two-repo)
The repo is private (bot, contracts, strategies must stay secret) and you want the public record
to show only the React front-end dashboard. Use `sync-public.yml` with an **allowlist** of just
`frontend/` (+ docs), and have it **inject a `deploy.yml`** into the public-preview repo that builds
the frontend with the correct `--base`. **Example:** `trading-bot_arbitrage_DAPPUv3…` — its
`sync-public.yml` even uses `--message-callback` + `--blob-callback` to scrub private references out
of the public history before push. See `sync-public-allowlist.yml` (template) and
`REPO-RESURRECTION-PLAYBOOK.md` (Alfred repo). **`wilson-lawn-ai-assist`** uses the **denylist** two-repo
variant (most private, a few public) — still `sync-public.yml`, not this doc.

### Case C — custom showcase repo, hand-rolled
`gratitude-token-project` keeps its showcase in a **separate sibling repo**
(`gratitude-token-project_docs`, surfaced locally as `_testPublish`) rather than via a filter-mirror
workflow. The main project has **no** `.github/workflows`. If you resurrect one of these, read the
repo's own `_testPublish` relationship before assuming any standard pattern applies — it's a bespoke
publish route, not a template.

### Decision rule
- Whole repo public, want a live demo → **`deploy.yml` only** (this doc).
- Whole repo private, showcase only the front end → **`sync-public.yml`** (allowlist) + injected `deploy.yml`.
- Mostly public with a few secrets → **`sync-public.yml`** (denylist).
- Bespoke two-repo showcase outside the mirror pattern → read the repo, don't assume.

---

## 5. Resurrecting an older dappu-style repo (checklist)

These repos drift — Pages gets disabled, `homepage` goes stale after a rename, secrets expire. If
you pick one up and nothing's live, go in order:

1. **Repo is public?** `gh repo view drasticstatic/<repo> --json visibility` → `public`. (A private
   repo can't use this single-repo Pages pattern at all on a free plan; it'd be Case B instead.)
2. **`deploy.yml` present + recent run green?** `gh run list --repo drasticstatic/<repo> --workflow=deploy.yml --limit 1`.
   Green but nothing live almost always means step 3.
3. **Pages enabled, Source = GitHub Actions?** `gh api repos/drasticstatic/<repo>/pages --jq '.build_type'`.
   Want `workflow`. If 404, enable it (the `gh api …/pages` POST above). **This is the common failure
   mode** — `amm` is in exactly this state today.
4. **`homepage` in `package.json` points at the repo's ghpages URL?** Stale after a repo rename →
   blank app. Update and push.
5. **Build-time secrets still set?** `gh secret list --repo drasticstatic/<repo>`. CRA bakes
   `REACT_APP_*` at build — an expired Infura key means the app builds but the on-chain calls fail
   silently at runtime. Refresh and push.
6. **Push a trivial commit** and watch the run + Pages both go live.

---

## 6. Pitfalls specific to CRA/Hardhat (quick table)

| # | Pitfall | Symptom | Fix |
|---|---------|---------|-----|
| 1 | Missing `homepage` in `package.json` | App deploys but loads blank, 404s on assets | Set `"homepage": "https://user.github.io/repo"` |
| 2 | Pages not enabled / wrong source | Green `deploy.yml` run, nothing at the URL | `gh api …/pages` POST with `build_type=workflow` |
| 3 | `CI: true` (default) | Build fails on CRA lint warnings | `env: CI: false` in build step |
| 4 | No `--legacy-peer-deps` | `ERESOLVE` peer-dep conflict on `npm ci` | Add `--legacy-peer-deps` (web3 deps) |
| 5 | `path: ./out` or `./dist` | "upload artifact" fails or deploys empty | CRA → `./build`; Vite → `./dist`; Next → `./out` |
| 6 | Expired `REACT_APP_*` secret | Builds + deploys, runtime fetches fail | Refresh secret, push |
| 7 | Renamed repo, `homepage` stale | Blank after rename | Update `homepage`, match new `user.github.io/repo` |

---

## Maintenance

- This doc lives in `my-template/workflow-templates/` as the **Pattern C** reference — keep it
  accurate to the `dappu` repos it documents; refresh §5's "current state" note when you
  re-verify. Last verified 2026-07-17.
- Sister docs in this folder: `nextjs-ssg-ghpages-deploy.md` (two-repo Next.js build→public),
  `sync-public-allowlist.yml` + `sync-public-excludelist.yml` (two-repo filter-mirror templates).
- Cross-reference: `anthropas-argus-alfred/REPO-RESURRECTION-PLAYBOOK.md` — the resurrection
  dispatcher; this doc is the Pattern C chapter it points to.
