# Multi-Agent AI Coding Orchestration: Landscape Research

> Researched 2026-03-22. Based on web research (Claude + Codex, 12 parallel streams) and codebase analysis of dotfiles repo + MTC Team reference.

## Executive Summary

The multi-agent AI coding space has exploded in early 2026. Every major vendor has shipped native multi-agent features (Claude Agent Teams, Codex subagents, Cursor Cloud Agents, Windsurf Wave 13, GitHub Agent HQ), while 14+ standalone orchestration tools and 11 general-purpose frameworks compete for the coordination layer. The landscape splits into four tiers: vendor-native features, standalone orchestrators, general frameworks, and DIY skill-based patterns. Your day-to-day stack — co-research, peer-review, auto-review, batch-repo-ops, and subagent patterns — is a solid implementation of the DIY tier using subagent dispatch and file-based coordination. The MTC Team Conductor (a shared reference, not in active use) demonstrates what's possible with specialist agents, peer messaging, and accumulating knowledge. The most relevant near-term upgrade path is Claude Code Agent Teams — a vendor-native feature that adds peer-to-peer messaging and shared task queues on top of the subagent primitives you already use daily.

## Key Concepts

**Orchestration vs. parallelism** — Running 5 agents in 5 tmux panes is parallelism. Orchestration adds: task decomposition, inter-agent communication, quality gates, and conflict resolution. Most tools in the ecosystem deliver parallelism. Few deliver orchestration.

**Conductor pattern** — A central coordinator dispatches specialist agents, holds gates, and manages workflow. Never touches code itself. Your MTC Conductor is a reference implementation.

**Worktree isolation** — The consensus solution for multi-agent file conflicts: each agent gets its own git worktree (separate working directory, shared .git). Adopted by Claude Code, Cursor, Windsurf, Claude Squad, and most standalone tools.

**Message bus vs. file-based coordination** — Two IPC paradigms. Message buses (SQLite mail, MCP, REST) are faster and more structured. File-based coordination (markdown artifacts, task files, git) is simpler, tool-agnostic, and fully inspectable. Your stack uses both: SendMessage for real-time, file artifacts for durable state.

**Zero-trust between agents** — Every inter-agent message should be treated as untrusted external input. Context contamination (one agent's hallucination spreading through shared memory) is the highest-risk failure mode in multi-agent systems.

---

## Ecosystem Landscape

### Tier 1: Vendor-Native Multi-Agent

| Platform | Feature | Status | Architecture | Agent Communication | Conflict Strategy |
|---|---|---|---|---|---|
| **Claude Code** | Agent Teams | Shipped (experimental) | Lead + independent teammates | Peer-to-peer mailbox + shared task queue | Separate context windows; user manages file overlap |
| **OpenAI Codex** | Subagents + MCP | Shipped (GA) | Parent-child spawn tree | Results aggregated to parent | Configurable sandbox; worktrees in Codex app |
| **Cursor** | Cloud Agents (2.0) | Shipped | Up to 8 parallel workers | None (workers → user) | Git worktrees or remote machines |
| **Windsurf** | Wave 13 parallel | Shipped | Independent parallel sessions | None (no agent-to-agent) | Git worktrees |
| **GitHub** | Agent HQ | Shipped (phased) | Meta-orchestrator across vendors | Mediated through PRs/issues | Native git branching |

**Key finding:** Claude Code Agent Teams is the only vendor-native feature with peer-to-peer agent messaging and a shared task queue with dependency tracking. Codex has the most composable architecture via MCP server mode. GitHub Agent HQ is unique as a vendor-agnostic meta-layer.

**Cost reality:** Agent Teams uses ~7x more tokens than a standard session. Cursor heavy usage targets Pro+ ($60/month) or Ultra ($200/month). Multi-agent is expensive across all vendors.

### Tier 2: Standalone Orchestrators

| Tool | Stars | IPC | Maturity | Key Differentiator |
|---|---|---|---|---|
| **Ruflo** (claude-flow) | 22.3k | MCP + swarm consensus | Production | Most feature-complete; Raft/Byzantine consensus; 60+ agents |
| **Claude Squad** | 6.5k | tmux + worktrees | Production | Most polished UX; Homebrew; human-in-the-loop by default |
| **Composio** | 5.1k | tmux/Docker + plugins | Production | Closes CI/review loop; 8 swappable plugin slots |
| **MCP Agent Mail** | 1.8k | FastMCP + SQLite + Git | Beta | Coordination infrastructure (BYOA); git-backed audit trail |
| **Multi-Agent Coding** | 1.4k | LiteLLM orchestration | Early | Benchmark-proven (#13 Terminal Bench); Explorer/Coder separation |
| **Overstory** | 1.1k | SQLite mail + worktrees | Beta | Most architecturally rigorous; tool-call guards; pluggable backends |
| **Agent Farm** | 730 | tmux + file locks | Beta | Industrial scale (50 agents); 34 pre-configured stacks |
| **agtx** | 596 | tmux + worktrees + artifacts | Early | Phase-routing (different agent per workflow phase); Rust binary |
| **Agent Swarm** | 289 | MCP/HTTP + Docker | Beta | Only tool with Docker worker isolation; persistent agent identity |
| **Ensemble** | 58 | tmux + shell bus | Alpha | Transparent message bus; multi-host; the tool that prompted this research |

**Key finding:** None of these tools provide meaningful OS-level sandboxing. Docker isolation (Agent Swarm only) is the strongest model. All tmux-based tools run with the invoking user's full permissions — incompatible with HIPAA requirements without additional containment.

**Ensemble assessment (unchanged):** 4 days old, 58 stars, no releases, `--dangerously-skip-permissions` baked in. Not ready. Claude Squad (6.5k stars, Homebrew, 17 releases) or Composio (5.1k stars, CI loop, plugin architecture) are the credible alternatives if you want a standalone tool.

### Tier 3: General-Purpose Frameworks

| Framework | Stars | Language | Architecture | Coding Fit |
|---|---|---|---|---|
| **MetaGPT** | 64k | Python | SOP-driven software team | Full SDLC simulation |
| **CrewAI** | 44k | Python | Role-based crew | Fast prototyping only |
| **AutoGen/AG2** | 35k | Python/.NET | Conversational group chat | Write → review → fix loops |
| **Semantic Kernel** | 27k | C#/Python/Java | Plugin orchestration SDK | Enterprise/.NET |
| **LangGraph** | 26k | Python | Graph/state machine | Production stateful workflows |
| **smolagents** | 25k | Python | Code-action agent | Single-agent coding tasks |
| **Ruflo/Swarm** | 20k | Python | Handoff-based | Reference design only |
| **OpenAI Agents SDK** | 19k | Python/TS | Handoff + guardrails | Codex CLI orchestration |
| **Mastra** | — | TypeScript | Workflow + supervisor | TypeScript-native stacks |
| **Agency Swarm** | 4k | Python | Role hierarchy on Agents SDK | OpenAI model lock-in |
| **OpenAI Symphony** | new | Elixir/BEAM | Conductor + specialist coding agents | Purpose-built issue → PR pipeline |

**Key finding for our context:** These are general-purpose agent frameworks, not coding agent orchestrators. They could theoretically coordinate coding agents, but none integrate with Claude Code or Codex CLIs natively. The exception is **OpenAI Symphony** — purpose-built for issue-tracker → PR delivery — and the **OpenAI Agents SDK** which has native Codex MCP integration.

**Mastra** is the only mature TypeScript-native framework, which is relevant to our stack.

### Tier 4: DIY / Skill-Based Patterns (Your Current Stack)

| Pattern | Implementation | Strength |
|---|---|---|
| **co-research** | Claude subagents + Codex exec, parallel dispatch, file-based coordination | Dual-engine research with structured synthesis |
| **peer-review** | Isolated reviewer with context separation, multi-round cycles | Context isolation as a quality mechanism |
| **auto-review** | Parallel expert panel + structured JSON merge + re-review loop | Multi-perspective review in a single flow |
| **batch-repo-ops** | Fan-out across repos with retry queues and rate limits | Multi-repo coordination primitive |
| **Subagent patterns** | Agent tool with typed agents (Explore, research, general-purpose) | Lightweight parallel dispatch |

**Key finding:** Your daily skills use Claude Code subagents (fire-and-collect) and Codex exec (headless dispatch) effectively for parallel work. The primary limitation is that subagents can't talk to each other — all results flow back to the parent, which becomes a bottleneck when synthesis requires cross-referencing between streams.

### Reference: MTC Team Conductor (Shared, Not in Active Use)

| Pattern | Implementation | Strength |
|---|---|---|
| **MTC Conductor** | 12-agent specialist team with gates, peer messaging, accumulating knowledge | Most mature skill-based orchestrator found in this research |

The MTC Team demonstrates patterns worth studying — specialist agents, Mongoose premise-challenging, peer messaging lanes, accumulating knowledge — but it's a reference implementation for a different codebase (MagicTouch Cloud), not something in your daily workflow. Its architectural ideas (especially Mongoose and the Cartographer) are the patterns most worth extracting and generalizing.

---

## Current State (Your Stack)

**Multi-agent primitives in use:**
- Claude Code Agent tool (subagent dispatch with typed agents)
- Claude Code Agent Teams (peer messaging, shared task queue) — available but not yet adopted in dotfiles skills
- Codex exec via `codex-research.sh` (headless dispatch with structured output)
- SendMessage for real-time inter-agent communication (MTC Team)
- File-based coordination (`.co-research/` artifacts, markdown handoffs)
- Git worktrees (available via `isolation: worktree` in agent frontmatter)

**Multi-agent skills:**
- `co-research` — dual-engine parallel research
- `peer-review` — isolated reviewer with round-by-round cycles
- `auto-review` — parallel expert panel
- `batch-repo-ops` — multi-repo fan-out
- `writing-skills` eval harness — paired subagent comparison

**MTC Team (shared reference, not in active use):**
- 12 specialist agents with narrow tool permissions — demonstrates what a full team orchestration looks like
- Patterns worth extracting: Mongoose (premise-challenging), Cartographer (accumulating system map), peer messaging lanes, decision-table gates

---

## Gap Analysis

| Capability | Current State | Gap | Effort |
|---|---|---|---|
| Peer-to-peer agent messaging | MTC Team uses SendMessage; dotfiles skills don't | Agent Teams available but not wired into existing skills | Medium — adopt Agent Teams for skills that benefit from inter-agent discussion |
| Real-time agent monitoring | None — rely on terminal output and idle summaries | No dashboard or watchdog; agents silently stuck on permission prompts | High — would require tooling (Amux, Overstory, or custom) |
| Agent recovery / self-healing | Manual restart on 3-min timeout (MTC policy) | No automated recovery; context lost on restart | Medium — Amux-style watchdog or TeammateIdle/TaskCompleted hooks |
| Container isolation | None — all agents run with user permissions | HIPAA concern for any workflow touching code that handles PHI | High — Docker Sandboxes or Firecracker, plus proxy for network |
| Conflict prevention | Git worktrees available but not enforced | Worktrees are opt-in per agent; no file-level locking | Low — add `isolation: worktree` to agent definitions |
| Audit trail | Shell history + hook logs; no centralized logging | No structured agent decision provenance | Medium — custom hook to log tool calls to append-only store |
| CI loop closure | Manual — review PR, fix, re-push | No automated routing of CI failures back to agents | High — Composio-style automation or GHA integration |
| Cross-tool orchestration | Claude + Codex via shell scripts | Can't natively dispatch to Gemini, Cursor, or other tools | Low priority — current two-engine pattern covers most needs |

---

## Trade-offs & Decision Points

### Build vs. Buy vs. Wait

**Build (extend existing stack):**
- Adopt Agent Teams for skills that need inter-agent collaboration
- Add `isolation: worktree` to agent definitions that modify code
- Wire TeammateIdle/TaskCompleted hooks for quality gates
- Modest effort, preserves existing architecture, no new dependencies
- Loses: dashboards, self-healing, container isolation

**Buy (adopt standalone tool):**
- Claude Squad for session management + worktree isolation
- Composio for CI loop closure + plugin architecture
- Gains: polished UX, community maintenance, proven patterns
- Loses: deep integration with your skill system; none of these tools understand your Conductor pattern, Mongoose, or accumulating knowledge
- Risk: tool churn in a 4-month-old category

**Wait (let vendors catch up):**
- Claude Agent Teams is experimental — Anthropic will likely ship monitoring, recovery, and better isolation
- OpenAI Symphony targets the exact issue → PR pipeline
- GitHub Agent HQ is a meta-orchestrator that could unify everything
- Gains: vendor-supported, integrated, maintained
- Loses: time; features shipping on vendor timelines, not yours

### The Mongoose Question

No external tool replicates the Mongoose premise-challenging pattern. If you adopt an external orchestrator, you either lose this or rebuild it as a plugin/hook. This pattern is your stack's most distinctive architectural advantage — it catches the most expensive failure mode (building on wrong assumptions).

### HIPAA Bottom Line

For code that handles PHI: no `--dangerously-skip-permissions`, container or microVM per agent, `--network none` + proxy, PHI scanners on prompts, zero-trust between agents, append-only audit logs with 6-year retention. No standalone tool in the ecosystem meets this bar today. Docker Sandboxes (Docker's official AI agent sandboxing) or Google Agent Sandbox (GKE-based) are the closest infrastructure plays.

---

## The PRD → Implementation Gap

### Current State

The existing skill pipeline has a clear seam: `create-prd` produces excellent specs, but the path from spec to code has three options, each with trade-offs:

| Approach | Strength | Weakness | Best For |
|---|---|---|---|
| **One-shot** | Fast, simple, low token cost | Context rot on anything non-trivial; manual handoff management | Small features (1-2 files, clear scope) |
| **prd-loop (ralph)** | Automated iteration with test/fix cycles | Immature; test/postmortem setup is clunky; hard to observe/steer | Convergence problems (run tests → fix → retry) |
| **Agent Teams** | **(proposed)** Parallel specialists, no single context holds everything | 7x token cost; experimental; unproven for this workflow | Medium features (3-8 files, cross-cutting, well-specced) |

### Why Agent Teams Attacks Context Rot Differently

A **loop** fights context rot by restarting with compressed context — it's a retry mechanism.
A **team** avoids context rot by **never loading the full context into one agent** — each teammate holds a narrow slice deeply rather than the whole PRD shallowly. The implementer holds the code, the reviewer holds the quality bar, the challenger holds the assumptions. No single context window rots because no single context window is doing everything.

This makes teams best suited for the **middle tier of PRD complexity** — too big for one-shot (context rots), too small to justify loop setup (clunky test/postmortem), but important enough that quality matters.

### Cross-Platform Constraint

The skill system is shared between Claude Code and Codex. Agent Teams is Claude Code-only. Codex has its own subagent model (`max_threads`, `max_depth`, custom agents in `.codex/agents/`) but no peer messaging or shared task queue. This means:

- **PRD triage** (routing to the right execution strategy) must work on both platforms
- **Agent Teams conductor** is Claude Code-only — Codex users fall back to one-shot or loop
- **Loops** work on both platforms (they use shell commands and subagent dispatch)
- Future Codex multi-agent features may close the gap, but not today

### Proposed Skills

1. **`prd-triage`** — Analyze a PRD and recommend the execution strategy. Platform-aware: on Codex, Agent Teams is not an option. Works on both platforms. Output: recommendation + reasoning, not execution.

2. **`ai-teamup`** — Claude Code-only command that implements a PRD using Agent Teams. Creates a team (lead + implementers + reviewer), decomposes the PRD into tasks, implements in parallel with worktree isolation, reviews each completion, merges and opens PR.

### Token Cost Reality

RTK and Waypoint have created significant token headroom. The 7x worst-case (all teammates in plan mode with full context) overstates actual cost because:
- Implementers with narrow task scope consume less context than a single agent holding the whole PRD
- The real comparison isn't "team vs one-shot" — it's "team vs one-shot + 2 handoffs + re-reads + context rot rework"
- Using Sonnet for implementer teammates and Opus for lead/reviewer further reduces cost

The rework avoided may cost more tokens than the team overhead.

---

## Recommended Approach

**Phase 1 — Immediate improvements:**
1. Add `isolation: worktree` to batch-repo-ops workers and any agent definitions that modify code
2. Sketch `prd-triage` skill (cross-platform, routes PRDs to the right execution strategy)
3. Sketch `ai-teamup` command (Claude Code-only, Agent Teams-based PRD implementation)

**Phase 2 — Validate Agent Teams for PRD implementation:**
1. Pilot `ai-teamup` on a medium-complexity neb PRD
2. Measure: token cost, quality vs one-shot, time-to-PR, context rot indicators
3. Compare against loop on the same or similar PRD
4. Refine based on findings

**Phase 3 — Monitor and selectively adopt (Q2 2026):**
1. Track Agent Teams stability — Anthropic will likely ship monitoring, recovery, and session resumption
2. Track Codex multi-agent evolution — if Codex ships peer messaging, port `ai-teamup` to cross-platform
3. If CI loop closure becomes a priority, evaluate Composio's plugin model
4. If container isolation becomes required (HIPAA audit), evaluate Docker Sandboxes

**Do not adopt now:**
- Ensemble (too immature)
- Any general-purpose framework (LangGraph, CrewAI, etc.) — they don't integrate with your CLI agent stack
- Ruflo/claude-flow (impressive star count but complexity raises questions; 379 open issues)

---

## Detailed Gap Analysis & Improvement Ideas

### Gap 1: Worktree Isolation Is Available but Not Enforced

**Current state:** Claude Code supports `isolation: worktree` in agent frontmatter. Your skills don't use it. MTC Surgeon creates worktrees manually in Phase 3 but other agents operate in the base checkout.

**Risk:** Two agents editing the same file silently overwrite each other. This is the #1 documented failure mode across the entire multi-agent ecosystem.

**Improvement ideas:**
- Add `isolation: worktree` to every agent definition that writes code (Surgeon, implementation subagents, batch-repo-ops workers)
- For MTC Team: enforce worktree creation at dispatch time (Conductor responsibility), not at agent discretion
- Consider per-worktree `.env` and port allocation if agents run servers or tests
- Add a session-start hook that detects and cleans orphan worktrees from prior sessions

**Effort:** Low. Frontmatter change per agent + one cleanup hook.

---

### Gap 2: No Real-Time Agent Monitoring or Recovery

**Current state:** MTC Conductor monitors via idle notification summaries. If an agent goes silent for 3 minutes, the policy is manual restart. No dashboard, no watchdog, no automated recovery. Permission prompt latency (MCP-heavy agents like Magpie and Lynx) causes agents to appear stuck.

**Risk:** Silent agent failures waste human attention and session time. Context is lost on restart.

**Improvement ideas:**
- **Short-term:** Wire `TeammateIdle` hook to detect stuck agents and surface a diagnostic (is it a permission prompt? a timeout? a hallucination loop?)
- **Medium-term:** Evaluate Amux's self-healing watchdog (auto-compact context, restart on corruption, unblock stuck prompts) as a pattern to port into your hook system
- **Long-term:** Build a lightweight web dashboard (Amux-style) that polls tmux pane state and agent task status — useful when running 3+ agents simultaneously
- **Alternative:** Wait for Anthropic to ship monitoring in Agent Teams (likely Q2-Q3 2026)

**Effort:** Medium. TeammateIdle hook is low-effort. Dashboard is high-effort but high-value at scale.

---

### Gap 3: No Container-Level Isolation (HIPAA Concern)

**Current state:** All agents run with the invoking user's full OS permissions. No sandboxing beyond git worktrees. Agents can read `~/.ssh`, `~/.aws`, `.env` files, and any file on disk.

**Risk:** For code that handles PHI, this is a HIPAA compliance gap. A hallucinating agent could read credentials, leak data through network requests, or modify files outside the project.

**Improvement ideas:**
- **Docker Sandboxes** (Docker's official AI agent sandboxing, March 2026): each agent gets a microVM with private Docker daemon, `--network none` by default, outbound traffic via allowlisted proxy. Evaluate feasibility for local dev.
- **Google Agent Sandbox** (GKE-based): gVisor isolation for agent fleets. Better for centralized/cloud deployments.
- **Proxy pattern** (applicable to any sandbox): no agent gets direct network access. All outbound traffic routes through a host proxy that injects credentials (agent never sees secrets), enforces domain allowlists, and logs all requests.
- **Pragmatic minimum:** Mount the project directory read-write, everything else read-only. Exclude credential files from the mount. This is achievable with Docker bind mounts today.
- **Phased deployment:** Start agents in read-only observation mode (access granted, writes blocked). Move to write mode after behavioral baseline.

**Effort:** High. Requires infrastructure investment. Docker Sandboxes are the lowest-friction path.

---

### Gap 4: No Structured Audit Trail

**Current state:** Shell history and hook logs capture some tool calls. No centralized, structured, append-only log of agent decisions. No way to answer "what did agent X do at time Y and why?" for compliance purposes.

**Risk:** HIPAA requires 6-year audit log retention with tamper-evident storage. Multi-agent workflows need decision provenance (reasoning chain), not just execution logs.

**Improvement ideas:**
- **Post-tool-call hook:** Log agent identity, tool name, arguments (PHI-scrubbed), timestamp, and result status to an append-only file or SIEM-compatible format
- **Inter-agent message logging:** Log all SendMessage/broadcast calls at the orchestrator level (Conductor or Agent Teams infrastructure)
- **PHI scanner gate:** Add a pre-prompt hook that scans for SSN patterns, MRN formats, and HIPAA identifier categories. Block prompts that contain PHI before they reach the LLM.
- **Storage:** Start with append-only local files (`.claude/audit/`), graduate to a proper SIEM when compliance requires it
- **Minimal viable schema:**
  ```
  {timestamp, session_id, agent_name, tool_name, args_hash, result_status, approval_decision}
  ```

**Effort:** Medium. The hook itself is straightforward. PHI scanning and SIEM integration add complexity.

---

### Gap 5: Agent Teams Not Yet Adopted in Skills

**Current state:** Agent Teams is available (shipped Feb 2026) but none of your dotfiles skills use it. All multi-agent coordination uses the older subagent pattern (fire-and-collect, no peer messaging).

**Risk:** You're missing the primary architectural advancement — peer-to-peer agent messaging and shared task queues. This is exactly what the MTC Conductor builds manually via SendMessage.

**Improvement ideas:**
- **Pilot in co-research:** Replace subagent dispatch with teammate dispatch. Test whether teammates sharing findings mid-research produces better synthesis than the current collect-and-merge pattern.
- **Pilot in peer-review:** Test whether a reviewing teammate that can ask the implementing teammate clarifying questions produces better review quality than the current context-isolated pattern. (Note: this might actually be worse — context isolation is a feature, not a bug, in peer-review.)
- **Port MTC Conductor to Agent Teams:** The Conductor's dispatch-and-gate pattern maps directly to Agent Teams' task list + messaging. Teammates replace standalone skill dispatch. TeammateIdle/TaskCompleted hooks replace manual timeout monitoring.
- **Measure token cost:** Agent Teams uses ~7x more tokens. Quantify whether the quality improvement justifies the cost for each skill.

**Effort:** Medium per skill. Start with one skill as a pilot.

---

### Gap 6: No CI Loop Closure

**Current state:** When a PR's CI fails, the human reads the failure, reopens an agent session, pastes the error, and drives the fix manually. No automated feedback loop.

**Risk:** Manual CI triage is a time sink, especially across multiple repos.

**Improvement ideas:**
- **Composio-style automation:** Composio routes CI failures and review comments back to agents automatically. Evaluate their plugin model for GHA integration.
- **GHA webhook → Claude Code:** Build a GHA workflow that posts CI failure details as a comment on the PR, then triggers a Claude Code session (via `claude --print` or Agent Teams) to propose a fix.
- **Self-healing PR skill:** A skill that monitors a PR's checks, detects failures, reads the logs, and pushes a fix commit. Human reviews the fix commit before merge.
- **Lightweight version:** A `/fix-ci` slash command that reads the latest CI failure from `gh run view` and proposes a fix in the current session. No automation — human-triggered but structured.

**Effort:** `/fix-ci` is low. Full automation is high (webhook infrastructure, security review for auto-push).

---

### Gap 7: Mongoose Pattern Not Portable

**Current state:** Premise-challenging is embedded in the MTC Mongoose skill with MTC-specific domain knowledge (dual-writers, no-FK environment, deployment gotchas). It's not reusable outside MTC.

**Risk:** Other workflows (neb platform, dotfiles, new projects) don't benefit from premise validation.

**Improvement ideas:**
- **Extract a generic Mongoose hook/gate:** A reusable pattern that takes any claim + evidence and runs a disprove-first validation. Domain knowledge comes from project-specific CLAUDE.md or knowledge files, not from the skill itself.
- **Mongoose-as-a-TeamCompleted hook:** Before any task is marked done in Agent Teams, run a lightweight premise check on the claimed result. Exit code 2 blocks completion if a premise is shaky.
- **Mongoose as a review skill augmentation:** Add a "challenge premises" phase to peer-review and auto-review skills. Before the reviewer starts, a Mongoose-like pass identifies assumptions in the diff that need validation.
- **The key insight to preserve:** Semantic > structural. Never demand pattern parity without checking why the reference has the pattern. This principle applies universally.

**Effort:** Medium. The pattern is clear; the challenge is domain-agnostic formulation.

---

### Gap 8: Knowledge Accumulation Limited to MTC

**Current state:** MTC Team has a sophisticated knowledge persistence system (Bloodhound memory, Cartographer map, Magpie specs, Attaché interaction log) that survives across sessions. Your dotfiles skills use Waypoint journal for learnings but don't accumulate system-level knowledge.

**Risk:** Each session in non-MTC projects starts from scratch. Discoveries about neb architecture, service conventions, and cross-cutting patterns are lost.

**Improvement ideas:**
- **Waypoint map as lightweight Cartographer:** Waypoint already tracks file descriptions. Extend it to track discovered patterns, architectural decisions, and cross-service flows.
- **Per-project knowledge directory:** Mirror MTC's `~/.claude/knowledge/<project>/` pattern for neb projects. Skills like Bloodhound could be generalized as project explorers.
- **Session-end knowledge commit:** Make the handoff skill write discovered knowledge to a persistent location before ending. Currently it captures context for resumption; extend to capture learnings.
- **Shared knowledge repo:** Like MTC's `ai-memories` — a repo that multiple projects push knowledge to. Enables cross-project discovery.

**Effort:** Low to start (extend Waypoint), medium for full knowledge persistence.

---

### Improvement Priority Matrix

| Improvement | Impact | Effort | HIPAA Relevance | Recommended Phase |
|---|---|---|---|---|
| Worktree isolation enforcement | High (prevents #1 failure mode) | Low | Indirect | Phase 1 (now) |
| Orphan team cleanup hook | High (prevents silent routing failure) | Low | None | Phase 1 (now) |
| TeammateIdle diagnostic hook | Medium (reduces wasted time) | Low | None | Phase 1 (now) |
| Structured audit logging hook | Medium (compliance foundation) | Medium | Direct | Phase 1 (now) |
| PHI scanner pre-prompt hook | High (blocks PHI leakage) | Medium | Direct | Phase 1 (now) |
| Agent Teams pilot (one skill) | Medium (validates architecture) | Medium | None | Phase 2 (next month) |
| Generic Mongoose gate | High (prevents expensive mistakes) | Medium | None | Phase 2 (next month) |
| Knowledge accumulation | Medium (prevents repeated discovery) | Low-Medium | None | Phase 2 (next month) |
| `/fix-ci` slash command | Medium (reduces manual triage) | Low | None | Phase 2 (next month) |
| Container isolation (Docker Sandboxes) | High (HIPAA compliance) | High | Direct | Phase 3 (Q2 2026) |
| Real-time agent dashboard | Medium (operational visibility) | High | Indirect | Phase 3 (Q2 2026) |
| Full CI loop closure automation | Medium (reduces manual work) | High | None | Phase 3 (Q2 2026) |

---

## Follow-Up Options (12)

1. **Claude Code Agent Teams** — pilot in an existing skill; measure token cost and quality delta
2. **Composio Agent Orchestrator** — evaluate for CI loop closure and its plugin architecture
3. **Claude Squad** — evaluate as a lightweight session manager alongside existing skills
4. **OpenAI Symphony** — watch for maturity; evaluate as issue → PR daemon when stable
5. **Docker Sandboxes** — evaluate for HIPAA-grade agent containment
6. **Overstory** — evaluate SQLite mail system and tool-call guards as coordination infrastructure
7. **MCP Agent Mail** — evaluate as a git-backed coordination layer for cross-tool orchestration
8. **TeammateIdle/TaskCompleted hooks** — implement quality gates for Agent Teams workflows
9. **Structured audit logging** — build a post-tool-call hook for compliance-grade decision provenance
10. **Mongoose-as-a-hook pattern** — extract premise-challenging into a reusable hook/gate applicable to any orchestration approach
11. **Agent Teams + MTC Team convergence** — port MTC Conductor to use Agent Teams instead of standalone subagent dispatch
12. **GitHub Agent HQ** — monitor as a potential meta-orchestrator that could unify Claude + Codex + others

---

## References & Sources

### Vendor Documentation
- [Claude Code Agent Teams](https://code.claude.com/docs/en/agent-teams)
- [Claude Code Security](https://code.claude.com/docs/en/security)
- [Anthropic Opus 4.6 announcement](https://techcrunch.com/2026/02/05/anthropic-releases-opus-4-6-with-new-agent-teams/)
- [Codex Subagents](https://developers.openai.com/codex/subagents)
- [Codex + Agents SDK](https://developers.openai.com/codex/guides/agents-sdk)
- [Cursor 2.0 changelog](https://cursor.com/changelog/2-0)
- [Windsurf Wave 13](https://windsurf.com/blog/windsurf-wave-13)
- [GitHub Agent HQ](https://github.blog/news-insights/company-news/welcome-home-agents/)
- [Anthropic secure deployment guide](https://platform.claude.com/docs/en/agent-sdk/secure-deployment)

### Standalone Tools
- [Claude Squad](https://github.com/smtg-ai/claude-squad) (6.5k stars)
- [Ruflo/claude-flow](https://github.com/ruvnet/ruflo) (22.3k stars)
- [Composio Agent Orchestrator](https://github.com/ComposioHQ/agent-orchestrator) (5.1k stars)
- [Overstory](https://github.com/jayminwest/overstory) (1.1k stars)
- [MCP Agent Mail](https://github.com/Dicklesworthstone/mcp_agent_mail) (1.8k stars)
- [Agent Swarm](https://github.com/desplega-ai/agent-swarm) (289 stars)
- [Ensemble](https://github.com/michelhelsdingen/ensemble) (58 stars)
- [Agent Farm](https://github.com/Dicklesworthstone/claude_code_agent_farm) (730 stars)
- [agtx](https://github.com/fynnfluegge/agtx) (596 stars)
- [Amux](https://github.com/mixpeek/amux) (86 stars)

### Frameworks
- [LangGraph](https://github.com/langchain-ai/langgraph) (26k stars)
- [CrewAI](https://github.com/crewAIInc/crewAI) (44k stars)
- [AutoGen/AG2](https://github.com/ag2ai/ag2) (35k stars)
- [OpenAI Agents SDK](https://openai.github.io/openai-agents-python/) (19k stars)
- [OpenAI Symphony](https://github.com/openai/symphony)
- [Mastra](https://github.com/mastra-ai/mastra)
- [MetaGPT](https://github.com/FoundationAgents/MetaGPT) (64k stars)
- [smolagents](https://github.com/huggingface/smolagents) (25k stars)
- [Semantic Kernel](https://github.com/microsoft/semantic-kernel) (27k stars)

### DIY Patterns & Community
- [Claude Code Sub-Agents best practices](https://claudefa.st/blog/guide/agents/sub-agent-best-practices)
- [Conductors to Orchestrators (Addy Osmani)](https://addyosmani.com/blog/future-agentic-coding/)
- [Git worktrees for parallel AI agents](https://devcenter.upsun.com/posts/git-worktrees-for-parallel-ai-coding-agents/)
- [Simon Willison: Parallel coding agents](https://simonwillison.net/2025/Oct/5/parallel-coding-agents/)
- [dispatch skill](https://github.com/bassimeledath/dispatch)
- [tick-md coordination](https://purplehorizons.io/blog/tick-md-multi-agent-coordination-markdown)
- [Agentmaxxing (2026)](https://vibecoding.app/blog/agentmaxxing)

### Security & Compliance
- [NVIDIA AI Red Team sandboxing guidance](https://developer.nvidia.com/blog/practical-security-guidance-for-sandboxing-agentic-workflows-and-managing-execution-risk/)
- [Docker Sandboxes](https://docs.docker.com/ai/sandboxes/)
- [Google Agent Sandbox (GKE)](https://docs.cloud.google.com/kubernetes-engine/docs/how-to/agent-sandbox)
- [NIST AI agent identity concept paper (Feb 2026)](https://csrc.nist.gov/pubs/other/2026/02/05/accelerating-the-adoption-of-software-and-ai-agent/ipd)
- [Knostic multi-agent security](https://www.knostic.ai/blog/multi-agent-security)
- [Augment Code HIPAA guide](https://www.augmentcode.com/guides/hipaa-compliant-ai-coding-guide-for-healthcare-developers)
- [Inter-agent prompt injection paper (arxiv)](https://arxiv.org/abs/2506.23260)

### Codebase Analysis
- MTC Team Conductor: `/Users/martinburch/reference/mtc-team-claude/`
- Dotfiles multi-agent skills: `/Users/martinburch/repos/dotfiles/codex/.agents/skills/`
- co-research command: `/Users/martinburch/repos/dotfiles/claude/.claude/commands/co-research.md`

## Open Questions

1. **Agent Teams token economics** — Is the 7x overhead justified for skills where inter-agent discussion adds value? Needs empirical measurement.
2. **Mongoose portability** — Can premise-challenging be extracted into a reusable hook/gate, or is it inherently tied to the MTC domain knowledge?
3. **Container isolation feasibility** — What's the developer experience cost of running coding agents in Docker Sandboxes? Does it break MCP server access, git credentials, shell tools?
4. **Audit trail architecture** — What's the minimum viable structured logging for HIPAA compliance in a multi-agent coding workflow?
5. **CI loop closure priority** — How much time is currently lost to manual CI failure → fix → re-push cycles? Would Composio-style automation pay for itself?
6. **Agent Teams stability** — When does Anthropic move Agent Teams from experimental to stable? What limitations get lifted?
7. **Symphony timeline** — When does OpenAI Symphony become usable for non-Elixir shops? Will they ship a hosted version?
