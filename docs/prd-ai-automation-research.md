# PRDs in the AI Automation Era

## Context

This document captures a research summary on:

1. What a PRD is
2. Why PRDs matter more when using AI coding agents
3. How harness engineering and loop-based execution relate
4. What to do in practice to turn PRDs into working code safely

As of February 23, 2026, the strongest industry pattern is not "AI writes code from vague prompts." The pattern is:

- clear intent documents (PRD/spec)
- strong execution harnesses (tools + constraints + tests)
- looped execution with objective feedback
- human oversight at decision and release boundaries

## What Is a PRD?

PRD stands for Product Requirements Document. It defines what should be built, who it serves, why it matters, constraints, and how success is measured.

A useful PRD answers:

- What user or business problem are we solving?
- Who are the users and what jobs are they trying to do?
- What is in scope and explicitly out of scope?
- What behavior must exist (functional requirements)?
- What qualities must hold (non-functional requirements: reliability, security, performance, compliance)?
- How will we know the work is done (acceptance criteria)?
- How will we know the work succeeded after release (metrics)?

A PRD is not:

- a low-level implementation plan
- a copy of engineering tickets
- a static artifact that never changes

## Why PRDs Matter More for AI Coding

In AI-assisted and agentic delivery, the PRD becomes part of the control system for code generation. The model fills ambiguity quickly. If intent is underspecified, the system still produces output, but often with hidden misalignment.

Practical consequence:

- Vague PRD -> high iteration cost, unstable behavior, rework
- Clear PRD + clear acceptance criteria -> reliable agent progress and lower supervision cost

## Harness Engineering: The Missing Layer

Harness engineering means designing the environment around the model so it can execute work predictably.

Common harness elements:

- execution tools (shell, test runner, linters, typechecks, browser automation)
- repository instructions (`AGENTS.md`, tool-specific instruction files)
- task/planning artifacts (`PLANS.md`, execution logs, decision records)
- quality gates (tests must pass, review checks required, policy checks)
- observability (logs, traces, run summaries)
- eval suites (capability + regression checks)

Without a harness, even a good model behaves inconsistently. With a harness, the same model can deliver repeatable progress.

## Loop Programming and the "Ralph Wiggum Loop"

"Ralph Wiggum loop" is a community term for repeated agent execution cycles toward a defined goal. In practice:

1. agent takes a step
2. harness runs checks/evals
3. failures or gaps feed the next step
4. loop stops when criteria are satisfied

The important part is not infinite iteration. The important part is objective back-pressure:

- tests
- static analysis
- policy checks
- regression evals
- human approval gates

Looping without back-pressure amplifies mistakes faster.

## Converting PRDs to Code Effectively

Use this pipeline:

1. Intent: PRD with clear outcomes, constraints, and non-goals
2. Execution breakdown: convert PRD into milestone/task plan
3. Harness setup: ensure agent can run tests, lint, build, and collect feedback
4. Loop execution: run incremental cycles with small diffs and fast validation
5. Eval gate: run capability + regression evals before merge/release
6. Human gate: approve product intent, risk posture, and release decision

## Failure Modes to Avoid

- Ambiguous requirements and implied assumptions left unstated
- Missing non-goals, causing scope drift
- Subjective "looks good" completion criteria
- No regression evals after first success
- Overfitting to benchmark numbers without production-grounded checks
- Treating agent output as done before product/security/compliance review

## Recommended PRD Quality Bar for Agentic Teams

Before implementation starts, a PRD should be able to answer:

- Problem: What outcome changes, and for whom?
- Scope: What is included and excluded in this iteration?
- Behavior: What exact user/system behaviors are required?
- Constraints: What must remain true (security, latency, cost, compliance)?
- Acceptance: What objective checks determine completion?
- Measurement: Which post-release metrics define success/failure?
- Risk: What could go wrong and what are the mitigation plans?

If these are unclear, the correct action is to improve the PRD before scaling agent execution.

## Sources

- Atlassian PRD guide: <https://www.atlassian.com/agile/product-management/requirements>
- Amazon Working Backwards context (PR/FAQ): <https://www.aboutamazon.com/news/workplace/an-insider-look-at-amazons-culture-and-processes>
- Working Backwards resources: <https://workingbackwards.com/resources/working-backwards-pr-faq/>
- OpenAI Harness Engineering (Feb 11, 2026): <https://openai.com/index/harness-engineering/>
- OpenAI Codex Exec Plans (`PLANS.md`): <https://developers.openai.com/cookbook/articles/codex_exec_plans>
- OpenAI agent evals guide: <https://developers.openai.com/api/docs/guides/agent-evals>
- OpenAI SWE-bench evaluation update (Feb 23, 2026): <https://openai.com/index/why-we-no-longer-evaluate-swe-bench-verified/>
- Anthropic Building Effective Agents: <https://www.anthropic.com/engineering/building-effective-agents>
- Anthropic Effective Harnesses for Long-Running Agents: <https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents>
- Anthropic Demystifying Evals for AI Agents: <https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents>
- GitHub custom instructions: <https://docs.github.com/copilot/customizing-copilot/adding-custom-instructions-for-github-copilot>
- GitHub issue forms syntax: <https://docs.github.com/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-issue-forms>
- `AGENTS.md` open format: <https://github.com/agentsmd/agents.md>
- Geoffrey Huntley on the Ralph loop: <https://ghuntley.com/ralph/> and <https://ghuntley.com/loop/>
- Back-pressure framing: <https://banay.me/dont-waste-your-backpressure/>
