#!/bin/sh
# build.sh: compile the runbook tray into an app with what macOS ships (osacompile, plutil, codesign). No outside code.
#
#   sh build.sh --config FILE              build "Runbook Tray.app" in ~/Applications from tray.applescript
#   sh build.sh --config FILE --print      say what it would do; write nothing
#
#   --out DIR        where the app goes (default ~/Applications)
#   --name NAME      the app's name, and the name in its Quit entry (default "Runbook Tray")
#   --bundle-id ID   its identifier (default local.runbook-tray)
#   --python PATH    the python3 the tray runs the helper with (default: the first python3 on PATH that is not
#                    /usr/bin/python3, whose first run can open an install dialog; then Homebrew's two usual places)
#   --state DIR      where the tray keeps its few files (default ~/Library/Application Support/<name>)
#   --every N        seconds between checks, 15 or more (default 60)
#
# It does not start the app and adds nothing to Login Items: both are yours. An app already at that place is moved
# into <state>/previous-builds/<time>/ and never deleted. It refuses while that app is running.
#
# The app is signed for this Mac only ("ad hoc"), which is what a locally built app needs to start on Apple silicon.
# It is not notarised and is not meant to be copied to another Mac: build it there from this folder instead.
#
# Exit: 0 built, or printed · 1 a step failed · 2 usage or config error · 3 the app is running; quit it from its menu first.
set -u
here="$(cd "$(dirname "$0")" && pwd -P)"
HELPER="$here/runbook-tray.py"
SOURCE="$here/tray.applescript"

CONFIG=""; OUT="$HOME/Applications"; NAME="Runbook Tray"; BUNDLE="local.runbook-tray"; PY=""; STATE=""; EVERY=60; PRINT=0
while [ $# -gt 0 ]; do
  case "$1" in
    --config|--out|--name|--bundle-id|--python|--state|--every)
      [ $# -ge 2 ] || { echo "build: $1 needs a value" >&2; exit 2; }
      case "$1" in
        --config) CONFIG="$2" ;; --out) OUT="$2" ;; --name) NAME="$2" ;; --bundle-id) BUNDLE="$2" ;;
        --python) PY="$2" ;; --state) STATE="$2" ;; --every) EVERY="$2" ;;
      esac
      shift ;;
    --print) PRINT=1 ;;
    -h|--help) sed -n '2,21p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "build: unknown option: $1" >&2; exit 2 ;;
  esac
  shift
done

[ -n "$CONFIG" ] || { echo "build: --config FILE is needed (start from config.example.json)" >&2; exit 2; }
[ -f "$CONFIG" ] || { echo "build: no config at $CONFIG" >&2; exit 2; }
CONFIG="$(cd "$(dirname "$CONFIG")" && pwd -P)/$(basename "$CONFIG")"
case "$EVERY" in ''|*[!0-9]*) echo "build: --every wants a whole number of seconds" >&2; exit 2 ;; esac
[ "$EVERY" -ge 15 ] || { echo "build: --every must be 15 or more" >&2; exit 2; }
case "$NAME" in ''|*/*|*'"'*|*'\'*) echo "build: --name cannot be empty or hold a slash, a quote or a backslash" >&2; exit 2 ;; esac
case "$BUNDLE" in ''|*[!A-Za-z0-9.-]*) echo "build: --bundle-id is letters, digits, dots and hyphens" >&2; exit 2 ;; esac
[ -n "$STATE" ] || STATE="$HOME/Library/Application Support/$NAME"
APP="$OUT/$NAME.app"

if [ -z "$PY" ]; then
  PY="$(command -v python3 || true)"
  if [ -z "$PY" ] || [ "$PY" = /usr/bin/python3 ]; then
    PY=""
    for p in /opt/homebrew/bin/python3 /usr/local/bin/python3; do [ -x "$p" ] && PY="$p" && break; done
  fi
fi
[ -n "$PY" ] && [ -x "$PY" ] || { echo "build: no python3 found other than /usr/bin/python3; name one with --python" >&2; exit 2; }
for f in "$HELPER" "$SOURCE"; do [ -f "$f" ] || { echo "build: $f is missing" >&2; exit 1; }; done
for tool in /usr/bin/osacompile /usr/bin/plutil /usr/bin/codesign; do
  [ -x "$tool" ] || { echo "build: $tool is not on this machine; the tray is built on macOS" >&2; exit 1; }
done

"$PY" -I "$HELPER" doctor --config "$CONFIG" || { echo "build: fix the config first (above)" >&2; exit 2; }

if ps -axo command= | grep -F "$APP/Contents/MacOS/applet" | grep -v grep >/dev/null 2>&1; then
  echo "build: $APP is running. Quit it from its own menu, then build again." >&2
  exit 3
fi

echo
echo "app      $APP"
echo "python   $PY"
echo "helper   $HELPER"
echo "state    $STATE"
echo "checks   every $EVERY s"
if [ "$PRINT" = 1 ]; then
  [ -e "$APP" ] && echo "         (an app is there now; a build would move it to $STATE/previous-builds/)"
  echo "build: printed only; nothing was written"
  exit 0
fi

work="$(mktemp -d "${TMPDIR:-/tmp}/runbook-tray-build.XXXXXX")" || exit 1
stamped="$work/tray.applescript"
"$PY" -I "$HELPER" stamp --source "$SOURCE" "PYTHON=$PY" "HELPER=$HELPER" "CONFIG=$CONFIG" "STATE=$STATE" \
  "NAME=$NAME" "EVERY=$EVERY" > "$stamped" || { echo "build: could not fill in the source" >&2; exit 1; }
# osacompile signs what it makes and says so on stderr; its words are shown only when it fails.
/usr/bin/osacompile -s -o "$work/$NAME.app" "$stamped" 2>"$work/compile.err" \
  || { cat "$work/compile.err" >&2; echo "build: osacompile refused the source" >&2; exit 1; }
plist="$work/$NAME.app/Contents/Info.plist"
/usr/bin/plutil -replace LSUIElement -bool true "$plist" \
  && /usr/bin/plutil -replace CFBundleIdentifier -string "$BUNDLE" "$plist" \
  && /usr/bin/plutil -replace CFBundleName -string "$NAME" "$plist" \
  && /usr/bin/plutil -replace CFBundleDisplayName -string "$NAME" "$plist" \
  || { echo "build: could not write the app's Info.plist" >&2; exit 1; }
/usr/bin/codesign --force --sign - "$work/$NAME.app" 2>/dev/null \
  && /usr/bin/codesign --verify "$work/$NAME.app" \
  || { echo "build: could not sign the app for this Mac" >&2; exit 1; }

mkdir -p "$OUT" "$STATE" || exit 1
chmod 700 "$STATE"
if [ -e "$APP" ]; then
  old="$STATE/previous-builds/$(date +%Y%m%d-%H%M%S)"
  mkdir -p "$old" && mv "$APP" "$old/" || { echo "build: could not move the app that was there" >&2; exit 1; }
  echo "moved    the app that was there to $old/"
fi
mv "$work/$NAME.app" "$APP" || { echo "build: could not put the app in $OUT" >&2; exit 1; }
mv "$stamped" "$STATE/last-build.applescript" 2>/dev/null
mv "$work/compile.err" "$STATE/last-build.compile.txt" 2>/dev/null
rmdir "$work" 2>/dev/null

echo
echo "built    $APP"
echo "start    open -g \"$APP\"        (an item appears in the menu bar; no window, no Dock icon)"
echo "stop     its own menu, Quit $NAME"
echo "at login System Settings > General > Login Items > Open at Login > +   (yours to choose; this script adds nothing)"
echo "files    $STATE/   (menu.json, status.json, tray.log, actions/)"
