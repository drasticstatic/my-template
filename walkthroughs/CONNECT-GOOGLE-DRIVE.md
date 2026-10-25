# 📁 Connect Google Drive

**TL;DR:** many of us keep our real working documents in Google Drive. Connect Drive to your helper and
it can read and search them alongside you.
- **The simple path:** your helper's built-in Drive connection, for reading and searching.
- **The power path:** a Google Workspace command-line profile, for helpers that also edit documents. Use
  one profile per organization, so accounts never mix.

> **Handing this to your AI helper?** Say: *"Read CONNECT-GOOGLE-DRIVE.md and help me connect my Drive.
> Use the simple path, read-only."*

## The simple path: built-in connections

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

## The power path: one Workspace profile per organization

For helpers that should **edit** Docs or Sheets, set up the Google Workspace CLI (`gws`) with a separate
profile for each Google account:

1. **A Google Cloud project per account:** for example `thef-workspace`. Enable the Drive, Docs and
   Sheets APIs there.
2. **An OAuth client** (type *Desktop app*) in that project. Download its `client_secret.json` into the
   profile's own folder, such as `~/.config/gws-thef/`. Never put it in a repository.
3. **Add yourself as a test user** on the project's OAuth consent screen. Otherwise Google blocks the
   sign-in with *Error 403: access_denied*.
4. **Sign in under that profile:**
   `GOOGLE_WORKSPACE_CLI_CONFIG_DIR=~/.config/gws-thef gws auth login`
5. **Give it a short alias** so the account is always explicit, such as
   `alias gwsthef='GOOGLE_WORKSPACE_CLI_CONFIG_DIR=~/.config/gws-thef gws'`.

Each profile has its own project, its own client and its own token, so organizations never share
credentials.

## Good to know

- **Read is the default.** The built-in connections read and search; editing takes the power path, on
  purpose.
- **Private stays private.** A document being readable by your helper doesn't make it publishable. The
  never-publish rule still applies.
- **Shared drives:** your helper sees only what *your* account can see. Ask the drive's owner, not the
  helper, for wider access.
