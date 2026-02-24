# Agent Configuration

This configuration is managed via a dotfiles repo with symlinks.

**Always edit files in the dotfiles repo** — never edit via symlinked paths (`~/.claude/`, `~/.codex/`, `~/.agents/`). Those are deployment targets. To find the repo root, use `git rev-parse --show-toplevel` from any file inside it, or follow a symlink (e.g., `readlink ~/.claude/skills`) back to the source.

## Tool Preferences

- **Prefer built-in tools over Bash equivalents** — `Read` not `cat`, `Glob` not `find`/`ls`, `Grep` not `grep`/`rg`.
- **Fallback preference when shell is needed** — use `rg` for text search and `fd` (or `rg --files`) for file discovery.
- `head`/`tail` are allowed for quick peeking. Never attempt to work around deny rules.

## Git Preferences

- Use **conventional commit** style unless the project specifies otherwise
- Only commit or push when I explicitly ask — every commit and push requires my approval
- Never auto-commit follow-up changes after an initial commit — always prompt again

## PR Defaults

- Default reviewers: `Chiropractic-CT-Cloud/phoenix`
- Always include default reviewers. Optional reviewers are additive only when explicitly requested.
- Optional team reviewer, if asking for "architecture team" review: `Chiropractic-CT-Cloud/architecture`
- Optional individual reviewers, if asking for "devops" review: `daniel-goss_ptek`, `troy-lewis_ptek`
- Use `-r` with `gh pr create`:
  - team format: `org/team-slug` (for example `Chiropractic-CT-Cloud/phoenix`)
  - individual format: `username` (for example `daniel-goss_ptek`)

## Skills

Detailed skill usage workflow lives in `using-skills` and is the source of truth.

- Use platform skill invocation (`Skill` tool in Claude Code, `$skill` in Codex). Direct SKILL.md reading is allowed for meta-maintenance and audit tasks.
- For non-trivial tasks, identify relevant skills first and follow them before responding.
- For trivial tasks (single-line fixes, typos, simple questions, file reads), proceed directly.
- Skills are mandatory when applicable.

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
