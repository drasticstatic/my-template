# Give an agent its own Google account profile

Connect one Google account to the `gws` command-line tool so an agent can read that account's Drive and Docs, and nothing else. Each account gets its own folder, its own Cloud project and its own login, so a mistake in one can never touch another.

**You need:** about 15 minutes, a browser signed in to the target account, and `gws` already installed (check with `gws --version`).

**Who does what:** an agent can prepare the folder and the wrapper. Signing in, passwords and consent screens are always done by a person.

Throughout, replace:

| Placeholder | Meaning | Example |
|---|---|---|
| `ACCOUNT` | the Google account being connected | `you@yourorg.org` |
| `NAME` | a short label for this profile | `acme` |

## 1. Make the isolated folder and wrapper

```sh
mkdir -m 700 -p ~/.config/gws-NAME
mkdir -p ~/.local/bin
cat > ~/.local/bin/gwsNAME <<'EOF'
#!/bin/sh
GOOGLE_WORKSPACE_CLI_CONFIG_DIR="$HOME/.config/gws-NAME" exec gws "$@"
EOF
chmod +x ~/.local/bin/gwsNAME
gwsNAME auth status
```

`auth status` should report `"auth_method": "none"` and point only at `~/.config/gws-NAME`. That is the smoke test: the profile is isolated and empty. Never use a bare `gws` once you have more than one account.

## 2. Create the Cloud project

1. Open <https://console.cloud.google.com/projectcreate>.
2. Click your picture, top right, and confirm it shows `ACCOUNT`. The console opens on whichever account the browser used last, and this is the easiest step to get wrong.
3. Replace the default "My Project 12345" with a real name, because the project ID comes from it and cannot be changed later. Choose the organization if one is offered, and click **Create**.

If the page says you lack permission to create projects, a Workspace administrator has to create it for you or grant the Project Creator role. Google may also ask for your password again here. That is normal.

## 3. Turn on only the APIs you need

**APIs & Services → Library.** For a read-only start, enable **Google Drive API** and **Google Docs API**. Add others later if a real need appears.

## 4. Create the desktop login

1. Open **Google Auth Platform** (search for it in the console's top bar) and click **Get started**.
2. **App Information:** give the app a name and choose `ACCOUNT` as the support email.
3. **Audience:** on a Workspace account choose **Internal**, which limits the app to your organization. On a personal account choose **External** and afterward add `ACCOUNT` under **Audience → Test users**, even if you own the project.
4. **Contact Information:** enter `ACCOUNT`.
5. **Finish:** read and tick the Google API Services User Data Policy yourself, then **Continue** and **Create**.
6. **Clients → Create client.** Application type **Desktop app**, name it, leave "Use this client for an AI-powered agent" unticked, and click **Create**.
7. Click **Download JSON** in the dialog that appears. Do this before closing it, and do not screenshot that dialog.
8. Move it into the profile, using the file you just downloaded:

```sh
mv ~/Downloads/client_secret_*.json ~/.config/gws-NAME/client_secret.json
chmod 600 ~/.config/gws-NAME/client_secret.json
```

This file is a credential. Never commit it, paste it into a chat, or show it on a screen share.

## 5. Sign in, read-only

```sh
gwsNAME auth login --readonly -s drive,docs
```

A browser opens. Choose `ACCOUNT` and approve. `--readonly` means the agent can look but not change anything, and you can widen it later on purpose.

## 6. Prove it is the right account

```sh
gwsNAME drive about get --params '{"fields":"user(emailAddress)"}'
```

The address must be `ACCOUNT`. If it is anything else, stop and start again at step 2.

Then read one document you are allowed to see:

```sh
gwsNAME docs documents get --params '{"documentId":"DOC_ID","fields":"title"}'
```

## If something goes wrong

| What you see | What it means |
|---|---|
| `invalid_grant` or 401 | The login expired. Run step 5 again. External apps in Testing expire after about a week. |
| `Error 403: access_denied` at sign-in | `ACCOUNT` is not listed as a test user (step 4). |
| `403` on a Drive or Docs call | That API is not enabled in this project (step 3). |
| A password box when opening the console | Google wants you to confirm it is you. Type it yourself. |
| `Access blocked` naming another app | You are using the wrong wrapper for this account. |

## Taking it away

Revoke access at <https://myaccount.google.com/permissions>, then move `~/.config/gws-NAME` aside. Deleting the Cloud project removes the login for good.
