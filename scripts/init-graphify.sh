#!/bin/zsh
set -e

# ============================================================
# init-graphify.sh — Deploy graphify to a repo (keyless steps)
# Version: 1.0
# ============================================================
# Copies the canonical .graphifyignore into this repo (unless one already
# exists) and runs `graphify claude install` to wire the Claude Code
# PreToolUse hook. Both steps are free/keyless. The actual knowledge-graph
# build (`graphify extract .`) needs a real LLM API key in the shell — this
# script does NOT run that step; see the printed next-steps at the end.
#
# Full background: ~/code/anthropas-argus-alfred/sandbox/GRAPHIFY_SETUP.md
#
# Usage:
#   ./scripts/init-graphify.sh              # run from the target repo's root
#
# Prerequisites:
#   - graphify installed (uv tool install graphifyy --with anthropic --with openai)
# ============================================================

REPO_ROOT=$(pwd)
CANONICAL_IGNORE="$HOME/code/my-template/.graphifyignore"

if ! command -v graphify >/dev/null 2>&1; then
  echo "❌ graphify not found on PATH. Install it first:"
  echo "   uv tool install graphifyy --with anthropic --with openai"
  exit 1
fi

# --- STEP 1: Deploy .graphifyignore ---
if [ -f "$REPO_ROOT/.graphifyignore" ]; then
  echo "ℹ️  .graphifyignore already exists here — leaving it as-is."
else
  if [ ! -f "$CANONICAL_IGNORE" ]; then
    echo "❌ Canonical template not found at $CANONICAL_IGNORE"
    exit 1
  fi
  cp "$CANONICAL_IGNORE" "$REPO_ROOT/.graphifyignore"
  echo "✅ Deployed .graphifyignore from the canonical template."
  echo "   Add repo-specific overrides at the bottom of the file (see the"
  echo "   REPO-SPECIFIC OVERRIDES section) before running extraction."
fi

# --- STEP 2: Install the Claude Code hook ---
echo "🔧 Running: graphify claude install"
graphify claude install

# --- STEP 3: Gitignore the non-committed graphify-out files ---
if [ -f "$REPO_ROOT/.gitignore" ] && ! grep -q "graphify-out/manifest.json" "$REPO_ROOT/.gitignore"; then
  {
    echo ""
    echo "# graphify — local-only outputs (see graphify-out/graph.json, GRAPH_REPORT.md, graph.html to commit)"
    echo "graphify-out/manifest.json"
    echo "graphify-out/cost.json"
  } >> "$REPO_ROOT/.gitignore"
  echo "✅ Added graphify-out/manifest.json + cost.json to .gitignore"
fi

echo ""
echo "🎉 Keyless graphify setup complete."
echo ""
echo "Next step — build the actual knowledge graph (needs a real LLM API key"
echo "in the shell; Claude Code's own OAuth session does not expose one):"
echo ""
echo "  ! export ANTHROPIC_API_KEY=sk-ant-...      # real Anthropic key, most reliable"
echo "  ! graphify extract ."
echo ""
echo "No Anthropic key? Free Gemini tier works for smaller repos:"
echo ""
echo "  ! export GEMINI_API_KEY=...                # aistudio.google.com — free, no card"
echo "  ! GEMINI_API_KEY=\$GEMINI_API_KEY graphify extract ."
echo ""
echo "If extraction gets rate-limited partway through (common on the free tier"
echo "for 100+ file repos), this still works — it's free and uses whatever"
echo "graph.json extraction already produced:"
echo ""
echo "  graphify cluster-only ."
echo ""
echo "Then commit: graphify-out/graph.json, GRAPH_REPORT.md, graph.html"
