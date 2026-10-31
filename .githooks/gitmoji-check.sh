#!/bin/sh
# gitmoji-check.sh — WARN-ONLY check of the commit subject against GITMOJI.md.
#
#     :sparkles: feat(scope): subject
#
# Called by .githooks/commit-msg after the attribution check has passed. It can
# also be run by hand on a message file:  sh .githooks/gitmoji-check.sh MSGFILE
#
# Prints at most ONE hint line on stderr and ALWAYS exits 0. It never blocks a
# commit: the subject convention is a habit to build, not a gate. The footer
# (attribution) is the gate, and it lives in commit-msg, untouched by this file.
#
# Spec: GITMOJI.md (https://github.com/drasticstatic/my-template/blob/main/GITMOJI.md)

MSG_FILE="$1"
[ -n "$MSG_FILE" ] && [ -f "$MSG_FILE" ] || exit 0

# Subject = first line that isn't a comment or blank.
SUBJECT=$(grep -v '^#' "$MSG_FILE" | grep -m1 '[^[:space:]]')
[ -n "$SUBJECT" ] || exit 0

hint() {
  printf '  \342\232\240 gitmoji: %s (GITMOJI.md)\n' "$1" >&2
  exit 0
}

# Exempt: messages git or a tool writes for you.
case "$SUBJECT" in
  "Merge "*|"Revert \""*|"Revert '"*|"fixup! "*|"squash! "*|"amend! "*) exit 0 ;;
esac

type_for() {
  case "$1" in
    sparkles) echo feat ;;      bug) echo fix ;;          memo) echo docs ;;
    white_check_mark) echo test ;; lock) echo security ;; recycle) echo refactor ;;
    wrench) echo config ;;      rocket) echo deploy ;;    bookmark) echo release ;;
    rewind) echo revert ;;      truck) echo move ;;       construction) echo wip ;;
    *) echo "" ;;
  esac
}

# The twelve glyphs, mapped to their alias. Compared byte-wise with the
# variation selector (U+FE0F) stripped, so "♻" and "♻️" are the same.
alias_for_glyph() {
  case "$1" in
    "✨") echo sparkles ;;   "🐛") echo bug ;;          "📝") echo memo ;;
    "✅") echo white_check_mark ;; "🔒") echo lock ;;   "♻") echo recycle ;;
    "🔧") echo wrench ;;     "🚀") echo rocket ;;       "🔖") echo bookmark ;;
    "⏪") echo rewind ;;     "🚚") echo truck ;;        "🚧") echo construction ;;
    *) echo "" ;;
  esac
}

FIRST=${SUBJECT%% *}
REST=${SUBJECT#"$FIRST"}
REST=${REST# }
[ "$FIRST" = "$SUBJECT" ] && REST=""

GLYPH=""
case "$FIRST" in
  :*:)
    ALIAS=${FIRST#:}; ALIAS=${ALIAS%:}
    ;;
  "["[Pp][123]*"]"*)
    hint "priority marker goes after the type, not first: ':bug: fix(scope): [P1] subject'"
    ;;
  *)
    STRIPPED=$(printf '%s' "$FIRST" | LC_ALL=C sed "s/$(printf '\357\270\217')//g")
    ALIAS=$(alias_for_glyph "$STRIPPED")
    if [ -n "$ALIAS" ]; then
      GLYPH=1
    else
      # A non-ASCII first token is some other emoji; ASCII means no gitmoji at all.
      if printf '%s' "$FIRST" | LC_ALL=C grep -q '[^ -~]'; then
        hint "'$FIRST' is not one of the twelve; start with e.g. ':sparkles: feat(scope): subject'"
      fi
      hint "subject has no gitmoji; start it like ':sparkles: feat(scope): subject'"
    fi
    ;;
esac

EXPECTED=$(type_for "$ALIAS")
if [ -z "$EXPECTED" ]; then
  case " $ALIAS " in
    " fire "|" zap "|" rotating_light "|" leaves ")
      hint ":$ALIAS: is a ledger priority glyph, not a type; use one of the twelve and '[P1]' after the type" ;;
  esac
  hint ":$ALIAS: is not one of the twelve (:sparkles: :bug: :memo: :white_check_mark: :lock: :recycle: :wrench: :rocket: :bookmark: :rewind: :truck: :construction:)"
fi

# After the gitmoji: type(scope)!: subject
TYPE=$(printf '%s' "$REST" | sed -n 's/^\([a-z][a-z]*\)\(([^)]*)\)\{0,1\}!\{0,1\}: [^ ].*/\1/p')
if [ -z "$TYPE" ]; then
  hint "after :$ALIAS: write the type, then ': subject', e.g. ':$ALIAS: $EXPECTED(scope): subject'"
fi
if [ "$TYPE" != "$EXPECTED" ]; then
  hint ":$ALIAS: goes with '$EXPECTED', not '$TYPE'"
fi

if [ -n "$GLYPH" ]; then
  hint "glyph form accepted; the alias ':$ALIAS:' greps and survives every terminal"
fi

exit 0
