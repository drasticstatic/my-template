#!/bin/sh
# install-claude-session-order.sh: install the three pieces of walkthroughs/CLAUDE-SESSION-ORDER.md for the person
# running it. Run it yourself; a helper session must not (it changes your own settings and shell profile).
#
#   sh ~/code/my-template/scripts/install-claude-session-order.sh            # install (safe to run twice)
#   sh ~/code/my-template/scripts/install-claude-session-order.sh --undo     # put both files back from the backups
#
# What it changes, and nothing else:
#   ~/.claude/settings.json  adds "cleanupPeriodDays": 3650 (Claude Code deletes transcripts older than 30 days by
#                            default) and a SessionStart hook running scripts/claude-session-start.sh. Every other key
#                            is kept exactly; the file is checked as JSON before it replaces the old one.
#   ~/.zshrc                 appends the claude-parent-guard function (between its >>> and <<< marker lines), once.
# Backups first: ~/.claude/backups/settings-before-session-order.json and ~/.zshrc.before-session-order (kept if they
# already exist, so --undo always returns to the state before the first install).
# Prints key names only, never values (settings.json can hold tokens).
set -eu
HERE=$(cd "$(dirname "$0")" && pwd)
S="$HOME/.claude/settings.json"; Z="$HOME/.zshrc"
SB="$HOME/.claude/backups/settings-before-session-order.json"; ZB="$HOME/.zshrc.before-session-order"
HOOK="$HERE/claude-session-start.sh"

if [ "${1-}" = --undo ]; then
  [ -f "$SB" ] && cp -p "$SB" "$S" && echo "restored $S"
  [ -f "$ZB" ] && cp -p "$ZB" "$Z" && echo "restored $Z"
  exit 0
fi

[ -f "$HOOK" ] || { echo "missing $HOOK"; exit 1; }
mkdir -p "$HOME/.claude/backups"
[ -f "$S" ] || echo '{}' > "$S"
[ -f "$SB" ] || cp -p "$S" "$SB"
touch "$Z"; [ -f "$ZB" ] || cp -p "$Z" "$ZB"

python3 -I - "$S" <<'PY'
import json, os, sys
p = sys.argv[1]
d = json.load(open(p))
cmd = 'sh "$HOME/code/my-template/scripts/claude-session-start.sh"'
d["cleanupPeriodDays"] = max(int(d.get("cleanupPeriodDays") or 0), 3650)
starts = d.setdefault("hooks", {}).setdefault("SessionStart", [])
if not any(h.get("command") == cmd for g in starts for h in g.get("hooks", [])):
    starts.append({"hooks": [{"type": "command", "command": cmd, "timeout": 10}]})
tmp = p + ".tmp"
with open(tmp, "w") as f:
    json.dump(d, f, indent=2); f.write("\n")
json.load(open(tmp)); os.replace(tmp, p)
print("settings.json keys:", ", ".join(sorted(d)))
print("cleanupPeriodDays:", d["cleanupPeriodDays"], "| SessionStart hooks:", sum(len(g.get("hooks", [])) for g in starts))
PY

if grep -q '>>> claude-parent-guard' "$Z"; then
  echo "~/.zshrc already has the guard"
else
  { echo; sed -n '/^# >>> claude-parent-guard (zsh)/,/^# <<< claude-parent-guard (zsh)/p' "$HOOK" | sed 's/^# \{0,1\}//; s/^>>> /# >>> /; s/^<<< /# <<< /'; } >> "$Z"
  zsh -n "$Z" && echo "~/.zshrc: guard added (syntax ok); open a new Terminal tab to use it"
fi

# prove both pieces
printf '{"session_id":"install-check","cwd":"%s/code","source":"startup"}' "$HOME" | sh "$HOOK" | grep -q additionalContext && echo "hook: speaks up in ~/code"
zsh -c 'source ~/.zshrc >/dev/null 2>&1; cd ~/code && claude >/dev/null; [ $? = 1 ]' && echo "guard: stops in ~/code (claude --here starts anyway)"
echo "Done. In your next session, /hooks lists SessionStart. Undo: sh $0 --undo"
