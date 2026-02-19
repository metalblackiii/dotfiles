# Claude Code Configuration

This configuration is managed via dotfiles repo with symlinks.

Config files live in `~/repos/dotfiles/` and are symlinked to their platform directories.

**When editing config, always use the dotfiles path:**

| What | Edit Here |
|------|-----------|
| Global instructions | `~/repos/dotfiles/claude/.claude/CLAUDE.md` |
| Skills | `~/repos/dotfiles/codex/.agents/skills/<name>/SKILL.md` |
| Settings | `~/repos/dotfiles/claude/.claude/settings.json` |
| Hooks | `~/repos/dotfiles/claude/.claude/hooks/` |
| Commands | `~/repos/dotfiles/claude/.claude/commands/<name>.md` |
| Agents | `~/repos/dotfiles/claude/.claude/agents/<name>.md` |
| Scripts | `~/repos/dotfiles/claude/.claude/scripts/<name>.sh` |

**Never edit via `~/.claude/` paths** — those are symlinks.

## Tool Preferences

- **Prefer built-in tools over Bash equivalents** — `Read` not `cat`, `Glob` not `find`/`ls`, `Grep` not `grep`/`rg`. `head`/`tail` are allowed for quick peeking. Never attempt to work around the deny rules.

## Git Preferences

- Use **conventional commit** style unless the project specifies otherwise
- Only commit or push when I explicitly ask — every commit and push requires my approval
- Never auto-commit follow-up changes after an initial commit — always prompt again

## PR Defaults

- Default reviewers: `Chiropractic-CT-Cloud/phoenix`
- Use `-r org/team-slug` with `gh pr create` (not `--team`)

## Skills

You have specialized skills installed. These represent personal development methodology and best practices.

Before responding to a non-trivial request (features, debugging, architecture, reviews, deployments), check if any installed skills apply. Invoke the relevant skill, follow its guidance, then respond to the user.

For trivial tasks (single-line fixes, typos, simple questions, file reads), proceed directly.

Skills often compose naturally — for example, a bugfix typically involves `systematic-debugging` then `test-driven-development`, and any task nearing completion should invoke `verification-before-completion`.

## Code Quality

Quality code is a first-class priority, not an afterthought.

Preparatory refactoring is expected when code structure fights the requested change. Reshape structure first, then make the change — in separate commits.

When touching code:
- Fix broken windows in code you're modifying (not drive-by cleanup of unrelated files)
- Apply the Rule of Three for extraction
- Name the code smell before refactoring — no smell, no refactor
- Stop when structure supports the current need
- Crash early — a dead program does less damage than a crippled one. Surface errors, don't mask them with defensive returns or empty catches
- Don't program by coincidence — understand *why* code works, not just *that* it works
- Prefer reversible decisions — hide third-party dependencies behind abstractions, prefer configuration over hardcoding

Don't gold-plate. Don't add features nobody asked for. But don't leave code worse than you found it either.

## Security

Healthcare data context — HIPAA compliance matters.

- Never output real PII (names, emails, SSNs, phone numbers) in examples or test data
- Use placeholder data like `john.doe@example.com` or `555-0100`
- Never hardcode credentials, API keys, or secrets — use environment variables or secret management
- Never log PHI, PII, or sensitive data (tokens, passwords, SSNs)
- Error messages must not leak implementation details or patient data

## Self-Documenting Code

Follow the `self-documenting-code` skill for naming conventions and comment survival criteria.
