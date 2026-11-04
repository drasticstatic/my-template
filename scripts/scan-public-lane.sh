#!/bin/sh
# scan-public-lane.sh — the public-lane tripwire: a public lane never publishes a file a machine or a person has not read.
#
#   sh scripts/scan-public-lane.sh [--strip N] [--media <PUBLIC-LANE-MEDIA.txt>] <directory-about-to-be-published> [<PUBLIC-ALLOWLIST-ATTESTED.txt>]
#
# It reads EVERY file under the directory (only the top-level .git is skipped) and exits non-zero, naming each file,
# when anything there has not been read:
#   text           scanned for credentials, agent-note pointers and sensitive shapes (identity numbers, labelled tax
#                  identifiers, birth dates, street addresses, giver lists, labelled account numbers, personal matters).
#                  Base64 embedded as a data: address is decoded and read: a plain picture passes; a script, HTML, a PDF
#                  or an executable is refused; a font passes only where a font file would; a credential inside is
#                  refused like any other; any other long embed is refused outside assets/ or icons/. An .svg that
#                  carries a script, an event handler or a code link is refused, wherever it sits
#   PDF            its text is extracted with pdftotext (poppler) and scanned the same way; a PDF with no text, or with
#                  pages that carry none (a scan, an image-only page), or that cannot be opened, is refused
#   .docx .xlsx    (and .pptx, OpenDocument) unzipped; the XML text is scanned; embedded pictures or objects are refused
#   pictures       allowed only under an assets/ or icons/ folder or a folder the lane's media list names (fonts too),
#                  and only when the bytes are the picture the name claims; anywhere else they are refused. Pixels are
#                  not read, but every picture's and font's bytes, and every office file's XML attributes (link targets,
#                  alt text), are searched for credentials and agent-note pointers
#   anything else  a binary no machine can read here, refused
#   Three narrow exceptions (Nov 4). A link to github.com/drasticstatic/<name>-public-preview or
#   drasticstatic.github.io/<name>-public-preview/ is not a personal matter: a public preview is public by definition.
#   Only that link token is exempt, and only from the personal-matter words; a street address inside it, or the same word
#   elsewhere on the line, still trips. The guardianship word negated (no ..., non-...) is a compliance note, not the
#   matter. Pagefind's search index under a folder named pagefind/ passes when its bytes are what pagefind writes (gzip
#   for *.pf_fragment *.pf_index *.pf_meta, WebAssembly for wasm.*.pagefind; its js, json and css are text and read as
#   text); the compressed text is inflated and searched for credentials, and anything else there is refused as before.
#
# Attestation: PUBLIC-ALLOWLIST-ATTESTED.txt names files a person opened and read, one per line:
#   path | officer | YYYY-MM-DD | opened and read
#   path | officer | YYYY-MM-DD | opened and read | sha256:<64 hex>      (optional fingerprint: void once the file changes)
# An attested file may carry a sensitive shape, be a picture outside assets/, or be a PDF without text. An attestation
# never opens these, which are refused whatever any list says:
#   - a credential or an agent-note pointer found in any readable text (attested files are still read when they can be)
#   - a legal lane by path: entity/ tax/ filings/ counsel/
#   - names that never travel (agent notes, tool configuration, keys, wallets, environment files), symbolic links,
#     files over 15 MB
#
# Media list: PUBLIC-LANE-MEDIA.txt names folders whose pictures and fonts this lane publishes on purpose. A person chose
# them; a machine still reads what it can. One folder per line, relative to the directory being scanned, each under a
# header that says who chose it and when (comments and blank lines allowed):
#   approved by <name> | YYYY-MM-DD
#   public/images
#   .                     (the top level only, for a favicon: never its subfolders)
# A listed folder covers its subfolders. It opens pictures and fonts whose bytes match their names, and nothing else: text,
# PDFs, office files and binaries under it are read and refused exactly as anywhere else. A folder with no header above it,
# a wildcard, a '..' or a legal lane makes the line malformed, which refuses the run. Without --media nothing is listed.
#
# --strip N   apply the path rules, the attestation and the media list to the path with its first N folders removed
#             (used when a workflow lays every historical version out as <blob>/<path>).
# --media F   the media list to honour (a missing file means nothing is listed). The scanner never looks for one inside
#             the directory it reads: what is being published does not get to vouch for itself.
# PDFTOTEXT   environment: the pdftotext to use (default: the one on PATH). Install: brew install poppler (macOS),
#             sudo apt-get install -y poppler-utils (Ubuntu runners).
#
# Exit codes: 0 every file read and clean · 1 refused (each file named above the summary) · 2 usage or environment.
# Matched text is never printed, only the kind of match and where it is, so a found secret does not leak into a log.
# Master copy: my-template/scripts/scan-public-lane.sh (self-test: scan-public-lane.selftest.sh). Copy, do not fork.
set -eu
command -v python3 >/dev/null 2>&1 || { echo "scan-public-lane: python3 is required" >&2; exit 2; }
exec python3 -I - "$@" <<'PY'
import base64, datetime, gzip, hashlib, html, io, os, re, shutil, stat, subprocess, sys, urllib.parse, zipfile, zlib

ME = "scan-public-lane"
GHA = os.environ.get("GITHUB_ACTIONS") == "true"
MAX_BYTES = 15 * 1024 * 1024
MAX_OFFICE_XML = 64 * 1024 * 1024
LONG_EMBED = 200     # base64 characters: a shorter embed of an unknown kind is not worth stopping a lane for
MAX_EMBED_DEPTH = 3  # an embed inside an embed inside an embed, then refused
USAGE = f"usage: sh scripts/{ME}.sh [--strip N] [--media <PUBLIC-LANE-MEDIA.txt>] <directory> [<attested-file>]"


def w(*parts):
    # Words are assembled from pieces so that this file, published through a lane, does not trip its own tripwire.
    return "".join(parts)


def usage(msg):
    print(f"{ME}: {msg}", file=sys.stderr)
    print(USAGE, file=sys.stderr)
    sys.exit(2)


args = sys.argv[1:]
strip = 0
media_file = ""
while args and args[0].startswith("-"):
    if args[0] == "--strip" and len(args) >= 2 and args[1].isdigit():
        strip = int(args[1])
        args = args[2:]
    elif args[0] == "--media" and len(args) >= 2:
        media_file = args[1]
        args = args[2:]
    elif args[0] in ("-h", "--help"):
        print(f"{USAGE}  (details: the comment at the top of the script)")
        sys.exit(0)
    else:
        usage(f"unknown option {args[0]}")
if len(args) not in (1, 2):
    usage("one directory, and optionally an attestation file")
root = args[0]
attested_file = args[1] if len(args) == 2 else ""
if not os.path.isdir(root):
    usage(f"{root} is not a directory")

# ── patterns ──────────────────────────────────────────────────────────────────────────────────────────────────────────
# NEVER: credentials and pointers into agent notes. Kept from the fleet's sync-allowlist.sh copies (THEF stage/apply and
# Psanctuary --check families), unioned; no attestation opens them.
AS = w("AGENT", "-SYNC")
NEVER = [
    ("a private-key block", re.compile(w("BEGIN [A-Z ]*PRI", "VATE KEY"))),
    ("a GitHub token", re.compile(w("gh", "[pousr]_[A-Za-z0-9]{20,}"))),
    ("a GitHub fine-grained token", re.compile(w("github", "_pat_[A-Za-z0-9_]{20,}"))),
    ("an API key shape (sk-...)", re.compile(w("(?:^|[^A-Za-z0-9])s", "k-[A-Za-z0-9_-]{32,}"))),
    ("a Slack token", re.compile(w("xo", "x[abprs]-[A-Za-z0-9-]{10,}"))),
    ("an AWS access key", re.compile(w("AK", "IA[0-9A-Z]{16}"))),
    ("an ntfy topic address", re.compile(w("ntfy", r"\.sh/[A-Za-z0-9_-]{6,}"))),
    ("a pointer into agent notes", re.compile(
        AS + "/" + w("created", "-by") + "|" + AS + "-[a-z]|" + w("created", "-by-")
        + "(?:fortuna|alfred|kavanah|auggie|littlebird|mystarch|cosmos)|" + w("HAND", "OFF_20") + "[0-9]{6}|"
        + w("_PRO", "MPT_20") + "[0-9]{6}", re.I)),
]
# The bare agent-notes folder name (Psanctuary family), except the public attribution spec link.
BARE_AS = re.compile(AS, re.I)
SPEC_LINK = re.compile(r"my-template/(?:(?:blob|tree)/[^/\s]+/)?" + AS + r"/README\.md", re.I)

# SENSITIVE: refused unless a person attested the file. The fleet's personal-matter words, plus the Nov 1 additions.
STREET = (r"\b\d{1,6}[ \t]+(?:[NSEW]\.?[ \t]+)?(?:(?:[A-Z][A-Za-z'.-]*|\d{1,3}(?:st|nd|rd|th))[ \t]+){1,3}"
          r"(?:Street|St|Avenue|Ave|Road|Rd|Boulevard|Blvd|Lane|Ln|Drive|Dr|Court|Ct|Way|Place|Pl|Terrace|Ter|"
          r"Circle|Cir|Highway|Hwy|Parkway|Pkwy|Trail|Trl|Square|Sq|Pike|Loop)\b")
# The guardianship-matter word, except its asset senses (held by oneself, by an institution, of keys or funds), which are
# treasury vocabulary rather than the personal matter, and except its negations ("no ...", "non-..."), which are a
# compliance note (no payments, no ..., no tokens) rather than the matter. The negation must sit right before the word.
CUST = ("".join(f"(?<!{b})" for b in ("self-", "self ", "institutional ", "qualified ", "key ", "asset ", "crypto ", "mpc ",
                                      r"\bno ", r"\bnon-"))
        + w("cus", "tody") + r"(?!\s+of\s+(?:the\s+)?(?:keys|funds|assets|tokens)\b)")
# A hyphen, or the dashes a word processor substitutes for one (non-breaking hyphen, en and em dash, minus sign).
DASH = "[-\u2010-\u2015\u2212]"
PERSONAL = "a personal-matter word"
# A link to a public preview is public by definition: github.com/drasticstatic/<name>-public-preview, or
# drasticstatic.github.io/<name>-public-preview/ and what follows. The link token is blanked (same length, so line
# numbers hold) before the personal-matter words are searched, and for no other rule: a street address inside the
# link, a credential, the same word elsewhere on the line, all still trip.
PUBLIC_PREVIEW = re.compile(r"(?:https?://)?(?:www\.)?(?:github\.com/drasticstatic/[A-Za-z0-9._-]+-public-preview(?:[/#?][^\s<>\"')\]]*)?"
                            r"(?=[^A-Za-z0-9._-]|$)|drasticstatic\.github\.io/[A-Za-z0-9._-]+-public-preview/[^\s<>\"')\]]*)", re.I)
SENSITIVE = [
    (PERSONAL, re.compile(r"\b(?:" + w("div", "orce") + "|" + CUST + "|" + w("tax", "-assistant") + ")", re.I)),
    ("an employer-number shape (NN-NNNNNNN)", re.compile(r"\b\d{2}" + DASH + r"\d{7}\b")),
    ("a social-security-number shape (NNN-NN-NNNN)", re.compile(r"\b\d{3}" + DASH + r"\d{2}" + DASH + r"\d{4}\b")),
    ("a tax-identifier label", re.compile(r"\b" + w("ta", "x") + r"[\s_-]*id\b|\b" + w("taxpayer", r"\s+identification"), re.I)),
    ("a birth-date label", re.compile(r"\b" + w("D", r"\.?O\.?B") + r"\b|(?i:\bdate\s+of\s+" + w("bi", "rth") + r"\b)")),
    ("a street-address shape", re.compile(STREET)),
    ("a post-office-box shape", re.compile(r"\bP\.?[ \t]?O\.?[ \t]+" + w("Bo", "x") + r"[ \t]+\d+", re.I)),
    ("a giver-list word", re.compile(r"\b" + w("don", "or") + r"s?\b", re.I)),
]
ACCOUNT = re.compile(r"\b(?:" + w("acc", "ount") + r"|acct|routing|iban|aba)\b(?:[ \t]*(?:number|num|no\.?|#))?[ \t]*[:#.-]?[ \t]*"
                     r"((?:[A-Z]{2}[0-9]{2}[ ]?)?[0-9][0-9 -]{3,}[0-9])", re.I)
EMBED = re.compile(r"data:([A-Za-z0-9.+/-]*)(?:;[A-Za-z0-9=._-]+)*?;base64,([A-Za-z0-9+/=%\s]*)", re.I)
# What an embed may not be, by its label or by its bytes.
ACTIVE_MIME = re.compile(r"html|script|wasm|pdf|executable|msdownload|dosexec|portable-exec|x-sh\b|x-elf|mach-?o|x-msi|java-archive", re.I)
ACTIVE_BYTES = ((b"MZ", "an executable"), (b"\x7fELF", "an executable"), (b"\xfe\xed\xfa\xce", "an executable"),
                (b"\xfe\xed\xfa\xcf", "an executable"), (b"\xce\xfa\xed\xfe", "an executable"), (b"\xcf\xfa\xed\xfe", "an executable"),
                (b"\xca\xfe\xba\xbe", "an executable"), (b"\x00asm", "an executable"), (b"#!", "a script"), (b"%PDF-", "a PDF"))
ACTIVE_TEXT = re.compile(r"<\s*(?:script|html|body|iframe|object|embed|!doctype\s+html)\b", re.I)
# What makes an SVG more than a picture: an active element, an event handler, a link that runs code.
SVG_TAGS = re.compile(r"<\s*(?:[a-z0-9_-]+:)?(?:script|iframe|embed|object)\b|<[^>]*[\s/\"']on[a-z]+\s*=", re.I)
SVG_LINK = re.compile(r"=\s*[\"']?\s*(?:javascript|vbscript):", re.I)

# Names that never travel (union of both families), and the legal lanes.
SEG_NEVER = re.compile(r"^(?:" + AS + r".*|\.git|\.github|\.claude|\.env.*|CLAUDE\.md|AGENTS(?:\.override)?\.md|"
                       r"PENDING-TASKS\.md|pending-tasks.*\.md|node_modules|memory|keys|keystore|wallets?|credentials|secrets)$", re.I)
FILE_NEVER = re.compile(r"^(?:.*\.(?:pem|key|p12|pfx|keystore)|id_rsa.*|id_ed25519.*|.*keystore.*|.*mnemonic.*|.*seed-phrase.*|"
                        r"seed.*|.*secret.*|.*credential.*|.*\.env|\.env.*|.*service-account.*\.json)$", re.I)
LEGAL_LANES = {"entity", "tax", "filings", "counsel"}
ASSET_DIRS = {"assets", "icons"}

IMAGES = {".png": [b"\x89PNG\r\n\x1a\n"], ".jpg": [b"\xff\xd8\xff"], ".jpeg": [b"\xff\xd8\xff"], ".gif": [b"GIF87a", b"GIF89a"],
          ".ico": [b"\x00\x00\x01\x00"], ".bmp": [b"BM"], ".tif": [b"II*\x00", b"MM\x00*"], ".tiff": [b"II*\x00", b"MM\x00*"],
          ".webp": None, ".avif": None, ".heic": None}
FONTS = {".woff": [b"wOFF"], ".woff2": [b"wOF2"], ".ttf": [b"\x00\x01\x00\x00", b"true"], ".otf": [b"OTTO"], ".eot": None}
OFFICE = {".docx", ".docm", ".dotx", ".xlsx", ".xlsm", ".xltx", ".pptx", ".pptm", ".potx", ".odt", ".ods", ".odp"}
# Pagefind's search index, as a site build writes it under pagefind/: gzip'd fragments, index chunks and metadata, one
# WebAssembly module per language. Its pagefind-entry.json, pagefind.js, pagefind-ui.js/.css and pagefind-highlight.js
# are plain text and are read like any text. Names carry a content hash, so these files cannot be attested by path.
PAGEFIND_GZIP = re.compile(r"\.pf_(?:fragment|index|meta)$", re.I)
PAGEFIND_WASM = re.compile(r"^wasm\.[A-Za-z0-9_-]+\.pagefind$", re.I)
MAX_INFLATE = 64 * 1024 * 1024


def magic_ok(ext, data):
    table = IMAGES if ext in IMAGES else FONTS
    sigs = table.get(ext)
    if ext == ".webp":
        return data[:4] == b"RIFF" and data[8:12] == b"WEBP"
    if ext == ".eot":
        return len(data) > 36 and data[34:36] == b"LP"
    if ext in (".avif", ".heic"):
        return data[4:8] == b"ftyp"
    if sigs is None:
        return True
    return any(data.startswith(s) for s in sigs)


# ── attestations ──────────────────────────────────────────────────────────────────────────────────────────────────────
refusals = []   # (display path, reason)
notes = []
attest = {}     # rule path -> list of (officer, date, fingerprint or None, line number)
used = set()


def refuse(path, reason):
    refusals.append((path, reason))


if attested_file:
    if not os.path.isfile(attested_file):
        notes.append(f"attestation file {attested_file} not found; nothing is attested")
    else:
        today = datetime.date.today()
        with open(attested_file, encoding="utf-8", errors="replace") as fh:
            for n, raw in enumerate(fh, 1):
                line = raw.strip()
                if not line or line.startswith("#"):
                    continue
                f = [x.strip() for x in line.split("|")]
                bad = None
                if len(f) not in (4, 5):
                    bad = "needs 'path | officer | YYYY-MM-DD | opened and read' (and optionally '| sha256:<hex>')"
                else:
                    p, officer, day, words = f[:4]
                    fp = f[4] if len(f) == 5 else None
                    p = p.strip("/") if not p.startswith("/") else p
                    if not p or p.startswith("/") or ".." in p.split("/") or any(c in p for c in "*?["):
                        bad = "the path must be one file, relative, with no '..' or wildcards"
                    elif not officer:
                        bad = "the officer's name is missing"
                    elif not re.fullmatch(r"\d{4}-\d{2}-\d{2}", day):
                        bad = "the date must be YYYY-MM-DD"
                    elif words.lower() != "opened and read":
                        bad = "the fourth field must say: opened and read"
                    elif fp is not None and not re.fullmatch(r"sha256:[0-9a-f]{64}", fp):
                        bad = "the optional fifth field must be sha256:<64 lowercase hex>"
                    else:
                        try:
                            d = datetime.date.fromisoformat(day)
                        except ValueError:
                            d = None
                        if d is None:
                            bad = "the date is not a real date"
                        elif d > today + datetime.timedelta(days=1):
                            bad = "the date is in the future"
                    if not bad:
                        segs = {s.lower() for s in p.split("/")[:-1]}
                        if segs & LEGAL_LANES:
                            bad = "a legal lane (" + "/, ".join(sorted(segs & LEGAL_LANES)) + "/) cannot be attested open"
                if bad:
                    refuse(f"{attested_file}:{n}", f"attestation line {n} is malformed: {bad}")
                    continue
                attest.setdefault(p, []).append((officer, day, fp[7:] if fp else None, n))

# ── media list ────────────────────────────────────────────────────────────────────────────────────────────────────────
media = {}      # listed folder -> (who approved it, date, how many pictures and fonts it let through)
APPROVED = re.compile(r"approved by:?\s+(\S.*?)\s*\|\s*(\S+)", re.I)
# Never listable: the legal lanes, what never travels, and the word for a private tax folder in its plural.
NOT_LISTABLE = LEGAL_LANES | {w("tax", "es")}

if media_file:
    if not os.path.isfile(media_file):
        notes.append(f"media list {media_file} not found; no folder is listed")
    else:
        approved = None
        with open(media_file, encoding="utf-8", errors="replace") as fh:
            for n, raw in enumerate(fh, 1):
                line = re.sub(r"(?:^|\s)#.*$", "", raw).strip()
                if not line:
                    continue
                bad = None
                head = APPROVED.fullmatch(line)
                if head:
                    who, day = head.groups()
                    try:
                        d = datetime.date.fromisoformat(day) if re.fullmatch(r"\d{4}-\d{2}-\d{2}", day) else None
                    except ValueError:
                        d = None
                    if d is None:
                        bad = "the date must be a real YYYY-MM-DD"
                    elif d > datetime.date.today() + datetime.timedelta(days=1):
                        bad = "the date is in the future"
                    else:
                        approved = (who, day)
                elif "|" in line or line.lower().startswith("approved"):
                    bad = "a header must read 'approved by <name> | YYYY-MM-DD'"
                else:
                    p = line.rstrip("/")
                    segs = p.split("/")
                    if p.startswith("/") or any(c in p for c in "*?[") or (p != "." and any(x in ("", ".", "..") for x in segs)):
                        bad = "a folder must be relative, one real path, with no '..' or wildcards"
                    elif {x.lower() for x in segs} & NOT_LISTABLE or any(SEG_NEVER.match(x) for x in segs):
                        bad = f"'{p}' can never be listed (a legal lane, or a name that never travels)"
                    elif approved is None:
                        bad = "it needs a line 'approved by <name> | YYYY-MM-DD' above it: a person chooses these folders"
                    else:
                        media[p] = (approved[0], approved[1], 0)
                if bad:
                    refuse(f"{media_file}:{n}", f"media list line {n} is malformed: {bad}")


def listed_folder(dirs):
    """The media-list folder covering this file's folder, or None. '.' covers the top level only."""
    if not dirs:
        return "." if "." in media else None
    for i in range(len(dirs), 0, -1):
        key = "/".join(dirs[:i])
        if key in media:
            return key
    return None


# ── reading ───────────────────────────────────────────────────────────────────────────────────────────────────────────
pdftotext = os.environ.get("PDFTOTEXT") or shutil.which("pdftotext")
if pdftotext and not (os.path.isfile(pdftotext) and os.access(pdftotext, os.X_OK)):
    pdftotext = None
counts = {"text": 0, "pdf": 0, "office": 0, "picture": 0, "other": 0}


def where(text, pos, paged):
    line = text.count("\n", 0, pos) + 1
    if paged:
        page = text.count("\f", 0, pos) + 1
        start = text.rfind("\f", 0, pos) + 1
        return f"page {page}, line {text.count(chr(10), start, pos) + 1}"
    return f"line {line}"


def scan_text(text, paged=False):
    never, sens = [], []
    for label, rx in NEVER:
        m = rx.search(text)
        if m:
            never.append(f"{label} ({where(text, m.start(), paged)})")
    stripped = SPEC_LINK.sub(" ", text)
    m = BARE_AS.search(stripped)
    if m:
        never.append(f"the agent-notes folder name ({where(stripped, m.start(), paged)})")
    for label, rx in SENSITIVE:
        hay = PUBLIC_PREVIEW.sub(lambda m: " " * len(m.group(0)), text) if label == PERSONAL else text
        m = rx.search(hay)
        if m:
            sens.append(f"{label} ({where(text, m.start(), paged)})")
    for m in ACCOUNT.finditer(text):
        if sum(c.isdigit() for c in m.group(1)) > 4:
            sens.append(f"a labelled account number longer than four digits ({where(text, m.start(), paged)})")
            break
    return never, sens


def xml_text(data):
    s = data.decode("utf-8", "replace")
    s = re.sub(r"</(?:w:p|a:p|text:p|text:h|row|si|w:tr|table:table-row)>", "\n", s)
    s = re.sub(r"</(?:c|w:tc|table:table-cell)>|<w:tab/>|<w:br/>|<text:s/>|<text:tab/>", " ", s)
    s = re.sub(r"<[^>]+>", "", s)
    return html.unescape(s)


def read_pdf(path):
    """-> (text or None, unreadable reason or None)"""
    if not pdftotext:
        return None, "a PDF, and pdftotext is not installed here, so nothing read it (brew install poppler; apt-get install poppler-utils)"
    try:
        r = subprocess.run([pdftotext, "-q", "-enc", "UTF-8", path, "-"], stdin=subprocess.DEVNULL,
                           capture_output=True, timeout=180)
    except subprocess.TimeoutExpired:
        return None, "a PDF that pdftotext could not finish reading"
    if r.returncode != 0:
        return None, "a PDF that pdftotext could not open (damaged or password-locked)"
    text = r.stdout.decode("utf-8", "replace")
    pages = text.split("\f")
    if pages and pages[-1].strip() == "":
        pages = pages[:-1]
    empty = [i + 1 for i, p in enumerate(pages) if not p.strip()]
    if not pages or len(empty) == len(pages):
        return text, "a PDF with no extractable text (a scan or an image-only file): no machine read it"
    if empty:
        shown = ", ".join(map(str, empty[:8])) + ("..." if len(empty) > 8 else "")
        return text, f"a PDF whose page(s) {shown} carry no text (scanned or image-only pages): no machine read them"
    return text, None


def read_office(path):
    try:
        with zipfile.ZipFile(path) as z:
            parts, embedded, attrs, total = [], [], [], 0
            for info in z.infolist():
                name = info.filename
                if name.endswith("/"):
                    continue
                low = name.lower()
                if low.endswith((".xml", ".rels")):
                    total += info.file_size
                    if total > MAX_OFFICE_XML:
                        return None, "an office file too large to read safely", ""
                    raw = z.read(info)
                    parts.append(xml_text(raw))
                    # attribute values are not text a reader sees, but they travel: hyperlink targets, alt text
                    attrs.extend(html.unescape(v) for v in re.findall(r'="([^"]*)"', raw.decode("utf-8", "replace")))
                elif low in ("mimetype", "meta-inf/manifest.rdf"):
                    continue
                else:
                    embedded.append(name)
    except (zipfile.BadZipFile, OSError, RuntimeError, NotImplementedError):
        return None, "an office file that could not be unzipped (damaged or password-locked)", ""
    text = "\n".join(parts)
    hidden = "\n".join(attrs)
    if embedded:
        return text, f"an office file carrying {len(embedded)} embedded picture(s) or object(s) no machine read (e.g. {embedded[0]})", hidden
    return text, None, hidden


def pagefind_kind(dirs, base):
    """'gzip' or 'wasm' when this is a pagefind index file under a pagefind/ folder, else None."""
    if "pagefind" not in {d.lower() for d in dirs}:
        return None
    if PAGEFIND_GZIP.search(base):
        return "gzip"
    if PAGEFIND_WASM.match(base):
        return "wasm"
    return None


def read_pagefind(kind, data):
    """-> (the bytes a machine can search, as text; or None and the reason it is not what pagefind writes)"""
    if kind == "wasm":
        if not data.startswith(b"\x00asm"):
            return None, "named like pagefind's WebAssembly but its bytes are not WebAssembly; rebuild the search index or remove it"
        return data.decode("latin-1"), None
    if not data.startswith(b"\x1f\x8b"):
        return None, "named like a pagefind index file but its bytes are not the gzip pagefind writes; rebuild the search index or remove it"
    try:
        inner = gzip.GzipFile(fileobj=io.BytesIO(data)).read(MAX_INFLATE + 1)
    except (OSError, EOFError, zlib.error):
        return None, "named like a pagefind index file but its gzip cannot be inflated; rebuild the search index or remove it"
    if len(inner) > MAX_INFLATE:
        return None, "a pagefind index file that inflates to more than 64 MB: too large to read safely"
    return inner.decode("latin-1"), None


def decode_text(data):
    if b"\x00" in data[:8192]:
        return None
    try:
        return data.decode("utf-8")
    except UnicodeDecodeError:
        ctrl = sum(1 for b in data[:65536] if b < 9 or 13 < b < 32)
        if ctrl > len(data[:65536]) // 100:
            return None
        return data.decode("latin-1")


def svg_active(text):
    """True when an SVG can run something. Entities and the blanks a browser ignores cannot hide a code link."""
    return bool(SVG_TAGS.search(text) or SVG_LINK.search(re.sub(r"[\t\r\n]", "", html.unescape(text))))


def decode_embed(payload):
    s = urllib.parse.unquote(re.sub(r"\s+", "", payload))
    s = re.match(r"[A-Za-z0-9+/]*", s).group(0)
    if len(s) % 4 == 1:
        s = s[:-1]
    return base64.b64decode(s + "=" * (-len(s) % 4))


def embed_active(mime, data):
    """What this embed is, if it is something that runs or a document no reader sees: a phrase, or None."""
    for sig, kind in ACTIVE_BYTES:
        if data.startswith(sig):
            return kind
    if ACTIVE_MIME.search(mime):
        return "a PDF" if "pdf" in mime else "a script or HTML"
    if ACTIVE_TEXT.search(data[:65536].decode("latin-1")):
        return "a script or HTML"
    return None


def read_embeds(text, in_assets, in_media, depth=0):
    """Decode every base64 data: address in this text. -> (never, sensitive, unread), as check() reads them."""
    never, sens, unread = [], [], []
    for m in EMBED.finditer(text):
        mime, payload = (m.group(1) or "text/plain").lower(), m.group(2)
        data = decode_embed(payload)
        if not data:
            continue    # the label with nothing after it: code that builds an address, or a page describing one
        at = where(text, m.start(), False)
        picture = mime.startswith("image/") and "svg" not in mime and any(magic_ok(x, data) for x in IMAGES)
        font = "font" in mime and any(magic_ok(x, data) for x in FONTS)
        decoded = None if picture or font else decode_text(data)
        n, s = scan_text(decoded) if decoded else (scan_text(data.decode("latin-1"))[0], [])
        never += [f"{x.rsplit(' (', 1)[0]} (inside a base64 embed, {at})" for x in n]
        sens += [f"{x.rsplit(' (', 1)[0]} (inside a base64 embed, {at})" for x in s]
        if picture:
            continue
        if font:
            if not (in_assets or in_media):
                unread.append(f"a font embedded as base64 ({at}) in a folder that is neither assets/ or icons/ nor in PUBLIC-LANE-MEDIA.txt")
            continue
        if "svg" in mime and decoded:
            if svg_active(decoded):
                unread.append(f"text that embeds an SVG as base64 that carries a script or an event handler ({at})")
            if depth >= MAX_EMBED_DEPTH:
                unread.append(f"base64 embeds nested too deep to read ({at})")
            else:
                inner = read_embeds(decoded, in_assets, in_media, depth + 1)
                never, sens, unread = never + inner[0], sens + inner[1], unread + inner[2]
            continue
        active = embed_active(mime, data)
        if active:
            unread.append(f"text that embeds {active} as base64: decoded and refused ({at})")
        elif len(payload) >= LONG_EMBED and not in_assets:
            unread.append(f"text that embeds a file as base64 that is not a plain picture ({mime}, {at})")
    return never, sens, unread


def check(full, rel):
    parts = rel.split("/")
    rule_parts = parts[strip:] if len(parts) > strip else parts[-1:]
    rule = "/".join(rule_parts)
    dirs = rule_parts[:-1]
    base = rule_parts[-1]

    # names that never travel
    for i, seg in enumerate(rule_parts):
        if SEG_NEVER.match(seg):
            if seg.lower() == ".claude" and rule_parts[i + 1:i + 2] == ["skills"]:
                continue
            return refuse(rel, f"'{seg}' never travels (agent notes, tool configuration or secrets), whatever any list says")
    if FILE_NEVER.match(base):
        return refuse(rel, "the name looks like a key, wallet, credential or environment file; it never travels")
    lanes = sorted({d.lower() for d in dirs} & LEGAL_LANES)
    if lanes:
        return refuse(rel, f"a legal lane ({'/, '.join(lanes)}/) never publishes, whatever the allowlist or an attestation says")
    st = os.lstat(full)
    if stat.S_ISLNK(st.st_mode):
        return refuse(rel, "a symbolic link; publish the file itself")
    if not stat.S_ISREG(st.st_mode):
        return refuse(rel, "not a regular file")
    if st.st_size > MAX_BYTES:
        return refuse(rel, "over 15 MB")

    with open(full, "rb") as fh:
        data = fh.read()
    digest = hashlib.sha256(data).hexdigest()
    ext = os.path.splitext(base)[1].lower()
    in_assets = bool({d.lower() for d in dirs} & ASSET_DIRS)
    folder = listed_folder(dirs)
    text, unread, paged = None, None, False
    embed_never, embed_sens = [], []
    hidden = ""   # bytes a reader never sees but that travel: office attributes, a picture's or font's own bytes
    hidden_at = "in the file's own bytes or attributes"
    pagefind = pagefind_kind(dirs, base)

    if ext == ".pdf" or data[:5] == b"%PDF-":
        counts["pdf"] += 1
        text, unread = read_pdf(full)
        paged = True
    elif ext in OFFICE:
        counts["office"] += 1
        text, unread, hidden = read_office(full)
    elif ext in IMAGES or ext in FONTS:
        counts["picture"] += 1
        if not magic_ok(ext, data):
            return refuse(rel, f"named {ext} but its bytes are not that kind of file; rename or replace it")
        if folder is None and not in_assets:
            here = "/".join(dirs) or "."
            unread = (("a picture" if ext in IMAGES else "a font") + " outside an assets/ or icons/ folder and outside any folder "
                      f"this lane lists: no machine reads pictures. If a person chose to publish this folder, add '{here}' to "
                      "PUBLIC-LANE-MEDIA.txt, under a line 'approved by <name> | YYYY-MM-DD'")
        # its pixels are not read, but its bytes are searched for credentials (metadata, or text appended after the image)
        hidden = data.decode("latin-1")
    elif pagefind:
        counts["other"] += 1
        hidden, bad = read_pagefind(pagefind, data)
        if bad:
            return refuse(rel, bad)
        # the index is what the site's pages say, compressed: inflated here and searched for credentials
        hidden_at = "inside the search index's compressed bytes"
    else:
        text = decode_text(data)
        if text is None:
            counts["other"] += 1
            unread = "a binary file no machine here can read"
        else:
            counts["text"] += 1
            embed_never, embed_sens, embed_unread = read_embeds(text, in_assets, folder is not None)
            if ext == ".svg" and svg_active(text):
                embed_unread.insert(0, "an SVG that carries a script, an event handler or a link that runs code")
            if embed_unread:
                unread = "; ".join(embed_unread[:3]) + (f"; and {len(embed_unread) - 3} more" if len(embed_unread) > 3 else "")

    never, sens = scan_text(text, paged) if text else ([], [])
    never, sens = never + embed_never, sens + embed_sens
    if hidden:
        never += [f"{x.rsplit(' (', 1)[0]} ({hidden_at})" for x in scan_text(hidden)[0]]
    if never:
        return refuse(rel, "carries " + "; ".join(never) + ". No attestation opens this: remove it from the file")
    problems = sens + ([unread] if unread else [])
    if not problems:
        if folder is not None and (ext in IMAGES or ext in FONTS) and not in_assets:
            who, day, seen = media[folder]
            media[folder] = (who, day, seen + 1)
        return
    entries = attest.get(rule, [])
    ok = [e for e in entries if e[2] is None or e[2] == digest]
    if ok:
        officer, day, fp, n = ok[0]
        used.add(rule)
        notes.append(f"attested  {rel}: {officer}, {day}" + ("" if fp else " (no fingerprint: read it again whenever it changes)")
                     + f" [{'; '.join(problems)}]")
        return
    if entries:
        used.add(rule)
        return refuse(rel, "; ".join(problems) + f". It was attested at a different fingerprint, so it changed after it was read:"
                      f" read it again, then update the line to sha256:{digest}")
    refuse(rel, "; ".join(problems) + f". A person may open and read it, then attest it: '{rule} | <officer> | "
           f"{datetime.date.today().isoformat()} | opened and read | sha256:{digest}'")


n_files = 0
for dirpath, dirnames, filenames in os.walk(root, followlinks=False):
    relbase = os.path.relpath(dirpath, root)
    relbase = "" if relbase == "." else relbase.replace(os.sep, "/")
    if relbase == "":
        dirnames[:] = [d for d in dirnames if d != ".git"]
    for d in list(dirnames):
        if os.path.islink(os.path.join(dirpath, d)):
            refuse(f"{relbase}/{d}".lstrip("/"), "a symbolic link to a folder; publish the folder itself")
            dirnames.remove(d)
    dirnames.sort()
    for name in sorted(filenames):
        n_files += 1
        check(os.path.join(dirpath, name), f"{relbase}/{name}".lstrip("/"))

for p in sorted(set(attest) - used):
    if strip == 0:
        notes.append(f"unused attestation: {p} is not in this lane or needed no attestation")

for folder, (who, day, seen) in sorted(media.items()):
    notes.append(f"listed    {folder}: {seen} picture(s) and font(s) published on purpose; approved by {who}, {day}"
                 + ("" if seen else " (nothing here needed the list)"))

for note in notes:
    print(f"{ME}: {note}")
for path, reason in refusals:
    print(f"{ME}: refused  {path} — {reason}", file=sys.stderr)
    if GHA:
        print(f"::error title=public-lane tripwire::{path}: {reason}", file=sys.stderr)
summary = (f"{n_files} file(s) read ({counts['text']} text, {counts['pdf']} PDF, {counts['office']} office, "
           f"{counts['picture']} picture/font, {counts['other']} other)")
if refusals:
    print(f"{ME}: {summary}; {len(refusals)} refused. Nothing should be published until each line above is fixed.", file=sys.stderr)
    sys.exit(1)
print(f"{ME}: {summary}; every file read; clean")
PY
