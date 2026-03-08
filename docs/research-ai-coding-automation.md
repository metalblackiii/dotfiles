# AI Coding Automation: Harness Engineering, Orchestration, and Dark Factory Patterns

> Researched 2026-03-08. Based on web research and codebase analysis of dotfiles and ptek-ai-playbook repos.

## Executive Summary

The AI coding automation landscape has matured rapidly. The dominant insight of early 2026 is that **the harness is the hard part** -- model capabilities are sufficient, but the engineering challenge is building the constraints, feedback loops, and verification systems that make agents reliable. Your existing setup (co-research/co-implement commands, auto-agent-codex PRD loop) already implements several production patterns -- Harness Engineering, Ralph Loop, and nascent Dark Factory -- but has identifiable fragile points that emerging best practices can address. Full automation ("Dark Factory") exists at companies like StrongDM but remains rare and unsuitable for regulated domains like healthcare. The centaur model -- selective, intentional AI use with human judgment at decision boundaries -- consistently outperforms both full autonomy and full manual work in research.

## Key Concepts

### Harness Engineering
The discipline of designing constraints, feedback loops, and lifecycle management systems around AI coding agents. Coined by OpenAI (Feb 2026) in their Codex write-up. The harness is the deterministic runtime layer -- task routing, state management, tool gating, safety enforcement -- wrapped around a stochastic model. "2025 was agents. 2026 is agent harnesses." The four pillars are: context architecture, agent specialization, persistent memory, and structured execution.

### Dark Factory
Borrowed from manufacturing ("lights-out factories"). Applied to software: fully automated coding pipelines where AI agents write, test, review, and deploy code with zero human intervention. Dan Shapiro's five autonomy levels range from "spicy autocomplete" (L1) to full Dark Factory (L5). Most teams operate at L2-3; L5 is experimental.

### Ralph Loop
A PRD-driven autonomous agent loop: human writes spec, agent converts to machine-readable tasks, fresh AI instance per iteration implements one story at a time with quality gates, persists learnings, and repeats until all tasks pass. Named after the open-source project by snarktank. Your auto-agent-codex is a sophisticated implementation of this pattern.

### AI Orchestration
Multi-agent coordination patterns for directing AI coding work. Core patterns include planner/executor separation, reviewer/implementer loops, specialist routing, fan-out/fan-in parallelism, and blackboard/shared-memory coordination. The two emerging standards are MCP (agent-to-tool, production standard) and A2A (agent-to-agent, joint spec Q3 2026).

## Ecosystem Landscape

### Autonomous Coding Agents

| Tool | Status | Pricing (entry) | Open Source | Fully Autonomous | Best For |
|---|---|---|---|---|---|
| **Claude Code** | GA | $20/mo (Pro) | SDK yes | Yes | Terminal-first, MCP workflows |
| **OpenAI Codex** | GA | $20/mo (ChatGPT Plus) | CLI yes | Yes (cloud) | OpenAI ecosystem |
| **Aider** | GA | Free (BYOK) | Yes (Apache 2.0) | Semi | Individual devs, any LLM |
| **OpenHands** | GA (v1.0) | Free (self-host) | Yes (MIT) | Yes | Research-grade autonomy |
| **Devin** | GA | $20/mo + ACUs | No | Yes | Async task delegation |
| **Factory** | GA | Free (BYOK) / $20 Pro | No | Yes | Enterprise ticket-to-PR |
| **Cursor** | GA | $20/mo (Pro) | No | Yes (cloud agents) | IDE-centric workflows |
| **Cline** | GA | Free (BYOK) | Yes (Apache 2.0) | Configurable | VS Code + human-in-the-loop |
| **Kiro** | GA | AWS Bedrock pricing | No | Yes (extended) | AWS enterprise |

### Agent Frameworks

| Framework | Status | Best For | Watch Out |
|---|---|---|---|
| **LangGraph v1.0** | GA | Stateful production pipelines | Over-abstraction critique |
| **OpenAI Agents SDK** | GA (v0.x) | OpenAI ecosystem, voice | Still pre-1.0 |
| **Claude Agent SDK** | GA | Claude ecosystem, MCP-native | Anthropic-only models |
| **CrewAI** | GA | Quick multi-agent prototyping | Expensive at scale ($60K+/yr) |
| **MS Agent Framework** | RC | .NET enterprise, Azure | Supersedes AutoGen + SK |

### Interoperability Protocols

| Protocol | Scope | Status | Owner |
|---|---|---|---|
| **MCP** | Agent-to-tool (vertical) | Production standard | Anthropic / Linux Foundation |
| **A2A** | Agent-to-agent (horizontal) | Active dev, Q3 2026 spec | Google / Linux Foundation |

### Benchmarks

SWE-bench Verified is retired (contaminated). **SWE-bench Pro** (Scale AI, 1,865 tasks) is the current gold standard -- best models solve ~57%. **SWE-Lancer** (OpenAI, $1M of real freelance tasks) adds economic grounding. No benchmark captures real multi-day engineering.

## Best Practices

### From Harness Engineering Literature

1. **Context architecture**: Tiered, progressive disclosure -- right context at right time, not everything at once
2. **Agent specialization**: Scoped prompts and restricted tool access per agent role (your command templates already do this)
3. **Persistent memory**: Filesystem-backed state (task_memory.json, progress files, git history), not conversation history
4. **Structured execution**: Explicit phases (plan → execute → verify → review), not open-ended generation
5. **External verification is non-negotiable**: Tests, linters, type checkers -- never rely on the model's self-assessment of correctness
6. **Fresh context beats long sessions**: Microsoft research confirms LLMs degrade in long multi-turn conversations. The Ralph pattern (fresh AI instance per task) outperforms extended sessions
7. **Specs matter more than ever**: Addy Osmani's workflow -- start with detailed specs, generate structured prompt plans, then implement. The spec is the product; code is downstream

### Anti-Patterns to Avoid

1. **Prompt-only safety**: State transitions enforced by prompts alone (not runtime-validated) will eventually be violated
2. **Swallowing errors**: Parse/read errors treated as "no state" can reinitialize and lose progress
3. **Unbounded loops**: Failed tasks that remain runnable forever cause infinite loops on irrecoverable failures
4. **Full-auto on production**: Multiple catastrophic incidents documented (Replit DROP DATABASE, Kiro 13-hour AWS outage)
5. **Trusting self-assessment**: METR study showed 39-point perception gap -- developers believed 20% faster while actually 19% slower

## Current State

### Dotfiles Repo (Agent Configuration)

Your setup is a well-structured harness with 43 skills, 3 commands (co-research, co-implement, codex-review), 4 hooks (session-start, guard, rtk-rewrite, eslint-autofix), and 3 agent profiles. Key architectural strengths:

- **Shared skills via symlinks** between Claude Code and Codex (`claude/.claude/skills` → `codex/.agents/skills`)
- **Shared instructions** via symlink chain (CLAUDE.md → AGENTS.md → shared/INSTRUCTIONS.md)
- **Three-layer hook policy enforcement**: deny patterns, sensitive paths, compound-command protection
- **SessionStart hook** injects `using-skills` every startup, ensuring skill discovery is always active
- **co-research/co-implement/batch-repo-ops** implement planner/executor separation with Claude as planner and Codex as executor

### Ptek-AI-Playbook (auto-agent-codex)

A sophisticated Ralph Loop implementation using the Codex SDK:

- **File-backed state machine**: `task_memory.json` with `status !== "completed"` routing
- **LLM-driven decomposition**: Planning prompts tell Codex to read PRD markdown and derive phases
- **Rolling sequential execution**: `plan N → execute N → pr_review N → plan N+1`
- **Three command templates**: Planning, execution, PR review -- each reads manifest + task memory, processes exactly one task, updates memory, stops
- **Circuit breaker**: 3 consecutive errors triggers exit
- **Codex SDK usage**: `Thread API` with `runStreamed()` for real-time visibility into tool calls and file changes

## Gap Analysis

| Recommendation | Current State | Gap | Effort |
|---|---|---|---|
| **Runtime state validation** | State transitions are prompt-enforced only | No schema validation on task_memory.json mutations; model can write invalid state | Medium -- add JSON schema validator after each Codex turn |
| **Failed task handling** | `status !== "completed"` selects next task | Failed tasks remain runnable forever; irrecoverable failures cause loops | Low -- add `failed_count` field, skip after 3 failures |
| **Error-resilient state reads** | Parse errors swallowed, treated as empty state | Can reinitialize and lose all progress | Low -- crash on parse error instead of silent recovery |
| **Run-state manifests for co-research/co-implement** | No structured tracking of dispatch status | Can't resume failed research/implementation runs | Medium -- add `.co-research/state.json` with per-stream status |
| **Verification gate after Codex delegation** | No artifact validation | Empty/malformed Codex output proceeds to synthesis | Low -- check non-empty + expected sections before using |
| **Policy drift between settings.json and guard.sh** | Parallel deny/ask rules in two locations | Rules can diverge silently | Medium -- generate guard rules from settings.json |
| **Changed-file tracking in co-implement** | Diffs only filename sets pre/post | Misses Codex edits to already-dirty files | Low -- use content hash, not just filename presence |
| **Observability** | Per-turn JSONL logs in auto-agent-codex; none in co-research/co-implement | No unified telemetry across orchestration patterns | Medium -- add per-run manifest with duration, retries, token usage, outcome |
| **Cross-session learning** | AGENTS.md / CLAUDE.md pattern (human-curated) | No automated learning accumulation | Hard -- best systems achieve only ~37% retention |

## Trade-offs & Decision Points

### 1. Human-in-the-Loop vs Full Autonomy

**Lean toward: Centaur model (selective autonomy)**

The evidence is clear: neither full autonomy nor full manual work is optimal. The centaur model (human control over architecture/security decisions, AI handles implementation) achieves the highest accuracy in Harvard's research. For healthcare-adjacent work (HIPAA), full autonomy is a non-starter -- audit trail requirements mandate documented human review chains.

Your co-implement pattern already embodies this: Claude plans (human reviews spec), Codex implements (human reviews diff), Claude validates acceptance criteria. This is the right architecture.

### 2. Invest in Harness vs Wait for Better Models

**Lean toward: Invest in harness now**

"The harness -- not the model -- is the bottleneck." The teams winning in 2026 are investing in constraints, verification, and orchestration infrastructure. Model improvements are additive to a good harness; a bad harness wastes better models. Your auto-agent-codex harness and dotfiles skill system are the right investment area.

### 3. Single-Agent Deep vs Multi-Agent Parallel

**Lean toward: Single-agent with phased execution for most work; multi-agent for research and batch ops**

The Anthropic compiler experiment showed that parallelism only helps with decomposable work -- when multiple agents hit the same indivisible problem, they overwrite each other. Your co-research (fan-out/fan-in for web research) and batch-repo-ops (parallel across repos) are good use cases for multi-agent. co-implement (single spec → single Codex pass) is the right call for implementation.

### 4. Codex SDK vs Claude Agent SDK vs Both

**Lean toward: Continue dual-stack, watch for convergence**

You're already running Claude Code as the orchestrator with Codex as a delegated executor. This gives you the best of both ecosystems. The Claude Agent SDK's TeammateTool (parallel agents with shared task lists) could eventually replace your custom orchestration, but it's still in research preview. Keep your current architecture; adopt SDK primitives as they stabilize.

### 5. How Much Automation for Healthcare Context

**Lean toward: L3 (Human-in-the-Loop Manager) for most work, never L5**

With HIPAA compliance requirements, full Dark Factory is inappropriate. The sweet spot is Level 3-4: agents do the work, humans review at well-defined checkpoints (spec approval, PR review, deployment gate). Your guard.sh hook and permission system provide the right enforcement layer.

## Recommended Approach

### Immediate (Low-Effort Hardening)

1. **Fix auto-agent-codex failed-task loop**: Add `failed_count` to task schema, skip tasks after 3 failures. Prevents infinite loops on irrecoverable errors.

2. **Crash on state parse errors**: In `run-agent-codex.mjs`, throw on `task_memory.json` parse failure instead of swallowing. Lost progress from silent reinitialization is worse than a crash.

3. **Add verification gate in co-research/co-implement**: Before synthesis/review, validate that Codex output is non-empty and contains expected structure. A simple `wc -l` check prevents synthesizing from empty artifacts.

4. **Fix co-implement changed-file tracking**: Use `git diff --stat` (content-aware) instead of `git diff --name-only` (filename-only) for pre/post comparison to catch edits to already-dirty files.

### Short-Term (Structured Resilience)

5. **Add run-state manifests**: Create `.co-research/state.json` and `.co-implement/state.json` tracking per-stream status, enabling resume after failure. Schema: `{ streams: [{ id, status, started_at, completed_at, artifact_path, error }] }`.

6. **Generate guard rules from settings.json**: Write a script that extracts deny/ask patterns from `settings.json` and generates the regex list for `guard.sh`, eliminating dual-maintenance drift.

7. **Add per-run observability**: After each co-research/co-implement/batch-repo-ops run, write a `run-manifest.json` with: run_id, duration, streams dispatched, streams completed, token usage estimate, outcome, and error taxonomy.

### Medium-Term (Pattern Adoption)

8. **Adopt Ralph Loop learnings in auto-agent-codex**: Add an append-only `progress.txt` learning log alongside `task_memory.json`. Each completed task appends what worked and what failed. Fresh Codex instances get this as additional context, enabling cross-turn learning without growing the context window.

9. **Wire peer-review as post-implementation gate**: After Codex implementation passes in co-implement, dispatch the `peer-review` skill to run a context-isolated review comparing the diff against the spec. `peer-review` delegates to `self-review` criteria via an isolated agent (Claude fork, not Codex round-trip), catching scope creep and quality issues without implementation bias. Wired into co-implement Step 6.

10. **Explore Claude Agent SDK TeammateTool**: When it exits research preview, evaluate whether it can replace the manual orchestration in co-research (parallel agent dispatch + synthesis). This would give you built-in context isolation, task lists, and peer messaging without custom bash glue.

### Watch List (Don't Build Yet)

- **A2A protocol**: Joint spec not until Q3 2026. Interesting for cross-tool orchestration but premature to adopt.
- **Microsoft Agent Framework**: RC, not GA. Wait for stable release before evaluating.
- **Automated cross-session learning**: Best systems achieve ~37% retention. The human-curated CLAUDE.md/AGENTS.md pattern is actually the practical standard -- don't over-invest in automated memory systems yet.
- **Full Dark Factory for production services**: Not appropriate given HIPAA context, current tool maturity, and documented failure modes (Replit, Kiro incidents).

## References & Sources

### Harness Engineering
- [OpenAI -- Harness engineering: leveraging Codex in an agent-first world](https://openai.com/index/harness-engineering/)
- [OpenAI -- Unrolling the Codex agent loop](https://openai.com/index/unrolling-the-codex-agent-loop/)
- [Anthropic -- Effective harnesses for long-running agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)
- [Martin Fowler -- Harness Engineering](https://martinfowler.com/articles/exploring-gen-ai/harness-engineering.html)
- [NxCode -- Harness Engineering Complete Guide](https://www.nxcode.io/resources/news/harness-engineering-complete-guide-ai-agent-codex-2026)

### Dark Factory
- [Dan Shapiro -- The Five Levels: from Spicy Autocomplete to the Dark Factory](https://www.danshapiro.com/blog/2026/01/the-five-levels-from-spicy-autocomplete-to-the-software-factory/)
- [Simon Willison -- How StrongDM's AI team build serious software](https://simonwillison.net/2026/Feb/7/software-factory/)
- [StrongDM/Attractor on GitHub](https://github.com/strongdm/attractor)
- [Anthropic -- Building a C compiler with parallel Claudes](https://www.anthropic.com/engineering/building-c-compiler)
- [Stanford Law -- Built by Agents, Tested by Agents, Trusted by Whom?](https://law.stanford.edu/2026/02/08/built-by-agents-tested-by-agents-trusted-by-whom/)

### Orchestration Patterns
- [Microsoft Azure -- AI Agent Design Patterns](https://learn.microsoft.com/en-us/azure/architecture/ai-ml/guide/ai-agent-design-patterns)
- [Anthropic -- Building agents with the Claude Agent SDK](https://www.anthropic.com/engineering/building-agents-with-the-claude-agent-sdk)
- [OpenAI Agents SDK docs](https://openai.github.io/openai-agents-python/)
- [LangGraph v1.0 announcement](https://blog.langchain.com/langchain-langgraph-1dot0/)
- [MCP Specification (2025-11-25)](https://modelcontextprotocol.io/specification/2025-11-25)
- [Google -- Announcing A2A Protocol](https://developers.googleblog.com/en/a2a-a-new-era-of-agent-interoperability/)

### Loop Patterns & Ralph Loop
- [Ralph (GitHub)](https://github.com/snarktank/ralph)
- [Addy Osmani -- Self-Improving Coding Agents](https://addyosmani.com/blog/self-improving-agents/)
- [Phil Schmid -- Can We Close the Loop in 2026?](https://www.philschmid.de/closing-the-loop)
- [Anthropic -- Demystifying Evals for AI Agents](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents)
- [Reflexion: Language Agents with Verbal Reinforcement Learning (arXiv)](https://arxiv.org/abs/2303.11366)

### Critical Analysis
- [METR -- AI Experienced OS Developer Study](https://metr.org/blog/2025-07-10-early-2025-ai-experienced-os-dev-study/)
- [CodeRabbit -- State of AI vs Human Code Generation](https://www.coderabbit.ai/blog/state-of-ai-vs-human-code-generation-report)
- [Stanford/Boneh -- Do Users Write More Insecure Code with AI?](https://arxiv.org/html/2211.03622v3)
- [Veracode -- GenAI Code Security Report](https://www.veracode.com/blog/genai-code-security-report/)
- [Anthropic -- AI Assistance and Coding Skills](https://www.anthropic.com/research/AI-assistance-coding-skills)
- [CMR Berkeley -- Seven Myths about AI and Productivity](https://cmr.berkeley.edu/2025/10/seven-myths-about-ai-and-productivity-what-the-evidence-really-says/)
- [GitClear -- AI Code Quality 2025](https://www.gitclear.com/ai_assistant_code_quality_2025_research)

### Ecosystem
- [OpenAI Codex product page](https://openai.com/codex/)
- [Claude Code product page](https://claude.com/product/claude-code)
- [OpenHands](https://openhands.dev/)
- [Cursor Cloud Agents (TechCrunch)](https://techcrunch.com/2026/03/05/cursor-is-rolling-out-a-new-system-for-agentic-coding/)
- [Factory.ai](https://factory.ai)
- [Cline](https://cline.bot/)
- [Addy Osmani -- My LLM coding workflow going into 2026](https://addyosmani.com/blog/ai-coding-workflow/)

## Open Questions

1. **Cross-session learning**: How to effectively accumulate agent learnings across runs without manual curation? Current best (~37% retention) is insufficient. The human-curated AGENTS.md pattern works but doesn't scale.

2. **Agent-written test trust**: Stanford Law's question -- when both code and tests are agent-written, who validates correctness? Systematic misunderstanding produces code that passes tests while being wrong. Property-based testing and mutation testing may help but aren't yet integrated into agent loops.

3. **Token economics at scale**: Reflexion loops (10 cycles) consume 50x tokens vs single pass. Enterprise scale (3K employees, 10x/day) projects to ~$126K/month. What's the right cost-quality tradeoff for your usage patterns?

4. **Claude Agent SDK TeammateTool maturity**: When does it exit research preview? Could it replace your custom co-research/co-implement orchestration? Worth monitoring Anthropic's engineering blog.

5. **HIPAA implications of autonomous code changes**: Current HIPAA guidance requires documented human review chains. How specific does the audit trail need to be for AI-assisted code? Is git history + PR review sufficient, or do you need explicit AI-attribution metadata?

6. **Skill atrophy in your team context**: Anthropic's study showed 17% lower comprehension in AI-assisted juniors. How does this affect team development when seniors use Level 3-4 automation extensively?

7. **When to upgrade from bash-glue orchestration to SDK-native**: Your co-research/co-implement use bash (`codex exec`) as the integration layer. At what complexity threshold should you switch to programmatic SDK integration (like auto-agent-codex does with the Codex SDK)?
