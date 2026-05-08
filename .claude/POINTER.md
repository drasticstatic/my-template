# .claude/skills — Public Skills Index

Skills live in `.claude/skills/` in each repo and are synced to their public preview repos
via `gitexporter.config.json`. This file points to where you can find them.

---

## Skills by Repo - Click Each Link to Explore

| Repo | Public Preview | What's There |
|------|---------------|-------------|
| **anthropas-argus-alfred** | [.claude/skills/](https://github.com/drasticstatic/anthropas-argus-alfred-public-preview/tree/main/.claude/skills) | `startup`, `create-skill`, `marp-deck`, `marp-quick-reference` |
| **trading-assistant** | [.claude/skills/](https://github.com/drasticstatic/trading-assistant-public-preview/tree/main/.claude/skills) | Full Fortuna skill suite — `premarket`, `daily-review`, `weekly-review`, `trade-review`, `session-sync`, `marp-deck`, `create-skill`, and more |
| **pir-devine-news** | [.claude/skills/](https://github.com/drasticstatic/pir-devine-news-public/tree/main/.claude/skills) | `startup`, `create-skill`, `marp-deck`, `marp-quick-reference` |
| **divorce-custody-assistant** | [.claude/skills/](https://github.com/drasticstatic/divorce-custody-assistant-public-preview/tree/main/.claude/skills) | `startup`, `session-sync`, `create-skill`, `marp-deck` |

---

Check out this Marp deck for more about skills: [Architecting Claude Code Skills for High-Impact](https://drasticstatic.github.io/trading-assistant-public-preview/setup/create-skill.marp.html)

---

## Skill Format

Each skill file uses a standard frontmatter header:

```markdown
---
name: skill-name
description: >
  One or two sentences. TRIGGER when: [conditions].
  Do NOT use for: [anti-triggers].
---

# Skill: /skill-name

[Instructions...]
```

The `description` field is what Claude Code reads to decide when to invoke the skill.
The body only loads when the skill is triggered — keeping context lean.

---

## Cross-Repo Marp Themes

Each repo has its own visual identity for Marp decks:

| Repo | Theme | Palette |
|------|-------|---------|
| **trading-assistant** | Dark professional | Canonical case study — linked externally |
| **pir-devine-news** | Dark navy/green | `#000814` · `#00d082` · `#7c3aed` |
| **divorce-custody** | Professional legal | `#f8f9fa` white · `#1a3a5c` navy · `#2c5f8a` steel |
| **alfred** | Clean minimal | `#0f172a` navy · `#38bdf8` sky · `#f1f5f9` white |

See `marp-deck.md` in each repo's `.claude/skills/` for the full theme definition.

---

## Adding Skills to a New Repo

1. Create `.claude/skills/skill-name.md` following the format above
2. Update `gitexporter.config.json` — exclude `".claude/settings.local.json"` not `".claude/"`
3. Run `/create-skill` (skill available in alfred, trading-assistant, pir-devine-news, divorce repos)
4. Reference: [makemyskill.com](https://makemyskill.com)
