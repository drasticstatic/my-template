#!/usr/bin/env python3
"""agent-sync-health.py: check every local clone's AGENT-SYNC lanes against my-template/AGENT-SYNC/README.md.

    python3 ~/code/my-template/scripts/agent-sync-health.py [root ...]     # default: ~/code ~/drasticstaticLabs ~/dappu ~/theholyearthfoundation ~/psychedelicsinrecovery ~/Octagon-Religious-Research-Group-ORG ~/psanctuary ~/psanctuarychurch ~/taylordwraps ~/WILSONSLAWNMAINTENANCE

my-template's own AGENT-SYNC/ is the public skeleton every repo copies, so it is exempt from the public-repo rule.
Lanes: the canonical created-by-* names below; any other created-by-<name> passes only when it holds a README.md
(a named collaborator's lane), and is flagged otherwise.
Read-only. It runs `git` locally and `gh repo list` once per owner (to learn each repository's visibility).
Prints one line per lane, then the problems; exits 1 if any lane breaks a rule.
"""
import os, re, subprocess, sys

OWNERS = ["drasticstatic", "theholyearthfoundation", "psychedelicsinrecovery", "psanctuary", "psanctuarychurch",
          "Octagon-Religious-Research-Group-ORG", "taylordwraps"]
LANES = {"created-by-christopher", "created-by-alfred", "created-by-fortuna", "created-by-kavanah",
         "created-by-mystarch", "created-by-auggie", "created-by-Littlebird", "created-by-cosmos",
         "created-by-Gemini", "created-by-1alfred"}
PERSON = re.compile(r"^created-by-[A-Za-z0-9][A-Za-z0-9_-]*$")   # a named collaborator's lane: allowed with a README.md
HISTORICAL = {"created-by-augment-vscode-migration", "created-in-claude-cloud"}   # kept as they were: delete nothing
EXTRAS = re.compile(r"^(archive.*|app-data-[a-z]+|VSCode|logs|scripts|\.githooks|\.github)$")

def run(*a, cwd=None):
    r = subprocess.run(a, cwd=cwd, capture_output=True, text=True)
    return r.stdout.strip() if r.returncode == 0 else None

def slug(url):
    m = re.search(r"github\.com[:/](.+?)(\.git)?$", url or "")
    return m.group(1).lower() if m else ""

vis = {}
for o in OWNERS:
    out = run("gh", "repo", "list", o, "-L", "500", "--json", "nameWithOwner,visibility",
              "--jq", '.[]|"\\(.nameWithOwner|ascii_downcase) \\(.visibility)"') or ""
    for line in out.splitlines():
        k, v = line.split(); vis[k] = v.lower()

roots = [os.path.expanduser(r) for r in (sys.argv[1:] or ["~/code", "~/drasticstaticLabs", "~/dappu", "~/theholyearthfoundation", "~/psychedelicsinrecovery",
     "~/Octagon-Religious-Research-Group-ORG", "~/psanctuary", "~/psanctuarychurch", "~/taylordwraps",
     "~/WILSONSLAWNMAINTENANCE"])]
repos = set()
for root in roots:
    for dp, dn, _ in os.walk(root):
        if os.path.exists(os.path.join(dp, ".git")): repos.add(dp)
        dn[:] = [d for d in dn if not d.startswith(".") and d not in ("node_modules", "vendor", "dist", "build")]
        if dp[len(root):].count(os.sep) >= 3: dn[:] = []

bad = 0
for r in sorted(repos):
    v = vis.get(slug(run("git", "remote", "get-url", "origin", cwd=r)), "unknown")
    for a in sorted(e for e in os.listdir(r) if e.startswith("AGENT-SYNC") and os.path.isdir(os.path.join(r, e))):
        p, issues = os.path.join(r, a), []
        own = os.path.exists(os.path.join(p, ".git"))
        ignored = subprocess.run(["git", "-C", r, "check-ignore", "-q", a + "/"]).returncode == 0
        files = [f for dp, _, fs in os.walk(p) if "/.git" not in dp for f in fs if f != ".DS_Store"]
        if own:
            hv = vis.get(slug(run("git", "remote", "get-url", "origin", cwd=p)), "no remote")
            state = f"own repo ({hv})"
            if hv != "private": issues.append("a hub lane must be its own PRIVATE repo")
            if run("git", "status", "--porcelain", cwd=p): issues.append("uncommitted files")
            ab = run("git", "rev-list", "--left-right", "--count", "@{u}...HEAD", cwd=p)
            if ab and ab.split()[1] != "0": issues.append("unpushed commits")
        elif ignored:
            state = "ignored"
            if a != "AGENT-SYNC" or v != "public":
                if files: issues.append(f"{len(files)} files exist only on this machine: make it its own private repo")
        else:
            state = "tracked"
            if v == "public" and a != "AGENT-SYNC_PUBLIC" and not r.endswith("/my-template"): issues.append("a private lane is committable in a PUBLIC repo: git-ignore it")
            if run("git", "status", "--porcelain", "--", a, cwd=r): issues.append("uncommitted files")
        if a == "AGENT-SYNC_PUBLIC" and v == "private": issues.append("AGENT-SYNC_PUBLIC in a private repo (Pattern A)")
        subs = [s for s in os.listdir(p) if os.path.isdir(os.path.join(p, s)) and s != ".git"]
        odd = [s for s in subs if s not in LANES and s not in HISTORICAL and not EXTRAS.match(s)
               and not (PERSON.match(s) and os.path.isfile(os.path.join(p, s, "README.md")))]
        if odd: issues.append("unexpected folders: " + ", ".join(odd)
                              + " (a person's created-by-<name> lane is allowed once it has a README.md saying whose it is)")
        if not os.path.exists(os.path.join(p, "README.md")) and not (a == "AGENT-SYNC" and v == "public" and ignored):
            issues.append("no README (a pointer to my-template/AGENT-SYNC/README.md is enough)")
        bad += bool(issues)
        print(f"{'✗' if issues else '✓'} {r.replace(os.path.expanduser('~'), '~')}/{a}  [{v} repo, {state}, {len(files)} files]"
              + ("".join("\n    - " + i for i in issues)))
print(f"\n{bad} lane(s) need attention." if bad else "\nEvery lane follows the convention.")
sys.exit(1 if bad else 0)
