# 🔒 The members' edition of an organization's profile

**TL;DR:** GitHub shows two different profile pages for an organization:
- **Visitors** see `.github/profile/README.md`, the public one.
- **Signed-in members** see `.github-private/profile/README.md` **instead**.

If the members' file is short, members miss the beautiful public welcome. So build the members'
edition from three parts, and let a small daily workflow keep it in step:

| Part | File (in `.github-private`) | Who edits it |
|---|---|---|
| 1. A short **"you're signed in as a member"** notice | `profile/members-notice.md` | rarely |
| 2. The **public profile README**, word for word | fetched from `<org>/.github` → `profile/README.md` | edit the public one, as always |
| 3. The **members' section**: proposals, trackers, contacts | `profile/members-section.md` | whenever something changes |

`profile/README.md` in `.github-private` is **generated**. Never edit it by hand; its header says so.

*Found on 2026-10-26, when one organization's members' view showed a five-line note instead of the
profile everyone had worked on. Now five organizations use this.*

---

## 🧩 How it works

`.github/scripts/compose-members-profile.py --org <org>` writes `profile/README.md` as:
1. the notice, rendered as a GitHub alert:

   ```markdown
   > [!NOTE]
   > 🔒 **You're signed in as a member of <Org>**, so you're seeing the members' edition of this page,
   > with extra links below the public welcome. Visitors who aren't signed in see only the public part.
   ```

2. the public README, fetched from `raw.githubusercontent.com/<org>/.github/main/profile/README.md`
   (it's public, so no token is needed), with **every relative link and image made absolute**: `src`,
   `href`, `srcset`, and markdown links. Otherwise `./assets/banner.svg` would break when it's shown
   from the other repository.
3. the members' section.

`.github/workflows/members-profile.yml` runs it:
- **daily**, so edits to the public profile reach members within a day
- **on demand** (Run workflow)
- **on any push** to the two members' files or the script

It commits only when something changed, using `GITHUB_TOKEN` with `contents: write`, and writes only
to its own repository.

## 🗳️ What belongs in the members' section

Open it with what's alive, then the essentials:
- **"What's happening: every proposal, in one place"**: a link to the organization's `proposals`
  repository and its `pdf/` folder. The directory comes before any single proposal, so members see
  everything in motion.
- The **site-health tracker** (`SITE-HEALTH-AND-DOMAINS.md`).
- **ONBOARDING**, **CONTRIBUTING** and the private **CONTACTS**.
- Decisions on record, and anything members-only that shouldn't be public.

Members-only doesn't mean secret. Never put passwords, keys or private personal history here; the
organization's never-publish list still applies.

## 🛠️ Set it up in a new organization

1. Copy `profile/members-notice.md`, `profile/members-section.md`,
   `.github/scripts/compose-members-profile.py` and `.github/workflows/members-profile.yml` from an
   organization that has them. Change the notice's organization name, and the `--org` in the
   workflow.
2. Move anything in today's members' README into `members-section.md` first, so nothing is lost.
3. Run the script once locally and commit the result, so the first workflow run finds nothing to
   change.
4. Check: open `https://github.com/<org>?view_as=member`, and see the notice, the public welcome and
   the members' section.

## 🧭 For the AI helper

- **Edit the parts, never the generated README.** If your person asks to change the members' page,
  edit `members-section.md` (or the public profile) and let the workflow recompose it.
- **The public profile is the source of the welcome.** Change it in `.github`; the members' edition
  follows within a day, or straight away with Run workflow.
- **Pairs with** the portal's `mirror-profile-readme.yml`, which copies the same profile onto the
  organization's website with its own notice. That's the same idea, pointed outward.

---

*Part of the [walkthroughs](README.md). Official docs:
[customizing your organization's profile](https://docs.github.com/en/organizations/collaborating-with-groups-in-organizations/customizing-your-organizations-profile).*
