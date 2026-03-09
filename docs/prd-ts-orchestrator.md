# PRD: TypeScript PRD-Loop Orchestrator

> Branch: feat/prd-loop-ts
> Status: Draft
> Date: 2026-03-09
> Prior art: `docs/prd-loop-vs-aac-vs-co-implement-2026-03-09.md`

## Problem & Outcome

The current prd-loop bash orchestrator (`prd-loop.sh`) works but has hit its ceiling: no structured error handling, fragile string manipulation, no multi-repo support, no parallel execution, and no PR automation. Meanwhile, auto-agent-codex has features we want (multi-repo, PRs, Playwright) but an architecture we don't (monolithic, no context isolation, no human gates).

**Outcome:** A TypeScript orchestrator that replaces `prd-loop.sh` with the same three-layer design (orchestrator → Claude → Codex), adding multi-repo support, PR boundary control, structured logging, and the co-implement spec format — while preserving fresh-context-per-phase and human approval gates.

## Package

Standalone repo: `prd-loop` (or similar) deployed to `~/repos/prd-loop`. Published under Martin's name. Not embedded in dotfiles — dotfiles consume it (e.g., Claude Code slash command calls the binary). Extract now; don't wait for others to ask.

## Scope

### In Scope

- TypeScript rewrite of the prd-loop state machine
- State file schema evolution (backward-compatible with existing `state.json`)
- Multi-repo worktree management
- PR boundary control (default: one PR per PRD, configurable per phase)
- Structured JSONL event logging
- Co-implement's spec template as the standard phase spec format
- Single-phase mode (`--single-phase`) to replace co-implement
- CLI interface: `prd-loop <prd.md>`, `prd-loop --resume`, `prd-loop --status`
- Circuit breaker, retry logic, consecutive failure tracking (ported from bash)

### Out of Scope (Future)

- Playwright/E2E validation (later hook)
- Parallel phase execution (requires dependency graph)
- Cost/token budget tracking
- Web dashboard / TUI
- Claude Code slash command wrapper (keep bash invocation for now)

## Requirements

### R1: State Machine (core loop)

The orchestrator is a deterministic state machine. It reads `state.json`, picks the next actionable task, dispatches it, updates state, and loops. No AI model runs inside the orchestrator — it's pure control flow.

**Task types and transitions:**

```
prd_decomposition → [phase_planning, phase_planning, ...]
phase_planning → phase_execution
phase_execution → phase_review
phase_review → phase_execution (remediation) | next phase_planning | pr_creation
pr_creation → done (or next pr_boundary group)
```

**State file schema:**

```typescript
interface PrdLoopState {
  version: "2.0";
  prd_path: string;
  project_name: string;
  branch: string;
  repos: RepoConfig[];           // NEW: multi-repo
  pr_strategy: "per_prd" | "per_boundary";  // NEW: PR control
  phases: Phase[];
  consecutive_failures: number;
  created_at: string;
  updated_at: string;
}

interface RepoConfig {
  path: string;                  // absolute path to repo root
  worktree_path?: string;       // if using isolated worktree
  branch: string;
  remote: string;               // default: "origin"
}

interface Phase {
  id: string;                    // e.g., "phase-01"
  title: string;
  description: string;
  repo: string;                  // which repo this phase targets
  status: "pending" | "planning" | "executing" | "reviewing" | "completed" | "failed" | "skipped";
  pr_boundary: boolean;          // NEW: should a PR be created after this phase?
  failed_count: number;
  tasks: Task[];                 // NEW: explicit sub-tasks
  spec_path?: string;           // path to phase spec file
  started_at?: string;
  completed_at?: string;
}

interface Task {
  task_id: string;
  type: "prd_decomposition" | "phase_planning" | "phase_execution" | "phase_review" | "pr_creation";
  status: "pending" | "in_progress" | "completed" | "failed";
  output_path?: string;
  error?: string;
  started_at?: string;
  completed_at?: string;
}
```

### R2: Phase Spec Format (from co-implement)

Every phase gets a spec file at `.prd-loop/specs/{phase-id}.md` using this template:

```markdown
## Goal
[One paragraph: what this phase builds and why. Codex reads this without conversation context.]

## Context
[Key files, existing patterns, relevant constants, current behavior.]

## Files to Modify
- `path/to/file.js` — [what to change and why]

## Files to Create
- `path/to/new-file.js` — [what it should contain]

## Do Not Touch
[Files and areas explicitly out of scope — prevents Codex drift.]

## Acceptance Criteria
- [ ] [Concrete, testable criterion]

## Constraints
[API contracts to maintain, patterns to follow, things not to break.]

## Verify
[Command to run to confirm correctness.]
```

Claude generates these during `phase_planning`. Codex consumes them during `phase_execution`.

### R3: Fresh Context Per Phase

Each `phase_planning` and `phase_execution` task spawns a new process with no accumulated context:

- **Planning:** `claude -p` with the phase prompt template + current codebase state
- **Execution:** `codex exec --full-auto` with the phase spec file contents
- **Review:** `claude -p` with the peer-review prompt + `git diff`

The orchestrator never passes conversation history between phases.

**Planning strategy:** Eager by default — all phase specs are generated during `prd_decomposition` so the human can review every spec before execution starts. `--lazy-planning` flag defers spec generation to right before each phase executes (better codebase accuracy for large PRDs where earlier phases change the landscape).

### R4: Multi-Repo Support

The PRD manifest can reference multiple repos:

```json
{
  "repos": [
    { "path": "/Users/me/repos/neb-ms-foo", "branch": "feat/thing" },
    { "path": "/Users/me/repos/neb-www", "branch": "feat/thing-ui" }
  ]
}
```

Each phase declares which repo it targets. The orchestrator `cd`s into the correct repo before dispatching. Branch creation and PR creation happen per-repo.

**Phase ordering:** Explicit in the PRD. The human specifies the order. During `prd_decomposition`, if the PRD doesn't specify ordering for multi-repo phases, Claude should interview: "These phases touch multiple repos — what order should they execute in?" and suggest a dependency-aware default (e.g., backend before frontend, types before consumers).

### R5: PR Boundary Control

Default behavior: one PR per PRD (all phases accumulate on a branch, PR created at the end).

Override: mark specific phases with `pr_boundary: true` in `state.json`. After a boundary phase completes review, the orchestrator creates a PR covering all commits since the last boundary (or branch start).

**PR defaults (beta):** Draft PRs with no reviewers. This is safe for autonomous workflows where the human reviews before marking ready. Configuration lives in `.prd-loop/config.json` (per-project) with a fallback to `~/.prd-loop/config.json` (global):

```json
{
  "pr": {
    "draft": true,
    "reviewers": [],
    "team_reviewers": [],
    "labels": ["prd-loop"]
  }
}
```

When ready to graduate from beta, flip `draft: false` and add reviewers. The config file is the single place to change this — no CLI flags to remember, no buried settings.

### R6: Structured Logging

All events written to `.prd-loop/logs/{run-id}.jsonl`:

```json
{"ts": "ISO", "event": "phase_start", "phase_id": "phase-01", "task_type": "phase_execution"}
{"ts": "ISO", "event": "codex_dispatch", "phase_id": "phase-01", "spec_path": "..."}
{"ts": "ISO", "event": "phase_complete", "phase_id": "phase-01", "commits": 2, "duration_ms": 45000}
{"ts": "ISO", "event": "review_verdict", "phase_id": "phase-01", "verdict": "pass", "findings": 0}
```

### R7: Human Approval Gate

After `prd_decomposition`, the orchestrator prints the proposed phases and pauses for confirmation (stdin prompt, same as current bash behavior). Execution does not start without explicit `y`.

In `--auto` mode (opt-in), the approval gate is skipped. However, `--auto` always runs a **preflight check** before starting execution:

**Preflight checks (run before first phase, bail early on failure):**

- All target repos exist and are clean (no uncommitted changes)
- `claude` and `codex` CLIs are authenticated and reachable
- `gh` CLI is authenticated and can reach the target org/repos
- Branch names don't already exist on the remote (unless `--resume`)
- PRD file parses correctly and references valid repo paths
- Disk space is sufficient for worktrees (if multi-repo)

If any preflight check fails, the orchestrator prints the failure and exits immediately — no hours wasted discovering a missing auth token on phase 7.

In interactive mode (default), preflight runs before the approval gate so the human sees any issues alongside the phase plan.

### R8: Single-Phase Mode (co-implement replacement)

`prd-loop --single-phase "add confetti to login page"` skips decomposition entirely:

1. Claude writes a single phase spec (using the co-implement spec template)
2. Human reviews spec
3. Codex executes
4. Peer review
5. User stages/commits

This replaces the standalone co-implement command.

### R9: Circuit Breaker & Retry

Ported from bash, now with proper error types:

- Max 3 retries per phase (configurable)
- Max 3 consecutive failures across phases → hard stop
- Failed phase cleanup: `git checkout -- . && git reset HEAD -- .` before retry
- Commit validation: if phase marked completed but `HEAD` unchanged, flag as silent failure

### R10: CLI Interface

```
prd-loop <prd.md>              # decompose + approve + execute
prd-loop --resume              # resume from existing state.json
prd-loop --status              # show current phase status
prd-loop --single-phase "..."  # co-implement mode
prd-loop --auto                # skip human approval gate
```

## Codebase Context

### Standalone package: `~/repos/prd-loop`

```
prd-loop/
├── package.json              # bin: { "prd-loop": "./dist/cli.js" }
├── tsconfig.json
├── src/
│   ├── cli.ts                # arg parsing, entry point
│   ├── orchestrator.ts       # state machine loop
│   ├── state.ts              # state file read/write/validate (zod)
│   ├── config.ts             # config file resolution (project → global)
│   ├── preflight.ts          # pre-execution checks
│   ├── dispatch/
│   │   ├── claude.ts         # spawn claude -p
│   │   ├── codex.ts          # spawn codex exec or use SDK
│   │   └── gh.ts             # gh pr create, gh auth status
│   ├── repos.ts              # multi-repo worktree management
│   └── log.ts                # JSONL event logger
├── prompts/                  # markdown templates (ported from prd-loop-prompts/)
│   ├── decompose.md
│   ├── phase-plan.md
│   └── phase-review.md
└── config/
    └── default.json          # shipped defaults (draft PRs, no reviewers)
```

### Dotfiles integration (consumers, not owners)

| Dotfiles file | Change |
|---|---|
| `claude/.claude/commands/prd-loop.md` | Updated to call `prd-loop` binary instead of `prd-loop.sh` |
| `claude/.claude/commands/co-implement.md` | Replaced with thin wrapper: calls `prd-loop --single-phase` |
| `claude/.claude/scripts/prd-loop.sh` | Deprecated (kept for reference, not invoked) |
| `claude/.claude/scripts/prd-loop-prompts/` | Deprecated (templates move into standalone package) |

### Files to keep (consumed by orchestrator, not modified)

- `codex/.agents/skills/create-prd/SKILL.md` — PRD creation (upstream of this system)
- `codex/.agents/skills/peer-review/SKILL.md` — review gate (invoked during `phase_review`)

### Dependencies

- `typescript` — language
- `@openai/codex-sdk` — Codex programmatic API
- `zod` — runtime state file validation
- No other runtime dependencies. Use Node built-ins (`child_process`, `fs/promises`) for everything else.

## Acceptance Criteria

- [ ] `prd-loop <prd.md>` decomposes a PRD into phases, gets human approval, executes all phases, creates one draft PR
- [ ] Each phase gets a fresh Claude/Codex context (no accumulated state)
- [ ] `state.json` is human-readable and hand-editable mid-run
- [ ] `prd-loop --resume` recovers from where it left off
- [ ] `prd-loop --single-phase "description"` replaces co-implement end-to-end
- [ ] Multi-repo: phases can target different repos, branches created per-repo, PRs created per-repo
- [ ] `pr_boundary: true` on a phase triggers PR creation at that point
- [ ] Circuit breaker stops after 3 consecutive failures
- [ ] JSONL log captures all events with timestamps
- [ ] Preflight checks run before execution; `--auto` bails early on preflight failure
- [ ] PRs default to draft with no reviewers; configurable via `.prd-loop/config.json`
- [ ] Eager planning by default; `--lazy-planning` defers spec generation per-phase
- [ ] Multi-repo phase ordering is explicit; decomposition interviews if ordering is ambiguous
- [ ] Existing prd-loop.sh POC behavior is preserved (no regression)

## Verification

```bash
# Smoke test: single-phase mode (replaces co-implement)
prd-loop --single-phase "add a health check endpoint to neb-ms-foo"

# Full test: decompose + execute a small PRD
prd-loop docs/prd-test-feature.md

# Resume test: kill mid-run, then resume
prd-loop --resume

# Status check
prd-loop --status
```

## Constraints

- Must work on macOS (darwin). Linux support is nice-to-have.
- Must not require global npm install — use `npx` or local `node_modules`.
- Must not store secrets in state files.
- Human approval gate is ON by default. `--auto` is opt-in only.
- `--auto` always runs preflight checks and bails early on failure — no silent hour-long failures.
- PR defaults: draft, no reviewers. Configurable via `.prd-loop/config.json`.

## Resolved Questions

1. **Standalone package vs dotfiles?** → Standalone repo at `~/repos/prd-loop`. Dotfiles consume it. Extract now; don't wait for demand.
2. **`--auto` safety?** → Preflight checks replace a paranoia flag. If preflight passes, the run is safe to proceed. If it fails, it bails immediately with a clear error. No hours wasted.
3. **Eager vs lazy planning?** → Eager by default (human reviews all specs before execution). `--lazy-planning` flag for large PRDs where earlier phases change the codebase significantly.
4. **Multi-repo ordering?** → Explicit in the PRD. During decomposition, Claude interviews the human if ordering is ambiguous and suggests dependency-aware defaults (backend before frontend, types before consumers).
