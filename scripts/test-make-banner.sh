#!/bin/sh
# test-make-banner.sh: make-banner.py keeps its promises. No network, no browser, nothing written outside a temp folder.
#     sh scripts/test-make-banner.sh
HERE=$(cd "$(dirname "$0")" && pwd)
MB="$HERE/make-banner.py"
T=$(mktemp -d "${TMPDIR:-/tmp}/make-banner.XXXXXX") || exit 1
trap 'rm -f "$T"/lane/* "$T"/ph/* "$T"/page/assets/icons/* "$T"/page/README.md; rmdir "$T"/page/assets/icons "$T"/page/assets "$T"/page "$T"/ph "$T"/lane; rm -f "$T"/*; rmdir "$T"' EXIT
mkdir "$T/lane" "$T/ph" "$T/page"
FAIL=0
no() { echo "FAIL  $1"; FAIL=$((FAIL + 1)); }
ok() { echo "ok    $1"; }

# every family with every motif: it writes, and its own check passes
n=0
for fam in amber purple teal blue emerald magenta brass rainbow maroon; do
  for motif in arch candles chain constellation mycelium path polygon seed unbound waves; do
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

# the families and motifs that came before maroon draw exactly what they always drew, down to the byte
pin_every_banner() {
  for fam in amber purple teal blue emerald magenta brass rainbow; do
    for motif in arch candles constellation mycelium path polygon seed waves; do
      python3 "$MB" --title "pin-$fam-$motif" --subtitle "A pinned banner." --kicker "A house" --family "$fam" --motif "$motif"
    done
  done
  for t in alpha beta gamma delta epsilon zeta eta theta; do python3 "$MB" --title "$t" --subtitle s --family teal; done
}
[ "$(pin_every_banner | shasum -a 256 | cut -d' ' -f1)" = "02bfe4d3431f852cdb2ec910ce275a0b4b1430337af9c60bbc3aace6309cf1d1" ] && ok "every banner from before maroon is byte-identical" || no "an older banner changed; the families and the title's pick must not"
# one real banner, as committed brass at ef21b2d (assets/banner-readme-standard.svg) before this template's own pages went maroon
[ "$(python3 "$MB" --title "README standard" --subtitle "A front door for every repository: where you are, what this is, how to help." --kicker "my-template · a living standard" --family brass --motif arch --count 13 | shasum -a 256 | cut -d' ' -f1)" = "5dc0350cae4268d03d62b23b9fd36759ac657690fe9a5301a90812e8f8c03398" ] && ok "a real committed banner regenerates byte-identical" || no "the committed brass banner no longer regenerates"

# maroon: its palette, its short names, and dark navy in the ground
python3 "$MB" --title m --subtitle s --family maroon --motif arch > "$T/m1"
python3 "$MB" --title m --subtitle s --family drasticstatic --motif arch > "$T/m2"
python3 "$MB" --title m --subtitle s --family ds --motif arch > "$T/m3"
cmp -s "$T/m1" "$T/m2" && cmp -s "$T/m1" "$T/m3" && ok "drasticstatic and ds are short for maroon" || no "the maroon aliases differ"
for c in 1a1a2e 0f3460 800020 5c1a2b fbeef1; do grep -q "#$c" "$T/m1" || no "the maroon banner has no #$c"; done
grep -q 'id="ground".*stop-color="#1a1a2e".*stop-color="#0f3460"' "$T/m1" && ok "maroon stands on a dark navy ground" || no "the maroon ground is not navy"
python3 "$MB" --title m --subtitle s --family teal --motif arch | grep -q 'ember' && no "another family took the maroon ember" || ok "the ember is maroon's alone"

# chain: linked blocks, for a blockchain repository, only when asked for by name
python3 "$MB" --title "a bootcamp" --subtitle s --family maroon --motif chain --out "$T/c1" >/dev/null && python3 "$MB" --check "$T/c1" >/dev/null && grep -q '5 blocks arrive' "$T/c1" && ok "--motif chain draws linked blocks and passes --check" || no "--motif chain failed"
python3 "$MB" --title "a bootcamp" --subtitle s --family maroon --motif chain --count 30 >/dev/null && python3 "$MB" --title "a bootcamp" --subtitle s --family maroon --motif chain --count 3 >/dev/null && ok "chain holds from 3 to 30 blocks" || no "chain failed at the ends of --count"
python3 "$MB" --title "a bootcamp" --subtitle s --family maroon --motif candles | grep -q 'blocks arrive' && no "candles drew blocks" || ok "chain is its own picture, not candles"
for t in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16; do python3 "$MB" --title "pick $t" --subtitle s --family lab; done | grep -q 'blocks arrive' && no "the title's own pick reached chain" || ok "a title never picks chain"

# unbound: a chain that opens and stays open, only when asked for by name, and it says nothing but the title
python3 "$MB" --title "a name" --subtitle "" --family maroon --motif unbound --out "$T/u1" >/dev/null && python3 "$MB" --check "$T/u1" >/dev/null && grep -q 'middle link has opened' "$T/u1" && ok "--motif unbound draws the opened chain and passes --check" || no "--motif unbound failed"
[ "$(grep -c '<text' "$T/u1")" -eq 1 ] && ok "with an empty subtitle the title is the only words" || no "an empty subtitle still set words"
grep -q '<desc id="d">The picture:' "$T/u1" && ok "an empty subtitle leaves the description clean" || no "an empty subtitle left a stray space in the description"
sed -n '/no-preference/,/^    }$/d; p' "$T/u1" | grep -q 'animation:' && no "unbound moves outside the reduced-motion gate" || ok "unbound moves only inside the gate"
sed -n '/no-preference/,/^    }$/d; p' "$T/u1" | grep -q 'class="part-l"' && ok "unbound's finished, open picture is what stands outside the gate" || no "unbound has no finished picture"
python3 "$MB" --title "a name" --subtitle s --family maroon --motif unbound --count 30 >/dev/null && python3 "$MB" --title "a name" --subtitle s --family maroon --motif unbound --count 3 >/dev/null && ok "unbound holds from 3 to 30 links a side" || no "unbound failed at the ends of --count"
for t in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16; do python3 "$MB" --title "pick $t" --subtitle s --family lab; done | grep -q 'middle link has opened' && no "the title's own pick reached unbound" || ok "a title never picks unbound"
python3 "$MB" --title "a name" --family lab --motif path >/dev/null 2>&1 && no "a forgotten subtitle was accepted" || ok "a forgotten subtitle is still refused"

# Phosphor: the map covers the Lucide set, the master set is sound, a folder turns over with its filenames
TP="$HERE/to-phosphor.py"
python3 "$TP" --check >/dev/null && ok "the map covers every Lucide name and every master icon is two-tone maroon" || no "to-phosphor.py --check failed"
[ "$(grep -vc '^#' "$HERE/phosphor-map.tsv")" -eq "$(ls "$HERE/../sop-template/repo/assets/icons/"*.svg | wc -l | tr -d ' ')" ] && ok "one map line per Lucide icon" || no "the map and the Lucide set differ in length"
cp "$HERE/../sop-template/repo/assets/icons/compass.svg" "$HERE/../sop-template/repo/assets/icons/LICENSE" "$T/ph/"
printf '<svg xmlns="http://www.w3.org/2000/svg"><circle fill="#15803d" r="1"/></svg>' > "$T/ph/status-ready.svg"
printf '<svg xmlns="http://www.w3.org/2000/svg"><circle fill="#123456" r="1"/></svg>' > "$T/ph/not-in-the-map.svg"
cp "$T/ph/status-ready.svg" "$T/keep1"; cp "$T/ph/not-in-the-map.svg" "$T/keep2"; cp "$T/ph/LICENSE" "$T/keep3"
python3 "$TP" "$T/ph" >/dev/null
grep -q 'fill="#800020"' "$T/ph/compass.svg" && grep -q 'opacity="0.2"' "$T/ph/compass.svg" && ! grep -q 'currentColor' "$T/ph/compass.svg" && ok "a mapped icon turns to two-tone maroon, same filename" || no "to-phosphor.py did not convert compass.svg"
cmp -s "$T/ph/status-ready.svg" "$T/keep1" && ok "status-* icons are left alone" || no "to-phosphor.py touched a status icon"
cmp -s "$T/ph/not-in-the-map.svg" "$T/keep2" && ok "an icon outside the map is left alone" || no "to-phosphor.py touched an unmapped icon"
cmp -s "$T/ph/LICENSE" "$T/keep3" && grep -q 'Phosphor' "$T/ph/LICENSE-phosphor" && ok "the licence lands beside the other one, which stays" || no "to-phosphor.py lost a licence"
python3 "$TP" "$T/ph" --primary 0f3460 >/dev/null && grep -q 'fill="#0f3460"' "$T/ph/compass.svg" && ok "--primary recolours the art" || no "--primary was ignored"
python3 "$TP" "$T/ph" --primary nope >/dev/null 2>&1 && no "--primary took something that is not a colour" || ok "--primary refuses what is not a colour"
python3 "$TP" "$HERE/../assets/icons-phosphor" >/dev/null 2>&1 && no "to-phosphor.py recoloured its own master set" || ok "the master set refuses to be recoloured"
printf '# p\n<img src="assets/icons/compass.svg" width="16" height="16" alt="">\n' > "$T/page/README.md"
python3 "$MB" --icons "$T/page/README.md" --family maroon >/dev/null && grep -q 'fill="#800020"' "$T/page/assets/icons/compass.svg" && grep -q 'Phosphor' "$T/page/assets/icons/LICENSE" && ok "--icons --family maroon copies Phosphor and its licence" || no "--icons maroon did not copy Phosphor"

# the hero stays small and within the rules
HERO="$HERE/../assets/demo.svg"
python3 "$MB" --check "$HERO" >/dev/null && [ "$(wc -c < "$HERO" | tr -d ' ')" -lt 61440 ] && ! grep -q '<script\|<animate\|font-face\|@import' "$HERO" && ok "the hero passes --check, under 60 KB, no SMIL, script or font" || no "the hero broke a rule"

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
