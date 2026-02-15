# Autonomous Coding Lanes via Ralph Wiggum Ecosystem

## Context

Goal: 4th-5th Claude Code windows that work autonomously with safety guarantees that don't depend on human prompts. The Ralph Wiggum ecosystem provides mature tooling for autonomous AI coding loops that integrate with Claude Code.

Key insight: existing deny rules + self-modification lockout provide hard safety regardless of human oversight. The `verification-before-completion` skill + `self-code-reviewer` agent already act as automated quality gates. The gap is narrow: `ask` rules for git commit/push/PR require human prompts, and there's no launcher for isolated workspaces.

**Safety model**: Human reviews the *output* (the PR), not each *step*. The agent cannot merge — `gh pr merge` stays in `ask`. Global deny rules and self-modification lockout remain in effect.

## Ralph Wiggum Landscape

"Ralph Wiggum" is an AI coding technique that runs agents in continuous loops until specs are fulfilled. Named after the Simpsons character — cheerful, relentless persistence. The core mechanism is a bash loop (`while :; do cat PROMPT.md | claude-code ; done`). Each iteration gets a fresh context window; progress persists in files and git history.

### Tool Comparison

| Tool | Approach | Safety | Parallel | Config Inheritance |
|------|----------|--------|----------|--------------------|
| **Official Ralph Plugin** | Stop hook loop inside session | Existing ask/deny rules | No | Full — runs in session |
| **parallel-cc** | E2B cloud sandboxes + worktrees | Sandbox isolation, file claims, AST conflict detection | Yes (default 3) | None — needs config sync |
| **ccpm** | GitHub Issues → worktrees → PRs | GH Issues audit trail, acceptance criteria | Yes | Partial — uses .claude/ in repo |
| **ralph-claude-code** | External wrapper with circuit breaker | Rate limiting (100/hr), circuit breaker (3 loops no progress), exit detection | No | Needs `--dangerously-skip-permissions` |
| **ralph-orchestrator** | Rust-based, 7 AI backends, "Hat System" | Backpressure via test/lint/typecheck | Yes | Multiple backend support |

### Tool Deep Dives

**Official Claude Code Ralph Wiggum Plugin** — A stop hook intercepts session exit and re-feeds the prompt. Commands: `/ralph-loop`, `/cancel-ralph`. Runs inside existing session so all skills, CLAUDE.md, settings.json permissions, and hooks apply. Safety: `--max-iterations` hard cap + `--completion-promise` exact string match. Limitation: single agent, no worktree isolation, no parallel dispatch.

**parallel-cc** — SQLite-tracked parallel sessions. Auto-creates git worktrees per agent. E2B cloud sandboxes for genuine isolation. File claim system with AST-based conflict detection. "Git Live mode" auto-pushes and creates PRs. Budget tracking. Limitation: E2B adds cost; sandboxed instances don't share local `~/.claude/` config.

**ccpm** — GitHub Issues as single source of truth. PRD → Technical Epic → Tasks → Issues → Parallel Execution. Bidirectional GitHub sync. Commands: `/pm:prd-new`, `/pm:prd-parse`, `/pm:epic-decompose`. Limitation: heavier process — full project management framework.

**ralph-claude-code** — Circuit breaker (stops after 3 loops without progress), rate limiting (100 API calls/hr), dual-condition exit detection, session management with 24h expiry. Per-project `.ralphrc` config. Limitation: requires `--dangerously-skip-permissions`.

---

## Recommended Adoption Path

### Phase 1: Official Ralph Plugin (Immediate)

Zero disruption. Install the plugin, test with `/ralph-loop`. All skills and permissions apply. Learn the iteration pattern with full safety.

No files to create/modify in dotfiles. Plugin installation only.

### Phase 2: parallel-cc for Multi-Agent Dispatch (Short-term)

Genuine parallel autonomous lanes with E2B sandboxing and worktree isolation. Solve the config sync gap with an autonomous settings template.

### Phase 3: Agent Teams (Long-term)

When Agent Teams exits research preview, migrate to the native solution for first-party config inheritance and parallel dispatch.

---

## What We'd Build (Minimal Custom Work)

Existing Ralph tools handle orchestration and sandboxing. We only build the **config bridge** between interactive setup and autonomous execution.

### Architecture

```
Interactive windows (unchanged)   Autonomous lanes (new)
─────────────────────────────     ──────────────────────────
~/repos/neb-ms-billing/           ~/repos/.worktrees/neb-ms-billing--fix-claim-calc/
  global settings (ask: commit)     project settings (allow: commit, push, PR)
  human in the loop                 PreToolUse hooks enforce quality gates
                                    output = PR for human review
```

### File 1: `claude/.claude/autonomous/settings.json`

Autonomous permission profile template. Copied into each worktree's `.claude/`. Derived from global settings.json with these changes:

| Rule | Global (interactive) | Autonomous |
|------|---------------------|------------|
| `git commit` | `ask` | `allow` |
| `git push` | `ask` | `allow` |
| `gh pr create` | `ask` | `allow` |
| `gh pr merge` | `ask` | **`ask` (unchanged)** |
| `gh pr close` | `ask` | `ask` (unchanged) |
| `gh issue close` | `ask` | `ask` (unchanged) |

Plus:
- All `deny` rules preserved verbatim
- `env.AUTONOMOUS_MODE = "true"`
- `PreToolUse` hooks for commit and PR quality gates

### File 2: `claude/.claude/autonomous/hooks/pre-commit-gate.sh`

PreToolUse hook. Matcher: Bash calls containing `git commit`.
- Checks for `.claude-test-passed` marker file in workspace
- Marker created by PostToolUse hook after successful test run
- Missing/stale marker → exit 2 (deny): "Tests must pass before committing."
- Present and fresh → exit 0 (allow)

### File 3: `claude/.claude/autonomous/hooks/post-test-marker.sh`

PostToolUse hook. Matcher: Bash calls containing `npm test`.
- Test passed (exit 0) → write timestamp to `.claude-test-passed`
- Test failed → delete marker if exists

### File 4: `claude/.claude/autonomous/hooks/pre-pr-gate.sh`

PreToolUse hook. Matcher: Bash calls containing `gh pr create`.
- Checks for `.claude-review-complete` marker
- Missing → exit 2 (deny): "Run self-code-reviewer before creating PR."
- Present → exit 0 (allow)

### File 5: `claude/.claude/commands/dispatch.md`

Slash command to dispatch an autonomous lane:

```
/dispatch ~/repos/neb-ms-billing fix/claim-calc "Fix the claim calculation bug in JIRA-1234"
```

The command:
1. Creates git worktree at `~/repos/.worktrees/<repo>--<branch>`
2. Copies autonomous settings template into worktree's `.claude/settings.json`
3. Detects test command from package.json
4. Launches `claude -p` in background with autonomous system prompt
5. Reports worktree path, log file, branch name

Works standalone for simple one-off dispatch, and alongside parallel-cc for managed parallel execution.

---

## Verification

1. **Plugin test**: Install official Ralph plugin, run `/ralph-loop` on a trivial task, verify skills fire and ask rules apply
2. **Hook tests**: Feed mock JSON to each gate hook, verify exit codes
3. **Dispatch test**: Run `/dispatch` on a test repo, verify worktree creation, settings copy, headless launch
4. **Safety test**: Verify autonomous agent cannot: modify `~/.claude/`, force push, rm -rf, read .env, merge PRs
5. **End-to-end**: Dispatch a real task, verify it tests, reviews, commits, pushes, creates PR

## Total Changes

| File | Action | Purpose |
|------|--------|---------|
| `claude/.claude/autonomous/settings.json` | Create | Autonomous permission profile |
| `claude/.claude/autonomous/hooks/pre-commit-gate.sh` | Create | Test gate before commits |
| `claude/.claude/autonomous/hooks/post-test-marker.sh` | Create | Marker when tests pass |
| `claude/.claude/autonomous/hooks/pre-pr-gate.sh` | Create | Review gate before PRs |
| `claude/.claude/commands/dispatch.md` | Create | `/dispatch` slash command |

**5 new files. No modifications to existing files. Interactive workflow untouched.**

## What NOT to Automate

- **PR merge** — always human-approved (the PR IS the review checkpoint)
- **Deployment** — autonomous lanes produce PRs, not deployments
- **Database migrations** — too risky for unattended operation
- **Global config changes** — self-modification lockout stays in effect
