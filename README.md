# dotfiles

Personal configuration files for AI coding assistants, managed with Git and symlinks.

Currently supports **Claude Code** and **Codex**. Skills and conventions are shared across platforms via a single `AGENTS.md` and symlinked skills directory.

## Prerequisites

[Claude Code](https://docs.anthropic.com/en/docs/claude-code) and/or [Codex](https://codex.openai.com/) must be installed. The following CLI tools are referenced in permissions and skills:

| Tool | Required | Install | Used by |
|------|----------|---------|---------|
| `git` | Yes | Xcode CLT / `brew install git` | Core workflow |
| `gh` | Yes | `brew install gh` | PR creation, issue management, `/review` command |
| `node` / `npm` / `npx` | Yes | `brew install node` or nvm | Running and testing projects |
| `docker` | Optional | [Docker Desktop](https://www.docker.com/products/docker-desktop/) | `docker-infrastructure` skill |
| `kubectl` | Optional | `brew install kubectl` | Read-only cluster access |
| `ast-grep` | Optional | `brew install ast-grep` | `ast-grep-patterns` skill (structural code search) |
| `jq` | Optional | `brew install jq` | JSON processing in scripts |

## Installation

```bash
git clone https://github.com/metalblackiii/dotfiles.git ~/repos/dotfiles
cd ~/repos/dotfiles

# Install everything
./install.sh

# Or install a single platform
./claude/install.sh
./codex/install.sh
```

Original files are backed up with `.backup.TIMESTAMP` before symlinking.

To remove:

```bash
# Uninstall everything
./uninstall.sh

# Or uninstall a single platform
./claude/uninstall.sh
./codex/uninstall.sh
```

## Structure

```
dotfiles/
├── claude/                  # Claude Code configuration
│   ├── install.sh
│   ├── uninstall.sh
│   └── .claude/
│       ├── AGENTS.md        # Shared instructions (single source of truth)
│       ├── CLAUDE.md        # Claude-specific settings (thin wrapper)
│       ├── settings.json    # Permissions, hooks, env vars
│       ├── agents/          # 6 custom subagents
│       ├── commands/        # 7 slash commands
│       ├── hooks/           # Session-start hook
│       ├── scripts/         # Status bar script
│       └── skills/          # 27 specialized skills (shared with Codex)
├── codex/                   # Codex configuration
│   ├── install.sh
│   ├── uninstall.sh
│   └── .codex/
│       └── config.toml      # Codex runtime settings
├── install.sh               # Orchestrator — runs */install.sh
├── uninstall.sh             # Orchestrator — runs */uninstall.sh
└── .gitignore
```

### What's Shared vs Platform-Specific

| Layer | Shared? | Where |
|-------|---------|-------|
| AGENTS.md (conventions, rules) | Yes | `claude/.claude/AGENTS.md` — both platforms symlink to it |
| Skills (27) | Yes | `claude/.claude/skills/` — Codex discovers via `~/.agents/skills/personal` |
| Claude settings, hooks, commands, agents | No | Claude-only features |
| Codex config.toml | No | Codex-only runtime settings |

## Shared Configuration (AGENTS.md)

The `AGENTS.md` file is the single source of truth for conventions shared across all platforms:

- **Git preferences** — conventional commits, explicit commit/push approval
- **PR defaults** — reviewers, gh flags
- **Code quality** — preparatory refactoring, Rule of Three, fix broken windows
- **Security** — HIPAA context, no PII in examples, no hardcoded secrets
- **Self-documenting code** — rename over comment, only "why" comments
- **Skill usage** — check skills before non-trivial tasks

## Claude Code Configuration

### Skills (27)

Specialized methodologies that activate automatically when relevant tasks are detected. A session-start hook enforces this via "The Iron Law" — check for applicable skills before responding to non-trivial requests.

| Skill | When it activates |
|-------|-------------------|
| **analyzing-prs** | Reviewing PR diffs for quality, security, architecture, testing |
| **api-designer** | Designing REST endpoints, versioning strategy, request/response contracts |
| **ast-grep-patterns** | Large refactors, structural code pattern searches, API migrations |
| **database-expert** | SQL queries, schema design, Aurora migrations, Sequelize tuning, index strategies |
| **dispatching-parallel-agents** | Multiple independent failures or investigations without shared state |
| **docker-infrastructure** | Troubleshooting containers, compose services, Dockerfiles |
| **feature-forge** | Defining new features, requirements workshops, writing specifications |
| **github-actions** | GitHub Actions failures, CI/CD pipeline errors, flaky tests |
| **handoff** | Ending sessions with work in progress or high context usage |
| **kubernetes-specialist** | Deploying/managing K8s workloads, Helm charts, RBAC, troubleshooting pods |
| **legacy-modernizer** | Incremental migrations, strangler fig patterns, dual-mode coexistence |
| **microservices-architect** | Distributed system design, service boundaries, sagas, event sourcing |
| **neb-ms-conventions** | Code in neb microservice repositories |
| **neb-repo-layout** | Background knowledge: where neb repos live and how they're organized |
| **neb-playwright-expert** | Writing, debugging, or planning E2E tests in neb-www's Playwright infrastructure |
| **prompt-engineer** | LLM prompt design, evaluation frameworks, structured outputs |
| **reflection** | After completing meaningful implementation chunks, before reporting progress |
| **self-documenting-code** | Naming quality reviews, comment hygiene, readability refactors |
| **refactoring-guide** | Code smells, refactoring discipline, structural improvements |
| **spec-miner** | Reverse-engineering specs from existing code, documenting legacy systems |
| **systematic-debugging** | Any bug or unexpected behavior — invoked before proposing fixes |
| **test-architect** | Planning test strategy for features, migrations, or refactoring of existing code |
| **test-driven-development** | Any feature or bugfix — invoked before writing implementation |
| **the-fool** | Challenging ideas with structured critical reasoning, pre-mortems, red teams |
| **verification-before-completion** | Before claiming work is done, committing, or creating PRs |
| **writing-agents** | Creating or editing custom agent .md files and frontmatter |
| **writing-skills** | Creating or editing SKILL.md files and frontmatter |

Several skills include reference libraries (e.g., `database-expert/references/`, `prompt-engineer/references/`, `microservices-architect/references/`, `the-fool/references/`, `test-architect/references/`, `neb-playwright-expert/references/`).

### Commands (7)

Slash commands invoked directly during sessions.

| Command | Purpose |
|---------|---------|
| `/audit-skills` | Audit skill usage across recent sessions to find dormant skills and adoption gaps |
| `/audit-commands` | Audit slash command usage across recent sessions to find unused commands |
| `/audit-agents` | Audit custom agent usage across recent sessions to find unused agents |
| `/audit-permissions` | Audit permission deny/allow/ask rules for denials and calibration issues |
| `/catchup` | Restore context after `/clear`, `/compact`, or a long break |
| `/introspect` | Review configuration for conflicts, redundancy, and staleness |
| `/review` | Review a pull request using the analyzing-prs skill |

### Agents (6)

Custom subagents spawned via the Task tool for parallel or specialized work.

| Agent | Purpose |
|-------|---------|
| **analysis-writer** | Produce structured analysis documents for team decision-making |
| **neb-explorer** | Explore feature implementations across neb microservices |
| **qa-engineer** | Plan and write test coverage for features, migrations, or refactoring |
| **requirements-analyst** | Surface ambiguities and risks in requirements before engineering |
| **self-code-reviewer** | Fresh-eyes code review as a pre-commit/pre-PR quality gate |
| **upgrade-analyst** | Research dependency upgrades, migrations, and breaking changes |

> **Neb-specific agents**: `neb-explorer` and `requirements-analyst` load the `neb-repo-layout` skill which assumes neb repositories are cloned into `~/repos/` with their standard names (e.g., `~/repos/neb-ms-billing`, `~/repos/neb-microservice`). If your repos live elsewhere, update the base path in `skills/neb-repo-layout/SKILL.md`.

### Hooks & Scripts

- **session-start.sh** — Fires on startup, resume, clear, and compact. Lists all installed skills and enforces skill-first workflow.
- **context-bar.sh** — Status line showing model, git branch, uncommitted files, sync status, and context usage percentage.

### Permissions

The `settings.json` enforces strict guardrails:

- **Denied**: shell aliases for tools with dedicated equivalents (`cat`, `grep`, `find`, `ls`), `python -c` inline execution (use `jq` instead), env/secret files, destructive git operations, dangerous docker flags, package publishing
- **Ask**: `git commit`, `git push`, `gh pr create/merge/close`
- **Allowed**: standard dev tools, read-only kubectl, scoped web access

## Codex Configuration

Codex shares `AGENTS.md` and skills from the Claude directory. Its only platform-specific file is `config.toml`:

- **Model**: `gpt-5.3-codex`
- **Approval policy**: `never` (sandbox restricts filesystem/network access)
- **Project doc fallback**: reads `CLAUDE.md` and `TEAM_GUIDE.md` from project roots

## Adding a New Platform

1. Create a directory: `platform-name/`
2. Add `install.sh` and `uninstall.sh`
3. Symlink to `claude/.claude/AGENTS.md` for shared conventions
4. Symlink to `claude/.claude/skills/` for shared skills
5. The top-level orchestrator picks up `*/install.sh` automatically

## Customization

If you fork this repo, update these team/environment-specific values:

| What | Where | Default |
|------|-------|---------|
| Neb repo base path | `claude/.claude/skills/neb-repo-layout/SKILL.md` | `~/repos/` |
| PR default reviewers | `claude/.claude/AGENTS.md` → PR Defaults | `Chiropractic-CT-Cloud/phoenix` |

## Attribution

See [ATTRIBUTION.md](ATTRIBUTION.md) for skill sources and credits.
