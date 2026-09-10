# Branch protection — templates and how to work around them safely

This directory holds the canonical branch-protection ruleset templates used across the fleet, plus
a guide for the one legitimate reason to ever temporarily disable one: a deliberate, one-off rewrite
of already-pushed history (e.g. a signature-fix rebase) on a repo that should otherwise never accept
a force-push.

## The templates

- **`ruleset.json`** — for a repo you push to normally (`deletion` + `non_fast_forward`). Apply once via:
  ```
  gh api repos/OWNER/REPO/rulesets --method POST --input branch-protection/ruleset.json
  ```
- **`ruleset-public-preview.json`** — for a `-public-preview`/`-public` mirror repo whose `main` gets
  force-pushed by `sync-public.yml`'s `git filter-repo` step. Deletion-only — applying the strict
  ruleset here breaks the sync (hit this exact failure on 2026-09-02, on
  `littlebird-ambassador-public-preview` and `augment-intent-properties-public-preview`).

**Never apply `ruleset.json` to a repo the public-preview sync force-pushes to.** If you're not sure
which one a repo needs, ask: "does anything other than a human ever force-push to this `main`?" If
yes, it needs the deletion-only version.

## Temporarily allowing a force-push, then restoring protection

Sometimes you legitimately need to force-push to a protected `main` — the clearest example: a
fleet-wide commit-signature correction that needs history *rewritten*, not patched with a new commit
on top. Do this by editing the ruleset's `rules` array via the API — never by deleting and
recreating the ruleset, and never by leaving it disabled longer than the one push needs.

1. **Find the ruleset ID:**
   ```
   gh api repos/OWNER/REPO/rulesets
   ```
2. **Drop `non_fast_forward`, keep `deletion`:**
   ```
   gh api --method PUT repos/OWNER/REPO/rulesets/RULESET_ID \
     -f name='protect-main' -f enforcement='active' -f 'rules[][type]=deletion'
   ```
3. **Do the one push this was for:**
   ```
   git push --force-with-lease origin main
   ```
4. **Restore it immediately:**
   ```
   gh api --method PUT repos/OWNER/REPO/rulesets/RULESET_ID \
     -f name='protect-main' -f enforcement='active' \
     -f 'rules[][type]=deletion' -f 'rules[][type]=non_fast_forward'
   ```

Verify the restore worked — the response's `rules` array should list both `deletion` and
`non_fast_forward` again, and `updated_at` should be seconds after step 2's.

**Why this order, and not deleting the ruleset:** editing the existing ruleset in place keeps its
`id`, `bypass_actors`, and creation date intact the whole time — there's no window where the branch
has *no* ruleset at all, just a narrower one for a few seconds. Using `--force-with-lease` (not a
bare `--force`) still refuses the push if the remote moved unexpectedly in the meantime, so a briefly
open door doesn't turn into blindly overwriting someone else's work.

**Worked example:** this exact sequence landed a fleet-wide `Co-Authored-By` signature-fix rebase on
`my-template`, `resume`, and `gratitude-token-project_docs` on 2026-09-09 — three repos whose
`protect-main` ruleset initially rejected the rebase's force-push with
`GH013: Cannot force-push to this branch`. Full story:
[`littlebird-ambassador/AGENT-SYNC/created-by-alfred/20260909-handoff-littlebird-audit-findings.md`](https://github.com/drasticstatic/littlebird-ambassador/blob/main/AGENT-SYNC/created-by-alfred/20260909-handoff-littlebird-audit-findings.md)
(private repo, gated to Christopher and the agent fleet).
