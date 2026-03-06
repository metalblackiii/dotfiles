# dotfiles

Personal configuration files for AI coding assistants, managed with Git and symlinks.

Currently supports **Codex**, **Claude Code**, and some **Git** configurations. Agent skills live in `codex/.agents/skills/` and agent instructions in `shared/INSTRUCTIONS.md` — both shared across Codex and Claude Code via symlinks.

New here? See [INTRODUCTION.md](INTRODUCTION.md) for the rationale, skill anatomy, and adoption guide.

## Prerequisites

[Codex](https://codex.openai.com/) and/or [Claude Code](https://docs.anthropic.com/en/docs/claude-code) must be installed. The following CLI tools are referenced in permissions and skills:

| Tool | Required | Install | Used by |
|------|----------|---------|---------|
| `git` | Yes | Xcode CLT / `brew install git` | Core workflow |
| `gh` | Yes | `brew install gh` | PR creation, issue management |
| `node` / `npm` / `npx` | Yes | `brew install node` or nvm | Running and testing projects |
| `docker` | Optional | [Rancher Desktop](https://rancherdesktop.io/) or [colima](https://github.com/abiosoft/colima) | Container workflows |
| `kubectl` | Optional | `brew install kubectl` | Read-only cluster access |
| `rg` (ripgrep) | Optional | `brew install ripgrep` | Fast shell fallback for text search when built-in tools are unavailable |
| `fd` | Optional | `brew install fd` | Fast shell fallback for file discovery when built-in tools are unavailable |
| `ast-grep` | Optional | `brew install ast-grep` | `ast-grep-patterns` skill (structural code search) |
| `playwright-cli` | Optional | `npm install -g @playwright/cli` | `playwright-cli` skill (browser automation for agents) |
| `jq` | Optional | `brew install jq` | JSON processing in scripts |
| `snyk` | Optional | `brew tap snyk/tap && brew install snyk` | `snyk-expert` skill, vulnerability scanning. Run `snyk auth` after install to authenticate. |
| `rtk` | Optional | `brew install rtk` | Token-optimized CLI proxy (60-90% savings) |

### Optional Security Tooling (Only for `security-reviewer` Scanner Mode)

The security skills work without additional installs. Extra tooling is optional and only used for deeper scan automation.

Scanner-mode tools that use `pip` assume `python3` and `pip` are installed (or use `pipx` equivalents).

| Tool | Required | Install | Used by |
|------|----------|---------|---------|
| `gitleaks` | No | `brew install gitleaks` | Secret scanning workflows |
| `semgrep` | No | `pip install semgrep` | Static security pattern scanning |
| `trivy` | No | `brew install trivy` | Dependency/config/container security checks |
| `checkov` | No | `pip install checkov` | IaC security checks |

If these tools are unavailable, `security-reviewer` falls back to manual review and reports which scans were not executed.

## Installation

```bash
git clone https://github.com/metalblackiii/dotfiles.git ~/repos/dotfiles
cd ~/repos/dotfiles

# Install everything
./install.sh

# Or install a single platform
./claude/install.sh
./codex/install.sh
./git/install.sh
```

Original files are backed up with `.backup.TIMESTAMP` before symlinking.

To remove:

```bash
# Uninstall everything
./uninstall.sh

# Or uninstall a single platform
./claude/uninstall.sh
./codex/uninstall.sh
./git/uninstall.sh
```

## Structure

```
dotfiles/
├── git/                     # Git configuration
│   ├── install.sh
│   ├── uninstall.sh
│   └── .gitignore_global    # Global gitignore → ~/.gitignore_global
├── shared/                  # Cross-platform sources of truth
│   └── INSTRUCTIONS.md      # Agent conventions, rules, preferences
├── codex/                   # Codex configuration
│   ├── install.sh
│   ├── uninstall.sh
│   ├── AGENTS.md            # Symlink → ../shared/INSTRUCTIONS.md
│   ├── .codex/
│   │   └── config.toml      # Codex runtime settings
│   └── .agents/
│       └── skills/          # SOURCE OF TRUTH — actual skill files
│           ├── pr-analysis/SKILL.md
│           ├── systematic-debugging/SKILL.md
│           └── ...
├── claude/                  # Claude Code configuration
│   ├── install.sh
│   ├── uninstall.sh
│   └── .claude/
│       ├── CLAUDE.md        # Symlink → ../../shared/INSTRUCTIONS.md
│       ├── RTK.md           # RTK usage reference (included via @RTK.md)
│       ├── settings.json    # Permissions, hooks, env vars
│       ├── agents/          # 3 custom subagents
│       ├── commands/        # Slash commands (co-implement)
│       ├── hooks/           # PreToolUse, PostToolUse, and SessionStart hooks
│       ├── scripts/         # Status bar script
│       └── skills           # Symlink → ../../codex/.agents/skills
├── docs/                    # Research docs, postmortems, analysis artifacts
├── install.sh               # Orchestrator — runs */install.sh
├── uninstall.sh             # Orchestrator — runs */uninstall.sh
└── .gitignore
```

### What's Shared vs Platform-Specific

| Layer | Shared? | Where |
|-------|---------|-------|
| Instructions (conventions, rules) | Yes | `shared/INSTRUCTIONS.md` — symlinked as `CLAUDE.md` and `AGENTS.md` |
| Skills | Yes | `codex/.agents/skills/` — Claude Code accesses via symlink |
| Claude settings, hooks, agents | No | Claude-only features |
| Codex config.toml | No | Codex-only runtime settings |

## Codex Configuration

Codex owns the canonical skill directory (`codex/.agents/skills/`), which is symlinked to `~/.agents/skills/personal` at install time. Its platform-specific file is `config.toml`:

- **Model**: `gpt-5.3-codex`
- **Reasoning effort**: `xhigh` by default for long-running, high-complexity tasks where quality and depth matter more than latency
- **Daily-driver guidance**: prefer `high` or `medium` when you want faster responsiveness for routine work
- **Model-dependent support**: valid reasoning effort levels depend on the selected model; check your model's supported levels before setting this value
- **Approval policy**: `on-request`
- **Developer instructions**: `developer_instructions` provides an always-on skills-first reminder for non-trivial work
- **Project docs**: platform-default behavior may load project instruction files (for example `AGENTS.md` and `CLAUDE.md`); this repo does not configure custom fallback behavior

### Skills

Specialized methodologies that activate automatically when relevant tasks are detected. The `developer_instructions` in `config.toml` enforce "The Iron Law" — check for applicable skills before responding to non-trivial requests.

| Skill | When it activates |
|-------|-------------------|
| **pr-analysis** | Reviewing PR diffs for quality, security, architecture, testing |
| **requirements-analyst** | Surfacing ambiguities, risks, and gaps in requirements before engineering |
| **api-designer** | Designing REST endpoints, versioning strategy, request/response contracts |
| **ast-grep-patterns** | Large refactors, structural code pattern searches, API migrations |
| **audit-skills** | Reviewing skill adoption, finding dormant skills, measuring effectiveness |
| **creating-neb-patch-pr** | Creating patch PRs for merged main PRs in neb repos for hotfix deployment |
| **database-expert** | SQL queries, schema design, Aurora migrations, Sequelize tuning, index strategies |
| **feature-forge** | Defining new features, requirements workshops, writing specifications |
| **handoff** | Ending sessions with work in progress or high context usage |
| **introspect** | Auditing agent configuration for conflicts, redundancy, staleness, prompt quality |
| **mcp-vetting** | Security evaluation before installing or trusting any MCP server |
| **neb-ms-conventions** | Code in neb microservice repositories |
| **neb-playwright-expert** | Writing, debugging, or planning E2E tests in neb-www's Playwright infrastructure |
| **playwright-cli** | Browser automation via playwright-cli CLI (navigation, forms, screenshots, data extraction) |
| **pr-review-queue** | Consolidated dashboard for PRs where you are a reviewer, with action buckets and next-step triage |
| **pr-status-report** | Consolidated dashboard for open GitHub PRs with action buckets and next-step triage |
| **prompt-engineer** | LLM prompt design, evaluation frameworks, structured outputs |
| **quick-wins** | Repo scan for low-risk improvements — reports findings without making changes |
| **code-renovator** | Refactoring discipline, code smells, incremental legacy migrations, strangler fig patterns |
| **review** | PR review for architecture, testing, code quality, security |
| **secure-code-guardian** | Implementing security controls (auth/authz, validation, secrets, encryption, headers) |
| **security-reviewer** | Dedicated security audit/deep-dive review beyond normal PR quality gates |
| **self-documenting-code** | Naming quality reviews, comment hygiene, readability refactors |
| **self-review** | Pre-commit/pre-PR quality gate for local git changes |
| **snyk-expert** | Interpreting Snyk scan results, CVE/CWE assessment, vulnerability prioritization, CLI config, container scanning, remediation strategy |
| **spec-miner** | Reverse-engineering specs from existing code, documenting legacy systems |
| **systematic-debugging** | Any bug or unexpected behavior — invoked before proposing fixes |
| **test-driven-development** | Any feature or bugfix — invoked before writing implementation |
| **the-fool** | Challenging ideas with structured critical reasoning, pre-mortems, red teams |
| **using-skills** | Session-start skill discovery and invocation workflow (loaded automatically) |
| **verification-before-completion** | Before claiming work is done, committing, or creating PRs |
| **writing-skills** | Creating, testing, or optimizing skills — authoring, description tuning, eval-driven iteration |

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

### Commands

| Command | Purpose |
|---------|---------|
| **co-implement** | Plan a feature, delegate implementation to Codex CLI, then supervise |

### Hooks & Scripts

- **session-start.sh** — SessionStart hook. Fires on startup, resume, clear, and compact. Lists all installed skills and enforces skill-first workflow.
- **rtk-rewrite.sh** — PreToolUse hook that transparently rewrites Bash commands through [RTK](https://github.com/rtk-ai/rtk) for token savings. Silently no-ops if `rtk` or `jq` aren't installed.
- **guard-sensitive-paths.sh** — PreToolUse hook that blocks Bash access to sensitive file paths (env files, secrets, credentials).
- **eslint-autofix.sh** — PostToolUse hook that auto-runs ESLint `--fix` after Edit/Write operations on JS/TS files.
- **context-bar.sh** — Status line script showing model, git branch, uncommitted files, sync status, and context usage percentage.

### Permissions

The `settings.json` enforces strict guardrails:

- **Denied**: shell commands with dedicated tool equivalents (`sed`, `awk`, `xargs`), `python -c` inline execution, env/secret files, destructive git operations, dangerous docker flags, package publishing, destructive AWS/CDK/Terraform/Helm/kubectl write operations
- **Ask**: `git commit`, `git push`, `git restore`, `gh pr create/merge/close`, `curl`, `chmod`
- **Allowed**: standard dev tools, read-only kubectl, scoped web access

## Git Configuration

The `git/` directory manages some global Git settings that aren't project-specific.

### Global Gitignore

`git/.gitignore_global` is symlinked to `~/.gitignore_global` and registered via `core.excludesFile`. This is not a Git default — without it, Git has no global ignore file.

To verify it's active:

```bash
git config --global core.excludesFile
# Should output: /Users/<you>/.gitignore_global

readlink ~/.gitignore_global
# Should point to: .../dotfiles/git/.gitignore_global
```

Current global ignores: editor backup files (`*~`), `.DS_Store`, and agent working artifacts (`.co-research/`, `.co-implement/`, `HANDOFF.md`).

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
