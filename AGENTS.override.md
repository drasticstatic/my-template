# AGENTS.override.md
# Priority: HIGH — These rules override standard AGENTS.md instructions.
# Usage: Drop this file in the project root (or a subdirectory for scoped overrides).
#        Delete this file when the task is complete to restore standard project rules.
#        No edits to AGENTS.md needed — clean removal restores baseline.

---

## 🎯 Current Focus

- **Task**: [e.g., Implementing Auth Flow / Refactoring Payments Module / Incident Response]
- **Constraint**: [e.g., Do not touch the /database folder until migration is validated]
- **Urgency**: [e.g., High — avoid deep refactoring; focus on functionality only]

---

## 🛠️ Tooling & Stack Overrides

- **Package manager**: Use `[pnpm / npm / uv / pip]` only for this task
- **Testing**: Run `[specific test command]` instead of the full suite
- **Environment target**: `[Production / Staging / Local]`

---

## 🚫 Restricted Actions (Safety)

- **Do not**: Delete or modify existing tests
- **Do not**: Update package versions in `package.json` / `pyproject.toml`
- **Do not**: Refactor code outside the current working scope
- **Do not**: [Add any task-specific restriction here]

---

## 📝 Style & Pattern Overrides

- **Preference**: [e.g., Functional components only — no class components]
- **Documentation**: [e.g., All new functions require JSDoc / docstrings]
- **Naming**: [e.g., PascalCase for components, camelCase for utilities]

---

## ⚡ Debugging / Logging

- **Rule**: Prefix all new `console.log` / `print` statements with `[DEBUG-TASK-NAME]`
- **Rule**: Verbose error handling required in all async `try/catch` blocks during this task

---

## 📋 Scope Boundaries

Files / directories that are **in scope** for this task:
- `[path/to/file-or-dir]`
- `[path/to/file-or-dir]`

Files / directories that are **out of scope** (read-only or hands-off):
- `[path/to/protected-dir/]`
- `[path/to/critical-file]`

---

## ✅ Done Condition

This override file should be **deleted** when:
- [ ] [Specific completion condition — e.g., auth flow passes all tests]
- [ ] [e.g., Maintenance window closes]
- [ ] Changes are committed and reviewed

*Delete this file to restore standard AGENTS.md rules.*
