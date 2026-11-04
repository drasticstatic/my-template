#!/bin/sh
# test-make-banner.sh: make-banner.py keeps its promises. No network, no browser, nothing written outside a temp folder.
#     sh scripts/test-make-banner.sh
HERE=$(cd "$(dirname "$0")" && pwd)
MB="$HERE/make-banner.py"
T=$(mktemp -d "${TMPDIR:-/tmp}/make-banner.XXXXXX") || exit 1
trap 'rm -f "$T"/lane/*; rmdir "$T"/lane; rm -f "$T"/*; rmdir "$T"' EXIT
mkdir "$T/lane"
FAIL=0
no() { echo "FAIL  $1"; FAIL=$((FAIL + 1)); }
ok() { echo "ok    $1"; }

# every family with every motif: it writes, and its own check passes
n=0
for fam in amber purple teal blue emerald magenta brass rainbow; do
  for motif in arch candles constellation mycelium path polygon seed waves; do
    python3 "$MB" --title "repo-$fam-$motif" --subtitle "A test banner." --kicker "A house" --family "$fam" --motif "$motif" --out "$T/lane/$fam-$motif.svg" >/dev/null || no "$fam $motif did not build"
    n=$((n + 1))
  done
done
python3 "$MB" --check "$T"/lane/*.svg >/dev/null && ok "$n banners pass --check" || no "--check refused a banner this script made"

# the public-lane tripwire reads them and lets them through
if [ -f "$HERE/scan-public-lane.sh" ]; then
  sh "$HERE/scan-public-lane.sh" "$T/lane" >/dev/null 2>&1 && ok "the public-lane tripwire passes them" || no "the public-lane tripwire refused a banner"
fi

# the same words give the same picture; other words give another
python3 "$MB" --title same --subtitle words --family teal --motif constellation > "$T/a"
python3 "$MB" --title same --subtitle words --family teal --motif constellation > "$T/b"
python3 "$MB" --title other --subtitle words --family teal --motif constellation > "$T/c"
cmp -s "$T/a" "$T/b" && ok "same words, same picture" || no "not deterministic"
[ "$(grep -c '<circle' "$T/a")" -gt 0 ] && ! cmp -s "$T/a" "$T/c" && ok "other words, another picture" || no "two titles drew the same picture"

# the two house styles: a style sets the motif and wears brass unless a family is named
python3 "$MB" --style seed --title "a beginning" --subtitle words --out "$T/s1" >/dev/null 2>&1 && python3 "$MB" --check "$T/s1" >/dev/null && grep -q 'find each other' "$T/s1" && grep -q '#d9a441' "$T/s1" && ok "--style seed builds in brass and passes --check" || no "--style seed did not build, failed --check, or is not the seed picture in brass"
python3 "$MB" --style waves --title "a front door" --subtitle words --out "$T/s2" >/dev/null 2>&1 && python3 "$MB" --check "$T/s2" >/dev/null && grep -q 'waves drawing in' "$T/s2" && ok "--style waves builds and passes --check" || no "--style waves did not build or is not the waves picture"
python3 "$MB" --style seed --family teal --title "a beginning" --subtitle words > "$T/s3" 2>/dev/null && ! grep -q '#d9a441' "$T/s3" && ok "--style seed takes a named family instead of brass" || no "--style seed ignored --family"
python3 "$MB" --motif mycelium --family brass --title "a beginning" --subtitle words > "$T/s4" 2>/dev/null && ! cmp -s "$T/s1" "$T/s4" && ok "seed is its own picture, not mycelium" || no "seed drew the mycelium picture"
python3 "$MB" --style seed --motif waves --title a --subtitle b >/dev/null 2>&1 && no "--style with --motif was accepted" || ok "--style with --motif is refused"
python3 "$MB" --title "constellation of words" --subtitle s --family lab > "$T/s5" 2>/dev/null && ! grep -q 'find each other' "$T/s5" && ok "a title picks its motif from the seven, never seed" || no "the title's own pick reached seed"

# motion only inside the gate
sed -n '/no-preference/,/^    }$/d; p' "$T/a" | grep -q 'animation:' && no "motion outside the reduced-motion gate" || ok "motion lives only inside the gate"

# words are escaped
python3 "$MB" --title 'a<b&c' --subtitle 'x "y" </desc><script>z</script>' --family lab --motif path --out "$T/d" >/dev/null
python3 "$MB" --check "$T/d" >/dev/null && ! grep -q '<script' "$T/d" && ok "words are escaped" || no "words reached the markup"

# what must be refused is refused
printf '<svg xmlns="http://www.w3.org/2000/svg"><title>t</title><circle r="1"><animate attributeName="r" values="1;2" dur="1s"/></circle></svg>' > "$T/e"
printf '<svg xmlns="http://www.w3.org/2000/svg"><title>t</title><style>.a{animation:b 1s}</style></svg>' > "$T/f"
printf '<svg xmlns="http://www.w3.org/2000/svg"><title>t</title><style>@media (prefers-reduced-motion: no-preference){.a{animation:b 1s}}</style><script>1</script></svg>' > "$T/g"
printf '<svg xmlns="http://www.w3.org/2000/svg"><title>t</title><style>@media (prefers-reduced-motion: no-preference){.a{animation:b 1s}}</style><image href="https://example.com/a.png"/></svg>' > "$T/h"
printf '<svg xmlns="http://www.w3.org/2000/svg"><title>t</title><style>@media (prefers-reduced-motion: no-preference){.a{animation:b 1s}}</style><image class="a" href="data:image/webp;base64,UklGRg=="/></svg>' > "$T/i"
python3 "$MB" --check "$T/i" >/dev/null && ok "--check allows a picture baked into the file" || no "--check refused a baked picture"
for f in e f g h; do python3 "$MB" --check "$T/$f" >/dev/null && no "--check passed a bad banner ($f)" || ok "--check refuses bad banner $f"; done

# a title or subtitle that cannot fit is refused, not squeezed
python3 "$MB" --title "$(printf 'x%.0s' 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0)" --subtitle s --family lab >/dev/null 2>&1 && no "an unbreakable long title was accepted" || ok "a title too long is refused"

# this template's own front doors meet the standard
python3 "$MB" --check-readme "$HERE/../README.md" "$HERE/../README-STANDARD.md" >/dev/null && ok "README.md and README-STANDARD.md pass --check-readme" || no "my-template's own READMEs fail --check-readme"

echo ""
[ "$FAIL" -eq 0 ] && echo "all passed" || { echo "$FAIL failed"; exit 1; }
