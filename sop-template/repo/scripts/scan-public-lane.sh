#!/bin/sh
# scan-public-lane.sh — the public-lane tripwire: a public lane never publishes a file a machine or a person has not read.
#
#   sh scripts/scan-public-lane.sh [--strip N] <directory-about-to-be-published> [<PUBLIC-ALLOWLIST-ATTESTED.txt>]
#
# It reads EVERY file under the directory (only the top-level .git is skipped) and exits non-zero, naming each file,
# when anything there has not been read:
#   text           scanned for credentials, agent-note pointers and sensitive shapes (identity numbers, labelled tax
#                  identifiers, birth dates, street addresses, giver lists, labelled account numbers, personal matters)
#   PDF            its text is extracted with pdftotext (poppler) and scanned the same way; a PDF with no text, or with
#                  pages that carry none (a scan, an image-only page), or that cannot be opened, is refused
#   .docx .xlsx    (and .pptx, OpenDocument) unzipped; the XML text is scanned; embedded pictures or objects are refused
#   pictures       allowed only under an assets/ or icons/ folder (fonts too), and only when the bytes are the picture
#                  the name claims; anywhere else they are refused. Pixels are not read, but every picture's and font's
#                  bytes, and every office file's XML attributes (link targets, alt text), are searched for credentials
#                  and agent-note pointers
#   anything else  a binary no machine can read here, refused
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
# --strip N   apply the path rules and the attestation to the path with its first N folders removed (used when a
#             workflow lays every historical version out as <blob>/<path>).
# PDFTOTEXT   environment: the pdftotext to use (default: the one on PATH). Install: brew install poppler (macOS),
#             sudo apt-get install -y poppler-utils (Ubuntu runners).
#
# Exit codes: 0 every file read and clean · 1 refused (each file named above the summary) · 2 usage or environment.
# Matched text is never printed, only the kind of match and where it is, so a found secret does not leak into a log.
# Master copy: my-template/scripts/scan-public-lane.sh (self-test: scan-public-lane.selftest.sh). Copy, do not fork.
set -eu
command -v python3 >/dev/null 2>&1 || { echo "scan-public-lane: python3 is required" >&2; exit 2; }
exec python3 -I - "$@" <<'PY'
import datetime, hashlib, html, os, re, shutil, stat, subprocess, sys, zipfile

ME = "scan-public-lane"
GHA = os.environ.get("GITHUB_ACTIONS") == "true"
MAX_BYTES = 15 * 1024 * 1024
MAX_OFFICE_XML = 64 * 1024 * 1024


def w(*parts):
    # Words are assembled from pieces so that this file, published through a lane, does not trip its own tripwire.
    return "".join(parts)


def usage(msg):
    print(f"{ME}: {msg}", file=sys.stderr)
    print(f"usage: sh scripts/{ME}.sh [--strip N] <directory> [<attested-file>]", file=sys.stderr)
    sys.exit(2)


args = sys.argv[1:]
strip = 0
while args and args[0].startswith("-"):
    if args[0] == "--strip" and len(args) >= 2 and args[1].isdigit():
        strip = int(args[1])
        args = args[2:]
    elif args[0] in ("-h", "--help"):
        print(f"usage: sh scripts/{ME}.sh [--strip N] <directory> [<attested-file>]  (details: the comment at the top of the script)")
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
# treasury vocabulary rather than the personal matter.
CUST = ("".join(f"(?<!{b})" for b in ("self-", "self ", "institutional ", "qualified ", "key ", "asset ", "crypto ", "mpc "))
        + w("cus", "tody") + r"(?!\s+of\s+(?:the\s+)?(?:keys|funds|assets|tokens)\b)")
# A hyphen, or the dashes a word processor substitutes for one (non-breaking hyphen, en and em dash, minus sign).
DASH = "[-\u2010-\u2015\u2212]"
SENSITIVE = [
    ("a personal-matter word", re.compile(r"\b(?:" + w("div", "orce") + "|" + CUST + "|" + w("tax", "-assistant") + ")", re.I)),
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
EMBEDDED_B64 = re.compile(r"data:[A-Za-z0-9.+/-]+;base64,[A-Za-z0-9+/=\s]{200,}")

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
        m = rx.search(text)
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
    text, unread, paged = None, None, False
    hidden = ""   # bytes a reader never sees but that travel: office attributes, a picture's or font's own bytes

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
        if not in_assets:
            unread = ("a picture" if ext in IMAGES else "a font") + " outside an assets/ or icons/ folder: no machine reads pictures"
        # its pixels are not read, but its bytes are searched for credentials (metadata, or text appended after the image)
        hidden = data.decode("latin-1")
    else:
        text = decode_text(data)
        if text is None:
            counts["other"] += 1
            unread = "a binary file no machine here can read"
        else:
            counts["text"] += 1
            if not in_assets and EMBEDDED_B64.search(text):
                unread = "text that embeds a file as base64 (a picture or document no machine read)"

    never, sens = scan_text(text, paged) if text else ([], [])
    if hidden:
        never += [f"{x.rsplit(' (', 1)[0]} (in the file's own bytes or attributes)" for x in scan_text(hidden)[0]]
    if never:
        return refuse(rel, "carries " + "; ".join(never) + ". No attestation opens this: remove it from the file")
    problems = sens + ([unread] if unread else [])
    if not problems:
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
