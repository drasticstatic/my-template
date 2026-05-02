#!/bin/zsh
set -e

# ============================================================
# syncDocs.sh — Selective Doc Sync: Private Repo → Public Docs Repo
# Version: 2.0 (genericized template)
# ============================================================
# Selectively rsyncs documentation files from a private repo
# to a separate public docs repo (e.g. Docusaurus, GitBook).
# Keeps private code out of the public surface while preserving
# commit history in the docs repo.
#
# Usage:
#   ./scripts/syncDocs.sh              # perform sync
#   ./scripts/syncDocs.sh --dry-run    # preview changes only
#
# Typical use cases:
#   - Syncing a whitepaper from a private dev repo to a Docusaurus site
#   - Keeping a public _docs repo in sync with a private monorepo
#   - Pushing select markdown files to a GitBook-connected repo
# ============================================================

# ── SETTINGS — edit these for your project ──────────────────
PRIVATE_REPO="$HOME/path/to/your/private-repo"     # ← update this
DOCS_REPO="$HOME/path/to/your/docs-repo"           # ← update this
DOCS_LIVE_URL="https://YOUR_USERNAME.github.io/YOUR_DOCS_REPO/"  # ← update

# Files and folders to sync FROM the private repo.
# Paths relative to PRIVATE_REPO root.
SYNC_SOURCES=(
  "docs/"
  "README.md"
  # "whitepaper/"
  # "examples/"
  # "src/components"     # uncomment to sync specific source dirs
)

# Files/folders to NEVER sync (applied as rsync --exclude)
EXCLUDES=(
  ".git"
  "node_modules"
  "build"
  "dist"
  "cache"
  "artifacts"
  ".env"
  "secrets"
  "private_config"
  ".DS_Store"
  "*.log"
  "CLAUDE.md"
  ".augmentignore"
  "AGENT-SYNC"
)
# ────────────────────────────────────────────────────────────

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=true
  echo "🔍 DRY RUN MODE — no changes will be made"
  echo ""
fi

# --- STEP 1: Validate repositories exist ---
echo "📋 Validating repositories..."

if [ ! -d "$PRIVATE_REPO" ]; then
  echo "❌ Private repo not found: $PRIVATE_REPO"
  exit 1
fi

if [ ! -d "$DOCS_REPO" ]; then
  echo "❌ Docs repo not found: $DOCS_REPO"
  echo "💡 Clone it first: git clone https://github.com/USERNAME/REPO.git $DOCS_REPO"
  exit 1
fi

echo "✅ Both repositories found"
echo ""

# --- STEP 2: Pull latest changes ---
if [ "$DRY_RUN" = false ]; then
  echo "📥 Pulling latest from private repo..."
  cd "$PRIVATE_REPO"
  git pull origin main || echo "⚠️  Could not pull (may not be on main)"
  echo ""

  echo "📥 Pulling latest from docs repo..."
  cd "$DOCS_REPO"
  git pull origin main || echo "⚠️  Could not pull (may not be on main)"
  echo ""
fi

# --- STEP 3: Sync files ---
echo "📦 Syncing documentation..."

EXCLUDE_ARGS=()
for item in "${EXCLUDES[@]}"; do
  EXCLUDE_ARGS+=(--exclude="$item")
done
if [ "$DRY_RUN" = true ]; then
  EXCLUDE_ARGS+=(--dry-run)
fi

for source in "${SYNC_SOURCES[@]}"; do
  SOURCE_PATH="$PRIVATE_REPO/$source"
  if [ -e "$SOURCE_PATH" ]; then
    DEST_PATH="$DOCS_REPO/docs/$source"
    DEST_DIR=$(dirname "$DEST_PATH")
    if [ "$DRY_RUN" = false ]; then
      mkdir -p "$DEST_DIR"
    fi
    echo "  📄 Syncing: $source"
    rsync -av "${EXCLUDE_ARGS[@]}" "$SOURCE_PATH" "$DEST_DIR/"
  else
    echo "  ⚠️  Skipping (not found): $source"
  fi
done

echo ""
echo "✅ Sync complete"
echo ""

# --- STEP 4: Commit and push ---
if [ "$DRY_RUN" = false ]; then
  cd "$DOCS_REPO"

  if git diff --quiet && git diff --cached --quiet; then
    echo "ℹ️  No changes to commit"
  else
    echo "📝 Committing changes..."
    git add .
    TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
    git commit -m "docs: sync from private repo — $TIMESTAMP"
    echo "⬆️  Pushing to GitHub..."
    git push origin main
    echo "✅ Docs repo updated!"
  fi
else
  echo "🔍 DRY RUN — nothing committed"
fi

# --- DONE ---
rm -rf "$TEMP_DIR" 2>/dev/null || true
echo ""
echo "🎉 Done!"
echo "📂 Private: $PRIVATE_REPO"
echo "📂 Docs:    $DOCS_REPO"
echo "🌐 Live:    $DOCS_LIVE_URL"
echo ""
if [ "$DRY_RUN" = false ]; then
  echo "💡 Tip: Use --dry-run to preview before syncing"
fi
