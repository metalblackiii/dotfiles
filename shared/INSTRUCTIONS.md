# Agent Configuration

This configuration is managed via dotfiles repo (`~/repos/dotfiles/`) with symlinks.

**Always edit files in the dotfiles repo** — never edit via symlinked paths (`~/.claude/`, `~/.codex/`, `~/.agents/`). Those are deployment targets.

## Tool Preferences

- **Prefer built-in tools over Bash equivalents** — `Read` not `cat`, `Glob` not `find`/`ls`, `Grep` not `grep`/`rg`. `head`/`tail` are allowed for quick peeking. Never attempt to work around deny rules.

## Git Preferences

- Use **conventional commit** style unless the project specifies otherwise
- Only commit or push when I explicitly ask — every commit and push requires my approval
- Never auto-commit follow-up changes after an initial commit — always prompt again

## PR Defaults

- Default reviewers: `Chiropractic-CT-Cloud/phoenix`
- Use `-r org/team-slug` with `gh pr create` (not `--team`)

## Skills

You have specialized skills installed. These represent personal development methodology and best practices.

### Discovery

Invoke skills via the platform's skill mechanism (e.g., `Skill` tool in Claude Code, `$skill` in Codex). The platform lists available skills — check there first. When you invoke a skill, its full content is loaded. Follow it directly.

Never use the Read tool on skill files. Always use the platform's skill invocation.

### When to Check for Skills

**Non-trivial tasks** — features, debugging, architecture, reviews, deployments:
1. Check which skills apply (scan the available skills list)
2. Invoke the relevant skill(s)
3. Follow the skill's guidance
4. THEN respond to the user

**Trivial tasks** — single-line fixes, typos, simple questions, file reads:
- Proceed directly. Skills add overhead here with no benefit.

### Sequencing

Skills compose naturally. Common sequences:

- **Bugfix:** `systematic-debugging` → `test-driven-development` → `verification-before-completion`
- **New feature:** `feature-forge` (or `requirements-analyst` agent) → `test-driven-development` → `verification-before-completion`
- **Refactor:** `refactoring-guide` → `verification-before-completion`
- **PR review:** `review` or `self-review` (these consume `analyzing-prs` internally)

When multiple skills apply, invoke process skills first (debugging, planning), then implementation skills (domain-specific, testing).

### Red Flags

If you're thinking any of these, stop and check for skills:

- "Let me just..." → Is this actually trivial, or are you rationalizing?
- "This won't take long..." → Check for skills first.
- "I need to explore first..." → Skills guide exploration.
- "After I gather context..." → Skills guide context gathering.

### The Iron Law

Skills are not optional when applicable. Invoke first, work second. But don't invoke skills for work that genuinely doesn't benefit from them.

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
