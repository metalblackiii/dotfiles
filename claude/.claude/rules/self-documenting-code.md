# Self-Documenting Code

Do NOT add comments that explain what code does. Rename to make it obvious instead.

Comments are ONLY permitted for:
- **WHY** — business rules, regulatory requirements, non-obvious design choices
- **WARNING** — hazards, ordering dependencies, surprising behavior
- **TODO** — with ticket number (e.g., `TODO(JIRA-1234)`)

Everything else is a naming failure. Fix the name, delete the comment.

Vague names are defects: `data`, `result`, `temp`, `handle*`, `process*` — rename to intent.
