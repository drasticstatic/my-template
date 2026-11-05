<div align="center">

<img src="assets/icons/shield-check.svg" width="56" height="56" alt="">

# Security: why a clone of this repository is safe to fetch

*Nothing runs when you clone or install. Every public page was read before it left. Here is how to tell us if you find otherwise.*

![Guard](https://img.shields.io/badge/Guard-SOP--IT--004_%2310-d97706?style=flat-square)
![Status](https://img.shields.io/badge/Status-living-6b4f1d?style=flat-square)
![Checked](https://img.shields.io/badge/Checked-2026--11--04-64748b?style=flat-square)

</div>

## <img src="assets/icons/compass.svg" width="24" height="24" alt=""> TL;DR

1. <img src="assets/icons/file-check.svg" width="16" height="16" alt=""> **Cloning runs nothing.** No `package.json` here carries a `preinstall`, `postinstall`, `prepare` or `install` script, and [`lifecycle-scripts-check.yml`](.github/workflows/lifecycle-scripts-check.yml) fails any pull request that adds one.
2. <img src="assets/icons/lock.svg" width="16" height="16" alt=""> **Hooks are installed only by hand.** They live in `.githooks/`, are short shell scripts you can read, and do nothing until a person runs `sh scripts/install-hooks.sh` in their own clone.
3. <img src="assets/icons/scan-search.svg" width="16" height="16" alt=""> **Every public page was read before it left,** by a machine and, where the machine could not, by a person who signed for it. The private history never travels.
4. <img src="assets/icons/message-circle-question.svg" width="16" height="16" alt=""> **Found something?** Open an [issue](../../issues), or write to the contact on the organisation's GitHub profile. Say what you saw and where.

## <img src="assets/icons/shield-check.svg" width="24" height="24" alt=""> Why a clone is safe

A repository can only harm the machine that fetches it by running something, and git itself runs nothing on clone. The two ways code gets run anyway are an install step and a hook, and this repository closes both. Its `package.json` files, where it has any, carry no `preinstall`, `postinstall`, `prepare` or `install` script, and the check [`lifecycle-scripts-check.yml`](.github/workflows/lifecycle-scripts-check.yml) fails any push or pull request that adds one, or that commits an executable named like a git hook anywhere but `.githooks/`. The hooks in `.githooks/` are plain shell you can open before you install them, and they stay inert until you run `sh scripts/install-hooks.sh` yourself, because git refuses to let a repository switch its own hooks on. Every page on a public twin was read before it left: the tripwire `scripts/scan-public-lane.sh` opens each file (PDF text included) and refuses credentials, identifiers and anything unreadable, and a person attests by name and date to what a machine cannot judge. The twin is rebuilt from the listed tree, so the private history never travels with it. The whole chain, guard by guard, is `IT/SOP-IT-004-tripwires-firewalls-and-shields.md` in this organisation's procedures.

## <img src="assets/icons/message-circle-question.svg" width="24" height="24" alt=""> How to report a concern

Open an [issue](../../issues) on this repository saying what you saw and where; the stewards read them. If what you found should not be public yet, such as a secret that slipped through, do not put it in an issue: if the **Security** tab here offers *Report a vulnerability*, use that, and otherwise write to the contact on the organisation's GitHub profile. Say the file, the line and what it looks like, and never paste the secret itself. A real secret is rotated first and discussed second.

## <img src="assets/icons/triangle-alert.svg" width="24" height="24" alt=""> An honest limit

The checks above run on every pull request, and a red check stops anyone who respects it. Whether GitHub *enforces* that stop, by refusing the merge button until the checks pass and a person has reviewed, depends on branch protection or a ruleset. Those are free on a public repository. On a private repository they need GitHub Pro (a personal account) or GitHub Team (an organisation); on GitHub Free, a private repository's "a person with the role merges, never a helper, never a squash" is a rule people keep, not a lock the platform holds. The organisation's `LEGEND.md` says, repository by repository, which it is, and `my-template/scripts/repo-guard.sh --plan` prints the settings an owner would apply.

<sub>Plan names and limits as GitHub published them on 2026-11-04; check GitHub's current pricing page before paying for anything. Not advice. The procedure this page implements is SOP-IT-004, guard #10. Icons: Lucide (ISC).</sub>
