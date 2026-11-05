<div align="center">

<img src="../assets/icons-phosphor/shield-check.svg" width="56" height="56" alt="">

# Org security settings: keeping an organization safe on the free plan

*Five owner clicks keep every repository watched and patched, at no cost. A helper explains and checks; a person clicks.*

![Kind](https://img.shields.io/badge/Walkthrough-org_security_settings-800020?style=flat-square)
![Changed](https://img.shields.io/badge/Changed-2026--11--04-5c1a2b?style=flat-square)
![For](https://img.shields.io/badge/For-Organization_owners_on_the_free_plan-64748b?style=flat-square)

<img src="../assets/icons-phosphor/map-pin.svg" width="16" height="16" alt=""> **You are here:** drasticstatic lab › [`my-template`](../README.md) › [walkthroughs](README.md) › `ORG-SECURITY-SETTINGS.md` · public · `main` is the working branch

</div>

## <img src="../assets/icons-phosphor/compass.svg" width="24" height="24" alt=""> TL;DR

Five owner clicks keep every repository in an organization watched and patched, at no cost:

1. <img src="../assets/icons-phosphor/bell.svg" width="16" height="16" alt=""> Turn on **Dependabot alerts and security fixes** on every repository.
2. <img src="../assets/icons-phosphor/globe.svg" width="16" height="16" alt=""> Apply **"GitHub recommended"** to the **public** repositories, and **enforce** it.
3. <img src="../assets/icons-phosphor/folder-lock.svg" width="16" height="16" alt=""> Add a **"Free features (private repos)"** configuration for the **private** ones, and enforce that
   too.
4. <img src="../assets/icons-phosphor/sprout.svg" width="16" height="16" alt=""> Make each configuration the **default for new repositories** of its kind.
5. <img src="../assets/icons-phosphor/layers.svg" width="16" height="16" alt=""> In **Global settings**, turn **Grouped security updates** on.

These are an **owner's** clicks. An AI helper explains them and checks the results afterwards; a
person clicks.

*Learned across several friendly communities' organizations on 2026-10-26: every private repository had
Dependabot alerts **off**, including the private sources behind live sites.*

## <img src="../assets/icons-phosphor/map.svg" width="24" height="24" alt=""> Where things live now

GitHub moved these pages. In an organization's **Settings**, under **Security and quality**:

| Page | What it's for |
|---|---|
| **Advanced Security → Configurations** | Bundles of security features, applied to chosen repositories. "GitHub recommended" is listed here |
| **Advanced Security → Global settings** | Organization-wide options: grouped security updates, Dependabot rules, CodeQL extras |
| **New configuration** | `github.com/organizations/<org>/settings/security_products/configurations/new`. The **Apply** pop-up can't name a new configuration, so start here |

## <img src="../assets/icons-phosphor/bell.svg" width="24" height="24" alt=""> 1 · Alerts and security fixes on every repository

New repositories, especially **private** ones, start with Dependabot alerts **off**. An owner turns
them on once, with one line. Alerts only list problems, privately; security fixes open a pull
request when a fix exists:

```sh
for o in <org-a> <org-b>; do
  for r in $(gh repo list $o --no-archived -L 200 --json name -q '.[].name'); do
    gh api -X PUT repos/$o/$r/vulnerability-alerts && \
    case "$r" in
      their-app-1|their-app-2) echo "$o/$r alerts on" ;;   # someone else maintains these: alerts only
      *) gh api -X PUT repos/$o/$r/automated-security-fixes && echo "$o/$r on" ;;
    esac
  done
done
```

**Repositories that belong to other maintainers** (for example, a member's own app inside the
organization) get **alerts only**. Automatic fix PRs land in *their* queue, so ask them first: a short
proposal does that kindly. Turning alerts on is harmless; it changes no code and opens nothing.

## <img src="../assets/icons-phosphor/globe.svg" width="24" height="24" alt=""> 2 · "GitHub recommended" for the public repositories

On **Configurations**, apply **GitHub recommended**. For public repositories that includes secret
scanning with push protection, CodeQL code scanning, the dependency graph, Dependabot alerts and
security updates, and private vulnerability reporting. All of it is free on public repositories.

- **Enforce it.** Enforcing stops anyone switching a feature off by accident. Owners can still edit
  the configuration itself. Applying with enforcement creates an organization copy, named like
  `<org>-org-config-1`.
- **Leave out repositories that belong to other maintainers.** Applying to "all repositories" would
  enforce security-fix PRs on their apps. Choose the repositories instead and skip theirs. They keep
  alerts from step 1.

<details>
<summary><img src="../assets/icons-phosphor/message-circle-question.svg" width="16" height="16" alt=""> <b>"Allow repository owners to modify features", or enforce?</b></summary>

- **Enforce** where every repository is the organization's own. It's simpler, and nothing drifts.
- **Allow** only where repository owners genuinely need to tune features, such as a member's app with
  its own maintainers. Usually, excluding those repositories from the configuration does the same
  job more cleanly.

</details>

## <img src="../assets/icons-phosphor/folder-lock.svg" width="24" height="24" alt=""> 3 · "Free features (private repos)": why private repositories show "failed"

On the free plan, **private** repositories can't have secret scanning or code scanning; those need
paid Advanced Security. So when "GitHub recommended" is applied with enforcement, every **public**
repository shows **enforced** and every **private** one shows **failed**. The new-configuration page
even warns: *"Applying it to private repositories will only enable free security features."*

The private repositories still have alerts and fixes from step 1. To lock those in too, add a second
configuration on the **New configuration** page:

| Field | Set it to |
|---|---|
| **Name** | `Free features (private repos)` |
| **Description** | Dependabot alerts and security updates for private repos on the free plan |
| **Secret scanning → Alerts** | *Disabled* (its sub-settings follow) |
| **Code scanning → Default setup** | *Disabled* |
| **Dependency graph** | *Enabled* |
| **Automatic dependency submission** | *Not set* (it costs Actions minutes) |
| **Dependabot alerts** | *Enabled* |
| **Security updates** | *Enabled* |
| **Malware alerts** | *Enabled* |
| **Private vulnerability reporting** | *Not set* (it only applies to public repositories) |
| **Use as default for newly created repositories** | *Private* repositories |
| **Enforce configuration** | *Enforce* |

**Save configuration**, then on the list choose **Apply to** → the private repositories that showed
**failed**.

## <img src="../assets/icons-phosphor/sprout.svg" width="24" height="24" alt=""> 4 · Defaults for new repositories

Each configuration's **Policy** sets it as the default for new repositories of its kind:
- "GitHub recommended" (or its organization copy) for **public** ones.
- "Free features (private repos)" for **private** ones.

A new workshop repository is then protected from its first commit, so nobody has to remember.

## <img src="../assets/icons-phosphor/layers.svg" width="24" height="24" alt=""> 5 · Global settings: grouped security updates

**Advanced Security → Global settings → Dependabot → Grouped security updates: On.** Dependabot then
opens one fix PR per package manager and folder, rather than one per alert. Fewer PRs, each tested
once. A group in `dependabot.yml` can override it (see [Dependabot](DEPENDABOT.md)).

Leave the rest as it is unless there's a reason:
- **Copilot Autofix** is on by default.
- **AI Scan** needs a payment method.
- **Dependabot's access to private repositories** only matters for private package registries.

## <img src="../assets/icons-phosphor/circle-check.svg" width="24" height="24" alt=""> Check it worked (an AI helper can do this part)

```sh
# alerts on? (204 = on, 404 = off)
gh api repos/<org>/<repo>/vulnerability-alerts -i | head -1
# which repositories each configuration reached, and how
for c in $(gh api orgs/<org>/code-security/configurations -q '.[].id'); do
  gh api "orgs/<org>/code-security/configurations/$c/repositories?per_page=100" \
    -q '.[]|"\(.status)\t\(.repository.name)"'
done
```

You're looking for every public repository **enforced** under one configuration, every private one
**enforced** under the free one, and no **failed** left.

## <img src="../assets/icons-phosphor/bot.svg" width="24" height="24" alt=""> For the AI helper

- <img src="../assets/icons-phosphor/hand-helping.svg" width="16" height="16" alt=""> **Explain, don't click.** These are organization security settings. Even if your person invites you
  to drive their browser, give them the exact clicks (the table above) and let them make them. You
  can read the pages to describe them precisely, and verify afterwards with the commands above.
- <img src="../assets/icons-phosphor/scan-search.svg" width="16" height="16" alt=""> **Count before and after.** The open-alert count per repository on day one is the best argument for
  the upkeep that follows.
- <img src="../assets/icons-phosphor/sprout.svg" width="16" height="16" alt=""> **Next:** once alerts are on, PRs start arriving. [Dependabot](DEPENDABOT.md) covers how to keep them
  a gentle trickle you can trust.

## <img src="../assets/icons-phosphor/git-pull-request.svg" width="24" height="24" alt=""> Suggest a change

Noticed something wrong, or a step that could be kinder? Open an [issue](https://github.com/drasticstatic/my-template/issues)
or a pull request against `main`, changing this page. A person with the role reads it and merges with a merge commit, so
your name stays on it. An AI helper may do all of that up to the merge. Not on GitHub? Tell any steward you know, or your
helper, in your own words.

*Part of the [walkthroughs](README.md). Official docs:
[security configurations](https://docs.github.com/en/code-security/securing-your-organization/introduction-to-securing-your-organization-at-scale/about-enabling-security-features-at-scale).*
