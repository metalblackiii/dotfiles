# GBB Tool Learning Lab: Ralph-Orchestrator vs ptek-ai-playbook

Date: 2026-02-24  
Purpose: Build operator-level understanding of both tools without running a full autonomous implementation cycle.

## Usage Model

This lab is read/inspect-first. Commands are designed to answer:

1. How each tool is structured
2. How each tool controls loops and safety
3. How each tool handles review/remediation and resume
4. Where each tool is currently weak

## Environment Setup

```bash
RALPH_REPO=/tmp/ralph-orchestrator
PTEK_REPO=/Users/martinburch/repos/ptek-ai-playbook/experimental/auto-agent-codex
```

If needed, clone Ralph first:

```bash
git clone --depth 1 https://github.com/mikeyobrien/ralph-orchestrator.git "$RALPH_REPO"
```

## Lab A: `ralph-orchestrator` (5 commands)

### A1) Product model and capabilities

```bash
cd "$RALPH_REPO" && rg -n "hat-based orchestration|Multi-Backend Support|Backpressure|Memories & Tasks|RObot" README.md
```

What to learn: What Ralph claims to be and its primary building blocks.

### A2) Backend support and Codex position

```bash
cd "$RALPH_REPO" && rg -n "Supported Backends|Codex|auto-detect|OPENAI_API_KEY|CODEX_API_KEY" docs/guide/backends.md
```

What to learn: How Codex fits into backend strategy and auth expectations.

### A3) Hard loop controls and defaults

```bash
cd "$RALPH_REPO" && rg -n "max_iterations|max_runtime_seconds|max_cost_usd|max_consecutive_failures|persistent|completion_promise" crates/ralph-core/src/config.rs
```

What to learn: Default safety and termination boundaries.

### A4) Runtime loop behavior and recovery

```bash
cd "$RALPH_REPO" && rg -n "check_termination|check_completion_event|inject_fallback_event|process_events_from_jsonl|human.interact|human.response" crates/ralph-core/src/event_loop/mod.rs
```

What to learn: How Ralph detects completion, recovers stalls, and handles human blocking flows.

### A5) Codex invocation + operational concurrency

```bash
cd "$RALPH_REPO" && rg -n "pub fn codex|exec|--yolo|parallel|auto_merge|--continue|--no-auto-merge" crates/ralph-adapters/src/cli_backend.rs crates/ralph-core/src/config.rs crates/ralph-cli/src/main.rs
```

What to learn: Exact Codex command wiring and multi-loop operational controls.

## Lab B: `ptek-ai-playbook` experimental auto-agent-codex (5 commands)

### B1) Package shape and runtime entry points

```bash
cd "$PTEK_REPO" && rg -n "\"run-agent\"|\"setup-agent\"|@openai/codex-sdk|\"node\": \">=24\"" package.json README.md
```

What to learn: Which scripts exist and baseline runtime requirements.

### B2) Runner control plane defaults

```bash
cd "$PTEK_REPO" && rg -n "MAX_TURNS|MAX_CONSECUTIVE_ERRORS|COMMAND_PATHS|approvalPolicy|sandboxMode|runStreamed" run-agent-codex.mjs
```

What to learn: Loop limits, routing model, and security-sensitive runtime defaults.

### B3) Planning and scope-budget policy

```bash
cd "$PTEK_REPO" && rg -n "planning_scope|single-repo|<= 12 files|<= 400 LOC|phase breakdown|review_remediation|playwright_validation" resources/commands/implement-prd-planning-codex.md resources/commands/implement-prd-execution-codex.md
```

What to learn: How decomposition, size gates, and remediation are encoded in the command contracts.

### B4) Review loop dependency and remediation insertion

```bash
cd "$PTEK_REPO" && test -f resources/commands/review-pr.md && echo "review-pr.md exists" || echo "review-pr.md missing"; rg -n "review-pr.md|overscoped-phase-pr|Changes Requested|fix-plan-1|fix-exec-1" resources/commands/review-pr-codex.md
```

What to learn: Whether the review workflow is currently runnable and how remediation tasks are created.

### B5) Onboarding and operability behavior

```bash
cd "$PTEK_REPO" && rg -n "checkPrerequisites|gh auth|codex login|INITIAL_PROJECTS_DIR|cloneSelectedRepos|--help" bootstrap-agent.mjs README.md
```

What to learn: How much setup is interactive vs automatable, and where onboarding friction sits.

## Fast Comparison Notes Template

Use this after each command pair (A1 vs B1, A2 vs B2, etc.):

```text
Command Pair:
Observed:
Operational impact:
Risk:
Confidence (High/Medium/Low):
```

## Interpretation Guide

Use these decision cues:

1. If you prioritize control-plane maturity and operational resilience, Ralph should score higher.
2. If you prioritize PRD-phase workflow fit and in-house customization, ptek should score higher.
3. If ptek retains missing review dependencies or permissive defaults, treat it as "promising but not default-ready."
