#!/bin/zsh
set -e

# ============================================================
# deployTest.sh — Dated Static Snapshot Deploy to GitHub Pages
# Version: 3.0 (genericized template)
# ============================================================
# Copies private repo → strips sensitive paths → builds Vite app
# → creates new public GitHub repo → pushes static output.
#
# Usage:
#   ./scripts/deployTest.sh              # uses today's date
#   ./scripts/deployTest.sh 2025-10-10   # uses specified date
#
# Prerequisites:
#   - Node.js + npm
#   - GitHub CLI (gh) — brew install gh
#   - gh auth login completed
# ============================================================

# ── SETTINGS — edit these for your project ──────────────────
REPO_NAME="YOUR_REPO_NAME"                    # your private repo folder name
GITHUB_USER="YOUR_GITHUB_USERNAME"            # your GitHub username
EXCLUDES=(
  ".git" "node_modules" ".env" "private_config" "secrets"
  ".DS_Store" "build" "dist" "cache" "artifacts"
  "AGENT-SYNC" "CLAUDE.md" ".augmentignore" "specs" "logs"
  # Add more private paths here
)
BUILD_BEFORE_DEPLOY=true    # build Vite app before deploying
DEPLOY_BUILD_ONLY=true      # deploy only the static build output (not source)
# ────────────────────────────────────────────────────────────

# --- STEP 1: Determine release date ---
DATE=${1:-$(date +"%Y-%m-%d")}
PUBLISH_REPO="${REPO_NAME}_testPublish_${DATE}"

echo "🚀 Starting deploy for: ${PUBLISH_REPO}"
sleep 1

# --- STEP 2: Move to parent directory ---
PROJECT_DIR=$(pwd)
PARENT_DIR=$(dirname "$PROJECT_DIR")
cd "$PARENT_DIR"

if [ ! -d "$REPO_NAME" ]; then
  echo "❌ Error: Project folder '$REPO_NAME' not found in $PARENT_DIR"
  exit 1
fi

# --- STEP 3: Remove old folder if it exists ---
if [ -d "$PUBLISH_REPO" ]; then
  echo "⚠️  Removing old folder ${PUBLISH_REPO}"
  rm -rf "$PUBLISH_REPO"
fi

# --- STEP 4: Copy files (excluding private paths) ---
echo "📦 Copying project folder..."
EXCLUDE_ARGS=()
for item in "${EXCLUDES[@]}"; do
  EXCLUDE_ARGS+=(--exclude="$item")
done
rsync -av "${EXCLUDE_ARGS[@]}" "$REPO_NAME/" "$PUBLISH_REPO/"
cd "$PUBLISH_REPO"

# --- STEP 5: Build and deploy ---
if [ "$BUILD_BEFORE_DEPLOY" = true ]; then
  DEPLOY_BASE="/${PUBLISH_REPO}/"
  HOMEPAGE_URL="https://${GITHUB_USER}.github.io/${PUBLISH_REPO}/"

  echo "📝 Vite base path: ${DEPLOY_BASE}"
  echo "🌐 Expected URL:   ${HOMEPAGE_URL}"

  echo "🏗️  Building Vite app..."
  npm install --legacy-peer-deps
  npm run build -- --base="${DEPLOY_BASE}"

  if [ "$DEPLOY_BUILD_ONLY" = true ]; then
    echo "📦 Extracting build output only..."
    mv dist ../temp_dist_${DATE}
    rm -rf *
    mv ../temp_dist_${DATE}/* .
    rm -rf ../temp_dist_${DATE}

    # 404.html for GitHub Pages SPA routing
    cp index.html 404.html
  fi
fi

# --- STEP 6: Initialize git and push ---
git init
git add .
git commit -m "feat: initial deploy snapshot ${DATE}"

echo "🐙 Creating public GitHub repo..."
gh repo create "${GITHUB_USER}/${PUBLISH_REPO}" --public --description "Dated deploy snapshot — ${DATE}" || true

git branch -M main
git remote add origin "https://github.com/${GITHUB_USER}/${PUBLISH_REPO}.git"
git push -u origin main --force

# --- STEP 7: Enable GitHub Pages ---
echo "📄 Enabling GitHub Pages..."
gh api "repos/${GITHUB_USER}/${PUBLISH_REPO}/pages" \
  --method POST \
  --field source='{"branch":"main","path":"/"}' 2>/dev/null || echo "ℹ️  Pages may already be enabled or needs manual activation."

# --- DONE ---
echo ""
echo "🎉 Deploy complete!"
echo "🌐 Site will be live at: https://${GITHUB_USER}.github.io/${PUBLISH_REPO}/"
echo "⏱️  GitHub Pages usually takes 1–2 minutes to go live."
echo ""
echo "💡 Tip: If Pages doesn't activate automatically, go to:"
echo "   https://github.com/${GITHUB_USER}/${PUBLISH_REPO}/settings/pages"
echo "   and set Source → GitHub Actions or Deploy from branch → main / root"
