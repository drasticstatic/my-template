<div align="center">

<img src="sop-template/repo/assets/icons/shield-check.svg" width="56" height="56" alt="">

# Security: why a clone of `my-template` is safe to fetch

*Nothing runs when you clone or install. Every public page was read before it left. Here is how to tell us if you find otherwise.*

![Guard](https://img.shields.io/badge/Guard-SOP--IT--004_%2310-d9a441?style=flat-square)
![Status](https://img.shields.io/badge/Status-living-8a6a2a?style=flat-square)
![Checked](https://img.shields.io/badge/Checked-2026--11--04-64748b?style=flat-square)

<img src="sop-template/repo/assets/icons/map-pin.svg" width="16" height="16" alt=""> **You are here:** drasticstatic lab › [`my-template`](./README.md) › `SECURITY.md` · public · `main` is the working branch

</div>

## <img src="sop-template/repo/assets/icons/compass.svg" width="24" height="24" alt=""> TL;DR

1. <img src="sop-template/repo/assets/icons/file-check.svg" width="16" height="16" alt=""> **Cloning runs nothing.** This repository has no `package.json` at all today, and the template it hands out carries [`lifecycle-scripts-check.yml`](./sop-template/repo/.github/workflows/lifecycle-scripts-check.yml), which fails any pull request that adds a `preinstall`, `postinstall`, `prepare` or `install` script.
2. <img src="sop-template/repo/assets/icons/lock.svg" width="16" height="16" alt=""> **Hooks are installed only by hand.** [`.githooks/`](./.githooks) holds three short shell scripts you can read; they do nothing until a person runs `sh scripts/install-hooks.sh` in their own clone.
3. <img src="sop-template/repo/assets/icons/scan-search.svg" width="16" height="16" alt=""> **Every public page was read before it left.** The tripwire [`scripts/scan-public-lane.sh`](./scripts/scan-public-lane.sh) opens each file a public lane publishes, and a private repository's history never travels to its twin.
4. <img src="sop-template/repo/assets/icons/message-circle-question.svg" width="16" height="16" alt=""> **Found something?** Open an [issue](https://github.com/drasticstatic/my-template/issues), or write to the contact on the [drasticstatic profile](https://github.com/drasticstatic). Say what you saw and where.

## <img src="sop-template/repo/assets/icons/shield-check.svg" width="24" height="24" alt=""> Why a clone is safe

A repository can only harm the machine that fetches it by running something, and git itself runs nothing on clone. The two ways code gets run anyway are an install step and a hook, and the repositories drasticstatic tends close both. `my-template` has no `package.json` at all; the repositories built from it carry [`lifecycle-scripts-check.yml`](./sop-template/repo/.github/workflows/lifecycle-scripts-check.yml), which reads every `package.json` outside `node_modules` and fails the push or pull request if one has a `preinstall`, `postinstall`, `prepare` or `install` script, or if an executable named like a git hook is committed anywhere but `.githooks/`. The hooks in [`.githooks/`](./.githooks) are plain shell you can open before you install them (`commit-msg` checks the attribution trailers, `pre-commit` refuses oversize images and chains to the secret scan, `gitmoji-check.sh` warns about a subject line), and they stay inert until you run `sh scripts/install-hooks.sh` yourself, because git refuses to let a repository switch its own hooks on. Every page on a public twin was read before it left: [`scripts/scan-public-lane.sh`](./scripts/scan-public-lane.sh) opens each file (PDF text included) and refuses credentials, identifiers and anything unreadable, and a person attests by name and date to what a machine cannot judge. The twin is rebuilt from the listed tree, so the private history never travels with it. The whole chain, guard by guard, is `SOP-IT-004 · Tripwires, firewalls and shields` in each organisation's procedures ([template](./sop-template/repo/README.md)).

## <img src="sop-template/repo/assets/icons/message-circle-question.svg" width="24" height="24" alt=""> How to report a concern

Open an [issue](https://github.com/drasticstatic/my-template/issues) saying what you saw and where; the lab steward reads them. If what you found should not be public yet, such as a secret that slipped through, do not put it in an issue: if this repository's **Security** tab offers *Report a vulnerability*, use that, and otherwise write to the contact on the [drasticstatic profile](https://github.com/drasticstatic). Say the file, the line and what it looks like, and never paste the secret itself. A real secret is rotated first and discussed second. Not on GitHub? Tell any steward you know, or your helper, in your own words.

## <img src="sop-template/repo/assets/icons/triangle-alert.svg" width="24" height="24" alt=""> An honest limit

The checks run on every pull request, and a red check stops anyone who respects it. Whether GitHub *enforces* that stop, by refusing the merge button until the checks pass and a person has reviewed, depends on branch protection or a ruleset. Those are free on a public repository, and `my-template` is public, so its `main` can carry one. On a private repository they need GitHub Pro (a personal account) or GitHub Team (an organisation); on GitHub Free, a private repository's "a person with the role merges, never a helper, never a squash" is a rule people keep, not a lock the platform holds. [`scripts/repo-guard.sh --plan`](./scripts/repo-guard.sh) prints, for any repository, the settings an owner would apply and says when the plan will not let them; it runs nothing. The ruleset templates and the one safe way to loosen one for a single push are in [`branch-protection/`](./branch-protection/README.md).

<sub>Plan names and limits as GitHub published them on 2026-11-04; check GitHub's current pricing page before paying for anything. Not advice. This page implements SOP-IT-004, guard #10. MIT ([`LICENSE`](./LICENSE)); icons Lucide (ISC).</sub>
