# Auto-Agent-Codex vs PRD-Loop vs Co-Implement

> Comparative analysis of three PRD-to-implementation orchestration systems.
> Date: 2026-03-09

## What Each System Is

| | **Auto-Agent-Codex (AAC)** | **PRD-Loop** | **Co-Implement** |
|---|---|---|---|
| **Purpose** | Autonomous PRD→PR pipeline | Phased PRD execution with human gates | Single-feature delegation to Codex |
| **Orchestrator** | Node.js (Codex SDK) | Bash script + Claude `-p` | Claude Code slash command (interactive) |
| **Autonomy** | Fully autonomous loop | Semi-autonomous (human approval gate) | Interactive (human in the loop) |
| **Scope** | Multi-PRD projects | Single PRD, multi-phase | Single feature or multi-spec batch |
| **State** | `task_memory.json` (task queue) | `state.json` + `progress.txt` | `.co-implement/` artifacts (ephemeral) |
| **Platform** | Codex-only | Bash → Claude → Codex (3-layer) | Claude Code (delegates to Codex) |

---

## Architecture

### AAC: SDK-Driven Agent Loop

```
run-agent-codex.mjs (Codex SDK)
  └─ Task Memory JSON (central router)
       ├─ planning tasks → decompose PRD into phases
       ├─ execution tasks → implement + create PR
       └─ pr_review tasks → review → inject remediation
```

- Single process, long-running
- Codex SDK `Thread` + `runStreamed` for each task
- All routing is task-type dispatch inside one JS file (82KB)
- Version manifest for remote update checks

### PRD-Loop: Deterministic Bash Shell

```
prd-loop.sh (bash)
  ├─ claude -p (fresh context per phase)
  │    ├─ plan spec
  │    ├─ peer-review
  │    └─ codex exec (implements one spec)
  └─ state.json + progress.txt (file-backed)
```

- Each phase gets a **fresh Claude context** — zero accumulated context rot
- Bash controls retry logic, circuit breaker, branch management
- Template-based prompts (`$PROMPT_DIR/decompose.md`, `$PROMPT_DIR/phase.md`)
- Claude is stateless; Codex is stateless; bash is the memory

### Co-Implement: Interactive Command

```
Claude Code session (interactive)
  ├─ Step 2: Write spec → .co-implement/spec.md
  ├─ Step 4: codex exec --full-auto "$(<spec.md)"
  ├─ Step 5: Review diff against acceptance criteria
  ├─ Step 6: peer-review (isolated agent)
  └─ Step 7: User stages/commits
```

- Runs inside a single Claude Code conversation
- Spec-driven handoff (self-contained context for Codex)
- Max 3 Codex passes per spec with follow-up narrowing
- Off-rails detection with `git stash` safety net

---

## Pros & Cons

### Auto-Agent-Codex

**Pros:**

- Fully autonomous — fire and forget with a PRD manifest
- Multi-PRD support out of the box (`prd_list.json`)
- PR-based workflow (creates real PRs for each phase)
- Remediation loops are automatic (review → fix → re-review)
- Experimental Playwright validation for E2E coverage
- Bootstrap wizard lowers onboarding friction
- JSONL event logs for post-mortem debugging
- Version manifest for self-update awareness

**Cons:**

- **Monolithic runner** — 82KB single JS file is hard to maintain/debug
- **No human gate before execution** — plans execute immediately (risky for production repos)
- **Codex-only** — tied to OpenAI's Codex SDK, no Claude Code path
- **Heavy dependencies** — requires Node 24+, npm, gh, Codex CLI
- **No fresh context isolation** — long-running agent accumulates context within a task
- **No circuit breaker for consecutive failures** (bash loop has one; JS loop relies on `max-turns`)
- **Bootstrap wizard is brittle** — interactive CLI with many edge cases
- PR review is self-review (same model reviews its own work, no context isolation)

### PRD-Loop

**Pros:**

- **Fresh context per phase** — the strongest architectural win; eliminates context rot
- **Deterministic orchestration** — bash is predictable, debuggable, inspectable
- **Circuit breaker** — 3 consecutive failures stops the loop
- **Human approval gate** — review phases before execution starts
- **State is human-editable** — you can manually tweak `state.json` mid-run
- **Portable** — bash + jq + claude + codex, no Node/npm needed
- **Clean separation** — each layer does one thing (bash=loop, Claude=plan, Codex=implement)
- **Peer review with context isolation** — reviewer agent has no implementation context
- **Proven** — POC validated end-to-end (3 phases, 0 retries, caught real bug)

**Cons:**

- **Single PRD at a time** — no manifest for batching multiple PRDs
- **No PR creation** — commits to a branch but doesn't create PRs per phase
- **No Playwright/E2E validation loop** — manual testing required
- **Prompt templates are separate files** — harder to see the full workflow at a glance
- **Bash limitations** — error handling is crude compared to a real language; complex string manipulation is fragile
- **No event logging** — progress.txt is human-readable but not machine-parseable
- **Codex sandbox constraints** — can't run browser-based tests (Karma, etc.)
- **Overhead for tiny phases** — 1-line changes still spin up full Claude + Codex

### Co-Implement

**Pros:**

- **Interactive** — human stays in the loop, can course-correct at every step
- **Spec quality** — Claude writes a rich, codebase-grounded spec before handing off
- **Multi-spec batching** — sequential processing with per-spec tracking
- **Off-rails detection** — stashes unexpected changes instead of losing them
- **File snapshotting** — tracks exactly which files each spec changed
- **Peer review gate** — isolated reviewer catches issues before staging
- **User controls git** — never auto-commits, `git add -p` recommended
- **Lightweight** — no external tooling beyond Codex CLI

**Cons:**

- **Single-session context** — runs in one Claude Code conversation (subject to context limits)
- **No persistence across sessions** — if you close the terminal, state is lost
- **No decomposition** — works at spec level, not PRD→phase level
- **Max 3 passes is arbitrary** — some tasks need more iteration
- **No branch management** — doesn't create or switch branches
- **Manual orchestration** — you have to invoke the command and babysit it
- **No retry/resume** — if Codex fails partway, you start over

---

## Feature Matrix

| Feature | AAC | PRD-Loop | Co-Implement |
|---|:---:|:---:|:---:|
| PRD decomposition | Yes | Yes | No (spec-level) |
| Fresh context per phase | No | **Yes** | No |
| Human approval gate | No | **Yes** | **Yes** (per step) |
| Multi-PRD support | **Yes** | No | No |
| Multi-spec batching | No | No | **Yes** |
| PR creation per phase | **Yes** | No | No |
| Remediation loops | **Yes** | Via retry | Via follow-up spec |
| Context-isolated review | No | **Yes** | **Yes** |
| Circuit breaker | No | **Yes** | Max 3 passes |
| Playwright/E2E validation | **Yes** (experimental) | No | No |
| Resumable across sessions | **Yes** | **Yes** (`--resume`) | No |
| Event logging | **Yes** (JSONL) | No | No |
| Branch management | **Yes** | **Yes** | No |
| Bootstrap/onboarding | **Yes** (wizard) | No | No |
| State human-editable | Partially | **Yes** | N/A |
| Platform | Codex SDK only | Bash + Claude + Codex | Claude Code + Codex |

---

## What's Missing (Across All Three)

1. **Unified pipeline**: No way to go `create-prd` → `prd-loop` → `co-implement` seamlessly. Each is a separate invocation with manual handoffs.

2. **Observability dashboard**: AAC has JSONL logs but no viewer. PRD-loop has progress.txt but it's unstructured. None have a web UI or TUI for real-time monitoring.

3. **Rollback on failure**: None can automatically revert a phase that left the codebase in a broken state. PRD-loop's bash cleanup (`git checkout -- .`) is the closest, but it's best-effort.

4. **Parallel phase execution**: All three are strictly sequential. Independent phases (e.g., adding types + adding docs) could run in parallel.

5. **Cost/token tracking**: None track API costs or token usage per phase. AAC logs events but doesn't aggregate costs.

6. **Human review of PRs**: AAC creates PRs but doesn't wait for human approval before proceeding to the next phase. The review is automated only.

7. **Cross-repo coordination**: None handle features that span multiple repos (e.g., backend + frontend). `batch-repo-ops` exists but doesn't integrate with these flows.

8. **Test-aware decomposition**: Phase decomposition doesn't analyze the test suite to determine which tests cover which phase. Phases can't validate they didn't break unrelated tests efficiently.

---

## Decisions (2026-03-09)

After evaluating all three systems, the following decisions were made:

### 1. Rewrite prd-loop as a TypeScript orchestrator

Bash worked for the POC but has hit its ceiling: no structured error handling, fragile string manipulation, no ability to run phases in parallel. TypeScript gives type-safe state management, proper async/await for Codex SDK calls, and direct `@openai/codex-sdk` imports. The three-layer separation stays — TS is still just the deterministic orchestrator. Claude and Codex remain stateless.

### 2. Decouple commit granularity from PR granularity

AAC's one-PR-per-phase approach produces too many small PRs that are hard to review. Phases should stay small (≤400 LOC commits), but the orchestrator accumulates phases into a **single PR per logical feature or per PRD**. A `pr_boundary: true` flag on specific phases in `state.json` allows manual PR break points for truly large PRDs. Default: one PR after all phases complete.

### 3. Add multi-repo support

This is where TypeScript pays off. The bash loop is fundamentally single-directory. A TS orchestrator can manage multiple worktrees, run phases across repos in sequence (or parallel for independent repos), and coordinate branches. The state file grows from tracking phases to tracking `{repo, phase}` tuples. The existing `batch-repo-ops` skill has the discovery pattern — the orchestrator consumes it.

### 4. Separate PRD decomposition from phase planning

AAC's `planning → phase_planning → execution → review` cascade is good. prd-loop currently collapses PRD decomposition and phase planning into one Claude call. Separating them — first decompose the PRD into phases, then plan each phase individually right before execution — produces better specs because the phase planner sees the current codebase state (which may have changed from prior phases). Make this an explicit task type in the state machine so it's trackable and retriable independently.

### 5. Codex for autonomous, Claude for interactive

The TS orchestrator uses Codex for all implementation tasks (cheap, autonomous, sandboxed) and Claude only for planning/review (where reasoning quality matters). The orchestrator itself doesn't need either model — it's pure state machine logic. This is an economic decision: Codex tokens are cheaper for bulk autonomous work, Claude stays available for day-to-day interactive use.

### 6. Retire co-implement as a standalone command

Co-implement becomes a thin wrapper: `prd-loop --single-phase "feature description"`. Internally it uses the same TS orchestrator with `phases: 1`. The spec template from co-implement (Goal, Context, Files to Modify, Do Not Touch, Verify) is promoted to the standard phase spec format — it's more detailed than prd-loop's current phase descriptions.

### Convergence Path

1. Rewrite prd-loop.sh as a TS orchestrator (keep the same state.json schema, add task types)
2. Adopt co-implement's spec template as the phase spec format
3. Add PR boundary control (default: one PR per PRD)
4. Add multi-repo support via worktree management
5. Retire co-implement as standalone; alias it to single-phase mode
6. Port AAC's Playwright validation as an optional post-PR hook

---

## Appendix: Original Recommendations (Pre-Decision)

### Quick Wins (superseded by TS rewrite)

- ~~Add `--create-pr` flag to prd-loop.sh~~ → Built into TS orchestrator
- ~~Add `--resume` to co-implement~~ → Co-implement retired into prd-loop
- ~~Structured progress log for prd-loop~~ → JSONL logging in TS orchestrator
- ~~Branch management in co-implement~~ → Handled by orchestrator

### Medium-Term (incorporated into decisions)

- ~~Extract AAC's PR review into a shared skill~~ → peer-review skill is the standard
- ~~Backport fresh-context-per-phase to AAC~~ → TS orchestrator inherits this from prd-loop
- ~~Add human gates to AAC~~ → TS orchestrator has approval gates by default
- ~~Merge co-implement's spec template~~ → Decision #6

### Longer-Term (still relevant)

- **Parallel phase execution** — detect phase dependencies and run independent phases concurrently (separate worktrees or branches)
- **Cost budget** — set a token/dollar budget per PRD; track usage per phase; stop or warn when approaching the limit
- **Playwright validation** — port AAC's experimental Playwright loop as optional post-PR hook
- **Web dashboard** — local UI that reads state files and shows phase progress, diffs, review results, and logs

---

## Bottom Line

**PRD-Loop** has the strongest architecture (fresh context per phase, deterministic orchestration, human gates). The path forward is rewriting its bash orchestrator in TypeScript, absorbing co-implement's spec format and AAC's multi-repo + PR automation features, while keeping the core three-layer design intact.

See: `docs/prd-ts-orchestrator.md` for the implementation PRD.
