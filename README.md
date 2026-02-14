# dotfiles

Personal configuration files, managed with Git and symlinks.

## Prerequisites

[Claude Code](https://docs.anthropic.com/en/docs/claude-code) must be installed. The following CLI tools are referenced in permissions and skills:

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
./install.sh
```

Original files are backed up with `.backup.TIMESTAMP` before symlinking.

## Structure

```
dotfiles/
├── claude/                  # Claude Code configuration
│   └── .claude/
│       ├── CLAUDE.md        # Global instructions
│       ├── settings.json    # Permissions, hooks, env vars
│       ├── agents/          # 5 custom subagents
│       ├── commands/        # 4 slash commands
│       ├── hooks/           # Session-start hook
│       ├── rules/           # 4 behavioral rules
│       ├── scripts/         # Status bar script
│       └── skills/          # 15 specialized skills
├── install.sh               # Symlink installer
└── .gitignore
```

## Claude Code Configuration

### Skills (15)

Specialized methodologies that activate automatically when relevant tasks are detected. A session-start hook enforces this via "The Iron Law" — check for applicable skills before responding to non-trivial requests.

| Skill | When it activates |
|-------|-------------------|
| **analyzing-prs** | Reviewing PR diffs for quality, security, architecture, testing |
| **ast-grep-patterns** | Large refactors, structural code pattern searches, API migrations |
| **docker-infrastructure** | Troubleshooting containers, compose services, Dockerfiles |
| **gha** | GitHub Actions failures, CI/CD pipeline errors, flaky tests |
| **handoff** | Ending sessions with work in progress or high context usage |
| **microservices-architect** | Distributed system design, service boundaries, sagas, event sourcing |
| **neb-ms-conventions** | Code in neb microservice repositories |
| **prompt-engineer** | LLM prompt design, evaluation frameworks, structured outputs |
| **self-documenting-code** | Naming quality reviews, comment hygiene, readability refactors |
| **software-design** | Single-service design, code smells, refactoring opportunities |
| **sql-pro** | Query optimization, schema design, migrations, indexing strategies |
| **systematic-debugging** | Any bug or unexpected behavior — invoked before proposing fixes |
| **test-driven-development** | Any feature or bugfix — invoked before writing implementation |
| **verification-before-completion** | Before claiming work is done, committing, or creating PRs |
| **writing-skills** | Creating or editing SKILL.md files and frontmatter |

Several skills include reference libraries (e.g., `sql-pro/references/`, `prompt-engineer/references/`, `microservices-architect/references/`).

### Commands (4)

Slash commands invoked directly during sessions.

| Command | Purpose |
|---------|---------|
| `/audit` | Audit usage patterns across all customizations by parsing session transcripts |
| `/catchup` | Restore context after `/clear`, `/compact`, or a long break |
| `/introspect` | Review configuration for conflicts, redundancy, and staleness |
| `/review` | Review a pull request using the analyzing-prs skill |

### Agents (5)

Custom subagents spawned via the Task tool for parallel or specialized work.

| Agent | Purpose |
|-------|---------|
| **analysis-writer** | Produce structured analysis documents for team decision-making |
| **neb-explorer** | Explore feature implementations across neb microservices |
| **requirements-analyst** | Surface ambiguities and risks in requirements before engineering |
| **self-review** | Fresh-eyes code review as a pre-commit/pre-PR quality gate |
| **upgrade-analyst** | Research dependency upgrades, migrations, and breaking changes |

> **Neb-specific agents**: `neb-explorer` and `requirements-analyst` assume neb repositories are cloned into `~/repos/` with their standard names (e.g., `~/repos/neb-ms-billing`, `~/repos/neb-microservice`). The `neb-ms-conventions` skill they load also references this layout. If your repos live elsewhere, update the paths in `agents/neb-explorer.md`, `agents/requirements-analyst.md`, and `skills/neb-ms-conventions/SKILL.md`.

### Rules (4)

Global behavioral rules applied to every interaction.

| Rule | Focus |
|------|-------|
| **code-quality** | Preparatory refactoring, Rule of Three, fix broken windows in code you touch |
| **communication** | Concise and direct, lead with solutions, prioritize bugs > security > perf > style |
| **security** | No hardcoded secrets, parameterized queries, input validation, secure defaults |
| **self-documenting-code** | Every "what" comment is a naming failure — rename first, comment only "why" |

### Hooks & Scripts

- **session-start.sh** — Fires on startup, resume, clear, and compact. Lists all installed skills and enforces skill-first workflow.
- **context-bar.sh** — Status line showing model, git branch, uncommitted files, sync status, and context usage percentage.

### Permissions

The `settings.json` enforces strict guardrails:

- **Denied**: shell aliases for tools with dedicated equivalents (`cat`, `grep`, `find`, `ls`), env/secret files, destructive git operations, dangerous docker flags, package publishing
- **Ask**: `git commit`, `git push`, `gh pr create/merge/close`
- **Allowed**: standard dev tools, read-only kubectl, scoped web access

## Adding New Topics

```bash
mkdir -p topic-name/
# Add config files mirroring home directory structure
# e.g., git/.gitconfig for ~/.gitconfig
```

Then update `install.sh` to symlink the new topic.

## Attribution

See [ATTRIBUTION.md](ATTRIBUTION.md) for skill sources and credits.
