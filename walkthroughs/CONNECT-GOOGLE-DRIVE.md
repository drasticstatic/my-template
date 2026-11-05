<div align="center">

<img src="../sop-template/repo/assets/icons/files.svg" width="56" height="56" alt="">

# Connect Google Drive

*Let your helper read the documents you keep in Drive, alongside you.*

![Kind](https://img.shields.io/badge/Kind-Walkthrough-d9a441?style=flat-square)
![Changed](https://img.shields.io/badge/Changed-2026--11--04-d9a441?style=flat-square)
![For](https://img.shields.io/badge/For-Anyone_whose_documents_live_in_Drive-d9a441?style=flat-square)

<img src="../sop-template/repo/assets/icons/map-pin.svg" width="16" height="16" alt=""> **You are here:** drasticstatic lab › [`my-template`](../README.md) › [`walkthroughs`](README.md) › `CONNECT-GOOGLE-DRIVE.md` · public · `main` is the working branch

</div>

## <img src="../sop-template/repo/assets/icons/compass.svg" width="24" height="24" alt=""> TL;DR

1. <img src="../sop-template/repo/assets/icons/files.svg" width="16" height="16" alt=""> **Many of us keep our real working documents in Google Drive.** Connect Drive to your helper and
   it can read and search them alongside you.
2. <img src="../sop-template/repo/assets/icons/eye.svg" width="16" height="16" alt=""> **The simple path:** your helper's built-in Drive connection, for reading and searching.
3. <img src="../sop-template/repo/assets/icons/wrench.svg" width="16" height="16" alt=""> **The power path:** a Google Workspace command-line profile, for helpers that also edit documents. Use
   one profile per organization, so accounts never mix.

> **Handing this to your AI helper?** Say: *"Read CONNECT-GOOGLE-DRIVE.md and help me connect my Drive.
> Use the simple path, read-only."*

## <img src="../sop-template/repo/assets/icons/eye.svg" width="24" height="24" alt=""> The simple path: built-in connections

<details open>
<summary><b>ChatGPT</b></summary>

In ChatGPT, open the plugins (apps) list, choose **Google Drive**, and sign in with the Google account
that holds your documents. Then: *"Find my retreat itinerary in Drive and summarise it."*

</details>

<details>
<summary><b>Claude (web and desktop)</b></summary>

Open **Settings → Connectors**, connect **Google Drive**, and sign in. Then ask Claude to search or read
a document by name.

</details>

<details>
<summary><b>Codex and Claude Code</b></summary>

These helpers work best with documents that live **in the repository**. When a Drive document should
shape a website, ask your chat helper to read it, then bring the agreed words into the repository's
content files. That way the change rehearses like any other.

</details>

## <img src="../sop-template/repo/assets/icons/wrench.svg" width="24" height="24" alt=""> The power path: one Workspace profile per organization

For helpers that should **edit** Docs or Sheets, set up the Google Workspace CLI (`gws`) with a separate
profile for each Google account:

1. <img src="../sop-template/repo/assets/icons/building-2.svg" width="16" height="16" alt=""> **A Google Cloud project per account:** for example `thef-workspace`. Enable the Drive, Docs and
   Sheets APIs there.
2. <img src="../sop-template/repo/assets/icons/key-round.svg" width="16" height="16" alt=""> **An OAuth client** (type *Desktop app*) in that project. Download its `client_secret.json` into the
   profile's own folder, such as `~/.config/gws-thef/`. Never put it in a repository.
3. <img src="../sop-template/repo/assets/icons/user-plus.svg" width="16" height="16" alt=""> **Add yourself as a test user** on the project's OAuth consent screen. Otherwise Google blocks the
   sign-in with *Error 403: access_denied*.
4. <img src="../sop-template/repo/assets/icons/log-in.svg" width="16" height="16" alt=""> **Sign in under that profile:**
   `GOOGLE_WORKSPACE_CLI_CONFIG_DIR=~/.config/gws-thef gws auth login`
5. <img src="../sop-template/repo/assets/icons/tags.svg" width="16" height="16" alt=""> **Give it a short alias** so the account is always explicit, such as
   `alias gwsthef='GOOGLE_WORKSPACE_CLI_CONFIG_DIR=~/.config/gws-thef gws'`.

Each profile has its own project, its own client and its own token, so organizations never share
credentials.

## <img src="../sop-template/repo/assets/icons/book-open.svg" width="24" height="24" alt=""> Good to know

- <img src="../sop-template/repo/assets/icons/eye.svg" width="16" height="16" alt=""> **Read is the default.** The built-in connections read and search; editing takes the power path, on
  purpose.
- <img src="../sop-template/repo/assets/icons/folder-lock.svg" width="16" height="16" alt=""> **Private stays private.** A document being readable by your helper doesn't make it publishable. The
  never-publish rule still applies.
- <img src="../sop-template/repo/assets/icons/users-round.svg" width="16" height="16" alt=""> **Shared drives:** your helper sees only what *your* account can see. Ask the drive's owner, not the
  helper, for wider access.

## <img src="../sop-template/repo/assets/icons/git-pull-request.svg" width="24" height="24" alt=""> Suggest a change

Noticed something wrong, or know a better way? Open an [issue](https://github.com/drasticstatic/my-template/issues) or a pull request against `main`; the lab steward reads them, and a person with the role merges with a merge commit so your name stays on it. Not on GitHub? Tell any steward you know, or your helper, in your own words.

<sub>One of the [walkthroughs](README.md) in `my-template`. Icons: Lucide (ISC).</sub>
