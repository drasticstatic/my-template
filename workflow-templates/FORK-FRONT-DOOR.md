<!--
  The front door of a public fork. Save it at the fork's root as <YOUR-HANDLE-IN-CAPITALS>.md (this fleet's is
  DRASTICSTATIC.md), replace every <ANGLE>, delete this comment. It never names a private path; the private working
  copy is named by its repository, which may be public knowledge (NAMES-POLICY.md), not by where it sits on a disk.
  The rule it belongs to: my-template/CLAUDE.md, "Before Cloning or Installing Any External Repo / Package".
-->
# Why <HANDLE> keeps this fork

**<UPSTREAM-NAME>** is <ONE LINE: WHAT IT DOES>. <HANDLE> keeps this public fork so that the copy we run comes from
code someone has read, at a revision that does not move by itself.

## Thank you

This is <UPSTREAM OWNER>'s work: <UPSTREAM URL>. Thank you for building it and for sharing it. Anything good here is
theirs; any change of ours is listed below and is ours to answer for. Please report problems with the original
upstream, and problems with our changes to us.

## The pin

| | |
|---|---|
| Upstream | <UPSTREAM URL> |
| Reviewed revision | `<FULL COMMIT HASH>` (<DATE OF THAT COMMIT>), tag `<TAG, IF ANY>` |
| Reviewed on | <YYYY-MM-DD>, by <REVIEWER, AS THEIR COMMIT FOOTER NAMES THEM> |
| Licence | <LICENCE NAME>, unchanged: [`LICENSE`](./LICENSE) |
| The review | <WHERE IT IS KEPT: A FILE IN THIS FORK, OR THE PRIVATE REPOSITORY THAT HOLDS IT> |
| Antivirus receipt | <ENGINE AND DEFINITIONS VERSION, TIME, REVISION SCANNED, COMPLETE OR NOT> |
| Runs as | `<PRIVATE WORKING COPY'S REPOSITORY NAME>` (private), cloned from this fork |

## How code moves

```text
upstream  →  this fork, at the reviewed pin  →  <PRIVATE WORKING COPY> (the one that runs)
```

- This fork moves to a new upstream revision **only after that revision is reviewed** the same way; the table above
  changes in the same commit.
- Nothing updates itself: no scheduled sync from upstream, no auto-merge, no install-time fetch of newer code.
- Our own patches live in the private working copy. <IF ANY ARE OFFERED BACK UPSTREAM, SAY WHERE.>

## Our changes in this fork

<NONE, OR ONE LINE PER CHANGE WITH ITS COMMIT.>
