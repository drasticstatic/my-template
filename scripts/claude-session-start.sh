#!/bin/sh
# claude-session-start.sh: a Claude Code SessionStart hook. It logs every start, and speaks up when a session started in
# a parent folder instead of inside a repository.
#
#   Written Nov 6, 2026. NOT installed by anyone but Christopher: it is persistent configuration. Install steps:
#   walkthroughs/CLAUDE-SESSION-ORDER.md. Proof: sh scripts/claude-projects-manifest.selftest.sh
#
# What it does, on every start (source startup, resume, clear, compact or fork):
#   1. Appends one row to ~/.claude/projects/SESSIONS-LOG.tsv: date, session id, cwd, source. The manifest
#      (claude-projects-manifest.py) reads it, so the manifest keeps itself.
#   2. When cwd is a parent folder (~, ~/code, ~/dappu, ~/drasticstaticLabs, ~/intent/workspaces, or a folder in ~
#      that is not a repository but holds repositories, such as an organisation folder), it prints the JSON below, which
#      Claude Code adds to the agent's context before the first prompt:
#        {"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"This session started in a parent ..."}}
#   It never blocks a session and always exits 0: Claude Code gives SessionStart no blocking (exit 2 only shows stderr
#   to the person). Reads nothing but its JSON input and folder names; never prints a token or the environment.
#
# --- (c) settings.json: merge this "hooks" block into ~/.claude/settings.json (the user file, so it covers every folder)
#   {
#     "hooks": {
#       "SessionStart": [
#         {
#           "hooks": [
#             { "type": "command", "command": "sh \"$HOME/code/my-template/scripts/claude-session-start.sh\"", "timeout": 10 }
#           ]
#         }
#       ]
#     }
#   }
#   No "matcher" means every source. Leave out an existing "hooks" key's other events as they are; add "SessionStart".
#
# --- (b) ~/.zshrc: "claude" in a parent folder lists the repositories and stops; "claude --here" starts there anyway.
# >>> claude-parent-guard (zsh)
# claude() {
#   local -a pass parents repos kids; local here=0 a d p i is_parent=0
#   for a in "$@"; do if [[ $a == --here ]]; then here=1; else pass+=("$a"); fi; done
#   case "${pass[1]-}" in
#     -p|--print|-v|--version|-h|--help|mcp|config|doctor|update|install|plugin|plugins|purge|auth|agents|attach|stop|rm|setup-token)
#       command claude "${pass[@]}"; return ;;
#   esac
#   d=${PWD:A}
#   parents=("$HOME" "$HOME/code" "$HOME/dappu" "$HOME/drasticstaticLabs" "$HOME/intent/workspaces")
#   (( ${parents[(Ie)$d]} )) && is_parent=1
#   if (( ! is_parent )) && [[ ${d:h} == $HOME && ! -e $d/.git ]]; then
#     kids=($d/*/.git(N)); (( ${#kids} )) && is_parent=1
#   fi
#   if (( is_parent && ! here )); then
#     print -r -- "claude: ${d/#$HOME/~} is a parent folder. A session is filed under the folder it starts in, so start it in the repository:"
#     repos=($d/*/.git(N:h:t)); i=1
#     for p in $repos; do print -r -- "  $i) cd ${d/#$HOME/~}/$p && claude"; (( i++ )); done
#     (( ${#repos} )) || print -r -- "  (no repositories directly inside; cd into the one you mean)"
#     print -r -- "Or start here anyway: claude --here"
#     return 1
#   fi
#   command claude "${pass[@]}"
# }
# <<< claude-parent-guard (zsh)
#   The guard covers the terminal only. The VS Code extension and the desktop app start Claude without a shell, so the
#   hook above is what speaks up there.
#
# Exit: always 0.

PY='
import json, os, sys, time
home = os.path.expanduser("~")
config = os.environ.get("CLAUDE_CONFIG_DIR") or os.path.join(home, ".claude")
try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)
if not isinstance(data, dict):
    sys.exit(0)
clean = lambda v: str(v or "").replace("\t", " ").replace("\n", " ")[:500]
sid, cwd, source = clean(data.get("session_id")), clean(data.get("cwd")), clean(data.get("source"))
projects = os.path.join(config, "projects")
log = os.path.join(projects, "SESSIONS-LOG.tsv")
try:
    os.makedirs(projects, exist_ok=True)
    new = not os.path.exists(log)
    with open(log, "a", encoding="utf-8") as fh:
        if new:
            fh.write("date\tsession_id\tsource\tcwd\n")
        fh.write("%s\t%s\t%s\t%s\n" % (time.strftime("%Y-%m-%dT%H:%M:%S%z"), sid, source, cwd))
except OSError:
    pass
if not cwd or not os.path.isdir(cwd):
    sys.exit(0)
cwd = os.path.realpath(cwd)
guarded = [os.path.join(home, g) for g in ("Desktop", "Documents", "Downloads", "Library", "Pictures", "Movies", "Music")]
if any(cwd == g or cwd.startswith(g + os.sep) for g in guarded):
    sys.exit(0)
fixed = [home] + [os.path.join(home, p) for p in ("code", "dappu", "drasticstaticLabs", "intent/workspaces")]
def repos_in(d):
    try:
        return sorted(n for n in os.listdir(d) if os.path.exists(os.path.join(d, n, ".git")))
    except OSError:
        return []
repos = repos_in(cwd)
parent = cwd in fixed or (os.path.dirname(cwd) == home and not os.path.exists(os.path.join(cwd, ".git")) and bool(repos))
if not parent:
    sys.exit(0)
short = lambda p: "~" + p[len(home):] if p.startswith(home) else p
listed = ", ".join(repos[:40]) + (" and %d more" % (len(repos) - 40) if len(repos) > 40 else "")
msg = ("This session started in a parent folder (%s), not inside a repository. Claude Code files its transcript under "
       "that folder, and its memory there is shared by everything inside. Before any work, ask Christopher which repository "
       "this is for, and suggest he restart Claude there (cd %s/<repo> && claude), or run /cd %s/<repo> in this session, "
       "which moves the session into that repository. Repositories directly inside: %s."
       % (short(cwd), short(cwd), short(cwd), listed or "none"))
print(json.dumps({"hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": msg}}))
'
python3 -I -c "$PY" 2>/dev/null
exit 0
