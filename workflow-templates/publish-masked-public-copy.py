#!/usr/bin/env python3
"""Generate the PUBLIC CONTACTS.md from this private one.

- Removes everything between <!-- private:start --> and <!-- private:end -->.
- Masks every email address NOT on @psychedelicsinrecovery.org as ***@<domain>, so readers know a
  contact exists (full details live in the private org repo) without publishing personal inboxes.
- Prepends a banner pointing at the private source.

Usage:  python3 scripts/publish-public-contacts.py [OUT_PATH]   (default: ../.github/CONTACTS.md)
"""
import pathlib, re, sys

ORG_DOMAIN = "example.org"  # emails on this domain stay visible; all others are masked
here = pathlib.Path(__file__).resolve().parent.parent
src = (here / "CONTACTS.md").read_text()
out = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else here.parent / ".github" / "CONTACTS.md"

text = re.sub(r"<!-- private:start -->.*?<!-- private:end -->\n?", "", src, flags=re.S)
if "private:start" in text or "private:end" in text:
    sys.exit("Unbalanced private markers — refusing to publish.")

def mask(m: re.Match) -> str:
    email = m.group(0)
    domain = email.split("@", 1)[1].lower()
    return email if domain == ORG_DOMAIN or domain.endswith("." + ORG_DOMAIN) else f"***@{domain}"

text = re.sub(r"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}", mask, text)
# Bare role-mailbox shorthand like `info@` is left as-is (it's the org domain).

banner = (
    "<!-- AUTO-GENERATED from psychedelicsinrecovery/.github-private/CONTACTS.md — do not edit here. -->\n"
    "> 📇 **Public copy.** Personal emails are masked (`***`) and some sections are private. Org members\n"
    "> can see the full version in the private `.github-private` repo. **Want access?** Email\n"
    "> helpdesk@psychedelicsinrecovery.org or open a `/github` ticket in PIR's Discord with your service role.\n\n"
)
out.write_text(banner + re.sub(r"\n{3,}", "\n\n", text).lstrip())
print(f"wrote {out}")
