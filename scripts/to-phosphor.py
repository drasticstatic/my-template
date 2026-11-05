#!/usr/bin/env python3
"""to-phosphor.py: turn a folder of the fleet's Lucide icons into two-tone Phosphor, for a repository that is drasticstatic's own.

    python3 scripts/to-phosphor.py <folder> [--primary 800020] [--dark e07a8f]   # overwrite each mapped .svg, same FILENAME, so no README link changes
    python3 scripts/to-phosphor.py --build                       # maintainers: fetch the art again into assets/icons-phosphor/ (curl)
    python3 scripts/to-phosphor.py --check                       # does the map cover the Lucide set, and is every master file sound?

The map is scripts/phosphor-map.tsv (lucide-name, phosphor-name, note); the master art is assets/icons-phosphor/, one file per
Lucide name, in maroon. Phosphor is MIT (Copyright (c) 2023 Phosphor Icons), so the licence travels beside the art: into a folder
with no LICENSE it lands as LICENSE, and beside someone else's LICENSE (Lucide's ISC, say) as LICENSE-phosphor, because a
licence already there may still cover icons left in the folder.

Each maroon icon carries one small <style> that lifts its fill to e07a8f in a dark colour scheme, because maroon on GitHub's dark
ground is 1.75:1 and e07a8f is 6.62:1 (the art's own measurement, Nov 5, 2026). A browser honours a media query inside an SVG even
when the SVG is in an <img>, so a README needs no <picture> and no second file. Another --primary drops the lift, unless --dark names one.

Left alone: anything not in the map, and every status-* icon, whose green, red, purple and grey mean something and are never
retoned (proposals-template/TONES.md). An organisation's repository stays Lucide: which family goes where is in LUCID.md.
"""
import argparse
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MAP = ROOT / "scripts/phosphor-map.tsv"
MASTER = ROOT / "assets/icons-phosphor"
LUCIDE = ROOT / "sop-template/repo/assets/icons"
MAROON = "800020"
LIFT = "e07a8f"
ART_URL = "https://raw.githubusercontent.com/phosphor-icons/core/main/assets/duotone/{}-duotone.svg"
LICENCE_URL = "https://raw.githubusercontent.com/phosphor-icons/core/main/LICENSE"


def read_map():
    pairs = {}
    for line in MAP.read_text(encoding="utf-8").splitlines():
        if line.strip() and not line.startswith("#"):
            lucide, phosphor = line.split("\t")[:2]
            pairs[lucide] = phosphor
    return pairs


def dark_style(hex_colour):
    return f"<style>@media (prefers-color-scheme: dark){{svg{{fill:#{hex_colour}}}}}</style>"


def with_dark(svg, hex_colour):
    """The style goes just inside the opening tag, so the art itself stays byte for byte what was fetched."""
    return re.sub(r"(<svg\b[^>]*>)", lambda m: m.group(1) + dark_style(hex_colour), svg, count=1)


def unsafe(svg):
    """What an icon must never carry. Art is fetched from outside, so it is read before it is accepted."""
    found = []
    if re.search(r"<style\b", svg.replace(dark_style(LIFT), ""), re.I):
        found.append("a style other than our dark-mode lift")
    if re.search(r"<script\b", svg, re.I):
        found.append("a script")
    if re.search(r"\son[a-z]+\s*=", svg, re.I):
        found.append("an event handler")
    if re.search(r"<(foreignObject|iframe|embed|object|image)\b", svg, re.I):
        found.append("an embed")
    if re.search(r"(?:xlink:)?href\s*=|url\(", svg, re.I):
        found.append("a link")
    return found


def build():
    """Fetches each mapped icon with curl, reads it, tones it maroon with its dark lift, writes the master set and the licence."""
    MASTER.mkdir(parents=True, exist_ok=True)
    failed = 0
    with tempfile.TemporaryDirectory() as tmp:
        for lucide, phosphor in sorted(read_map().items()):
            raw = Path(tmp) / f"{phosphor}.svg"
            got = subprocess.run(["curl", "-fsS", "-m", "30", "-o", str(raw), ART_URL.format(phosphor)], check=False)
            if got.returncode:
                print(f"FAIL  {lucide}: no Phosphor icon named {phosphor}")
                failed += 1
                continue
            svg = raw.read_text(encoding="utf-8")
            bad = unsafe(svg)
            if bad or "currentColor" not in svg:
                print(f"FAIL  {phosphor}: refused ({', '.join(bad) or 'not the expected art'})")
                failed += 1
                continue
            (MASTER / f"{lucide}.svg").write_text(with_dark(svg.replace("currentColor", f"#{MAROON}"), LIFT), encoding="utf-8")
        got = subprocess.run(["curl", "-fsS", "-m", "30", "-o", str(MASTER / "LICENSE"), LICENCE_URL], check=False)
        failed += bool(got.returncode)
    print(f"built {MASTER}: {len(list(MASTER.glob('*.svg')))} icons, {failed} problems")
    return failed


def check():
    pairs, failed = read_map(), 0

    def complain(message):
        nonlocal failed
        print(f"FAIL  {message}")
        failed += 1
    lucide = {p.stem for p in LUCIDE.glob("*.svg")}
    master = {p.stem for p in MASTER.glob("*.svg")}
    for name in sorted(lucide - set(pairs)):
        complain(f"{name} is in the Lucide set but not in the map")
    for name in sorted(set(pairs) - master):
        complain(f"{name} is in the map but has no master file")
    for name in sorted(master - lucide):
        complain(f"{name} is in the master set but not in the Lucide set; the filenames must match")
    for path in sorted(MASTER.glob("*.svg")):
        svg = path.read_text(encoding="utf-8")
        for what in unsafe(svg):
            complain(f"{path.name} carries {what}")
        if f'fill="#{MAROON}"' not in svg or 'opacity="0.2"' not in svg or "currentColor" in svg:
            complain(f"{path.name} is not two-tone maroon art")
        if dark_style(LIFT) not in svg:
            complain(f"{path.name} has no dark-mode lift")
    if not (MASTER / "LICENSE").is_file():
        complain("the master set has no LICENSE")
    print(f"map: {len(pairs)} names; master: {len(master)} icons; {failed} problems")
    return failed


def convert(folder, primary, dark=None):
    if folder.resolve() == MASTER.resolve():
        sys.exit("to-phosphor: that is the master set; copy from it, do not recolour it (--build remakes it)")
    pairs = read_map()
    done, left = 0, []
    for path in sorted(folder.glob("*.svg")):
        art = MASTER / path.name
        if path.stem.startswith("status-") or path.stem not in pairs:
            left.append(path.name)
            continue
        if not art.is_file():
            sys.exit(f"to-phosphor: the map names {path.stem} but {art} is missing; run --check")
        svg = art.read_text(encoding="utf-8")
        if primary != MAROON or dark:
            svg = svg.replace(dark_style(LIFT), "")
            if dark:
                svg = with_dark(svg, dark)
        path.write_text(svg.replace(f"#{MAROON}", f"#{primary}"), encoding="utf-8")
        done += 1
    if done:
        licence, ours = folder / "LICENSE", MASTER / "LICENSE"
        if not licence.exists():
            shutil.copyfile(ours, licence)
        elif licence.read_bytes() != ours.read_bytes():
            shutil.copyfile(ours, folder / "LICENSE-phosphor")
    lift = dark or (LIFT if primary == MAROON else None)
    print(f"{folder}: {done} icons now Phosphor duotone (#{primary}{', dark #' + lift if lift else ''}); left alone: {', '.join(left) or 'none'}")
    return 0


def main():
    ap = argparse.ArgumentParser(description="Lucide icons to two-tone Phosphor, same filenames. See the top of this file.")
    ap.add_argument("folder", nargs="?", type=Path)
    ap.add_argument("--primary", default=MAROON, help="the hex for the art and its .2-opacity layer (no #); default maroon")
    ap.add_argument("--dark", help=f"the hex a dark colour scheme lifts the art to (no #); maroon's is {LIFT}, another --primary has none unless named")
    ap.add_argument("--build", action="store_true", help="fetch the master set again")
    ap.add_argument("--check", action="store_true", help="check the map against the Lucide and master sets")
    a = ap.parse_args()
    if a.build:
        return 1 if build() else 0
    if a.check:
        return 1 if check() else 0
    if not a.folder or not a.folder.is_dir():
        ap.error("give a folder of icons, or --build, or --check")
    primary = a.primary.lstrip("#").lower()
    if not re.fullmatch(r"[0-9a-f]{6}", primary):
        ap.error("--primary takes one hex colour, no #")
    dark = a.dark.lstrip("#").lower() if a.dark else None
    if dark and not re.fullmatch(r"[0-9a-f]{6}", dark):
        ap.error("--dark takes one hex colour, no #")
    return convert(a.folder, primary, dark)


if __name__ == "__main__":
    sys.exit(main())
