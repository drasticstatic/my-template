# <img src="assets/icons/door-open.svg" width="28" height="28" alt=""> Start here, if you are a helper or brought one

**TL;DR:** read two procedures, make your change on the working branch, open a pull request with the acknowledgement line ticked, and stop. A person here reads it and merges it. You cannot break anything by trying.

**People:** give your AI helper this sentence: *"Read START-HERE.md in this repository and do what it says before you change anything."*

## <img src="assets/icons/book-open.svg" width="24" height="24" alt=""> Read these two first

| Read | Because |
|---|---|
| [SOP-OPS-002, Pull requests and Promotes](OPS/SOP-OPS-002-pull-requests-and-promotes.md) | how a change asks to move, and who says yes |
| [SOP-IT-004, Tripwires, firewalls and shields](IT/SOP-IT-004-tripwires-firewalls-and-shields.md) | every guard your change will meet, what each one catches, and what to do when one speaks |

New to GitHub altogether? [SOP-COM-001](COM/SOP-COM-001-new-to-github-your-first-hour.md) comes first, and takes an hour.

## <img src="assets/icons/git-pull-request.svg" width="24" height="24" alt=""> Then, in this order

1. **Get current:** `git pull --rebase --autostash`.
2. **Work on the working branch** (`preview` where it exists, otherwise a short-lived branch). No access? Work from a fork.
3. **Commit with who you are**, as [`AGENTS.md`](AGENTS.md) says.
4. **Open a pull request.** Its description already has the line below. Tick it, if it is true:
   > `- [x] I read SOP-OPS-002 and SOP-IT-004`
5. **Post the link, and stop.** A check named `helper-ack` fails until the line is ticked. A person with the role reads and merges. Helpers do not merge.

## <img src="assets/icons/triangle-alert.svg" width="24" height="24" alt=""> Four things that are always no

- Deleting a file, or force-pushing.
- Reading, printing or committing anything secret.
- Making something public: only an officer adds a line to the public list.
- Giving a procedure a number from 001 to 099. Those come only from the template; yours start at 100.

## <img src="assets/icons/message-circle-question.svg" width="24" height="24" alt=""> Stuck?

If a guard refuses you, it says which file and which rule. Look it up in SOP-IT-004, and do not go around it. If you still cannot see what it wants, say so in the pull request or tell a steward. Asking is always welcome.
