set -u
R="$(mktemp -d)"; mkdir -p "$R/home/code/pir/foo" "$R/home/code/pir-foo" "$R/projects"
P="$R/projects"
enc() { printf '%s' "$1" | sed 's/[^A-Za-z0-9]/-/g'; }
git -C "$R/home/code/pir/foo" init -q; git -C "$R/home/code/pir/foo" -c user.email=a@b -c user.name=a commit -q --allow-empty -m one
git -C "$R/home/code/pir/foo" worktree add -q "$R/wt" -b side
mk() { d="$P/$(enc "$1")"; mkdir -p "$d/memory"; echo note > "$d/memory/MEMORY.md"; printf '{"cwd":"%s","type":"user"}\n' "$2" > "$d/s1.jsonl"; }
mk "$R/home/code/pir" "$R/home/code/pir"
mk "$R/home/code/pir/foo" "$R/home/code/pir/foo"
mkdir -p "$P/$(enc "$R/home/code/pir")-empty"
pass=0; fail=0; ok() { if [ "$1" = "$2" ]; then pass=$((pass+1)); else fail=$((fail+1)); echo "FAIL $3: got [$1] want [$2]"; fi; }
T="python3 -I $(dirname "$0")/rename-local-repo.py"
# a sibling that flattens alike collides with the child's project name
out=$($T "$R/home/code/pir" "$R/home/code/pir-lab" --projects "$P")
ok "$(printf '%s' "$out" | grep -c 'DRY RUN')" 1 "dry run says so"
ok "$([ -d "$R/home/code/pir" ] && echo yes)" yes "dry run moves nothing"
ok "$(printf '%s' "$out" | grep -c 'LEFT ALONE')" 1 "the empty project dir is left alone"
$T "$R/home/code/pir" "$R/home/code/pir-lab" --projects "$P" --apply >/dev/null
ok "$([ -d "$R/home/code/pir-lab/foo" ] && echo yes)" yes "folder moved"
ok "$([ -d "$P/$(enc "$R/home/code/pir-lab")/memory" ] && echo yes)" yes "parent project moved with memory"
ok "$(cat "$P/$(enc "$R/home/code/pir-lab")-foo/memory/MEMORY.md" 2>/dev/null)" note "child project moved"
ok "$(grep -c cwd "$P/$(enc "$R/home/code/pir-lab")-foo/s1.jsonl")" 1 "transcript intact"
ok "$(git -C "$R/wt" status -sb 2>/dev/null | head -1)" "## side" "linked worktree repaired"
ok "$($T "$R/home/code/pir-lab" "$R/home/code/pir-foo" --projects "$P" | head -1 | cut -c1-8)" refused: "refuses an existing target"
# a true collision: the sibling's project keeps its place when its cwd is elsewhere
mkdir -p "$R/home/code/abc" "$R/home/code/abc-x"; d="$P/$(enc "$R/home/code/abc")-x"; mkdir -p "$d"; printf '{"cwd":"%s"}\n' "$R/home/code/abc-x" > "$d/s.jsonl"
$T "$R/home/code/abc" "$R/home/code/abc-lab" --projects "$P" --apply >/dev/null
ok "$([ -d "$d" ] && echo stays)" stays "a sibling's history is not taken by a name match"
# a move is noted in MANIFEST-LOG.md's Moves section, above its end marker; a dry run notes nothing
printf '## Moves\n- an older line\n<!-- moves:end (new lines go above this one) -->\n## After\n' > "$P/MANIFEST-LOG.md"
mkdir -p "$R/home/code/mno"; d2="$P/$(enc "$R/home/code/mno")"; mkdir -p "$d2"; printf '{"cwd":"%s"}\n' "$R/home/code/mno" > "$d2/s.jsonl"
$T "$R/home/code/mno" "$R/home/code/mno-lab" --projects "$P" >/dev/null
ok "$(wc -l < "$P/MANIFEST-LOG.md" | tr -d ' ')" 4 "a dry run leaves the manifest alone"
$T "$R/home/code/mno" "$R/home/code/mno-lab" --projects "$P" --apply >/dev/null
ok "$(sed -n 3p "$P/MANIFEST-LOG.md" | grep -c -F -- "mno-lab\`, by rename-local-repo.py. Claude project folders: \`$(enc "$R/home/code/mno")\` to \`$(enc "$R/home/code/mno-lab")\`")" 1 "the move is noted above the Moves end marker"
ok "$(sed -n 4p "$P/MANIFEST-LOG.md" | cut -c1-14)" "<!-- moves:end" "the end marker stays below it"
echo "rename-local-repo: $pass passed, $fail failed"; exit $fail
