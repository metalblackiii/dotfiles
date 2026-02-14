# Self-Documenting Code

When writing or editing code, apply these principles automatically.

## The Rule

Every comment that explains "what" is a naming failure. Before writing a comment, try renaming first.

## Post-Write Scan

Before delivering code, scan your output and fix:

- **"What" comments** — Delete the comment, rename the variable/function to make it obvious
- **Redundant comments** — `// Return the result` above `return result` — just delete
- **Vague names** — `data`, `result`, `temp`, `handle*`, `process*` — rename to intent

## Comments That Survive

A comment earns its place ONLY if it explains something the code cannot:

- **WHY** — Business logic, legal requirements, non-obvious constraints
- **WARNING** — Order dependencies, concurrency hazards, subtle gotchas
- **TODO** — With a ticket number (`TODO(JIRA-1234)`)

Everything else? Rename instead.
