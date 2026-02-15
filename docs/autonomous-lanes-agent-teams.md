# Autonomous Coding Lanes via Agent Teams

## Context

Goal: 4th-5th Claude Code windows that work autonomously with safety guarantees that don't depend on human prompts. Agent Teams is the best long-term fit — it's first-party, inherits full config (CLAUDE.md, skills, permissions), and has built-in quality gate hooks (`TaskCompleted`, `TeammateIdle`).

Agent Teams is experimental (behind a feature flag) but usable today. The plan: enable it, add quality gate hooks, and run controlled trials to evaluate whether the current state is reliable enough for semi-autonomous operation.

## Agent Teams — How It Maps to Our Needs

| Need | Agent Teams Capability |
|------|----------------------|
| Autonomous coding lanes | Teammates are full Claude Code sessions working in parallel |
| Safety without prompts | `TaskCompleted` hook enforces tests before task completion |
| Config inheritance | Teammates load CLAUDE.md, skills, and permissions automatically |
| PR-based output | Teammates can commit/push/create PRs (subject to permission rules) |
| Human reviews output | Lead synthesizes results; human reviews the PR |
| No merge without approval | `gh pr merge` stays in `ask` — teammates can't merge |

### Key Hooks for Quality Gates

**`TaskCompleted`** — fires when a teammate marks a task complete. Exit code 2 blocks completion and sends feedback. This replaces human approval with automated checks:

```bash
# If tests aren't passing, teammate can't mark task done
if ! npm test 2>&1; then
  echo "Tests failing. Fix before completing task." >&2
  exit 2
fi
```

**`TeammateIdle`** — fires when a teammate finishes and is about to stop. Exit code 2 sends feedback and keeps them working. Can enforce review before stopping.

### Architecture

```
You (lead session)
  ├── Teammate 1 (full Claude Code instance, own context)
  ├── Teammate 2 (full Claude Code instance, own context)
  └── Teammate 3 ...

Communication: mailbox messaging (direct + broadcast)
Coordination: shared task list with dependency tracking + self-claim
Config: all teammates inherit CLAUDE.md, skills, permissions from lead
Display: in-process mode (Shift+Up/Down to cycle, Ctrl+T for tasks)
```

### How to Start

Enable feature flag in `settings.json`:
```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

Then in a session:
```
Create a team with 2 teammates:
- Teammate 1: add unit tests for claim-calculation.service.js
- Teammate 2: add unit tests for payment-reconciliation.service.js
Each should run tests and commit when done. Use conventional commit style.
```

### Known Limitations (as of Feb 2026)

| Issue | Impact | Workaround |
|-------|--------|------------|
| No per-teammate tool restriction | Can't give researcher read-only, implementer write | Specify constraints in spawn prompt |
| Delegate mode broken (#25037) | Lead can't be coordination-only | Don't use delegate mode; lead does light coordination |
| No custom agent .md as teammates (#24316) | Can't use self-code-reviewer as a teammate | Load skills via natural language prompt |
| No session resumption | Can't resume after disconnect | Keep sessions short; use handoff skill |
| No file conflict prevention | Two teammates can overwrite each other | Decompose work by file ownership |
| Inbox polling issues on macOS/tmux (#23415) | Messages may not deliver | Use `in-process` mode instead of tmux |

---

## What We'd Build

### 1. Enable Agent Teams

Add to `~/repos/dotfiles/claude/.claude/settings.json` env section:
```json
"CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
```

### 2. TaskCompleted Quality Gate Hook

**File**: `~/repos/dotfiles/claude/.claude/hooks/task-completed-gate.sh`

Fires on every `TaskCompleted` event. Enforces:
1. Read task subject from stdin JSON
2. Detect project test command (check `package.json` for `test` script, default to `npm test`)
3. Run tests — if failing, exit 2 with feedback
4. Check for `.claude-review-complete` marker — if missing, exit 2
5. If all gates pass, exit 0

### 3. TeammateIdle Check Hook

**File**: `~/repos/dotfiles/claude/.claude/hooks/teammate-idle-check.sh`

Fires when a teammate is about to stop. Checks:
1. Were there any uncommitted changes? If so, exit 2: "You have uncommitted changes. Commit or explain why before stopping."
2. Otherwise, exit 0 (allow idle)

### 4. Register Hooks in settings.json

Add to `hooks` section:
```json
"TaskCompleted": [{
  "hooks": [{
    "type": "command",
    "command": "bash ~/.claude/hooks/task-completed-gate.sh"
  }]
}],
"TeammateIdle": [{
  "hooks": [{
    "type": "command",
    "command": "bash ~/.claude/hooks/teammate-idle-check.sh"
  }]
}]
```

### 5. Teammate Display Mode

Add top-level to settings.json:
```json
"teammateMode": "in-process"
```

Using `in-process` avoids the macOS tmux inbox polling bug (#23415).

---

## Trial Protocol

### Trial 1: Supervised Parallel Research (Low Risk)

**Goal**: Verify Agent Teams works with config, hooks fire, teammates load skills.

```
Create a team with 2 teammates to investigate the neb-ms-billing codebase:
- Teammate 1: trace the claim calculation flow from controller to model
- Teammate 2: find all cross-service calls from billing to other services
Report findings back to me.
```

**Verify**:
- Teammates load CLAUDE.md and skills
- `ask` rules still apply (if teammates try to commit)
- TeammateIdle hook fires when teammates finish
- Can Shift+Up/Down to see teammate work

### Trial 2: Supervised Parallel Implementation (Medium Risk)

**Goal**: Test file editing, commits, and quality gates with teammates.

**Verify**:
- TaskCompleted hook blocks completion if tests fail
- Teammates don't edit the same files (decomposed by file ownership)
- Commits follow conventional style
- `ask` rules prompt for commit approval

### Trial 3: Semi-Autonomous (High Confidence)

**Goal**: Let the team work with minimal intervention. Monitor but don't drive.

**Prerequisite**: Trials 1-2 succeeded. Hooks are reliable. Quality gates trusted.

---

## Comparison: Three Options Side-by-Side

| Dimension | Agent Teams | Subagents (Task tool) | Manual Worktrees |
|-----------|------------|----------------------|-----------------|
| **Autonomy** | High — teammates self-coordinate | Medium — report back to caller | Low — human coordinates |
| **Parallel** | Native (multiple teammates) | Yes (multiple Task calls) | Yes (separate terminals) |
| **Config inheritance** | Full (CLAUDE.md, skills, permissions) | Partial (configurable per agent) | Full (project-level settings) |
| **Tool control** | All tools, no per-teammate restriction | Fine-grained per agent | Full (project-level settings) |
| **Quality gates** | `TaskCompleted` + `TeammateIdle` hooks | Via skills only (soft enforcement) | Via project-level hooks |
| **Communication** | Teammates message each other | Results return to caller only | None (human relays) |
| **File conflict risk** | Possible (no prevention) | Low (subagents rarely edit files) | None (separate directories) |
| **Cost** | ~7x standard for full team | Lower (results summarized) | Standard per session |
| **Maturity** | Experimental | Production | Production |
| **Best for** | Parallel implementation + coordination | Focused research/review tasks | Fully isolated autonomous work |

---

## Total Changes

| File | Action | Purpose |
|------|--------|---------|
| `claude/.claude/settings.json` | Modify | Add feature flag, hooks, teammateMode |
| `claude/.claude/hooks/task-completed-gate.sh` | Create | Test + review gate on task completion |
| `claude/.claude/hooks/teammate-idle-check.sh` | Create | Prevent silent work-dropping |

**3 files total. 1 modified, 2 new.**

## What NOT to Automate

- **PR merge** — always human-approved
- **Deployment** — teams produce PRs, not deployments
- **Database migrations** — too risky for unattended operation
- **Teammate tool restrictions** — wait for #24316 to be resolved
