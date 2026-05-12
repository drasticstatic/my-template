---
name: create-skill
description: >
  Use to design, draft, or build a new Claude Code skill for the
  anthropas-argus-alfred repo. TRIGGER when: "create skill", "build skill for", "make a
  skill", "new skill for [task]", "draft a skill", "skill template". Do NOT use for:
  general task execution, explaining how skills work conceptually, executing a skill that
  already exists, or creating skills for specialist repos (trading-assistant, divorce-custody,
  pir-devine-news) — those belong in their respective .claude/skills/ directories.
---

# Skill: /create-skill — Alfred (anthropas-argus-alfred)

Design a new Claude Code skill for the Alfred coordinator repo. Produce a draft ready for review.

## The 7 Rules for Effective Skills

1. **Debug with description echo:** Ask "When would you use the [skill-name] skill?" — Claude quotes the description back. Reveals what's vague.
2. **Negative triggers matter more than positive:** The "Do NOT use for..." line prevents skill hijacking. Write it first.
3. **Skills stack with CLAUDE.md and memory:** Skill = process. CLAUDE.md = context and rules. Don't repeat CLAUDE.md rules inside the skill.
4. **Build from what already worked:** Best skills are reverse-engineered from prompts that worked well in past sessions.
5. **Description is everything:** Too vague → skill never fires. Too broad → hijacks conversations. Test both.
6. **Laziness workaround:** If Claude cuts corners, add "Take your time. Quality over speed." to the invocation, not the skill file.
7. **Skills are portable:** The format is an open standard. Build once, works across sessions.

---

## Skill File Format

```markdown
---
name: skill-name
description: >
  One or two sentences. TRIGGER when: [specific conditions].
  Do NOT use for: [anti-triggers — be specific].
---

# Skill: /skill-name

[Full instructions.]

## Before Starting
[What to read/check]

## Steps
[Numbered process]

## Output Format
[What the result looks like]

## After Completing
[Cleanup, commits, follow-on actions]

## Quick Commands
[Exact bash commands — use [PLACEHOLDER] for anything variable]
```

---

## How to Create a Skill

1. Describe what you want the skill to do
2. Draft following the format above — start with "Do NOT use for"
3. Test: ask "When would you use the [skill-name] skill?"
4. Save to `.claude/skills/skill-name.md`
5. Add to the skills table below and commit (skills are public in this repo)

---

## Skills in This Repo

| Skill | Trigger | Purpose |
|-------|---------|---------|
| `/create-skill` | "create skill", "build skill for", "new skill" | Design a new skill for this repo |

---

## Generation Workflow

1. **Write "Do NOT use for" first** — prevents skill hijacking
2. **Write positive triggers** — TRIGGER when: keywords, task types, phrasings (be "pushy"; include synonyms)
3. **Write the body** — explain WHY, not just WHAT; concrete examples beat abstract placeholders
4. **Self-review:** Can I cut 20% without losing value? Are there rigid rules that should be reasoning instead?
5. **Test the trigger:** Ask "When would you use the [skill-name] skill?"

---

## Version Control Safety

Skills in `.claude/skills/` are tracked in git and **synced to the public preview repo** via gitexporter.
**Never include:**
- API keys, tokens, passwords, seed phrases, or wallet addresses
- Specific account numbers or personal file paths with sensitive info
- Content from other repos — cross-repo privacy firewall

Use `[PLACEHOLDER]` for anything account- or person-specific.

---

## Reference

- Skills are public in this repo — synced via `gitexporter.config.json`
- Framework reference: [makemyskill.com](https://makemyskill.com)
