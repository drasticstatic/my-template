<div align="center">

<img src="../assets/icons/loader-circle.svg" width="48" height="48" alt="">

# Drafts

*Where a proposal grows before it has a number.*

</div>

## <img src="../assets/icons/compass.svg" width="24" height="24" alt=""> The convention

- <img src="../assets/icons/sprout.svg" width="16" height="16" alt=""> **A draft is a folder here with no number:** `drafts/short-name/README.md`, copied from [`../_template/`](../_template/README.md).
- <img src="../assets/icons/circle-dashed.svg" width="16" height="16" alt=""> **Drafts are not rendered to PDF,** not listed in the index, not collected by a board's inbox, and never put on a public allowlist. They are for the author, the helpers and whoever the author asks to read early.
- <img src="../assets/icons/git-branch.svg" width="16" height="16" alt=""> **A draft graduates** when it is ready to ask a decision of someone: give it the next number with a move, so its history comes along, and add its row to the index.
  ```sh
  git mv drafts/short-name 014-short-name
  ```
  The next push renders its PDF.
- <img src="../assets/icons/lock.svg" width="16" height="16" alt=""> **Private stays private.** A draft is still in the private repository; the names policy lets its *folder name* be mentioned, never its contents (`my-template/NAMES-POLICY.md`).
- <img src="../assets/icons/trash-2.svg" width="16" height="16" alt=""> **A draft that will not go forward** is deleted, or kept with one line at the top saying why it stopped. Nothing here is a promise.

## <img src="../assets/icons/workflow.svg" width="24" height="24" alt=""> From idea to decision

```mermaid
flowchart LR
  I["an idea"] --> D["drafts/short-name/<br/>(no number, no PDF)"]
  D -->|"git mv, next number"| N["014-short-name/<br/>(indexed, PDF on push)"]
  N --> A["asked of the people<br/>it affects"]
  A --> L["decisions log:<br/>what, when, who"]
```

<sub>Write it lucid: plain words, an icon beside each idea, one Mermaid diagram where a picture explains the mechanism (`my-template/LUCID.md`).</sub>
