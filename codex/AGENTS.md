# Agent Configuration

## Canonical Editing

This configuration is managed via a dotfiles repo. `codex/AGENTS.md` is the single source of truth for shared instructions. Claude Code imports it via `@` in `claude/.claude/CLAUDE.md`; Codex reads it directly.

**IMPORTANT: Always edit files in the dotfiles repo** — never edit via deployed paths (`~/.claude/`, `~/.codex/`, `~/.agents/`). Those are deployment targets. The canonical location for skills is `codex/.agents/skills/` within this repo. Both Claude Code (`~/.claude/skills/`) and Codex (`~/.agents/skills/`) symlink to it — all skills are shared across platforms. To find the repo root, use `git rev-parse --show-toplevel` from any file inside it, or follow a symlink (e.g., `readlink ~/.claude/skills`) back to the source.

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
- **IMPORTANT:** For repo-scoped `gh` commands (`pr`, `issue`, `repo view`, `run`, etc.), when the target repo is known from batch results, conversation context, or user input, always use `-R owner/repo` — do not rely on cwd. When operating in a single repo and cwd is trustworthy, verify with `gh repo view --json nameWithOwner -q .nameWithOwner` before running `gh` commands. After multi-repo operations, cwd is never trustworthy — always use `-R`.


## PR Defaults

- Default reviewers: `Chiropractic-CT-Cloud/phoenix`
- Always include default reviewers. Optional reviewers are additive only when explicitly requested.
- Optional team reviewer, if asking for "architecture team" review: `Chiropractic-CT-Cloud/architecture`
- Optional individual reviewers, if asking for "devops" review: `daniel-goss_ptek`, `troy-lewis_ptek`
- GitHub usernames follow the format `firstname-lastname_ptek` (e.g., `daniel-goss_ptek`, `vais-salikhov_ptek`)
- Use `-r` with `gh pr create`:
  - team format: `org/team-slug` (for example `Chiropractic-CT-Cloud/phoenix`)
  - individual format: `username` (for example `daniel-goss_ptek`)
- When creating PRs, include a Jira ticket link in the body if a ticket number is detectable (from branch name or context). After PR creation, add a comment on the Jira ticket linking back to the PR.
- When commenting on Jira tickets, use markdown link syntax `[text](url)` — bare URLs render as plain text in ADF.

## Jira Defaults

- Base URL: `https://practicetek.atlassian.net` (link format: `https://practicetek.atlassian.net/browse/NEB-XXXXX`)
- Scrum team field: `customfield_11251` ("Nebula Scrum Team"), Phoenix = `id:11570`

## Output Preferences

- When listing URLs (PR links, run links, etc.), default to a plain newline-separated list — no bullets, no tables. Optimized for copy-paste into Slack/Teams.

## Documentation Tasks

When asked to update or create documentation, only change documentation. Do not write implementation code, enter plan mode, or create implementation tasks unless explicitly asked. If something needs implementing, note it as a TODO in the doc instead.

## Security

Healthcare data context — HIPAA compliance matters.

- **IMPORTANT:** Never output real PII (names, emails, SSNs, phone numbers) in examples or test data
- Use placeholder data like `john.doe@example.com` or `555-0100`
- Never hardcode credentials, API keys, or secrets — use environment variables or secret management
- Never log PHI, PII, or sensitive data (tokens, passwords, SSNs)
- Error messages must not leak implementation details or patient data

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

## Brewfile

CLI tools and GUI apps are managed via `~/repos/dotfiles/Brewfile`. When installing a brew package, also add it to the Brewfile. Don't just `brew install` ad hoc.

- To sync after editing: `brew bundle install --file=~/repos/dotfiles/Brewfile`

## Shell Hygiene

- If a blocked command appears to come from a project-level hook or permission system, ask for guidance rather than retrying.
- When npm/shell commands fail due to cwd, use `--prefix <path>` or `cd <path> &&` immediately — don't retry the broken approach.

## Skill Compliance

Check the skills list before every task. Matching skill → invoke it first, work second.

## Self-Documenting Code

- Every "what" comment is a naming failure. Try renaming before commenting.
- Comments survive only for: WHY (business logic/regulatory), WARNING (non-obvious traps), TODO (with ticket number). Everything else dies.
- Scan your output for vague names — `data`, `result`, `temp`, `handle*`, `process*`, `manager`, `helper`, `utils` — and rename to intent.
- The name test: read the name aloud. If you need "which means..." to explain it, the name failed.
