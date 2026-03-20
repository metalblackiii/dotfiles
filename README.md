# dotfiles

Personal configuration files for AI coding assistants, managed with Git and symlinks.

Currently supports **Codex**, **Claude Code**, **VS Code**, **Ghostty**, **Yazi**, and some **Git** configurations. Agent skills live in `codex/.agents/skills/` and agent instructions in `shared/INSTRUCTIONS.md` — both shared across Codex and Claude Code via symlinks.

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
├── AGENTS.md                # Project-level rules (dotfiles-specific)
├── CLAUDE.md                # Symlink → AGENTS.md
├── shared/                  # Cross-platform sources of truth
│   └── INSTRUCTIONS.md      # Global agent conventions, rules, preferences
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
│       ├── CLAUDE.md        # Symlink → ../../shared/INSTRUCTIONS.md (global rules)
│       ├── BASH-PERMISSIONS.md # Bash permissions context (included via project AGENTS.md)
│       ├── RTK.md           # RTK usage reference (included via project AGENTS.md)
│       ├── settings.json    # Permissions, hooks, env vars
│       ├── agents/          # 4 custom subagents
│       ├── commands/        # Slash commands (co-research)
│       ├── hooks/           # PreToolUse, PostToolUse, and SessionStart hooks
│       ├── scripts/         # Status bar, hooks
│       └── skills           # Symlink → ../../codex/.agents/skills
├── ghostty/                 # Ghostty terminal configuration (personal)
│   ├── install.sh
│   ├── uninstall.sh
│   └── config.ghostty       # Ghostty config → ~/Library/Application Support/com.mitchellh.ghostty/config.ghostty
├── vscode/                  # VS Code configuration (personal)
│   ├── install.sh
│   ├── uninstall.sh
│   └── settings.json        # User settings → ~/Library/Application Support/Code/User/settings.json
├── yazi/                    # Yazi file manager configuration (personal)
│   ├── install.sh
│   ├── uninstall.sh
│   └── yazi.toml            # Yazi config → ~/.config/yazi/yazi.toml
├── zsh/                     # Zsh shell configuration (personal)
│   ├── install.sh
│   ├── uninstall.sh
│   ├── .zshrc               # Shell config → ~/.zshrc
│   └── .p10k.zsh            # Powerlevel10k prompt config → ~/.p10k.zsh
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
| `mysql-client` | Optional | `brew install mysql-client` | `db-query` skill (live MySQL database queries via login paths) |
| `snyk` | Optional | `brew tap snyk/tap && brew install snyk` | `snyk-expert` skill, vulnerability scanning. Run `snyk auth` after install to authenticate. |
| `rtk` | Optional | `brew install rtk` | Token-optimized CLI proxy (60-90% savings) |

#### Optional Security Tooling (Only for `security-review` Scanner Mode)

The security skills work without additional installs. Extra tooling is optional and only used for deeper scan automation.

**Recommended:** `gitleaks` + `trivy` + `snyk` cover all five scanning lanes (secrets, dependencies, containers, IaC, SAST) with no gaps. `snyk` is listed above and requires authentication.

| Tool | Install | Coverage |
|------|---------|----------|
| `gitleaks` | `brew install gitleaks` | Secret scanning (git history) — sole coverage, no overlap |
| `trivy` | `brew install trivy` | Dependencies, container images, IaC misconfigs |
| `semgrep` | `brew install semgrep` | SAST (static analysis). Optional — Snyk Code covers this lane; both together add depth |
| `checkov` | `pip install checkov` | IaC policy checks. Optional — trivy covers IaC basics. Requires `python3`/`pip` |

If these tools are unavailable, `security-review` falls back to manual review and reports which scans were not executed.

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

#### Skills (48)

Specialized methodologies that activate automatically when relevant tasks are detected. The `developer_instructions` in `config.toml` enforce "The Iron Law" — check for applicable skills before responding to non-trivial requests.

| Skill | When it activates |
|-------|-------------------|
| **agents-md** | Writing, auditing, or improving AGENTS.md, CLAUDE.md, or AI agent instruction files |
| **api-designer** | Designing REST endpoints, versioning strategy, request/response contracts |
| **ast-grep-patterns** | Large refactors, structural code pattern searches, API migrations |
| **audit-skills** | Reviewing skill adoption, finding dormant skills, measuring effectiveness |
| **auto-review** | Automated PR review with domain-expert panel, batch comment approval, and 30-minute re-review loop. Manual invoke only (`/auto-review`) |
| **babysit-loop** | Monitor a running prd-loop session. Designed for use with `/loop` |
| **bash-expert** | Create, generate, validate, lint, audit, or fix bash/shell scripts |
| **batch-repo-ops** | Applying the same operation across multiple repos with batched sub-agents, rate limit awareness, and status tracking |
| **cli-developer** | Building CLI tools, argument parsing, interactive prompts, shell completions |
| **code-renovator** | Refactoring discipline, code smells, incremental legacy migrations, strangler fig patterns |
| **create-prd** | Define what to build before running an agentic loop, formalize a feature idea, convert a ticket into an implementation-ready PRD, or write feature specs with structured requirements |
| **creating-neb-patch-pr** | Creating patch PRs for merged main PRs in neb repos for hotfix deployment |
| **database-expert** | SQL queries, schema design, Aurora migrations, Sequelize tuning, index strategies |
| **db-query** | Execute queries against live MySQL databases using mysql-client with login paths |
| **dockerfile-expert** | Create, generate, validate, lint, scan, audit, or optimize Dockerfiles |
| **gha-expert** | Create, generate, validate, lint, audit, fix, or diagnose GitHub Actions workflows and CI/CD pipeline failures |
| **handoff** | Ending sessions with work in progress with context saved in a doc for a fresh session |
| **helm-expert** | Create, scaffold, generate, validate, lint, audit, or check Helm charts |
| **introspect** | Auditing agent configuration for conflicts, redundancy, staleness, prompt quality |
| **k8s-expert** | Diagnose, troubleshoot, and fix Kubernetes clusters, pods, networking, storage, and rollout failures |
| **loop-postmortem** | Structured post-mortem after a prd-loop run completes or crashes |
| **mcp-expert** | Evaluate, build, debug, or extend MCP servers and clients (vetting + development) |
| **neb-ms-conventions** | Code conventions used in neb microservice repositories |
| **neb-playwright-expert** | Writing, debugging, or planning E2E tests in neb-www's Playwright infrastructure |
| **peer-review** | Multi-round code review using an isolated agentic reviewer with progressive verdict thresholds |
| **playwright-cli** | Browser automation via playwright-cli CLI (navigation, forms, screenshots, data extraction) |
| **pr-analysis** | Reviewing PR/git diffs for quality, security, architecture, testing |
| **pr-review-queue** | Consolidated dashboard for PRs where you are a reviewer, with action buckets and next-step triage |
| **pr-status-report** | Consolidated dashboard for open GitHub PRs with action buckets and next-step triage |
| **prompt-engineer** | LLM prompt design, evaluation frameworks, structured outputs |
| **ptjira-cli** | Interacting with Jira via `ptjira` CLI — ticket lookup, search, context, comments, updates, attachments |
| **quick-wins** | Repo scan for low-risk improvements — reports findings without making changes |
| **ratchet** | Autonomous metric-driven iteration — interview, loop (change → verify → keep/restore), hand off for review. Manual invoke only (`/ratchet`) |
| **requirements-analyst** | Surfacing ambiguities, risks, and gaps in requirements before engineering |
| **review** | PR review for architecture, testing, code quality, security |
| **secure-code-guardian** | Implementing security controls (auth/authz, validation, secrets, encryption, headers) |
| **security-review** | Dedicated security audit/deep-dive review beyond normal PR quality gates |
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

### Instructions (Two Layers)

**Global** — `shared/INSTRUCTIONS.md` is symlinked as `claude/.claude/CLAUDE.md` and `codex/AGENTS.md`, loaded in every repo:

- **Git preferences** — conventional commits, explicit commit/push approval
- **PR defaults** — reviewers, gh flags
- **Code quality** — preparatory refactoring, Rule of Three, fix broken windows
- **Security** — HIPAA context, no PII in examples, no hardcoded secrets
- **Self-documenting code** — rename over comment, only "why" comments

**Project-level** — `AGENTS.md` (with `CLAUDE.md` symlinked to it) at the repo root, loaded only in the dotfiles repo:

- **Canonical editing** — always edit in the dotfiles repo, never via symlinked paths
- **Bash permissions** — rule format, layers, test suite for `bash-permissions.json`
- **RTK** — Rust Token Killer usage reference

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

No MCP servers currently have explicit tool permissions in `settings.json`. Servers are added to `~/.claude.json` (user scope) and all their tools default to prompting for confirmation.

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

#### CLI Tools (`claude/bin/`)

| Tool | Purpose |
|------|---------|
| **claude-backup** | Back up Claude Code runtime data (sessions, history, usage-data) to `~/.claude-backup/<timestamp>` |
| **claude-restore** | Restore from backup with non-destructive merge (`-n` dry run, `-l` list backups) |

#### Hooks & Scripts

- **session-start.sh** — SessionStart hook. Fires on startup, resume, clear, and compact. Injects the `using-skills` guidance and enforces skill-first workflow.
- **rtk-rewrite.sh** — PreToolUse hook that transparently rewrites Bash commands through [RTK](https://github.com/rtk-ai/rtk) for token savings. Silently no-ops if `rtk` or `jq` aren't installed.
- **bash-permissions.sh** + **bash-permissions.json** — PreToolUse hook that enforces layered Bash permission rules (deny, sensitive paths, branch-conditional allow, ask). Rules are externalized to JSON for easy editing.
- **eslint-autofix.sh** — PostToolUse hook that auto-runs ESLint `--fix` after Edit/Write operations on JS/TS files.
- **context-bar.sh** — Status line script showing model, git branch, uncommitted files, sync status, and context usage percentage.
- **claude-guard.sh** (zsh) — `npm` wrapper that auto-triggers `claude-backup` before `npm uninstall ... claude-code` to prevent runtime data loss.

#### Permissions

Claude Code permissions are split across two layers that handle different tool types. (Codex uses `approval_policy` in `config.toml` — see [Codex Configuration](#codex-configuration).)

##### Non-Bash Tools (`settings.json`)

The `permissions` block in `settings.json` controls Claude Code's built-in tools (Read, Edit, Write, Glob, Grep, WebFetch, WebSearch). These use glob-based path matching:

- **Allowed**: all built-in tools, `Bash(*)`, scoped web access
- **Denied**: Read/Edit/Write of `.env*` files, `/secrets/`, `.pem`/`.key` files, `~/.aws/`, `~/.ssh/`, `~/.config/`, `~/.mylogin.cnf`, shell configs (`~/.zshrc`, `~/.bashrc`, `~/.gitconfig`), private local overrides (`~/.*.local`), and the symlinked `~/.claude/` config files (prevents the agent from modifying its own configuration)

##### Bash Commands (`bash-permissions.sh` + `bash-permissions.json`)

All Bash permission rules are enforced by a PreToolUse hook — not by `settings.json`. The hook runs regex against the full command string, which is more reliable than glob matching for compound commands, pipes, and heredocs.

Rules live in `bash-permissions.json` and are evaluated in four layers. The script processes layers in a fixed order (deny → paths → allow → ask); the JSON key order is cosmetic.

| Layer | Decision | Purpose |
|-------|----------|---------|
| **deny** | Block | Unconditionally blocked. Optional `"nudge"` message guides Claude toward the right tool. |
| **paths** | Block | Blocks commands referencing sensitive file patterns (`.env`, `/secrets/`, `.pem`, `~/.aws/`, `~/.ssh/`, `~/.config/`, `~/.mylogin.cnf`, shell configs). Uses `__HOME__` placeholder expanded at runtime. |
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

Current global ignores are defined in `git_ai/.gitignore_global`. Keep the README high-level and treat that file as the source of truth.

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

### Ghostty

`ghostty/config.ghostty` is symlinked to `~/Library/Application Support/com.mitchellh.ghostty/config.ghostty`. Edit the dotfiles copy to change Ghostty settings.

### Yazi

`yazi/yazi.toml` is symlinked to `~/.config/yazi/yazi.toml`. A `y` shell wrapper in `zsh/omz-custom/aliases.zsh` provides cd-on-exit behavior (quit with `q` to cd, `Q` to stay).

### Zsh

`zsh/.zshrc` is symlinked to `~/.zshrc`. Machine-specific secrets (API keys, tokens, credentials) go in `~/.zshrc.local`, which is:

- Sourced by `.zshrc` after oh-my-zsh init
- Excluded from the repo via `*.local` in `.gitignore`
- Protected from agent access via `settings.json` deny rules and bash-permissions path rules
