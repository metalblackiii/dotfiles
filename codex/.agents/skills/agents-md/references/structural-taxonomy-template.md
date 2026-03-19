# Structural Taxonomy Template

## Annotated Template

```markdown
# <Project Name>
<!-- Keep the header minimal. 1-2 sentence project context ONLY if
     not obvious from repo name + README. Most repos skip this. -->

## Non-Negotiables
<!-- 3-5 hardest constraints. Things that break if violated.
     Use IMPORTANT/MUST sparingly — if everything is critical, nothing is.
     Put these FIRST: Lost in the Middle effect means rules here get
     highest compliance.
     Format: imperative statements, one per bullet. -->
- **IMPORTANT:** Never commit .env files or hardcoded credentials
- Always run `make lint` before committing — CI will reject unlinted code
- Use feature branches; never push directly to main

## Build / Test / Validate
<!-- Exact commands only. Non-obvious flags. Execution order when it matters.
     Skip anything discoverable from package.json scripts or Makefile targets
     UNLESS the invocation is non-obvious. -->
- `make db-reset && make test` — DB must be clean before test suite
- `pnpm --filter @app/api test:integration` — integration tests need running DB
- Environment: copy `.env.example` to `.env`, set `DATABASE_URL`

## Architecture
<!-- ONLY what can't be inferred from the code. Key decisions, not descriptions.
     Bad: "src/ contains components organized by feature"
     Good: "legacy-auth/ is deprecated but still serves 30% of traffic — don't modify" -->
- Monorepo: `packages/api` (backend), `packages/web` (frontend), `packages/shared` (types)
- Event sourcing for billing domain — never mutate events, only append
- `v1/` API routes are frozen; all new work goes in `v2/`

## Conventions
<!-- Only rules that differ from defaults or can't be enforced by tools.
     Bad: "Use camelCase" (standard JS, agent knows this)
     Good: "Use barrel exports in packages/shared — other packages import from index" -->
- Commit format: `type(scope): message` (conventional commits)
- Style enforced by Biome — don't add style rules here
- Feature flags: wrap new features in `isEnabled('flag-name')` checks

## Safety / Security
<!-- Regulatory consequences, auth patterns, data handling.
     Only 14.5% of repos include this section — but it's critical for
     healthcare, finance, and regulated industries. -->
- HIPAA: never log PII/PHI. Use placeholder data in tests
- Auth: all API routes require `requireAuth` middleware — no exceptions
- Secrets via environment variables only; never hardcode

## Workflow
<!-- Branch naming, PR format, commit conventions, review expectations.
     Skip if fully covered by CONTRIBUTING.md or CI checks. -->
- Branch naming: `type/TICKET-123-short-description`
- PRs require 1 approval from @team-name
- Squash merge to main; delete branch after merge

## References
<!-- @imports to satellite docs. Links to specs. NOT inline content.
     Use this section to keep the root file small while providing
     depth on demand. -->
@.claude/rules/api-conventions.md
@.claude/rules/database-patterns.md
```

## Section Ordering Rationale

The ordering is deliberate, based on the Lost in the Middle effect and GitHub's analysis of 2,500 repos:

| Position | Section | Why Here |
|---|---|---|
| 1st | Non-Negotiables | Highest compliance position; hardest constraints |
| 2nd | Build / Test | Early executable commands with full flags outperform vague tool names |
| 3rd | Architecture | Context for understanding; middle position is acceptable for reference material |
| 4th | Conventions | Lower priority than constraints; middle position |
| 5th | Safety / Security | Important but often conditional; middle-to-late |
| 6th | Workflow | Process rules; late position acceptable |
| Last | References | Structural bookend; compliance recovery position; also naturally terminal |

## When to Omit Sections

- **Non-Negotiables**: Never omit — every project has hard constraints (even if it's just "don't push to main")
- **Build / Test**: Omit only if all commands are discoverable from `package.json` scripts or `Makefile` help
- **Architecture**: Omit for simple single-purpose repos where the code is self-explanatory
- **Conventions**: Omit if all conventions match language/framework defaults and are enforced by linters
- **Safety / Security**: Omit only for non-regulated contexts with no auth, no user data, no secrets
- **Workflow**: Omit if covered by CONTRIBUTING.md and the agent can read it
- **References**: Omit if the file is already short (<50 lines) and self-contained

## Good vs Bad Content

| Section | Bad (Exclude) | Good (Include) |
|---|---|---|
| Non-Negotiables | "Write high-quality code" | "Never skip the `pre-commit` hook — it runs secrets detection" |
| Build / Test | "Run tests before committing" | "`make db-reset && make test` — DB must be clean first" |
| Architecture | "We use a microservices architecture with React frontend" | "`billing-service` uses event sourcing — never mutate events" |
| Conventions | "Use meaningful variable names" | "Barrel exports required in `packages/shared` — other packages import from index only" |
| Safety | "Be careful with user data" | "HIPAA: never log fields from `patient.*` models" |
| Workflow | "Follow good git practices" | "Branch format: `type/JIRA-123-description`; squash merge to main" |

## Sources

- MSR 2026 taxonomy: arxiv.org/abs/2510.21413
- Agent READMEs characterization: arxiv.org/abs/2511.12884
- GitHub Blog (2,500 repo analysis): github.blog/ai-and-ml/github-copilot/how-to-write-a-great-agents-md
- Anthropic Memory docs: code.claude.com/docs/en/memory
- Lost in the Middle: aclanthology.org/2024.tacl-1.9
