# dotfiles

Personal configuration files for AI coding assistants, managed with Git and symlinks.

Currently supports **Codex** and **Claude Code**. Skills live in `codex/.agents/skills/` and instructions in `shared/INSTRUCTIONS.md` — both shared across platforms via symlinks.

## Prerequisites

[Codex](https://codex.openai.com/) and/or [Claude Code](https://docs.anthropic.com/en/docs/claude-code) must be installed. The following CLI tools are referenced in permissions and skills:

| Tool | Required | Install | Used by |
|------|----------|---------|---------|
| `git` | Yes | Xcode CLT / `brew install git` | Core workflow |
| `gh` | Yes | `brew install gh` | PR creation, issue management |
| `node` / `npm` / `npx` | Yes | `brew install node` or nvm | Running and testing projects |
| `docker` | Optional | [Docker Desktop](https://www.docker.com/products/docker-desktop/) | Container workflows |
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
├── shared/                  # Cross-platform sources of truth
│   └── INSTRUCTIONS.md      # Agent conventions, rules, preferences
├── codex/                   # Codex configuration
│   ├── install.sh
│   ├── uninstall.sh
│   ├── AGENTS.md            # Symlink → ../shared/INSTRUCTIONS.md
│   ├── .codex/
│   │   └── config.toml      # Codex runtime settings
│   └── .agents/
│       └── skills/          # SOURCE OF TRUTH — actual skill files (26)
│           ├── analyzing-prs/SKILL.md
│           ├── systematic-debugging/SKILL.md
│           └── ...
├── claude/                  # Claude Code configuration
│   ├── install.sh
│   ├── uninstall.sh
│   └── .claude/
│       ├── CLAUDE.md        # Symlink → ../../shared/INSTRUCTIONS.md
│       ├── settings.json    # Permissions, hooks, env vars
│       ├── agents/          # 3 custom subagents
│       ├── hooks/           # Session-start hook
│       ├── scripts/         # Status bar script
│       └── skills           # Symlink → ../../codex/.agents/skills
├── install.sh               # Orchestrator — runs */install.sh
├── uninstall.sh             # Orchestrator — runs */uninstall.sh
└── .gitignore
```

### What's Shared vs Platform-Specific

| Layer | Shared? | Where |
|-------|---------|-------|
| Instructions (conventions, rules) | Yes | `shared/INSTRUCTIONS.md` — symlinked as `CLAUDE.md` and `AGENTS.md` |
| Skills (26) | Yes | `codex/.agents/skills/` — Claude Code accesses via symlink |
| Claude settings, hooks, agents | No | Claude-only features |
| Codex config.toml | No | Codex-only runtime settings |

## Codex Configuration

Codex owns the canonical skill directory (`codex/.agents/skills/`), which is symlinked to `~/.agents/skills/personal` at install time. Its platform-specific file is `config.toml`:

- **Model**: `gpt-5.3-codex`
- **Approval policy**: `on-request`
- **Developer instructions**: `developer_instructions` provides an always-on skills-first reminder for non-trivial work
- **Project docs**: platform-default behavior may load project instruction files (for example `AGENTS.md` and `CLAUDE.md`); this repo does not configure custom fallback behavior

### Skills (26)

Specialized methodologies that activate automatically when relevant tasks are detected. The `developer_instructions` in `config.toml` enforce "The Iron Law" — check for applicable skills before responding to non-trivial requests.

| Skill | When it activates |
|-------|-------------------|
| **analyzing-prs** | Reviewing PR diffs for quality, security, architecture, testing |
| **analyzing-requirements** | Surfacing ambiguities, risks, and gaps in requirements before engineering |
| **audit-skills** | Reviewing skill adoption, finding dormant skills, measuring effectiveness |
| **api-designer** | Designing REST endpoints, versioning strategy, request/response contracts |
| **ast-grep-patterns** | Large refactors, structural code pattern searches, API migrations |
| **database-expert** | SQL queries, schema design, Aurora migrations, Sequelize tuning, index strategies |
| **feature-forge** | Defining new features, requirements workshops, writing specifications |
| **gha** | GitHub Actions failures, CI/CD pipeline errors, flaky tests |
| **handoff** | Ending sessions with work in progress or high context usage |
| **introspect** | Auditing agent configuration for conflicts, redundancy, staleness, prompt quality |
| **kubernetes-specialist** | Deploying/managing K8s workloads, Helm charts, RBAC, troubleshooting pods |
| **legacy-modernizer** | Incremental migrations, strangler fig patterns, dual-mode coexistence |
| **neb-ms-conventions** | Code in neb microservice repositories |
| **neb-playwright-expert** | Writing, debugging, or planning E2E tests in neb-www's Playwright infrastructure |
| **prompt-engineer** | LLM prompt design, evaluation frameworks, structured outputs |
| **self-documenting-code** | Naming quality reviews, comment hygiene, readability refactors |
| **refactoring-guide** | Code smells, refactoring discipline, structural improvements |
| **review** | PR review for architecture, testing, code quality, security |
| **self-review** | Pre-commit/pre-PR quality gate for local git changes |
| **spec-miner** | Reverse-engineering specs from existing code, documenting legacy systems |
| **systematic-debugging** | Any bug or unexpected behavior — invoked before proposing fixes |
| **test-driven-development** | Any feature or bugfix — invoked before writing implementation |
| **the-fool** | Challenging ideas with structured critical reasoning, pre-mortems, red teams |
| **using-skills** | Session-start skill discovery and invocation workflow (loaded automatically) |
| **verification-before-completion** | Before claiming work is done, committing, or creating PRs |
| **writing-skills** | Creating or editing SKILL.md files and frontmatter |

Several skills include reference libraries (e.g., `codex/.agents/skills/database-expert/references/`, `codex/.agents/skills/prompt-engineer/references/`, `codex/.agents/skills/the-fool/references/`).

## Shared Instructions

`shared/INSTRUCTIONS.md` is the single source of truth for agent conventions. It's symlinked as `CLAUDE.md` (for Claude Code) and `AGENTS.md` (for Codex), so both platforms get the same rules:

- **Git preferences** — conventional commits, explicit commit/push approval
- **PR defaults** — reviewers, gh flags
- **Code quality** — preparatory refactoring, Rule of Three, fix broken windows
- **Security** — HIPAA context, no PII in examples, no hardcoded secrets
- **Self-documenting code** — rename over comment, only "why" comments
- **Skill usage** — check skills before non-trivial tasks

## Claude Code Configuration

Claude Code accesses skills via a symlink (`claude/.claude/skills` → `codex/.agents/skills`) and instructions via another (`claude/.claude/CLAUDE.md` → `shared/INSTRUCTIONS.md`). It adds platform-specific features on top.

### Agents (3)

Custom subagents spawned via the Task tool for parallel or specialized work.

| Agent | Purpose |
|-------|---------|
| **analysis-writer** | Produce structured analysis documents for team decision-making |
| **neb-explorer** | Explore feature implementations across neb microservices |
| **upgrade-analyst** | Research dependency upgrades, migrations, and breaking changes |

> **Neb-specific agents**: `neb-explorer` has the neb architecture knowledge (layers, environments, services, shared libraries) inlined directly and assumes neb repositories are cloned into `~/repos/` with their standard names (e.g., `~/repos/neb-ms-billing`, `~/repos/neb-microservice`). If your repos live elsewhere, update the base path in `claude/.claude/agents/neb-explorer.md`.

### Hooks & Scripts

- **session-start.sh** — Fires on startup, resume, clear, and compact. Lists all installed skills and enforces skill-first workflow.
- **context-bar.sh** — Status line showing model, git branch, uncommitted files, sync status, and context usage percentage.

### Permissions

The `settings.json` enforces strict guardrails:

- **Denied**: shell aliases for tools with dedicated equivalents (`cat`, `grep`, `find`), `python -c` inline execution (use `jq` instead), env/secret files, destructive git operations, dangerous docker flags, package publishing
- **Ask**: `git commit`, `git push`, `gh pr create/merge/close`
- **Allowed**: standard dev tools, read-only kubectl, scoped web access

## Adding a New Platform

1. Create a directory: `platform-name/`
2. Add `install.sh` and `uninstall.sh`
3. Symlink `platform-name/.config/skills/` → `codex/.agents/skills/`
4. The top-level orchestrator picks up `*/install.sh` automatically

## Customization

If you fork this repo, update these team/environment-specific values:

| What | Where | Default |
|------|-------|---------|
| Neb repo base path | `claude/.claude/agents/neb-explorer.md` | `~/repos/` |
| PR default reviewers | `shared/INSTRUCTIONS.md` → PR Defaults | `Chiropractic-CT-Cloud/phoenix` |

## Attribution

See [ATTRIBUTION.md](ATTRIBUTION.md) for skill sources and credits.
