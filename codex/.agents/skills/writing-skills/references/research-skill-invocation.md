# Claude Code Skill Invocation Failure: Research Summary

> Researched 2026-03-10. Based on web research (Claude agents x3) and codebase analysis (Codex survey) of the dotfiles repo.

## Executive Summary

Claude Code almost never proactively invokes skills despite explicit instructions to do so. This is not a configuration problem — the plumbing is solid (SessionStart hook injects full `using-skills` content wrapped in `<EXTREMELY_IMPORTANT>` tags, CLAUDE.md reinforces with "skills are mandatory"). The failure is a **fundamental behavioral limitation of RLHF-trained LLMs in interactive mode**: proactive tool invocation is out-of-distribution for chat-trained models. The single most impactful fix is rewriting skill descriptions to use directive language with negative constraints ("ALWAYS invoke for X. Do not X directly."), which achieved **100% activation in a 650-trial controlled study** — compared to 20-50% baseline. No hooks or CLAUDE.md changes required.

## Key Concepts

**Proactive vs Reactive Tool Use.** LLMs are trained as reactive systems — they respond to explicit requests. "Scan skills before every task and invoke if matching" is a proactive behavior requiring the model to self-initiate a tool call on every turn. Academic benchmarks (ProactiveBench, PROBE) show even frontier models achieve only ~40% on proactive tasks. ([arXiv:2410.12361](https://arxiv.org/abs/2410.12361), [arXiv:2510.19771](https://arxiv.org/pdf/2510.19771))

**The RLHF Helpfulness Trap.** RLHF trains models on question-answer pairs where the reward signal is: user asks → model responds helpfully. Tool invocation is a trained deviation — it introduces delay and uncertainty where the model could just respond directly. The model's "path of least resistance" is always to answer without tools. ([Anthropic: Sycophancy Research](https://www.anthropic.com/research/towards-understanding-sycophancy-in-language-models))

**Text-Action Decoupling.** What models say (text) and what they do (tool calls) are not tightly coupled. The "GAP" paper found a 79.3% rate where models verbally acknowledged instructions but didn't execute them via tool calls. Claude can recite "I should check skills" and then not do it. ([arXiv:2602.16943](https://arxiv.org/abs/2602.16943))

**Instruction Decay.** The "Lost in the Middle" effect: LLMs attend strongly to the beginning and end of context, poorly to the middle. As conversation grows, CLAUDE.md instructions drift into the low-attention zone. A 39% performance drop is measured in multi-turn vs single-turn across 200K+ conversations. ([arXiv:2307.03172](https://arxiv.org/abs/2307.03172), [arXiv:2505.06120](https://arxiv.org/abs/2505.06120))

## Why Codex Invokes Skills but Claude Code Doesn't

The divergence is overdetermined — multiple independent factors all push in the same direction:

| Factor | Claude Code (Interactive) | Codex (Autonomous) |
|--------|--------------------------|-------------------|
| **Loop architecture** | Terminates on plain text; tool use is optional | Must use tools to make progress; text-only is a dead end |
| **Turn-taking pressure** | User is waiting; trained to respond fast | No user present during execution |
| **RLHF reward landscape** | Helpfulness = direct response | Helpfulness = task completion via tool chains |
| **Instruction position** | Skills in system prompt; decay over conversation | Instructions in task prompt; no conversation to dilute |
| **Escape hatch** | system-reminder says "may or may not be relevant" | No such qualifier |
| **Training** | General chat RLHF (reactive) | codex-1 explicitly trained for agentic tool chains |

The system-reminder escape hatch is particularly damaging. Claude Code re-injects CLAUDE.md periodically but frames it as: *"IMPORTANT: this context may or may not be relevant to your tasks. You should not respond to this context unless it is highly relevant to your task."* This actively encourages the model to ignore its own skill invocation instructions. ([GitHub Issue #18560](https://github.com/anthropics/claude-code/issues/18560))

## Current State (Codebase Survey)

The skill surfacing mechanism in the dotfiles repo is well-architected:

1. **SessionStart hook** (`claude/.claude/hooks/session-start.sh`) reads `~/.claude/skills/using-skills/SKILL.md`, JSON-escapes it, and injects the full body wrapped in `<EXTREMELY_IMPORTANT>` tags into startup context
2. **Shared skill corpus** — `claude/.claude/skills` symlinks to `codex/.agents/skills` (47 skills), so both platforms consume the same definitions
3. **CLAUDE.md reinforcement** — `codex/AGENTS.md` (shared instructions) explicitly states: "Before responding to any task, scan the available skills list... Skills are mandatory when applicable"
4. **`ENABLE_TOOL_SEARCH=true`** — set in settings.json, enabling deferred tool discovery
5. **Agent preloading** — `neb-explorer.md` demonstrates skill preloading via frontmatter (`skills: neb-ms-conventions`)

The plumbing works. The model doesn't follow it. The hook fires on `startup|resume|clear|compact`, and the 23.5% discovery signal (172/732 sessions) warrants investigation — this may reflect sessions starting before the hook is registered, or hook failures that silently return empty context.

## The Evidence Base

### This is a known, documented problem

| Source | Finding |
|--------|---------|
| [GitHub #15443](https://github.com/anthropics/claude-code/issues/15443) | Claude ignores CLAUDE.md while claiming to understand it |
| [GitHub #18454](https://github.com/anthropics/claude-code/issues/18454) | Skills and CLAUDE.md dropped during multi-step tasks |
| [GitHub #21119](https://github.com/anthropics/claude-code/issues/21119) | Claude defaults to training patterns over CLAUDE.md |
| [GitHub #14851](https://github.com/anthropics/claude-code/issues/14851) | Commands/skills loaded into context without being invoked |
| [Scott Spence](https://scottspence.com/posts/claude-code-skills-dont-auto-activate) | Skills don't auto-activate despite matching descriptions |
| [Paddo.dev](https://paddo.dev/blog/claude-skills-controllability-problem/) | Skills rely on LLM reasoning, not algorithmic matching — inherently non-deterministic |

### Empirical activation rates (650 trials)

| Description Style | Activation Rate |
|-------------------|----------------|
| No intervention (baseline) | ~20% |
| Passive/informative description | 77% |
| Directive + negative constraint ("ALWAYS invoke... Do not X directly") | **100%** |
| Simple instruction hook | 20% |
| Forced evaluation hook | 84% |
| Directive description + hook + CLAUDE.md | **100%** |

Source: [Medium — Ivan Seleznov, 650-trial study](https://medium.com/@ivan.seleznov1/why-claude-code-skills-dont-activate-and-how-to-fix-it-86f679409af1)

The critical finding: **directive descriptions alone match the best combined approach**. Hooks add marginal safety-net value but descriptions do the heavy lifting.

## Root Causes (Ranked by Impact)

1. **Training distribution mismatch** — proactive self-initiated tool use is out-of-distribution for RLHF chat models. The model was trained to respond, not to pre-check.

2. **Architecture incentives** — Claude Code's chat loop terminates on text; tool use is always the harder path. Codex's autonomous loop makes tools the only path forward.

3. **Skill descriptions are passive** — current descriptions use "Use when..." language (Variant B). The 650-trial study shows this achieves ~85%, not 100%. The gap is real and measurable.

4. **Instruction competition** — CLAUDE.md skill instructions compete with ~150 other instructions for attention. More rules = less compliance per rule. The "200 rules" ceiling is real.

5. **system-reminder escape hatch** — the injected "may or may not be relevant" qualifier actively undermines CLAUDE.md instructions.

6. **Attention decay over conversation** — skill-scan instructions at session start lose salience as context fills with task-specific content.

## Recommended Approach

Ordered by impact. Each layer is independent — implement whichever you're comfortable with.

### Layer 1: Rewrite skill descriptions (highest impact, zero cost)

Convert all 47 skill `description` fields to the Variant C pattern:

```yaml
# Before (Variant B — current style)
description: Use when implementing or remediating security controls in code

# After (Variant C — directive + negative constraint)
description: ALWAYS invoke for security control implementation (authn/authz, input validation, secrets, encryption). Do not implement security controls directly.
```

This achieved 100% activation in controlled trials. It's the single highest-leverage change.

**Important caveat for Claude 4.6:** Anthropic's latest guidance says to dial back "CRITICAL"/"MUST" language because it causes overtriggering on other tools. The Variant C pattern is different — it's in the *description*, not the system prompt, and includes a specific negative constraint that targets the behavior precisely. Monitor for side effects.

### Layer 2: Ensure visibility

- Run `/context` to verify skills appear in loaded context
- If skills are truncated: set `SLASH_COMMAND_TOOL_CHAR_BUDGET=30000` in settings.json env
- Ensure all descriptions are single-line YAML (multi-line breaks parsing and silently drops skills)

### Layer 3: Slim CLAUDE.md

- Current codex/AGENTS.md (shared instructions) is well-structured but the skill section could be leaner
- Move enforcement to descriptions (Layer 1) and hooks (Layer 4)
- The using-skills content injected via SessionStart is valuable but may be doing more harm than good if it pushes context past the attention threshold

### Layer 4: UserPromptSubmit hook (safety net)

A lightweight forced-eval hook that fires on every prompt:

```bash
#!/bin/bash
cat <<'EOF'
Before implementing, check <available_skills> for matches. If relevant, invoke via Skill() first.
EOF
```

Keep it short — a verbose hook adds context pollution. This is insurance, not the primary mechanism.

### Layer 5: Investigate the 23.5% discovery signal

The SessionStart hook only fires in ~1 in 4 sessions. This deserves investigation:
- Is the matcher pattern (`startup|resume|clear|compact`) too narrow?
- Does the hook fail silently when `~/.claude/skills` symlink is unresolvable?
- Are project-scoped sessions bypassing the global hook?

### What NOT to do

- **Don't add more CLAUDE.md instructions** — you're already competing with the instruction budget
- **Don't use "CRITICAL"/"MUST"/"BLOCKING" language** — Anthropic says this causes overtriggering on Claude 4.6
- **Don't use LLM-eval hooks** (calling another LLM to decide skill relevance) — 0-100% variance, adds latency
- **Don't expect 100% compliance from prompting alone** — this is an architectural limitation of interactive chat mode, not a fixable prompt bug

## Trade-offs & Decision Points

### Accept the limitation vs fight it

The interactive chat loop structurally biases against proactive tool invocation. You can improve rates from ~20% to ~100% with Layer 1 (descriptions), but you're always working against the architecture. The alternative: accept that Claude Code is user-driven for skills (slash commands) and Codex is agent-driven, and design workflows accordingly.

### Directive descriptions: precision vs overtriggering

Variant C descriptions are aggressive ("ALWAYS invoke", "Do not X directly"). With 47 skills, there's a risk of Claude invoking skills for tasks that only loosely match. Monitor and tune descriptions for specificity.

### Hook overhead vs reliability

Every UserPromptSubmit hook adds tokens to every prompt. With a short hook (1-2 lines), the cost is trivial. With a verbose forced-eval hook, you're consuming instruction budget that could go to task-specific context.

### Using-skills injection: help or harm?

The SessionStart hook injects the full using-skills SKILL.md (~55 lines) into startup context. This is ~500 tokens that may be pushing CLAUDE.md past the attention threshold. Consider: does the model perform better with the using-skills injection, or would those tokens be better spent on task context?

## References & Sources

### Academic Research
- [Proactive Agent (ProactiveBench)](https://arxiv.org/abs/2410.12361) — LLMs can't anticipate tasks without explicit instructions
- [PROBE: Beyond Reactivity](https://arxiv.org/pdf/2510.19771) — Best models achieve ~40% on proactive tasks
- [Lost in the Middle](https://arxiv.org/abs/2307.03172) — U-shaped attention curve in long context
- [LLMs Get Lost in Multi-Turn](https://arxiv.org/abs/2505.06120) — 39% performance drop in multi-turn
- [Mind the GAP](https://arxiv.org/abs/2602.16943) — Text-action decoupling in tool use
- [Sycophancy in LMs](https://www.anthropic.com/research/towards-understanding-sycophancy-in-language-models) — RLHF creates respond-not-initiate bias
- [ReTool](https://arxiv.org/abs/2504.11536) — RL for strategic tool use (separate training needed)
- [Toxic Proactivity](https://arxiv.org/abs/2602.04197) — Helpfulness objective can cause wrong tool use

### Anthropic Official
- [Context Engineering Guide](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)
- [Writing Effective Tools](https://www.anthropic.com/engineering/writing-tools-for-agents)
- [Claude Code Skills Docs](https://code.claude.com/docs/en/skills)
- [Claude 4.6 Prompting Best Practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices)

### Community Evidence
- [650-Trial Skill Activation Study](https://medium.com/@ivan.seleznov1/why-claude-code-skills-dont-activate-and-how-to-fix-it-86f679409af1)
- [Scott Spence: Skills Don't Auto-Activate](https://scottspence.com/posts/claude-code-skills-dont-auto-activate)
- [Paddo: Controllability Problem](https://paddo.dev/blog/claude-skills-controllability-problem/)
- [Paddo: Hooks Solution](https://paddo.dev/blog/claude-skills-hooks-solution/)
- [Scott Spence: Measuring Skill Activation](https://scottspence.com/posts/measuring-claude-code-skill-activation-with-sandboxed-evals)
- [SCAN Method for Instruction Drift](https://gist.github.com/sigalovskinick/c6c88f235dc85be9ae40c4737538e8c6)
- [HumanLayer: CLAUDE.md Best Practices](https://www.humanlayer.dev/blog/writing-a-good-claude-md)

### GitHub Issues
- [#15443: Ignores CLAUDE.md while claiming to understand](https://github.com/anthropics/claude-code/issues/15443)
- [#18454: Skills dropped during multi-step tasks](https://github.com/anthropics/claude-code/issues/18454)
- [#21119: Defaults to training patterns over CLAUDE.md](https://github.com/anthropics/claude-code/issues/21119)
- [#18560: system-reminder undermines CLAUDE.md](https://github.com/anthropics/claude-code/issues/18560)
- [#14851: Skills loaded but not invoked](https://github.com/anthropics/claude-code/issues/14851)

## Open Questions

- **Can the 650-trial result be reproduced on Claude Opus 4.6?** The study may have been on an earlier model. Behavior changes between releases.
- **Does `SLASH_COMMAND_TOOL_CHAR_BUDGET` actually affect skill visibility?** Needs empirical verification with `/context`.
- **What explains the 23.5% SessionStart hook fire rate?** Is this a hook configuration issue or a platform limitation?
- **Would removing the using-skills SessionStart injection and relying solely on Variant C descriptions perform better?** The injection may be consuming attention budget without adding compliance.
- **Is there a way to get the system-reminder "may or may not be relevant" language changed?** This is a platform-level issue that undermines all CLAUDE.md-based enforcement.
- **Can skill descriptions include a compressed few-shot example** (e.g., "Example: user says 'fix this auth bug' → invoke secure-code-guardian") without hitting the character budget?

---

*Research conducted 2026-03-10. Sources: 3 Claude web research agents, 1 Codex codebase survey. 3 Codex web searches were dispatched but outputs lost to sandbox/tee path issue.*
