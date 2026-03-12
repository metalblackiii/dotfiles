# Agent Configuration

This configuration is managed via a dotfiles repo with symlinks.

**IMPORTANT: Always edit files in the dotfiles repo** — never edit via symlinked paths (`~/.claude/`, `~/.codex/`, `~/.agents/`). Those are deployment targets. The canonical location for skills is `codex/.agents/skills/` within this repo. Both Claude Code (`~/.claude/skills/`) and Codex (`~/.agents/skills/`) symlink to it — all skills are shared across platforms. To find the repo root, use `git rev-parse --show-toplevel` from any file inside it, or follow a symlink (e.g., `readlink ~/.claude/skills`) back to the source.

## Tool Preferences

### Claude Code

- **Prefer built-in tools over Bash equivalents** — `Read` not `cat`, `Glob` not `find`/`ls`, `Grep` not `grep`/`rg`.
- **Fallback preference when shell is needed** — use `rg` for text search and `fd` (or `rg --files`) for file discovery.
- `head`/`tail` are allowed for quick peeking. Never attempt to work around deny rules.

### Codex

- Prefer platform-native tools when available in the active Codex runtime.
- In shell-first Codex environments, use `rg` for text search and `fd` (or `rg --files`) for file discovery.
- `head`/`tail` are allowed for quick peeking. Never attempt to work around deny rules.

## Git Preferences

- Use **conventional commit** style unless the project specifies otherwise
- **IMPORTANT:** Only commit or push when I explicitly ask — every commit and push requires my approval
- Never auto-commit follow-up changes after an initial commit — always prompt again
- Always use the branch name I specify. If I haven't specified one, ask before creating a branch.
- After edits and before committing, run `git status` to catch unstaged content edits alongside renames or moves.
- When using gh CLI across repos, verify repo context (`gh repo view --json nameWithOwner -q .nameWithOwner`) before running commands.


## PR Defaults

- Default reviewers: `Chiropractic-CT-Cloud/phoenix`
- Always include default reviewers. Optional reviewers are additive only when explicitly requested.
- Optional team reviewer, if asking for "architecture team" review: `Chiropractic-CT-Cloud/architecture`
- Optional individual reviewers, if asking for "devops" review: `daniel-goss_ptek`, `troy-lewis_ptek`
- GitHub usernames follow the format `firstname-lastname_ptek` (e.g., `daniel-goss_ptek`, `vais-salikhov_ptek`)
- Use `-r` with `gh pr create`:
  - team format: `org/team-slug` (for example `Chiropractic-CT-Cloud/phoenix`)
  - individual format: `username` (for example `daniel-goss_ptek`)

## Documentation Tasks

When asked to update or create documentation, only change documentation. Do not write implementation code, enter plan mode, or create implementation tasks unless explicitly asked. If something needs implementing, note it as a TODO in the doc instead.

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

Don't add plugin-style abstractions, path resolution systems, or multi-layer patterns unless explicitly requested.

## Security

Healthcare data context — HIPAA compliance matters.

- **IMPORTANT:** Never output real PII (names, emails, SSNs, phone numbers) in examples or test data
- Use placeholder data like `john.doe@example.com` or `555-0100`
- Never hardcode credentials, API keys, or secrets — use environment variables or secret management
- Never log PHI, PII, or sensitive data (tokens, passwords, SSNs)
- Error messages must not leak implementation details or patient data

## Context Management

When a session runs long, proactively run the `handoff` skill before autocompact kicks in. Signs you should trigger handoff:
- Conversation has had many tool calls or substantial back-and-forth
- You're working on a multi-step task that isn't yet complete
- The session feels heavy — don't wait to be asked

Run handoff, tell the user to start fresh with HANDOFF.md, and stop. A full-context handoff is far more useful than a post-compact recovery.

## Shell Hygiene

- If a command is blocked by a guard hook, ask for guidance rather than retrying blocked patterns.
- When npm/shell commands fail due to cwd, use `--prefix <path>` or `cd <path> &&` immediately — don't retry the broken approach.

## Self-Documenting Code

- Every "what" comment is a naming failure. Try renaming before commenting.
- Comments survive only for: WHY (business logic/regulatory), WARNING (non-obvious traps), TODO (with ticket number). Everything else dies.
- Scan your output for vague names — `data`, `result`, `temp`, `handle*`, `process*`, `manager`, `helper`, `utils` — and rename to intent.
- The name test: read the name aloud. If you need "which means..." to explain it, the name failed.

@RTK.md
@GUARD.md
