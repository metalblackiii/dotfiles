---
name: dispatching-parallel-agents
description: Use when facing multiple independent tasks, failures, investigations, or explorations that don't share state — parallel file analysis, concurrent codebase searches, simultaneous multi-repo investigation, or any work that can be decomposed into independent threads
user-invocable: false
---

# Dispatching Parallel Agents

## Overview

When you have multiple unrelated problems (different test files, different subsystems, different bugs), investigating them sequentially wastes time. Dispatch one agent per independent problem domain and let them work concurrently.

## When to Dispatch

All three must be true:

1. **Multiple problems** — 2+ distinct failures or investigations
2. **Independent** — fixing one doesn't affect the others
3. **No shared state** — agents won't edit the same files or use the same resources

**Do NOT dispatch in parallel when:**
- Failures might be related (fix one, fix all) — investigate together first
- You don't yet know what's broken (exploratory debugging)
- Agents would edit the same files or contend for the same resources

## The Pattern

### 1. Group by Problem Domain

Separate failures by what's broken, not where they appear:
- File A tests: authentication flow
- File B tests: batch processing
- File C tests: abort handling

Each domain is independent — fixing auth doesn't affect abort.

### 2. Write Focused Agent Prompts

Each agent gets:
- **Specific scope** — one test file, one subsystem, one bug
- **Full context** — error messages, test names, relevant file paths
- **Constraints** — what NOT to change
- **Expected output** — summary of root cause and changes

### 3. Dispatch and Integrate

After agents return:
1. Read each summary — understand what changed
2. Check for conflicts — did agents edit the same code?
3. Run full test suite — verify fixes work together
4. Spot check — agents can make systematic errors

## Agent Prompt Quality

| Pattern | Bad | Good |
|---------|-----|------|
| **Scope** | "Fix all the tests" | "Fix agent-tool-abort.test.ts" |
| **Context** | "Fix the race condition" | Paste error messages and test names |
| **Constraints** | (none — agent refactors everything) | "Do NOT change production code outside auth module" |
| **Output** | "Fix it" | "Return summary of root cause and what you changed" |

## Anti-Patterns

- **Dispatching before understanding** — If you don't know whether failures are related, investigate first. Parallel dispatch on a shared root cause wastes all agents' time.
- **Too-broad scope** — "Fix the backend" gives the agent too much freedom. Narrow to one subsystem or test file.
- **Missing conflict check** — Always verify agents didn't edit the same files before integrating.
