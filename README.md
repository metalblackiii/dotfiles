# dotfiles

Personal configuration files for AI coding assistants, managed with Git and symlinks.

Currently supports **Codex**, **Claude Code**, and some **Git** configurations. Agent skills live in `codex/.agents/skills/` and agent instructions in `shared/INSTRUCTIONS.md` — both shared across Codex and Claude Code via symlinks.

New here? See [INTRODUCTION.md](INTRODUCTION.md) for the rationale, skill anatomy, and adoption guide.

## Structure

```
dotfiles/
├── install-ai.sh            # AI tool config installer
├── uninstall-ai.sh          # AI tool config uninstaller
├── install-personal.sh      # Personal config installer (shell, editor)
├── uninstall-personal.sh    # Personal config uninstaller
├── Brewfile                  # Homebrew manifest (formulae, casks, VSCode extensions)
├── git_ai/                  # Git AI config (shared/forkable)
│   ├── install.sh
│   ├── uninstall.sh
│   └── .gitignore_global    # Global gitignore → ~/.gitignore_global
├── git_personal/            # Git personal config (delta, merge style)
│   ├── install.sh
│   ├── uninstall.sh
│   └── .gitconfig.shared    # Included via [include] in ~/.gitconfig
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
│       ├── BASH-PERMISSIONS.md # Bash permissions context (included via @BASH-PERMISSIONS.md)
│       ├── RTK.md           # RTK usage reference (included via @RTK.md)
│       ├── settings.json    # Permissions, hooks, env vars
│       ├── agents/          # 3 custom subagents
│       ├── commands/        # Slash commands (co-research)
│       ├── hooks/           # PreToolUse, PostToolUse, and SessionStart hooks
│       ├── scripts/         # Status bar, hooks
│       └── skills           # Symlink → ../../codex/.agents/skills
├── zsh/                     # Zsh shell configuration (personal)
│   ├── install.sh
│   ├── uninstall.sh
│   └── .zshrc               # Shell config → ~/.zshrc
├── docs/                    # Research docs, postmortems, analysis artifacts
└── .gitignore
```

---

## AI Tooling

The AI tool configuration is designed to be shareable. It covers agent platforms (Claude Code, Codex), shared instructions, skills, hooks, and permissions.

### Prerequisites

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
| `actionlint` | Optional | `brew install actionlint` | `gha-expert` skill (GitHub Actions static analysis) |
| `act` | Optional | `brew install act` | `gha-expert` skill (local GitHub Actions execution) |
| `ast-grep` | Optional | `brew install ast-grep` | `ast-grep-patterns` skill (structural code search) |
| `playwright-cli` | Optional | `npm install -g @playwright/cli` | `playwright-cli` skill (browser automation for agents) |
| `jq` | Optional | `brew install jq` | JSON processing in scripts |
| `snyk` | Optional | `brew tap snyk/tap && brew install snyk` | `snyk-expert` skill, vulnerability scanning. Run `snyk auth` after install to authenticate. |
| `rtk` | Optional | `brew install rtk` | Token-optimized CLI proxy (60-90% savings) |

#### Optional Security Tooling (Only for `security-reviewer` Scanner Mode)

The security skills work without additional installs. Extra tooling is optional and only used for deeper scan automation.

Scanner-mode tools that use `pip` assume `python3` and `pip` are installed (or use `pipx` equivalents).

| Tool | Required | Install | Used by |
|------|----------|---------|---------|
| `gitleaks` | No | `brew install gitleaks` | Secret scanning workflows |
| `semgrep` | No | `pip install semgrep` | Static security pattern scanning |
| `trivy` | No | `brew install trivy` | Dependency/config/container security checks |
| `checkov` | No | `pip install checkov` | IaC security checks |

If these tools are unavailable, `security-reviewer` falls back to manual review and reports which scans were not executed.

### Installation

```bash
git clone https://github.com/metalblackiii/dotfiles.git ~/repos/dotfiles
cd ~/repos/dotfiles

# Install AI tool config (Claude Code, Codex, RTK, global gitignore)
./install-ai.sh

# Or install a single module
./claude/install.sh
./codex/install.sh
./git_ai/install.sh
```

Original files are backed up with `.backup.TIMESTAMP` before symlinking.

To remove:

```bash
./uninstall-ai.sh

# Or uninstall a single module
./claude/uninstall.sh
./codex/uninstall.sh
./git_ai/uninstall.sh
```

### What's Shared vs Platform-Specific

| Layer | Shared? | Where |
|-------|---------|-------|
| Instructions (conventions, rules) | Yes | `shared/INSTRUCTIONS.md` — symlinked as `CLAUDE.md` and `AGENTS.md` |
| Skills | Yes | `codex/.agents/skills/` — Claude Code accesses via symlink |
| Claude settings, hooks, agents | No | Claude-only features |
| Codex config.toml | No | Codex-only runtime settings |

### Codex Configuration

Codex owns the canonical skill directory (`codex/.agents/skills/`), which is symlinked to `~/.agents/skills/personal` at install time. Its platform-specific file is `config.toml`:

- **Model**: configured per preference (see `config.toml`)
- **Reasoning effort**: configured per preference; valid levels depend on the selected model
- **Approval policy**: `on-request`
- **Sandbox mode**: `workspace-write` with network access enabled (required for `gh` commands, web searches, and API calls)
- **Developer instructions**: `developer_instructions` provides an always-on skills-first reminder for non-trivial work
- **Project docs**: platform-default behavior may load project instruction files (for example `AGENTS.md` and `CLAUDE.md`); this repo does not configure custom fallback behavior

#### Skills (41)

Specialized methodologies that activate automatically when relevant tasks are detected. The `developer_instructions` in `config.toml` enforce "The Iron Law" — check for applicable skills before responding to non-trivial requests.

| Skill | When it activates |
|-------|-------------------|
| **pr-analysis** | Reviewing PR diffs for quality, security, architecture, testing |
| **requirements-analyst** | Surfacing ambiguities, risks, and gaps in requirements before engineering |
| **api-designer** | Designing REST endpoints, versioning strategy, request/response contracts |
| **ast-grep-patterns** | Large refactors, structural code pattern searches, API migrations |
| **audit-skills** | Reviewing skill adoption, finding dormant skills, measuring effectiveness |
| **bash-expert** | Create, generate, validate, lint, audit, or fix bash/shell scripts |
| **batch-repo-ops** | Applying the same operation across multiple repos with batched sub-agents, rate limit awareness, and status tracking |
| **cli-developer** | Building CLI tools, argument parsing, interactive prompts, shell completions |
| **create-prd** | Define what to build before a prd-loop run, formalize a feature idea, convert a ticket into an implementation-ready PRD, or write feature specs with structured requirements |
| **creating-neb-patch-pr** | Creating patch PRs for merged main PRs in neb repos for hotfix deployment |
| **database-expert** | SQL queries, schema design, Aurora migrations, Sequelize tuning, index strategies |
| **dockerfile-expert** | Create, generate, validate, lint, scan, audit, or optimize Dockerfiles |
| **gha-expert** | Create, generate, validate, lint, audit, fix, or diagnose GitHub Actions workflows and CI/CD pipeline failures |
| **handoff** | Ending sessions with work in progress or high context usage |
| **helm-expert** | Create, scaffold, generate, validate, lint, audit, or check Helm charts |
| **introspect** | Auditing agent configuration for conflicts, redundancy, staleness, prompt quality |
| **k8s-debug** | Diagnose and fix Kubernetes pods, CrashLoopBackOff, Pending, DNS, networking, storage, and rollout failures |
| **mcp-vetting** | Security evaluation before installing or trusting any MCP server |
| **neb-ms-conventions** | Code in neb microservice repositories |
| **neb-playwright-expert** | Writing, debugging, or planning E2E tests in neb-www's Playwright infrastructure |
| **peer-review** | Context-isolated review gate for automated workflows (e.g., prd-loop). Not for manual review — use self-review instead |
| **playwright-cli** | Browser automation via playwright-cli CLI (navigation, forms, screenshots, data extraction) |
| **pr-review-queue** | Consolidated dashboard for PRs where you are a reviewer, with action buckets and next-step triage |
| **pr-status-report** | Consolidated dashboard for open GitHub PRs with action buckets and next-step triage |
| **prompt-engineer** | LLM prompt design, evaluation frameworks, structured outputs |
| **quick-wins** | Repo scan for low-risk improvements — reports findings without making changes |
| **code-renovator** | Refactoring discipline, code smells, incremental legacy migrations, strangler fig patterns |
| **review** | PR review for architecture, testing, code quality, security |
| **secure-code-guardian** | Implementing security controls (auth/authz, validation, secrets, encryption, headers) |
| **security-reviewer** | Dedicated security audit/deep-dive review beyond normal PR quality gates |
| **self-review** | Pre-commit/pre-PR quality gate for local git changes |
| **snyk-expert** | Interpreting Snyk scan results, CVE/CWE assessment, vulnerability prioritization, CLI config, container scanning, remediation strategy |
| **snyk-scan** | Scanning repos for vulnerabilities and applying fixes — orchestrates scan, assess, approve, remediate, report |
| **spec-miner** | Reverse-engineering specs from existing code, documenting legacy systems |
| **systematic-debugging** | Any bug or unexpected behavior — invoked before proposing fixes |
| **test-driven-development** | Any feature or bugfix — invoked before writing implementation |
| **the-fool** | Challenging ideas with structured critical reasoning, pre-mortems, red teams |
| **typescript-pro** | Advanced TypeScript generics, conditional/mapped types, branded types, monorepo setup, full-stack type safety |
| **using-skills** | Session-start skill discovery and invocation workflow (loaded automatically) |
| **verification-before-completion** | Before claiming work is done, committing, or creating PRs |
| **writing-skills** | Creating, testing, or optimizing skills — authoring, description tuning, eval-driven iteration |

### Shared Instructions

`shared/INSTRUCTIONS.md` is the single source of truth for agent conventions. It's symlinked as `CLAUDE.md` (for Claude Code) and `AGENTS.md` (for Codex), so both platforms get the same rules:

- **Git preferences** — conventional commits, explicit commit/push approval
- **PR defaults** — reviewers, gh flags
- **Code quality** — preparatory refactoring, Rule of Three, fix broken windows
- **Security** — HIPAA context, no PII in examples, no hardcoded secrets
- **Self-documenting code** — rename over comment, only "why" comments
- **Skill usage** — check skills before non-trivial tasks

### MCP Servers

MCP servers are configured in `~/.claude.json` (user scope), **not** in `settings.json` or the dotfiles repo. This file is machine-local — it contains absolute paths and may reference credentials via environment variables. Think of it like `~/.gitconfig` for MCP: personal, untracked.

To add a server:

```bash
claude mcp add -s user <name> -- <command> [args...]
```

To list or remove:

```bash
claude mcp list
claude mcp remove -s user <name>
```

#### Permissions for MCP Tools

MCP tools follow the same permission model as built-in tools. With `defaultMode: "default"`, all MCP tools prompt for confirmation unless explicitly allowed or denied in `settings.json`.

Read-only MCP tools can be added to the `permissions.allow` list in `settings.json` to skip the confirmation prompt. Write tools (update, comment, create) should stay at the default to require confirmation before making changes visible to others.

```json
"allow": [
  "mcp__server-name__readTool",
  "mcp__server-name__anotherReadTool"
]
```

#### Current Servers

| Server | Source | Profile | Allowed | Ask |
|--------|--------|---------|---------|-----|
| **ptek-jira** | [ptek-eng-toolbox](../ptek-eng-toolbox) | `jira` | getJiraTicket, searchJiraIssuesUsingJql, getJiraIssueContext, getJiraAttachments, getJiraDefectSummary | updateJiraTicket, addCommentToJiraTicket |

### Claude Code Configuration

Claude Code accesses skills via a symlink (`claude/.claude/skills` → `codex/.agents/skills`) and instructions via another (`claude/.claude/CLAUDE.md` → `shared/INSTRUCTIONS.md`). It adds platform-specific features on top.

#### Agents (4)

Custom subagents spawned via the Task tool for parallel or specialized work.

| Agent | Purpose |
|-------|---------|
| **analysis-writer** | Produce structured analysis documents for team decision-making |
| **neb-explorer** | Explore feature implementations across neb microservices |
| **research** | General-purpose research, web fetching, codebase investigation, multi-step tasks |
| **upgrade-analyst** | Research dependency upgrades, migrations, and breaking changes |

> **Neb-specific agents**: `neb-explorer` has the neb architecture knowledge (layers, environments, services, shared libraries) inlined directly and assumes neb repositories are cloned into `~/repos/` with their standard names (e.g., `~/repos/neb-ms-billing`, `~/repos/neb-microservice`). If your repos live elsewhere, update the base path in `claude/.claude/agents/neb-explorer.md`.

#### Commands

| Command | Purpose |
|---------|---------|
| **co-research** | Dispatch parallel research agents and Codex, then synthesize findings |

#### Hooks & Scripts

- **session-start.sh** — SessionStart hook. Fires on startup, resume, clear, and compact. Lists all installed skills and enforces skill-first workflow.
- **rtk-rewrite.sh** — PreToolUse hook that transparently rewrites Bash commands through [RTK](https://github.com/rtk-ai/rtk) for token savings. Silently no-ops if `rtk` or `jq` aren't installed.
- **bash-permissions.sh** + **bash-permissions.json** — PreToolUse hook that enforces layered Bash permission rules (deny, sensitive paths, branch-conditional allow, ask). Rules are externalized to JSON for easy editing.
- **eslint-autofix.sh** — PostToolUse hook that auto-runs ESLint `--fix` after Edit/Write operations on JS/TS files.
- **context-bar.sh** — Status line script showing model, git branch, uncommitted files, sync status, and context usage percentage.

#### Permissions

Claude Code permissions are split across two layers that handle different tool types. (Codex uses `approval_policy` in `config.toml` — see [Codex Configuration](#codex-configuration).)

##### Non-Bash Tools (`settings.json`)

The `permissions` block in `settings.json` controls Claude Code's built-in tools (Read, Edit, Write, Glob, Grep, WebFetch, WebSearch). These use glob-based path matching:

- **Allowed**: all built-in tools, `Bash(*)`, scoped web access
- **Denied**: Read/Edit/Write of `.env*` files, `/secrets/`, `.pem`/`.key` files, `~/.aws/`, `~/.ssh/`, shell configs (`~/.zshrc`, `~/.bashrc`, `~/.gitconfig`), private local overrides (`~/.*.local`), and the symlinked `~/.claude/` config files (prevents the agent from modifying its own configuration)

##### Bash Commands (`bash-permissions.sh` + `bash-permissions.json`)

All Bash permission rules are enforced by a PreToolUse hook — not by `settings.json`. The hook runs regex against the full command string, which is more reliable than glob matching for compound commands, pipes, and heredocs.

Rules live in `bash-permissions.json` and are evaluated in four layers. The script processes layers in a fixed order (deny → paths → allow → ask); the JSON key order is cosmetic.

| Layer | Decision | Purpose |
|-------|----------|---------|
| **deny** | Block | Unconditionally blocked. Optional `"nudge"` message guides Claude toward the right tool. |
| **paths** | Block | Blocks commands referencing sensitive file patterns (`.env`, `/secrets/`, `.pem`, `~/.aws/`, `~/.ssh/`, shell configs). Uses `__HOME__` placeholder expanded at runtime. |
| **allow** | Auto-approve | Bypasses the ask layer for trusted patterns. Supports optional `"branch"` condition — rule only fires when the current git branch matches the regex (e.g., `^mjb-pho-NEB-` auto-approves `git commit`, `git push`, and `gh pr create` on personal feature branches). |
| **ask** | Prompt user | Forces confirmation for `git commit/push`, `gh pr create/merge/close`, `curl`, `chmod`, `brew`, etc. |

First match wins. If no layer matches, the command is allowed.

Each rule uses one of two formats:
- `"commands": ["git commit", "rm -rf"]` — human-readable, auto-converted to `\b...\b` word-boundary regex
- `"regex": "\\baws\\s+[a-z-]+\\s+delete\\b"` — raw regex for complex patterns

**Design choices:**
- **Fail-open**: missing `jq`, missing rules file, or malformed JSON all silently allow (avoids blocking all commands on a broken config)
- **Command cleaning**: `/dev/null` redirects are stripped before matching to prevent false positives
- **Lazy git resolution**: branch conditions resolve the effective git directory from `cd <path> &&` prefixes in the command, falling back to cwd

### Git Configuration

Git config is split into two modules:

- **`git_ai/`** — Global gitignore (controls what AI agents see in repos). Installed by `install-ai.sh`.
- **`git_personal/`** — Delta pager, merge style, and other human-facing defaults. Installed by `install-personal.sh` via `[include]` in `~/.gitconfig`.

#### Global Gitignore

`git_ai/.gitignore_global` is symlinked to `~/.gitignore_global` and registered via `core.excludesFile`. This is not a Git default — without it, Git has no global ignore file.

To verify it's active:

```bash
git config --global core.excludesFile
# Should output: /Users/<you>/.gitignore_global

readlink ~/.gitignore_global
# Should point to: .../dotfiles/git_ai/.gitignore_global
```

Current global ignores: editor backup files (`*~`), `.DS_Store`, and agent working artifacts (`.co-research/`, `.prd-loop/`, `HANDOFF.md`).

#### Personal Git Config

`git_personal/.gitconfig.shared` is included in `~/.gitconfig` via `[include]`. This keeps personal identity and credentials in your local `~/.gitconfig` while sharing tool config (delta, merge style) from the dotfiles repo. Delta only activates on TTYs — AI agents running git over pipes get plain diffs automatically.

### Adding a New Module

1. Create a directory: `module-name/`
2. Add `install.sh` and `uninstall.sh`
3. For AI tool modules: symlink skills → `codex/.agents/skills/` and add to `install-ai.sh`
4. For personal config modules: add to `install-personal.sh`

### Customization

If you fork this repo, update these team/environment-specific values:

| What | Where | Default |
|------|-------|---------|
| Neb repo base path | `claude/.claude/agents/neb-explorer.md` | `~/repos/` |
| PR default reviewers | `shared/INSTRUCTIONS.md` → PR Defaults | `Chiropractic-CT-Cloud/phoenix` |
| Feature branch pattern | `claude/.claude/hooks/bash-permissions.json` → allow layer `"branch"` | `^mjb-pho-NEB-` |

## Attribution

See [ATTRIBUTION.md](ATTRIBUTION.md) for skill sources and credits.

---

## Personal Configuration

Personal config (shell, editor, etc.) is separated from AI tool config. These modules contain machine-specific settings and are not required for the AI tools to function.

```bash
./install-personal.sh    # Install all personal config
./uninstall-personal.sh  # Remove all personal config
```

### Brewfile

A `Brewfile` at the repo root tracks all Homebrew formulae, casks, and VSCode extensions.

```bash
cd ~/repos/dotfiles

# Install everything in the Brewfile
brew bundle

# Check what's missing vs the Brewfile
brew bundle check

# Re-dump current state (after manually installing something)
brew bundle dump --force
```

When adding a new tool, add it to the Brewfile and run `brew bundle` rather than `brew install` directly — this keeps the manifest in sync.

### Zsh

`zsh/.zshrc` is symlinked to `~/.zshrc`. Machine-specific secrets (API keys, tokens, credentials) go in `~/.zshrc.local`, which is:

- Sourced by `.zshrc` after oh-my-zsh init
- Excluded from the repo via `*.local` in `.gitignore`
- Protected from agent access via `settings.json` deny rules and bash-permissions path rules
