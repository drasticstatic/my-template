#!/usr/bin/env python3
"""make-banner.py: a repository's banner, as one small SVG with no dependencies. Part of README-STANDARD.md.

    python3 scripts/make-banner.py --title NAME --subtitle "WHAT IT IS" --family amber --motif waves \\
                                   [--kicker "WHOSE IT IS"] [--count N] [--seed TEXT] [--out assets/banner.svg]
    python3 scripts/make-banner.py --palette 134e4a,0f766e,0d9488,ccfbf1 ...   # your own four shades, instead of --family
    python3 scripts/make-banner.py --list                                      # families and motifs
    python3 scripts/make-banner.py --check assets/banner.svg ...               # does a banner meet the standard?
    python3 scripts/make-banner.py --check-readme README.md ...                # does a README meet the standard?
    python3 scripts/make-banner.py --icons README.md [--family amber]          # copy the Lucide icons it names, toned

The same words give the same picture, and different words give a different one: the geometry grows from --seed, which
defaults to the title. Choose the motif for what the repository means; left out, it is picked from the title.

What the fleet's hand-drawn banners taught, kept here so nobody relearns it:
  * Motion lives only inside @media (prefers-reduced-motion: no-preference). Outside it every element is in its
    finished state, so a reader who asked for less, or a viewer that ignores CSS, sees the whole picture at once.
    SMIL (<animate>) cannot honour that setting, so it is never used.
  * An opaque ground, so one file reads the same on GitHub's light and dark themes.
  * The words hold still. Only the picture moves.
  * Cost: no filters and no blur; an intro that finishes, then at most two quiet loops at 12 frames a second (steps()).
    An SVG in an <img> repaints on the main thread, and a banner should not warm anyone's laptop.
  * System fonts only: an SVG in an <img> cannot load anything, so no font files, no images, no links, no script.
    That is also why a banner from this script passes the public-lane tripwire.
"""
import argparse
import hashlib
import math
import random
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path
from xml.sax.saxutils import escape

W, H, RAIL = 1200, 260, 12
TEXT_X, TEXT_W = 56, 590
ZONE = (668, 28, 1160, 222)  # x0, y0, x1, y1: where the picture lives
FONT = "Helvetica Neue, Helvetica, Arial, sans-serif"

# One family per organisation, four shades each: proposals-template/TONES.md is the register.
FAMILIES = {
    "amber": ("6b4f1d", "b45309", "d97706", "fef3c7"),
    "purple": ("3b1f6e", "7c3aed", "5b2bb5", "ede9fe"),
    "teal": ("134e4a", "0f766e", "0d9488", "ccfbf1"),
    "blue": ("1e3a8a", "1d4ed8", "2563eb", "dbeafe"),
    "emerald": ("064e3b", "047857", "059669", "d1fae5"),
    "magenta": ("9d174d", "be185d", "ec4899", "fce7f3"),
    "brass": ("334155", "8a6a2a", "d9a441", "f1f5f9"),
    "rainbow": ("312e81", "7c3aed", "2563eb", "f5f3ff"),
}
RAINBOW = ("dc2626", "ea580c", "ca8a04", "16a34a", "2563eb", "7c3aed")
ALIASES = {"thef": "amber", "pir": "purple", "psanctuary": "teal", "ethereal-offering": "teal", "church": "blue",
           "org": "emerald", "taylor": "magenta", "lab": "brass", "david": "rainbow"}
# The icon stroke for GitHub's light and dark pages. Purple's primary is too dark on the dark page, so it uses its mid.
ICON_STROKE = {"amber": "d97706", "purple": "7c3aed", "teal": "0d9488", "blue": "2563eb", "emerald": "059669",
               "magenta": "ec4899", "brass": "d9a441", "rainbow": "7c4dff"}


# ---------------------------------------------------------------- colour
def rgb(h):
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def mix(a, b, t):
    """t = 0 gives a, t = 1 gives b."""
    return "".join(f"{round(x + (y - x) * t):02x}" for x, y in zip(rgb(a), rgb(b)))


def luminance(h):
    def channel(c):
        c /= 255
        return c / 12.92 if c <= .03928 else ((c + .055) / 1.055) ** 2.4
    r, g, b = map(channel, rgb(h))
    return .2126 * r + .7152 * g + .0722 * b


def contrast(a, b):
    hi, lo = sorted((luminance(a), luminance(b)), reverse=True)
    return (hi + .05) / (lo + .05)


def legible(colour, on, least):
    """The colour, moved toward white only as far as it takes to reach the contrast asked for on this ground."""
    for t in range(0, 101, 2):
        c = mix(colour, "ffffff", t / 100)
        if contrast(c, on) >= least:
            return c
    return "ffffff"


class Tone:
    def __init__(self, shades, hues=None):
        self.deep, self.mid, self.primary, self.tint = shades
        self.hues = hues
        self.ground_a = mix(self.deep, "0a0f1a", .62)
        self.ground_b = mix(self.deep, "0a0f1a", .86)
        worst = self.ground_a if luminance(self.ground_a) > luminance(self.ground_b) else self.ground_b
        self.title = legible(self.tint, worst, 7)
        self.sub = legible(mix(self.tint, self.ground_a, .14), worst, 4.5)
        self.line = legible(self.primary, worst, 3.2)
        self.kicker = legible(self.primary, worst, 4.5)
        self.hi = mix(self.line, self.tint, .55)
        self.dim = mix(self.line, self.ground_a, .55)
        self.faint = mix(self.line, self.ground_a, .8)
        self.pit = self.ground_b


# ---------------------------------------------------------------- words
def est_width(s, size, bold=False):
    """Roughly how wide Helvetica sets this. There is no font to measure in an <img>, so it errs a little wide."""
    w = 0
    for c in s:
        if c in "iljI.,:;'|!·": w += .30
        elif c in " -_ftr()": w += .36
        elif c in "mwMW": w += .88
        elif c.isupper() or c.isdigit(): w += .70 if c.isupper() else .58
        else: w += .57
    return w * size * (1.05 if bold else 1)


def wrap(text, size, width, bold=False, breaks=r"(?<=\s)|(?<=[-_/])"):
    """Greedy wrap. A long repository name may break after - _ or /, and a word never breaks in the middle."""
    lines, cur = [], ""
    for tok in [t for t in re.split(breaks, text) if t]:
        if cur and est_width((cur + tok).rstrip(), size, bold) > width:
            lines.append(cur.rstrip())
            cur = tok
        else:
            cur += tok
    if cur.strip():
        lines.append(cur.rstrip())
    return lines


def fit_title(title):
    for lines_allowed, sizes in ((1, range(60, 37, -2)), (2, range(46, 27, -2))):
        for size in sizes:
            lines = wrap(title, size, TEXT_W, bold=True)
            if len(lines) <= lines_allowed and all(est_width(x, size, True) <= TEXT_W for x in lines):
                return size, lines
    sys.exit(f"make-banner: the title is too long to set in two lines, even at 28px: {title!r}. Shorten it.")


def fit_subtitle(subtitle):
    for size in (23, 21, 19):
        lines = wrap(subtitle, size, TEXT_W, breaks=r"(?<=\s)")
        if len(lines) <= 3 and all(est_width(x, size) <= TEXT_W for x in lines):
            return size, lines
    sys.exit(f"make-banner: the subtitle needs more than three lines: {subtitle!r}. Say it in fewer words; the TL;DR "
             "below the banner can carry the rest.")


# ---------------------------------------------------------------- motifs (each returns its marks and its sentence for <desc>)
def delay(s):
    return f' style="animation-delay:{s:.2f}s"'


def line_path(d, stroke, width, cls="draw", start=0.3, extra=""):
    return (f'<path class="{cls}" pathLength="100" d="{d}" fill="none" stroke="{stroke}" stroke-width="{width}" '
            f'stroke-linecap="round" stroke-linejoin="round"{delay(start)}{extra}/>')


def halo(x, y, r, colour):
    return f'<circle class="halo" cx="{x:.1f}" cy="{y:.1f}" r="{r}" fill="none" stroke="{colour}" stroke-width="2"/>'


def m_path(t, rng, n):
    n = n or 6
    x0, y0, x1, y1 = ZONE
    pts = []
    for i in range(n):
        f = i / (n - 1)
        wobble = (rng.random() - .3) * 34 if 0 < i < n - 1 else 0
        pts.append((x0 + 24 + f * (x1 - x0 - 48), y1 - 24 - f * (y1 - y0 - 52) + wobble))
    out = [f'<g stroke="{t.faint}" stroke-width="1" opacity=".5">']
    out += [f'<path d="M{x0 + i * (x1 - x0) / 7:.0f} {y0}V{y1}"/>' for i in range(8)]
    out += [f'<path d="M{x0} {y0 + i * (y1 - y0) / 3:.0f}H{x1}"/>' for i in range(4)]
    out.append("</g>")
    out.append(line_path("M" + " L".join(f"{x:.1f} {y:.1f}" for x, y in pts), "url(#line)", 3))
    out.append(halo(*pts[-1], 13, t.hi))
    out.append(f'<g font-family="{FONT}" font-size="13" font-weight="700" text-anchor="middle">')
    for i, (x, y) in enumerate(pts):
        out.append(f'<g class="arrive"{delay(.4 + i * 2.8 / (n - 1))}><circle cx="{x:.1f}" cy="{y:.1f}" r="13" fill="{t.pit}" '
                   f'stroke="{t.line}" stroke-width="2.5"/><text x="{x:.1f}" y="{y + 4.5:.1f}" fill="{t.hi}">{i + 1}</text></g>')
    out.append("</g>")
    return out, f"{n} numbered stops on a line that climbs, each arriving in turn"


def m_mycelium(t, rng, n):
    n = n or 5
    x0, y0, x1, y1 = ZONE
    hx, hy = x1 - 54, (y0 + y1) / 2 + (rng.random() - .5) * 40
    out, nodes = [], []
    for i in range(n):
        f = (i + .5) / n
        ex = x0 + 20 + rng.random() * 150
        ey = y0 + 14 + f * (y1 - y0 - 28) + (rng.random() - .5) * 12
        c1 = (hx - 70 - rng.random() * 60, hy + (ey - hy) * .55 + (rng.random() - .5) * 30)
        c2 = (ex + 60 + rng.random() * 70, ey + (rng.random() - .5) * 46)
        out.append(line_path(f"M{hx:.1f} {hy:.1f}C{c1[0]:.1f} {c1[1]:.1f} {c2[0]:.1f} {c2[1]:.1f} {ex:.1f} {ey:.1f}", "url(#line)", 2.6, start=.2 + i * .3))
        nodes.append((ex, ey, 1.6 + i * .3))
        # a side thread from about the middle of each main thread
        u = .45 + rng.random() * .2
        mx = (1 - u) ** 3 * hx + 3 * (1 - u) ** 2 * u * c1[0] + 3 * (1 - u) * u ** 2 * c2[0] + u ** 3 * ex
        my = (1 - u) ** 3 * hy + 3 * (1 - u) ** 2 * u * c1[1] + 3 * (1 - u) * u ** 2 * c2[1] + u ** 3 * ey
        bx, by = mx - 30 - rng.random() * 40, my + (.5 - rng.random()) * 64
        by = min(max(by, y0 + 8), y1 - 8)
        out.append(line_path(f"M{mx:.1f} {my:.1f}Q{(mx + bx) / 2:.1f} {by:.1f} {bx:.1f} {by:.1f}", t.dim, 1.6, start=1.4 + i * .3))
        nodes.append((bx, by, 2.4 + i * .3))
    for i, (x, y, d) in enumerate(nodes):
        main = i % 2 == 0
        out.append(f'<circle class="arrive"{delay(d)} cx="{x:.1f}" cy="{y:.1f}" r="{6 if main else 3.5}" fill="{t.line if main else t.dim}"/>')
    out.append(halo(hx, hy, 18, t.hi))
    out.append(f'<circle class="breathe" cx="{hx:.1f}" cy="{hy:.1f}" r="15" fill="{t.line}"/>')
    out.append(f'<circle cx="{hx:.1f}" cy="{hy:.1f}" r="6" fill="{t.tint}"/>')
    return out, f"threads grow from one node toward {n} others, the way mycelium finds its neighbours"


def m_waves(t, rng, n):
    n = n or 4
    x0, y0, x1, y1 = ZONE
    sx, sy = x0 + 220 + rng.random() * 130, y0 + 66 + rng.random() * 12
    gap = rng.random() * 40
    a0, a1 = math.radians(-60 + gap), math.radians(240 + gap)
    r = 66
    out = [f'<circle class="breathe" cx="{sx:.1f}" cy="{sy:.1f}" r="46" fill="url(#line)"/>']
    arc = (f"M{sx + r * math.cos(a0):.1f} {sy + r * math.sin(a0):.1f}"
           f"A{r} {r} 0 1 1 {sx + r * math.cos(a1):.1f} {sy + r * math.sin(a1):.1f}")
    out.append(line_path(arc, t.line, 4, start=.2))
    for i in range(n):
        y = y1 - 58 + i * 58 / max(n - 1, 1)
        a = 10 + rng.random() * 14
        step = 110 + rng.random() * 50
        d = f"M620 {y:.1f}"
        x, s = 620, 1 if rng.random() > .5 else -1
        while x < W + 40:
            d += f"Q{x + step / 2:.1f} {y + s * a:.1f} {x + step:.1f} {y:.1f}"
            x += step
            s = -s
        out.append(line_path(d, "url(#fade)", 3.2 - i * .4, start=.4 + i * .5))
    return out, f"a sun held by an open circle, and {n} waves drawing in beneath it"


def m_polygon(t, rng, n):
    n = n or 8
    x0, y0, x1, y1 = ZONE
    cx, cy = (x0 + x1) / 2 + 40 + rng.random() * 40, (y0 + y1) / 2
    r = 90
    spin = rng.random() * math.tau / n

    def ring(radius, off):
        return [(cx + radius * math.cos(spin + off + i * math.tau / n), cy + radius * math.sin(spin + off + i * math.tau / n)) for i in range(n)]
    outer, inner = ring(r, 0), ring(r * .6, math.pi / n)
    out = [f'<path d="M{" L".join(f"{x:.1f} {y:.1f}" for x, y in inner)}Z" fill="{t.faint}" fill-opacity=".35" stroke="{t.dim}" stroke-width="1.5"/>']
    out += [f'<path d="M{cx:.1f} {cy:.1f}L{x:.1f} {y:.1f}" stroke="{t.faint}" stroke-width="1"/>' for x, y in outer]
    out.append(line_path("M" + " L".join(f"{x:.1f} {y:.1f}" for x, y in outer) + "Z", "url(#line)", 3.5))
    out += [f'<circle class="arrive"{delay(.35 + i * 2.9 / n)} cx="{x:.1f}" cy="{y:.1f}" r="7" fill="{t.pit}" stroke="{t.hi}" stroke-width="2.5"/>' for i, (x, y) in enumerate(outer)]
    out.append(halo(cx, cy, 12, t.hi))
    out.append(f'<circle class="breathe" cx="{cx:.1f}" cy="{cy:.1f}" r="10" fill="{t.line}"/>')
    return out, f"a {n}-sided figure draws itself and its corners arrive one by one"


def m_arch(t, rng, n):
    n = n or 13
    if n % 2 == 0:
        n += 1  # a keystone needs a middle
    x0, y0, x1, y1 = ZONE
    cx, cy, r = (x0 + x1) / 2 + 30 + rng.random() * 50, y1 - 2, 142
    per = math.pi / n
    out = [f'<path d="M{cx - r + 22:.1f} {cy}A{r - 22} {r - 22} 0 0 1 {cx + r - 22:.1f} {cy}Z" fill="{t.faint}" fill-opacity=".28"/>']
    key = n // 2
    for i in range(n):
        a0, a1 = math.pi + i * per + .018, math.pi + (i + 1) * per - .018
        d = (f"M{cx + r * math.cos(a0):.1f} {cy + r * math.sin(a0):.1f}A{r} {r} 0 0 1 {cx + r * math.cos(a1):.1f} {cy + r * math.sin(a1):.1f}")
        dist = abs(i - key)
        wait = .3 + (key - dist) * .28
        colour = t.hi if i == key else mix(t.dim, t.line, (key - dist) / key)
        out.append(f'<path class="arrive"{delay(wait)} d="{d}" fill="none" stroke="{colour}" stroke-width="{34 if i == key else 28}"/>')
    kx, ky = cx, cy - r
    out.append(halo(kx, ky, 22, t.hi))
    for _ in range(4):
        mx, my = cx + (rng.random() - .5) * (r * 1.1), cy - 14 - rng.random() * (r * .55)
        out.append(f'<circle cx="{mx:.1f}" cy="{my:.1f}" r="{1.6 + rng.random() * 1.6:.1f}" fill="{t.hi}" opacity=".7"/>')
    return out, f"an arch of {n} stones lights from both sides inward until the keystone is reached"


def m_candles(t, rng, n):
    n = n or 15
    x0, y0, x1, y1 = ZONE
    v, walk = 0.0, []
    for _ in range(n):
        o = v
        v += (rng.random() - .36) * .9
        walk.append((o, v, max(o, v) + rng.random() * .45, min(o, v) - rng.random() * .45))
    lo, hi = min(c[3] for c in walk), max(c[2] for c in walk)

    def y_of(q):
        return y1 - 10 - (q - lo) / ((hi - lo) or 1) * (y1 - y0 - 20)
    dx = (x1 - x0 - 24) / n
    out, closes = [], []
    for i, (o, c, h, l) in enumerate(walk):
        x = x0 + 12 + dx * (i + .5)
        top, bot = y_of(max(o, c)), y_of(min(o, c))
        up = c >= o
        colour = t.line if up else t.dim
        body = f'fill="{colour}"' if up else f'fill="{t.pit}" stroke="{colour}" stroke-width="1.5"'
        out.append(f'<g class="arrive"{delay(.25 + i * 2.6 / n)}><path d="M{x:.1f} {y_of(h):.1f}V{y_of(l):.1f}" stroke="{colour}" stroke-width="1.5"/>'
                   f'<rect x="{x - dx * .3:.1f}" y="{top:.1f}" width="{dx * .6:.1f}" height="{max(bot - top, 2):.1f}" rx="1" {body}/></g>')
        closes.append((x, y_of(c)))
    out.append(line_path("M" + " L".join(f"{x:.1f} {y:.1f}" for x, y in closes), t.hi, 2, start=1.8))
    out.append(halo(*closes[-1], 9, t.hi))
    out.append(f'<circle cx="{closes[-1][0]:.1f}" cy="{closes[-1][1]:.1f}" r="4.5" fill="{t.hi}"/>')
    return out, f"{n} candles arrive left to right with a line along their closes; the shapes are illustration, not data"


def m_constellation(t, rng, n):
    n = n or 10
    x0, y0, x1, y1 = ZONE
    pts = []
    tries = 0
    while len(pts) < n and tries < 4000:
        tries += 1
        p = (x0 + 14 + rng.random() * (x1 - x0 - 28), y0 + 12 + rng.random() * (y1 - y0 - 24))
        if all(math.dist(p, q) > 62 - tries / 200 for q in pts):
            pts.append(p)
    # a minimum spanning tree: every star reached, and no line crossing the whole sky
    seen, links = {0}, []
    while len(seen) < len(pts):
        a, b = min(((i, j) for i in seen for j in range(len(pts)) if j not in seen), key=lambda ij: math.dist(pts[ij[0]], pts[ij[1]]))
        links.append((a, b))
        seen.add(b)
    out = [line_path(f"M{pts[a][0]:.1f} {pts[a][1]:.1f}L{pts[b][0]:.1f} {pts[b][1]:.1f}", t.dim, 1.6, start=.3 + i * .22) for i, (a, b) in enumerate(links)]
    for i, (x, y) in enumerate(pts):
        size = 3 + rng.random() * 3.5 if i else 8
        out.append(f'<circle class="arrive"{delay(.15 + i * .24)} cx="{x:.1f}" cy="{y:.1f}" r="{size:.1f}" fill="{t.hi if i else t.line}"/>')
    out.insert(0, halo(*pts[0], 13, t.hi))
    return out, f"{len(pts)} stars arrive and join into one constellation"


MOTIFS = {"path": (m_path, "a road: a sequence of stops, onboarding, a method"),
          "mycelium": (m_mycelium, "a network: people or repositories that feed each other"),
          "waves": (m_waves, "a practice or a rhythm: sun, circle, sea"),
          "polygon": (m_polygon, "a form with named parts (--count is its sides)"),
          "arch": (m_arch, "a threshold: a front door, a law, something that holds up"),
          "candles": (m_candles, "markets: illustration only, never real data, never a real pair"),
          "constellation": (m_constellation, "a library or a map: many things, one sky")}


# ---------------------------------------------------------------- the picture
def build(title, subtitle, tone, motif, count=None, seed=None, kicker=None):
    rng = random.Random(int(hashlib.sha256((seed or title).encode()).hexdigest(), 16))
    marks, sentence = MOTIFS[motif][0](tone, rng, count)
    tsize, tlines = fit_title(title)
    ssize, slines = fit_subtitle(subtitle)

    # vertically centre the words over the card, above the rail
    block = (22 if kicker else 0) + tsize * 1.12 * len(tlines) + 12 + ssize * 1.34 * len(slines)
    y = (H - RAIL - block) / 2
    words = [f'<g font-family="{FONT}">']
    if kicker:
        y += 14
        words.append(f'<text x="{TEXT_X}" y="{y:.1f}" fill="#{tone.kicker}" font-size="15" font-weight="700" letter-spacing=".6">{escape(kicker)}</text>')
        y += 8
    for ln in tlines:
        y += tsize * 1.12
        words.append(f'<text x="{TEXT_X}" y="{y - tsize * .16:.1f}" fill="#{tone.title}" font-size="{tsize}" font-weight="700" letter-spacing="-.5">{escape(ln)}</text>')
    y += 8
    for ln in slines:
        y += ssize * 1.34
        words.append(f'<text x="{TEXT_X}" y="{y - ssize * .2:.1f}" fill="#{tone.sub}" font-size="{ssize}">{escape(ln)}</text>')
    words.append("</g>")

    stops = tone.hues or (tone.mid, tone.line, tone.hi)
    stop_marks = "".join(f'<stop offset="{i / (len(stops) - 1):.2f}" stop-color="#{legible(c, tone.ground_a, 2.4)}"/>' for i, c in enumerate(stops))
    rail_shades = tone.hues or (tone.deep, tone.mid, tone.primary, tone.tint)
    seg = W / len(rail_shades)
    rail = "".join(f'<rect x="{i * seg:.1f}" y="{H - RAIL}" width="{seg + .5:.1f}" height="{RAIL}" fill="#{c}"/>' for i, c in enumerate(rail_shades))
    desc = (f"{subtitle} The picture: {sentence}. With reduced motion, the finished picture shows at once.")

    body = "\n    ".join(re.sub(r'(fill|stroke)="([0-9a-f]{6})"', r'\1="#\2"', m) for m in marks)
    return f"""<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}" role="img" aria-labelledby="t d">
  <title id="t">{escape(title)}</title>
  <desc id="d">{escape(desc)}</desc>
  <style>
    /* Motion only for readers who have not asked for less. Outside this block everything is in its finished state. */
    @media (prefers-reduced-motion: no-preference) {{
      .draw {{ stroke-dasharray: 100; animation: draw 2.6s cubic-bezier(.4,0,.2,1) both; }}
      .arrive {{ animation: arrive .5s ease-out both; }}
      .breathe {{ transform-box: fill-box; transform-origin: center; animation: breathe 8s steps(48) 3s infinite; }}
      .halo {{ transform-box: fill-box; transform-origin: center; animation: halo 5s steps(60) 3.6s infinite; }}
    }}
    @keyframes draw {{ from {{ stroke-dashoffset: 100 }} to {{ stroke-dashoffset: 0 }} }}
    @keyframes arrive {{ from {{ opacity: 0 }} to {{ opacity: 1 }} }}
    @keyframes breathe {{ 0%, 100% {{ transform: scale(1) }} 50% {{ transform: scale(1.07) }} }}
    @keyframes halo {{ 0% {{ opacity: .55; transform: scale(1) }} 70%, 100% {{ opacity: 0; transform: scale(2.1) }} }}
    .halo {{ opacity: 0 }}
  </style>
  <defs>
    <linearGradient id="ground" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#{tone.ground_a}"/><stop offset="1" stop-color="#{tone.ground_b}"/></linearGradient>
    <linearGradient id="line" gradientUnits="userSpaceOnUse" x1="{ZONE[0]}" y1="0" x2="{ZONE[2]}" y2="0">{stop_marks}</linearGradient>
    <linearGradient id="fade" gradientUnits="userSpaceOnUse" x1="620" y1="0" x2="{W}" y2="0"><stop offset="0" stop-color="#{tone.line}" stop-opacity="0"/><stop offset=".35" stop-color="#{tone.line}"/><stop offset="1" stop-color="#{tone.hi}"/></linearGradient>
    <clipPath id="card"><rect width="{W}" height="{H}" rx="18"/></clipPath>
  </defs>
  <g clip-path="url(#card)">
    <!-- an opaque ground: the same picture on GitHub's light and dark themes -->
    <rect width="{W}" height="{H}" fill="url(#ground)"/>
    {body}
    {rail}
    {"".join(words)}
  </g>
</svg>
"""


# ---------------------------------------------------------------- checks
def lint_svg(text):
    """Returns (refusals, warnings). A banner made by hand is held to the same rules as one made here."""
    bad, warn = [], []
    try:
        ET.fromstring(text)
    except ET.ParseError as e:
        return [f"not well-formed XML: {e}"], []
    if re.search(r"<(script|foreignObject|iframe|embed|object)\b", text, re.I):
        bad.append("carries something that can run or embed (script, foreignObject, iframe, embed, object)")
    if re.search(r"\son\w+\s*=", text, re.I):
        bad.append("has an event handler attribute")
    if re.search(r"<image\b|@import|url\(\s*['\"]?https?:", text, re.I):
        bad.append("loads something from outside the file; an SVG in an <img> cannot")
    if re.search(r"(?:xlink:)?href\s*=\s*['\"](?!#)", text, re.I):
        bad.append("links outside the file")
    if re.search(r"<(animate|animateTransform|animateMotion|set)\b", text):
        bad.append("uses SMIL (<animate>), which ignores prefers-reduced-motion; use CSS animation")
    if not re.search(r"animation\s*:", text):
        bad.append("does not move; the standard asks for motion that honours reduced motion")
    elif "prefers-reduced-motion" not in text:
        bad.append("moves without honouring prefers-reduced-motion")
    if not re.search(r"<title\b|aria-label", text):
        bad.append("has no <title> or aria-label")
    if re.search(r"<filter\b|filter\s*:", text):
        warn.append("uses a filter or blur, the most expensive thing an SVG can repaint")
    if len(text.encode()) > 64 * 1024:
        warn.append(f"is {len(text.encode()) // 1024} KB; a banner should stay under 64 KB")
    return bad, warn


def check_svgs(paths):
    failed = 0
    for p in paths:
        bad, warn = lint_svg(Path(p).read_text(encoding="utf-8", errors="replace"))
        print(f"{'ok  ' if not bad else 'FAIL'}  {p}")
        for x in bad:
            print(f"      refuse: {x}")
        for x in warn:
            print(f"      warn:   {x}")
        failed += bool(bad)
    return failed


def prose(text):
    """The page without its fenced code: an example of a banner or an icon is not the page's own."""
    return re.sub(r"^(`{3,}|~{3,})[^\n]*\n.*?^\1[ \t]*$", "", text, flags=re.M | re.S)


def check_readme(path):
    """The standard's checklist, as far as a machine can read it. A person still reads the page."""
    readme = Path(path)
    text = prose(readme.read_text(encoding="utf-8", errors="replace"))
    head = "\n".join(text.splitlines()[:40])
    res = []

    def need(ok, label):
        res.append((bool(ok), label))
    srcs = re.findall(r"""(?:src|srcset)=["']([^"']+)["']""", text)
    banners = [s for s in re.findall(r"""(?:src|srcset)=["']([^"']+)["']""", head) if "banner" in s.lower()]
    need(banners, "a banner in the first lines")
    for s in banners:
        f = readme.parent / s
        if s.startswith("http"):
            need(False, f"the banner is a file in the repository, not hot-linked: {s}")
        elif not f.is_file():
            need(False, f"the banner file exists: {s}")
        elif f.suffix == ".svg":
            bad, _ = lint_svg(f.read_text(encoding="utf-8", errors="replace"))
            need(not bad, f"the banner meets the rules: {s}" + (f" ({bad[0]})" if bad else ""))
    need(re.search(r"^# ", text, re.M), "one H1, the name")
    need(re.search(r"you are here", head, re.I), 'a "You are here" line in the header')
    need(len(re.findall(r"img\.shields\.io/badge", text)) >= 2, "at least two badges")
    need(re.search(r"^#+ .*TL;DR", text, re.M | re.I), "a TL;DR heading")
    icons = [s for s in srcs if "icons/" in s]
    local = [s for s in icons if not s.startswith("http")]
    need(len(local) >= 3, f"at least three Lucide icons from the repository ({len(local)} found)")
    need(len(local) == len(icons), "no hot-linked icons")
    missing = sorted({s for s in local if not (readme.parent / s).is_file()})
    need(not missing, "every icon file exists" + (f" (missing: {', '.join(missing)})" if missing else ""))
    need(not re.findall(r"""<img(?=[^>]*icons/)(?![^>]*alt="")[^>]*>""", text), 'every icon has alt="" (the words beside it say the idea)')
    need(re.search(r"^#+ .*suggest", text, re.M | re.I), 'a "Suggest a change" section')
    need(re.search(r"readme-standard:", text), "the readme-standard marker, so a sweep can find what is done")
    print(f"--- {path}")
    for ok, label in res:
        print(f"{'ok  ' if ok else 'FAIL'}  {label}")
    return sum(not ok for ok, _ in res)


def copy_icons(path, family):
    """Copies each assets/icons/<name>.svg the README names from this template's set, toned, plus the licence."""
    readme = Path(path)
    source = Path(__file__).resolve().parent.parent / "sop-template/repo/assets/icons"
    stroke = ICON_STROKE[family]
    src_list = sorted(set(re.findall(r"""src=["']([^"'\s]*icons/[\w.-]+\.svg)["']""", prose(readme.read_text(encoding="utf-8")))))
    problems = copied = 0
    folder = None
    for s in src_list:
        if s.startswith("http"):
            print(f"FAIL  hot-linked: {s}")
            problems += 1
            continue
        dest = (readme.parent / s).resolve()
        folder = dest.parent
        if dest.exists():
            continue
        src = source / dest.name
        if not src.is_file():
            print(f"FAIL  {dest.name} is not in this template's set: fetch it as LUCID.md says, then commit it here")
            problems += 1
            continue
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_text(src.read_text(encoding="utf-8").replace('stroke="#7c4dff"', f'stroke="#{stroke}"'), encoding="utf-8")
        copied += 1
    if folder and copied and not (folder / "LICENSE").exists() and (source / "LICENSE").is_file():
        (folder / "LICENSE").write_text((source / "LICENSE").read_text(encoding="utf-8"), encoding="utf-8")
    print(f"icons: {copied} copied (stroke #{stroke}), {len(src_list) - copied - problems} already there, {problems} problems")
    return problems


def main():
    ap = argparse.ArgumentParser(description="A repository's banner, per README-STANDARD.md. See the top of this file.")
    ap.add_argument("--title")
    ap.add_argument("--subtitle")
    ap.add_argument("--kicker", help="small line above the title: whose this is")
    ap.add_argument("--family", help="a TONES.md family or its short name (see --list)")
    ap.add_argument("--palette", help="your own four shades instead of a family: deep,mid,primary,tint (hex, no #)")
    ap.add_argument("--motif", choices=sorted(MOTIFS))
    ap.add_argument("--count", type=int, help="how many stops, threads, waves, sides, stones, candles or stars")
    ap.add_argument("--seed", help="geometry seed; defaults to the title")
    ap.add_argument("--out", help="write here; default is standard output")
    ap.add_argument("--list", action="store_true")
    ap.add_argument("--check", nargs="+", metavar="SVG")
    ap.add_argument("--check-readme", nargs="+", metavar="README")
    ap.add_argument("--icons", metavar="README")
    a = ap.parse_args()

    if a.list:
        print("families:", ", ".join(FAMILIES), "(short names:", ", ".join(f"{k}={v}" for k, v in ALIASES.items()) + ")")
        for k, (_, why) in sorted(MOTIFS.items()):
            print(f"  {k:<14} {why}")
        return 0
    if a.check:
        return 1 if check_svgs(a.check) else 0
    if a.check_readme:
        return 1 if sum(check_readme(p) for p in a.check_readme) else 0

    family = ALIASES.get((a.family or "").lower(), (a.family or "").lower())
    if family and family not in FAMILIES:
        ap.error(f"unknown family {a.family!r}; see --list")
    if a.icons:
        return 1 if copy_icons(a.icons, family or "brass") else 0

    if not (a.title and a.subtitle):
        ap.error("--title and --subtitle are required")
    if a.palette:
        shades = tuple(x.strip().lstrip("#").lower() for x in a.palette.split(","))
        if len(shades) != 4 or not all(re.fullmatch(r"[0-9a-f]{6}", x) for x in shades):
            ap.error("--palette takes four hex colours: deep,mid,primary,tint")
        tone = Tone(shades)
    elif family:
        tone = Tone(FAMILIES[family], RAINBOW if family == "rainbow" else None)
    else:
        ap.error("--family or --palette is required")
    if a.count is not None and not 3 <= a.count <= 30:
        ap.error("--count runs from 3 to 30")
    motif = a.motif or sorted(MOTIFS)[int(hashlib.sha256((a.seed or a.title).encode()).hexdigest(), 16) % len(MOTIFS)]

    svg = build(a.title, a.subtitle, tone, motif, a.count, a.seed, a.kicker)
    bad, warn = lint_svg(svg)
    if bad or warn:
        sys.exit(f"make-banner: this script made a banner its own check refuses: {bad + warn}")
    if a.out:
        out = Path(a.out)
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(svg, encoding="utf-8")
        print(f"{out}: {motif}, {len(svg.encode()) / 1024:.1f} KB")
    else:
        sys.stdout.write(svg)
    return 0


if __name__ == "__main__":
    sys.exit(main())
