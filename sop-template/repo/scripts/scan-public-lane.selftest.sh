#!/bin/sh
# scan-public-lane.selftest.sh — proves the public-lane tripwire refuses what it must and passes what it may.
#
#   sh scripts/scan-public-lane.selftest.sh
#
# Every fixture is generated at test time with python3's standard library (hand-assembled PDFs, .docx/.xlsx zips, a
# PNG) in a temporary folder that is removed afterwards; no fixture is committed. Planted values are fakes, assembled
# from pieces so this file itself passes the tripwire. The PDF cases need pdftotext (brew install poppler; on Ubuntu
# runners sudo apt-get install -y poppler-utils); without it the run checks that PDFs are refused (fail closed) and
# exits 2, INCOMPLETE.
#
# Exit codes: 0 every case as expected · 1 a case failed · 2 incomplete (pdftotext missing).
set -eu
here="$(cd "$(dirname "$0")" && pwd)"
scan="$here/scan-public-lane.sh"
[ -f "$scan" ] || { echo "selftest: $scan not found" >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "selftest: python3 is required" >&2; exit 1; }
work="$(mktemp -d "${RUNNER_TEMP:-${TMPDIR:-/tmp}}/scan-selftest.XXXXXX")"
trap 'rm -rf "$work"' EXIT INT TERM
have_pdf=1
if [ -n "${PDFTOTEXT:-}" ]; then [ -x "$PDFTOTEXT" ] || have_pdf=0; else command -v pdftotext >/dev/null 2>&1 || have_pdf=0; fi

# ── fixtures ──────────────────────────────────────────────────────────────────────────────────────────────────────────
python3 -I - "$work/fx" <<'PY'
import os, struct, sys, zipfile, zlib
fx = sys.argv[1]
os.makedirs(fx)
EIN = "12" + "-" + "3456789"                     # a fake employer number
SSN = "123" + "-" + "45" + "-" + "6789"           # a fake social-security number
TOKEN = "gh" + "p_" + "Q" * 36                    # a fake GitHub token

def pdf(path, text=None):
    if text is not None:
        content = b"BT /F1 14 Tf 72 720 Td (" + text.encode("latin-1") + b") Tj ET"
    else:  # a 2x2 grey picture drawn across the page: an image-only PDF, as a scanner makes
        content = b"q 300 0 0 300 72 400 cm BI /W 2 /H 2 /CS /G /BPC 8 /F /AHx ID 0080FF40> EI Q"
    objs = [b"<< /Type /Catalog /Pages 2 0 R >>",
            b"<< /Type /Pages /Kids [3 0 R] /Count 1 >>",
            b"<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Resources << /Font << /F1 5 0 R >> >> /Contents 4 0 R >>",
            b"<< /Length %d >>\nstream\n" % len(content) + content + b"\nendstream",
            b"<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>"]
    out = b"%PDF-1.4\n"
    offs = []
    for i, o in enumerate(objs, 1):
        offs.append(len(out))
        out += b"%d 0 obj\n" % i + o + b"\nendobj\n"
    xref = len(out)
    out += b"xref\n0 %d\n0000000000 65535 f \n" % (len(objs) + 1)
    for o in offs:
        out += b"%010d 00000 n \n" % o
    out += b"trailer\n<< /Size %d /Root 1 0 R >>\nstartxref\n%d\n%%%%EOF\n" % (len(objs) + 1, xref)
    write(path, out)

def png():
    def chunk(t, d):
        return struct.pack(">I", len(d)) + t + d + struct.pack(">I", zlib.crc32(t + d) & 0xffffffff)
    raw = b"\x00\xff\x00\x00\x00\xff"
    return (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", 2, 1, 8, 0, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress(raw)) + chunk(b"IEND", b""))

def write(path, data):
    full = os.path.join(fx, path)
    os.makedirs(os.path.dirname(full), exist_ok=True)
    with open(full, "wb") as fh:
        fh.write(data if isinstance(data, bytes) else data.encode())

def office(path, members):
    full = os.path.join(fx, path)
    os.makedirs(os.path.dirname(full), exist_ok=True)
    with zipfile.ZipFile(full, "w") as z:
        z.writestr("[Content_Types].xml", '<?xml version="1.0"?><Types/>')
        for n, d in members.items():
            z.writestr(n, d)

W = 'xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"'
write("clean/README.md", "# A public page\n\nPlain words for anyone. Step 2 is to read the welcome deck.\n")
write("clean/icons/dot.png", png())
pdf("clean/pdf/welcome.pdf", "Welcome, reader. This page has words a machine can read.")
office("clean/docs/notes.docx", {"word/document.xml": f'<w:document {W}><w:body><w:p><w:r><w:t>Hello</w:t></w:r></w:p></w:body></w:document>'})
pdf("ein_pdf/letter.pdf", "Our EIN is " + EIN)
pdf("image_pdf/scan.pdf")
pdf("legal/tax/return.pdf", "Plain words")
write("legal/README.md", "the legal lane's public face\n")
# a token split across two runs, as Word stores text
office("docx_secret/memo.docx", {"word/document.xml": f'<w:document {W}><w:body><w:p><w:r><w:t>{TOKEN[:3]}</w:t></w:r><w:r><w:t>{TOKEN[3:]}</w:t></w:r></w:p></w:body></w:document>'})
office("xlsx_ssn/sheet.xlsx", {"xl/sharedStrings.xml": f'<sst><si><t>{SSN}</t></si></sst>', "xl/worksheets/sheet1.xml": "<worksheet/>"})
office("docx_picture/brochure.docx", {"word/document.xml": f'<w:document {W}><w:body><w:p><w:r><w:t>See the picture</w:t></w:r></w:p></w:body></w:document>', "word/media/image1.png": png()})
write("stray_image/photos/dot.png", png())
write("fake_image/assets/dot.png", b"PK\x03\x04 not a picture")
write("binary/blob.bin", b"\x00\x01\x02\x03binary")
write("street/README.md", "Visit us at " + "42 Example " + "Street" + ", any day.\n")
write("giver/README.md", "Our " + "don" + "or list is below.\n")
write("account/README.md", "Acc" + "ount number: 12345678\n")
write("account_short/README.md", "Acc" + "ount ending 1234 is masked as ****1234.\n")
write("agentnote/README.md", "See " + "AGENT" + "-SYNC/created-" + "by-alfred/x.md\n")
write("speclink/README.md", "Attribution: https://github.com/drasticstatic/my-template/blob/main/" + "AGENT" + "-SYNC/README.md\n")
write("forbidden/CLAUDE.md", "notes\n")
write("treasury/README.md", "Self-" + "cus" + "tody, institutional " + "cus" + "tody and " + "cus" + "tody of the keys are treasury words.\n")
write("matter/README.md", "The " + "cus" + "tody hearing is next week.\n")
# round-four review: holes the first version left open
write("eot_fake/assets/font.eot", "not a font " + TOKEN)
write("png_tail/assets/dot.png", png() + TOKEN.encode())
office("docx_link/memo.docx", {"word/document.xml": f'<w:document {W}><w:body><w:p><w:r><w:t>Click here</w:t></w:r></w:p></w:body></w:document>',
       "word/_rels/document.xml.rels": '<Relationships><Relationship Id="r1" Target="https://' + "nt" + "fy.sh/" + "abcdefghij" + '" TargetMode="External"/></Relationships>'})
write("iban/README.md", "IB" + "AN: " + "DE89" + "370400440532013000\n")
write("street_ordinal/README.md", "Visit 1600 W " + "5th " + "Street" + " today.\n")
write("ein_dash/README.md", "Number 12" + "\u2013" + "3456789 on file.\n")
write("b64/page.html", "<img src=\"data:image/png;base64," + "A" * 400 + "\">\n")
pdf("history/abc123/tax/old.pdf", "Plain words")
pdf("history/def456/docs/old.pdf")
PY

# ── harness ───────────────────────────────────────────────────────────────────────────────────────────────────────────
fails=0; total=0
expect () { # expect <want-exit> <must-contain or ""> <label> -- scanner arguments...
  want="$1"; grep_for="$2"; label="$3"; shift 4
  total=$((total + 1))
  set +e; out="$(sh "$scan" "$@" 2>&1)"; got=$?; set -e
  if [ "$got" = "$want" ] && { [ -z "$grep_for" ] || printf '%s' "$out" | grep -Fq -- "$grep_for"; }; then
    echo "ok    $label"
  else
    echo "FAIL  $label (wanted exit $want${grep_for:+ and '$grep_for'}, got $got)"; printf '%s\n' "$out" | sed 's/^/      /'
    fails=$((fails + 1))
  fi
}
att="$work/attested.txt"
attest () { printf '%s\n' "$@" > "$att"; }
sha () { python3 -I -c 'import hashlib,sys; print(hashlib.sha256(open(sys.argv[1],"rb").read()).hexdigest())' "$1"; }
fx="$work/fx"

if [ "$have_pdf" = 1 ]; then
  expect 0 "clean"                  "clean text, an icon, a text PDF and a plain .docx pass"              -- "$fx/clean"
  expect 1 "letter.pdf"             "a fake EIN inside a PDF is refused"                                  -- "$fx/ein_pdf"
  expect 1 "no extractable text"    "an image-only PDF is refused"                                        -- "$fx/image_pdf"
  attest "scan.pdf | Test Officer | 2026-11-01 | opened and read"
  expect 0 "attested  scan.pdf"     "the image-only PDF, attested by an officer, passes"                  -- "$fx/image_pdf" "$att"
  attest "scan.pdf | Test Officer | 2026-11-01 | opened and read | sha256:$(sha "$fx/image_pdf/scan.pdf")"
  expect 0 "attested  scan.pdf"     "an attestation with the right fingerprint passes"                    -- "$fx/image_pdf" "$att"
  attest "scan.pdf | Test Officer | 2026-11-01 | opened and read | sha256:$(printf '0%.0s' $(seq 64))"
  expect 1 "different fingerprint"  "an attestation whose fingerprint no longer matches is refused"       -- "$fx/image_pdf" "$att"
  attest "letter.pdf | Test Officer | 2026-11-01 | opened and read"
  expect 0 "attested  letter.pdf"   "a sensitive shape in an attested PDF passes (a person read it)"      -- "$fx/ein_pdf" "$att"
  attest "tax/return.pdf | Test Officer | 2026-11-01 | opened and read"
  expect 1 "cannot be attested"     "tax/ is refused, and an attestation cannot open it"                  -- "$fx/legal" "$att"
  expect 1 "a legal lane (tax/)"    "tax/ is refused by path even with no attestation file"               -- "$fx/legal"
  expect 1 "a legal lane (tax/)"    "--strip 1: tax/ in a historical version is refused"                  -- --strip 1 "$fx/history"
  attest "docs/old.pdf | Test Officer | 2026-11-01 | opened and read"
  rm -rf "$fx/history/abc123"
  expect 0 "attested"               "--strip 1: an attestation matches the path inside a version folder"  -- --strip 1 "$fx/history" "$att"
fi
expect 1 "GitHub token"             "a token split across .docx runs is refused"                          -- "$fx/docx_secret"
attest "memo.docx | Test Officer | 2026-11-01 | opened and read"
expect 1 "No attestation opens"     "a credential stays refused even when attested"                       -- "$fx/docx_secret" "$att"
expect 1 "social-security"          "a fake SSN in an .xlsx is refused"                                   -- "$fx/xlsx_ssn"
expect 1 "embedded picture"         "a .docx carrying a picture is refused"                               -- "$fx/docx_picture"
expect 1 "outside an assets/"       "a picture outside assets/ or icons/ is refused"                      -- "$fx/stray_image"
attest "photos/dot.png | Test Officer | 2026-11-01 | opened and read"
expect 0 "attested  photos/dot.png" "the same picture, attested, passes"                                  -- "$fx/stray_image" "$att"
expect 1 "not that kind of file"    "a file named .png that is not a picture is refused, even in assets/" -- "$fx/fake_image"
expect 1 "binary file"              "an unknown binary is refused"                                        -- "$fx/binary"
expect 1 "street-address"           "a street address is refused"                                         -- "$fx/street"
expect 1 "giver-list"               "the giver-list word is refused"                                      -- "$fx/giver"
expect 1 "account number"           "a labelled account number longer than four digits is refused"        -- "$fx/account"
expect 0 "clean"                    "a masked four-digit account ending passes"                           -- "$fx/account_short"
expect 1 "agent notes"              "a pointer into agent notes is refused"                               -- "$fx/agentnote"
expect 0 "clean"                    "the public attribution-spec link passes"                             -- "$fx/speclink"
expect 1 "never travels"            "CLAUDE.md never travels"                                             -- "$fx/forbidden"
expect 0 "clean"                    "the asset senses of the matter word pass (treasury vocabulary)"        -- "$fx/treasury"
expect 1 "personal-matter"          "the matter word in its personal sense is refused"                   -- "$fx/matter"
expect 1 "base64"                   "text embedding a base64 picture outside assets/ is refused"          -- "$fx/b64"
expect 1 "not that kind of file"    "a font named .eot whose bytes are not a font is refused, even in assets/" -- "$fx/eot_fake"
expect 1 "GitHub token"             "a token appended to a picture in assets/ is refused"                 -- "$fx/png_tail"
expect 1 "ntfy topic"               "a .docx link target (an attribute, not text) is still searched"      -- "$fx/docx_link"
expect 1 "account number"           "an IBAN (country code first) beside its label is refused"           -- "$fx/iban"
expect 1 "street-address"           "a street address on a numbered street is refused"                   -- "$fx/street_ordinal"
expect 1 "employer-number"          "an employer-number shape written with an en dash is refused"        -- "$fx/ein_dash"
attest "photos/dot.png | Test Officer | 01-11-2026 | opened and read"
expect 1 "malformed"                "a malformed attestation line is refused"                             -- "$fx/stray_image" "$att"
attest "photos/dot.png | Test Officer | 2026-11-01 | looked at it"
expect 1 "opened and read"          "an attestation must say opened and read"                             -- "$fx/stray_image" "$att"
ln -s "$fx/clean/README.md" "$fx/binary/link.md"
expect 1 "symbolic link"            "a symbolic link is refused"                                          -- "$fx/binary"
saved="${PDFTOTEXT-__unset__}"; export PDFTOTEXT=/nonexistent/pdftotext
expect 1 "pdftotext is not installed" "without pdftotext a PDF is refused (fail closed)"                 -- "$fx/ein_pdf"
if [ "$saved" = __unset__ ]; then unset PDFTOTEXT; else PDFTOTEXT="$saved"; fi
# the scanner and this test are publishable through a lane: they trip nothing themselves
mkdir -p "$work/self/scripts"; cp "$scan" "$0" "$work/self/scripts/"
expect 0 "clean"                    "the scanner and its self-test pass their own tripwire"               -- "$work/self"

# sync-allowlist.sh integration, where a copy sits beside this script (the SOP template and the repositories using it)
sync="${SYNC_ALLOWLIST:-}"
[ -n "$sync" ] || { [ -f "$here/sync-allowlist.sh" ] && sync="$here/sync-allowlist.sh"; } || true
[ -n "$sync" ] || { [ -f "$here/../sop-template/repo/scripts/sync-allowlist.sh" ] && sync="$here/../sop-template/repo/scripts/sync-allowlist.sh"; } || true
if [ -n "$sync" ] && [ "$have_pdf" = 1 ] && grep -q 'scan-public-lane' "$sync"; then
  repo="$work/repo"; mkdir -p "$repo/scripts" "$repo/docs"
  cp "$sync" "$repo/scripts/sync-allowlist.sh"; cp "$scan" "$repo/scripts/scan-public-lane.sh"
  cp "$fx/ein_pdf/letter.pdf" "$repo/docs/letter.pdf"; cp "$fx/clean/README.md" "$repo/docs/README.md"
  for case in bad good; do
    total=$((total + 1))
    if [ "$case" = bad ]; then printf 'docs\n' > "$repo/PUBLIC-ALLOWLIST.txt"; want=1; else printf 'docs/README.md\n' > "$repo/PUBLIC-ALLOWLIST.txt"; want=0; fi
    set +e; out="$(cd "$repo" && TRIPWIRE_PUBLIC=1 sh scripts/sync-allowlist.sh stage PUBLIC-ALLOWLIST.txt "$work/stage-$case" 2>&1)"; got=$?; set -e
    if [ "$got" = "$want" ]; then echo "ok    sync-allowlist.sh stage ($case lane) exits $want"; else
      echo "FAIL  sync-allowlist.sh stage ($case lane): wanted $want, got $got"; printf '%s\n' "$out" | sed 's/^/      /'; fails=$((fails + 1)); fi
  done
fi
# the SOP template's copies must be the master, byte for byte
for copy in "$here/../sop-template/repo/scripts/scan-public-lane.sh" "$here/../sop-template/repo/scripts/scan-public-lane.selftest.sh"; do
  [ -f "$copy" ] || continue
  total=$((total + 1)); master="$here/$(basename "$copy")"
  if cmp -s "$master" "$copy"; then echo "ok    $(basename "$copy") in sop-template matches the master"; else
    echo "FAIL  sop-template's $(basename "$copy") differs from the master: copy it again"; fails=$((fails + 1)); fi
done

echo "selftest: $((total - fails))/$total as expected"
[ "$fails" = 0 ] || exit 1
if [ "$have_pdf" = 0 ]; then
  echo "selftest: INCOMPLETE: pdftotext is not installed, so the PDF cases did not run (brew install poppler)" >&2; exit 2
fi
