---
name: graphify-setup-stub
description: Redirect stub — canonical graphify setup guide + security review + install roadmap lives in anthropas-argus-alfred/sandbox
metadata:
  type: reference
---

# Graphify Setup — see canonical file

This is a pointer, not a copy. The full guide — the pre-install security review, setup steps, the
`.graphifyignore` base template, and the ecosystem-wide install roadmap (which repos are done, which
are next, per-repo `.graphifyignore` override notes) — lives at:

**[`anthropas-argus-alfred/sandbox/GRAPHIFY_SETUP.md`](https://github.com/drasticstatic/anthropas-argus-alfred/blob/main/sandbox/GRAPHIFY_SETUP.md)**

The `.graphifyignore` base template every repo customizes from is at
[`my-template/.graphifyignore`](../.graphifyignore) — deploy + customize per repo before running
`graphify extract .`.

Quick version: `graphify extract .` needs a real LLM API key in the shell (not available in a Claude
Code OAuth session) — the free-tier workaround is a Gemini key
(`! GEMINI_API_KEY=... graphify extract .`). The keyless steps (`.graphifyignore` deploy +
`graphify claude install`) can be done in any session regardless.
