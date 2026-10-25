# AGENTS.md — {{SITE_NAME}}

The rulebook for **every** AI helper working here: ChatGPT, Codex, Augment/Cosmos, Claude, Cursor and any
other. Humans welcome too. Read it before changing anything.

{{ONE_PARAGRAPH: what this repository is, who it serves, and whose content it is to approve.}}

## The house rules

1. **Sync first.** Run `git pull --rebase --autostash` before you read deeply or edit. Never
   `git push --force`.
2. **Work on `preview`.** Every change goes to `preview`, which publishes to the rehearsal copy. **Never
   commit to `main`**; it changes only through a "Promote" pull request.
3. **Never publish what isn't ours to share.** This is a hard rule. Never put into the site, a commit, an
   issue or any public place:
   - anyone's recovery or 12-step fellowship involvement, or any sponsor relationship;
   - quotes from private messages without permission;
   - anyone's personal, medical or legal history;
   - private contact details.
4. **No secrets, ever.** Never add passwords, keys, tokens or `.env` contents to any file; never read
   them. The secret scan blocks commits that contain secrets. Never use `--no-verify`.
5. **`public/` is visible to the world.**
6. **Leave the machinery to the technical steward.** Ask before changing `.github/`, `.githooks/`,
   `scripts/`, build config or dependencies.
7. **Words, not code, wherever possible.** Change the words where they live (table below).
8. **Both languages** (if the site has two): update the twin with the original.
9. **Build before you finish.**
10. **Credit your work** with one trailer line (below).

## Where the words live

| What | Where |
|---|---|
| {{CONTENT}} | {{FILE}} |

## How changes go live

```
you (or your AI) ── commit ──▶ preview ──▶ rehearsal copy (lineage note + ribbon)
                                  │
                         "Promote" pull request (preview → main)
                                  ▼
                                main ──▶ live site
```

## Commit messages

```
<type> YYYY-MM-DD — <what changed, in plain words>

Co-Authored-By: <Agent> · <Engine> · <Provider> [<Model>]
```

- **No AI helped?** Leave the line off.
- **The hook advises; it never blocks** (`org-onboarding/githooks/commit-msg.advisory`).
- **Full spec:** [my-template/AGENT-SYNC/README.md](https://github.com/drasticstatic/my-template/blob/main/AGENT-SYNC/README.md).

## Team notes

- `PENDING-TASKS.md`: the shared to-do list. Add, don't erase.
- `AGENT-SYNC/created-by-<you>/`: handoff notes between helpers.
