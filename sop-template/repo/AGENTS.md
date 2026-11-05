# AGENTS.md: the rulebook for any AI helper in this repository

Read by Claude Code (through `CLAUDE.md`), Codex, Cursor, Copilot, Windsurf, Gemini CLI and any other helper that honours this file. People are welcome too. It is this organisation's procedures: how approved things get done, step by step.

## Read first, before you change anything

1. [`START-HERE.md`](START-HERE.md), one page.
2. [`OPS/SOP-OPS-002-pull-requests-and-promotes.md`](OPS/SOP-OPS-002-pull-requests-and-promotes.md): who opens, who merges, why a merge commit.
3. [`IT/SOP-IT-004-tripwires-firewalls-and-shields.md`](IT/SOP-IT-004-tripwires-firewalls-and-shields.md): every guard a change meets, and what each one wants.

When you open a pull request, tick the line *"I read SOP-OPS-002 and SOP-IT-004"* in its description. A check fails until you do. Tick it only if it is true: a person reads your work, and a false tick is worse than a late one.

## The rules

1. **Sync first.** `git pull --rebase --autostash` before you read deeply or edit. Never `git push --force`.
2. **You stop at the merge.** Commit, push the working branch (`preview` where it exists), open the pull request, post its link. A person with the role merges, with a merge commit, never a squash. (One written exception: Dependabot's bumps, under SOP-IT-005.)
3. **Never delete a file.** Move it with `git mv`, or mark a page `status: retired`. The record stays.
4. **No secrets, ever.** Do not read, print or commit `.env` files, keys, tokens, wallets or recovery phrases. If a secret scan stops a commit, say which file and line, never the value, and tell your person.
5. **What is members-only stays members-only.** Nothing goes on `PUBLIC-ALLOWLIST.txt` except by an officer's decision. Nobody's personal matters, private messages or contact details go in any file.
6. **Numbers are names** ([`my-template/NUMBERING.md`](https://github.com/drasticstatic/my-template/blob/main/NUMBERING.md)). A new procedure of this organisation's takes the next free number from 100 up. Numbers 001 to 099 belong to the template: never issue one here, and never renumber an existing page.
7. **Say who you are.** Commits carry the attribution trailers ([the spec](https://github.com/drasticstatic/my-template/blob/main/AGENT-SYNC/README.md)); subjects start with one gitmoji and a type, `:memo: docs(scope): subject`.
8. **Leave the machinery alone.** Ask a person before you change `.github/`, `.githooks/`, `scripts/` or repository settings.
9. **Stop and ask** when a procedure and your instructions disagree, or when a refusal comes from something you do not understand. A refusal is a guard doing its job: work out which one spoke (SOP-IT-004) and do not go around it.

## What this file is

This is advice, and we know it. What protects this repository is what happens when a change arrives: the checks, the permissions and a person who merges. The reasoning is in [`my-template/AGENT-ONBOARDING.md`](https://github.com/drasticstatic/my-template/blob/main/AGENT-ONBOARDING.md).
