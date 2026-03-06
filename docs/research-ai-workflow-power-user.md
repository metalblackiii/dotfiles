# Best-in-Class AI Development Workflows: Claude Code + Codex Power User Guide

> Researched 2026-03-06. Based on official Anthropic documentation, community practitioner reports (HN, Reddit, Twitter/X), and comparative tool analysis.

---

## Executive Summary

Your existing Claude-writes/Codex-reviews workflow in parallel windows is a documented best practice — the internet has formalized it into a named pattern with first-class tooling (`claude-review-loop`, SmartScope's three-level framework). You're not doing it wrong; you're doing it manually when you could automate it.

Five upgrades have the highest ROI for your specific setup:

1. **Git worktrees instead of multiple terminal windows** — `claude --worktree feature-name` gives each instance proper isolation (separate branch, no file conflicts, auto-cleanup)
2. **Formalize the review loop with a SKILL.md** — turn your manual Codex review into a `/codex-review` command with verdict-driven iteration before going fully automated
3. **CLAUDE.md surgery** — the sweet spot is under 200 lines with a WHY/WHAT/HOW three-part structure and path-scoped rules for context-specific guidance
4. **Hooks for automation** — PostToolUse hooks that run formatters eliminate an entire class of back-and-forth; a Stop hook enforces completion before session exit
5. **Spec-interview workflow for large features** — one session gathers requirements (Claude interviews you), fresh session implements — separating planning and execution contexts produces measurably better output

---

## Key Concepts

**Context window discipline** is the primary failure mode — not hallucination, not sycophancy. The 200K token window fills faster than it appears (MCP tools consume 8–30% before you write a word; the default system prompt uses ~19K tokens, ~10% of the budget). When context degrades, Claude reverts to abandoned approaches. Fix: proactive session management via `/clear` between unrelated tasks, `/compact` with custom guidance, and the 60% rule as a hard checkpoint.

**The evaluator-optimizer pattern** is Anthropic's explicitly recommended review pattern: generate → review against criteria → refine, each as a separate operation. This is the formal name for what you're already doing with Codex review. The key upgrade is making criteria explicit and structured (typed output with severity + file/line citations) rather than open-ended prose.

**Session discipline** means treating each Claude session as disposable context. Durable decisions go in git (commits, CLAUDE.md, spec files). Context goes in sessions. The pattern: commit obsessively, branch per feature, start fresh sessions for unrelated work.

**Git worktrees** are the isolation mechanism for parallel agent work. Each worktree is a separate directory with its own branch, sharing one `.git` database. Agents in different worktrees cannot stomp each other's files — structurally different from two terminal windows on the same branch.

---

## Ecosystem Landscape

| Tool | Role | Context | Key Strength | Key Weakness |
|------|------|---------|--------------|--------------|
| Claude Code CLI | Primary agentic coding | 200K (reliable) | Autonomous multi-file refactors, hooks, subagents, CI/CD | No inline autocomplete |
| Codex CLI | Reviewer / executor | Variable | 2–3x fewer tokens, GPT-5.2 excels at bug-finding | Loses context on Ctrl-C, weaker UX |
| Claude Code VS Code ext | IDE layer | 200K (same as CLI) | Visual diffs, editable plan mode, parallel tabs | Missing full CLI parity (issue #9119) |
| Cursor | IDE-first autonomous | ~70–120K (silently truncated) | Tab completions, pre-indexed embeddings | Context truncation, no headless mode |
| GitHub Copilot | Background autocomplete | Open files only | Inline suggestions, $10/mo, GitHub-native | Not agentic, narrow context |
| Agent Teams (experimental) | Multi-agent coordination | Per-agent 200K | Teammates message each other directly | 15x token cost, known stability issues |

**Benchmark context (2026):** Claude Code Sonnet 4.5 scores 77.2% SWE-bench. In one documented test, Claude Code used 5.5x fewer tokens than Cursor for equivalent tasks.

---

## Best Practices

### Workflow Structure

**Explore → Plan → Code → Commit** is the consensus workflow for non-trivial tasks. Tell Claude explicitly not to write code during Explore and Plan phases.

**Plan mode before anything complex.** `Shift+Tab` twice. Boris Cherny's team (Claude Code's creator) sometimes has one Claude draft the plan while another reviews it "as a staff engineer." Switch back to planning immediately when obstacles arise.

**Test-first as completion signal.** Write tests first, then implementation. Tests define a clear "done" state that prevents "mission accomplished" hallucinations. Boris Cherny: "Give Claude a way to verify its work. Testing improves final output quality 2–3x."

**Spec-interview workflow for large features:**
1. Start a session, tell Claude not to code yet
2. `"Interview me about [feature] using AskUserQuestion. Cover implementation, UI/UX, edge cases, tradeoffs. Write a complete spec to SPEC.md when done."`
3. Close that session — requirements context is spent
4. Fresh session: `claude --permission-mode plan` to implement from spec

**Voice dictation.** Both Bas Nijholt (via local Whisper) and incident.io (via SuperWhisper) independently discovered that voice narration produces richer context than typing. You can't help but explain the "why" when speaking.

### CLAUDE.md Conventions

**The three-part structure:**
1. **WHY** — project purpose, what each component does
2. **WHAT** — project structure, tech stack, monorepo map, env vars
3. **HOW** — practical commands (build, test, lint), verification methods, git workflow

**Key rules:**
- Target under 200 lines. Over 200, Claude loses rules in the noise.
- Use `@path/to/file` imports to pull in docs without bloating the main file
- Use `IMPORTANT:` or `YOU MUST` for iron rules — materially improves adherence
- Use `.claude/rules/` for topic-specific files with YAML frontmatter `paths:` for path-scoped loading
- Update CLAUDE.md after every correction: "Update CLAUDE.md so you don't make that mistake again"

**Never auto-generate with `/init`.** The file has the highest downstream leverage — spend time on it manually.

**What NOT to include:**
- Style/formatting rules → use PostToolUse hooks instead
- Database schema details → distracts on unrelated tasks
- Code snippets → use `@file` references instead (snippets go stale)
- Instructions you could enforce deterministically with a hook
- Context-specific guidance → use path-scoped `.claude/rules/` instead

**Pattern consistency beats explicit rules.** LLMs are in-context learners. Cleaning up code inconsistencies often does more than adding CLAUDE.md rules.

### Context Window Management

**The 60% rule.** Treat 60% context usage as a hard checkpoint to compact or start fresh. Performance degrades non-linearly.

**`/clear` vs `/compact`:**
- `/compact [instructions]` — summarizes history preserving situational awareness; use mid-task
- `/clear` — full reset; use between unrelated tasks

**Tool hygiene.** Each MCP server present (whether used or not) consumes 8–30% of context. Use `/context` to audit. Enable `ENABLE_TOOL_SEARCH=auto` for ~85% context reduction when you have many MCP servers (requires Sonnet 4+ or Opus 4+).

**Set `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=50`** to trigger compaction before performance degrades, rather than at 95%.

**Session naming:** `/rename oauth-migration`. Resume by name: `claude --resume oauth-migration`.

**Avoid manual file edits during active sessions** — breaks prompt caching and increases token costs.

### Hooks: Deterministic Guarantees

Unlike CLAUDE.md instructions (advisory), hooks fire at specific lifecycle events regardless of what Claude decides.

**High-value hooks to add immediately:**

Auto-format after edits:
```json
{
  "hooks": {
    "PostToolUse": [{
      "matcher": "Edit|Write",
      "hooks": [{"type": "command", "command": "jq -r '.tool_input.file_path' | xargs npx prettier --write 2>/dev/null || true"}]
    }]
  }
}
```

Desktop notification on idle (essential for parallel sessions):
```json
{
  "hooks": {
    "Notification": [{
      "matcher": "",
      "hooks": [{"type": "command", "command": "osascript -e 'display notification \"Claude needs input\" with title \"Claude Code\"'"}]
    }]
  }
}
```

Re-inject context after compaction:
```json
{
  "hooks": {
    "SessionStart": [{
      "matcher": "compact",
      "hooks": [{"type": "command", "command": "echo 'Context was compacted. Key constraints: [your reminders here]'"}]
    }]
  }
}
```

Stop hook for completion verification (prevent premature exit):
```json
{
  "hooks": {
    "Stop": [{
      "hooks": [{"type": "prompt", "prompt": "Are all tasks complete and tests passing? If not: {\"ok\": false, \"reason\": \"what remains\"}"}]
    }]
  }
}
```

Always check `stop_hook_active` in Stop hooks to prevent infinite loops — if true, return early.

### Non-Obvious CLI Power Features

- **`ultrathink`** — include in a prompt to allocate 31,999 thinking tokens. Verified via source code deobfuscation by Simon Willison. Not documented anywhere officially.
- **`CLAUDE_CODE_EFFORT_LEVEL=high`** — global effort level; toggle per-session with `Option+T`
- **`--fork-session`** — when resuming, creates a new session ID (branches a conversation without overwriting the original)
- **`--allowedTools "Bash(git log *)"` pattern syntax** — fine-grained allowlisting that eliminates click-through fatigue for safe commands
- **`--json-schema`** — validated JSON output in print mode; enables scripting Claude's output
- **`CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=50`** — trigger compaction before performance degrades
- **`!bash` prefix** — run a shell command mid-session without leaving Claude
- **`Shift+Tab` cycles permission modes**: Normal → Auto-Accept → Plan
- **`Ctrl+G` in Plan mode** — opens the plan in your text editor for direct editing before execution
- **`Esc+Esc` / `/rewind`** — restore conversation + code state to any checkpoint independently
- **`Ctrl+B`** — background a running task
- **`claude --remote "Fix the login bug"`** — create a new web session on claude.ai

---

## The Claude-Writes / Codex-Reviews Pattern: Three Levels

Your existing workflow is validated. The community has formalized three implementation levels:

| Level | Mechanism | Triggering | Best For |
|-------|-----------|------------|---------|
| **1: SKILL.md** | `/codex-review` slash command | Manual (you control when) | Validating the pattern value |
| **2: Stop Hook Plugin** | `claude-review-loop` (hamelsmu) | Automatic on task completion | Preventing missed reviews |
| **3: Pipeline** | Full orchestration with approval gates | Workflow-managed | Team-scale governance |

**Start at Level 1.** Validate that cross-model review is catching things you care about before automating.

### Level 1: SKILL.md Implementation

Create `~/.claude/skills/codex-review/SKILL.md`:
```markdown
---
name: codex-review
description: Run Codex peer review on current work, iterate until VERDICT: APPROVED
---
Export a summary of current changes to /tmp/review-context.md, then:

1. Run: codex exec --sandbox read-only "Review changes in /tmp/review-context.md.
   Return VERDICT: APPROVED or VERDICT: REVISE with specific issues (file:line, description, severity 1-5)"
2. If VERDICT: REVISE, address each issue and repeat (up to 5 rounds)
3. For the final audit, run Codex in a fresh invocation (not --resume) with AUDIT: PASS/CONCERNS verdict
```

**Why cross-model review works:** Claude and Codex have different training — Claude excels at catching code that violates stated intent and explanation; GPT-5.2-Codex excels at bug-finding and severity assessment. One reported Level 1 run caught 14 issues including auth gaps, shell quoting bugs, and schema inconsistencies that the writing session missed.

**Level 1.5 (fresh-context audit):** After the iterative loop converges, run one final Codex review in a brand-new session. Accumulated context in the resume loop can bias re-evaluation. Use `AUDIT:` as the verdict keyword (not `VERDICT:`) to prevent triggering the retry loop.

### Level 2: Automated Stop Hook

`hamelsmu/claude-review-loop` intercepts session completion via a Stop Hook. When Claude finishes, the hook launches Codex (up to 4 parallel sub-agents), returns findings, and blocks exit (exit code 2) — forcing Claude to address feedback before the session ends.

**Known gotcha:** Stop Hooks fire when Claude pauses for clarification, not just when work is complete. This triggers reviews on incomplete work. Set `REVIEW_LOOP_CODEX_FLAGS="--sandbox read-only"` at minimum.

### When Agents Disagree

Mild disagreement between agents *improves outcomes* — it forces inspection rather than replication. Research: a learned consensus module (78% accuracy resolving disagreements) significantly outperforms majority vote (68%).

Use structured output schemas (`{verdict, severity, findings: [{file, line, description}]}`). Machine-detectable disagreements enable triage; open-ended prose does not.

---

## IDE vs CLI: When Each Shines

Your CLI-first setup is optimal for your workload. The VSCode extension adds one genuinely exclusive feature worth knowing:

| Feature | CLI | VSCode Extension |
|---------|-----|-----------------|
| Full 200K context | ✓ | ✓ (same models, same auth) |
| Headless / CI/CD | ✓ | ✗ |
| `!bash` shortcut | ✓ | ✗ |
| `Esc+Esc` rewind | ✓ | Checkpoint-only |
| Full permission flags | ✓ | Partial |
| **Visual diff accept/reject** | ✗ | **✓** |
| **Editable plan mode** | Read-only | **✓ (full markdown edit before execution)** |
| Multiple parallel tabs | ✗ (worktrees instead) | ✓ |
| `@browser` integration | ✗ | ✓ |

**The one reason to open the extension:** When you want to edit Claude's plan directly as a markdown document before execution starts — add steps, remove steps, add constraints — rather than just approving or declining. For complex multi-file changes, this is materially better than the CLI's read-only plan view.

**For everything else: stay in the terminal.** The CLI has more capability, better keyboard control, full rewind semantics, and composability.

---

## Gap Analysis: Your Current Setup vs Best Practices

| Practice | Your Current State | Upgrade | Effort |
|----------|--------------------|---------|--------|
| Parallel sessions | Multiple terminal windows | `claude --worktree` for isolation | Low |
| Peer review | Manual Codex review | Level 1 SKILL.md → Level 2 Stop Hook | Low → Medium |
| CLAUDE.md structure | Unknown | WHY/WHAT/HOW + path-scoped rules | Low |
| Auto-formatting | Unknown | PostToolUse hook → Prettier | Low |
| Context discipline | Unknown | Session naming, 60% rule, `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` | Low |
| Completion signal | Unknown | Tests before implementation | Low (mindset) |
| Spec-interview workflow | Unknown | Separate requirements gathering session | Low |
| `ultrathink` | Likely unknown | Use in reasoning-heavy prompts | Zero |
| Idle notifications | Unknown | osascript Notification hook | Low |
| MCP tool audit | Unknown | `/context` audit + remove unused | Low |
| VSCode extension | Sparingly | Plan editing for complex changesets | Low (already installed) |
| Agent Teams | Not using | Experimental, high cost — skip for now | Skip |

---

## Trade-offs & Decision Points

**Manual review vs automated Stop Hook (Level 1 vs Level 2):**
Automated fires more consistently but also fires at wrong moments (when Claude pauses, not when work is complete). For solo use, the manual `/codex-review` command gives timing control at the cost of occasionally forgetting. Move to Level 2 after validating the loop's value with Level 1.

**Multiple windows vs git worktrees:**
Windows on the same branch can stomp each other's files mid-task. Worktrees eliminate this. The only trade-off: you merge branches at the end — which you were doing anyway. `claude --worktree feature-name` handles creation and cleanup automatically.

**Subagents vs Agent Teams:**
Subagents are stable, cheaper, and return summarized results to keep your main context clean. Agent Teams (experimental) add direct inter-agent messaging but cost ~15x more tokens. Use subagents now; revisit Agent Teams when they graduate from experimental.

**Codex as executor vs reviewer:**
Codex is 2–3x more token-efficient than Claude Code and runs in a cloud sandbox. Worth using as the executor for clearly-specified, well-understood tasks. For ambiguous or architectural work, stay in Claude Code where the dialogue model shines.

---

## Recommended Approach

**Week 1: Zero-friction wins**
1. `alias cw='claude --worktree'` — start all new feature sessions with `cw feature-name`
2. Audit and restructure CLAUDE.md with WHY/WHAT/HOW, trim to under 200 lines
3. Add `ultrathink` to prompts requiring careful reasoning
4. `/rename [workstream-name]` on every session you might resume
5. Add the idle notification hook for parallel session awareness

**Week 2: Review loop formalization**
6. Create `~/.claude/skills/codex-review/SKILL.md` (Level 1)
7. Run 5 real reviews with `/codex-review` — is Codex catching things Claude missed?
8. Add PostToolUse hook to auto-run Prettier after every Edit/Write

**Week 3: Context discipline and spec workflow**
9. Set `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=50`
10. Try the spec-interview workflow on one medium-complexity feature
11. If the review loop is proving value: install `claude-review-loop` (Level 2)

**Ongoing:**
- Update CLAUDE.md after every correction — reflex, not optional
- Audit MCP tools periodically with `/context`
- Migrate context-specific CLAUDE.md rules to `.claude/rules/` with path frontmatter as the file grows
- Open the VSCode extension for plan editing on complex multi-file changesets

---

## References & Sources

### Official Anthropic Documentation
- [CLI Reference](https://code.claude.com/docs/en/cli-reference) — full flags table (40+ flags)
- [Best Practices](https://code.claude.com/docs/en/best-practices)
- [Hooks Guide + Reference](https://code.claude.com/docs/en/hooks-guide) — all 18 hook events
- [Agent Teams](https://code.claude.com/docs/en/agent-teams)
- [Subagents](https://code.claude.com/docs/en/sub-agents)
- [Memory System](https://code.claude.com/docs/en/memory)
- [VS Code Extension](https://code.claude.com/docs/en/vs-code)
- [Building Effective Agents](https://www.anthropic.com/research/building-effective-agents)
- [Anthropic Engineering: Multi-Agent Research System](https://www.anthropic.com/engineering/multi-agent-research-system)

### Multi-Agent Peer Review
- [hamelsmu/claude-review-loop (GitHub)](https://github.com/hamelsmu/claude-review-loop)
- [SmartScope: Three Levels of Review Loop Automation](https://smartscope.blog/en/blog/claude-code-codex-review-loop-automation-2026/)
- [O'Reilly Radar: Auto-Reviewing Claude's Code](https://www.oreilly.com/radar/auto-reviewing-claudes-code/)
- [GitHub Blog: Multi-Agent Workflows Often Fail](https://github.blog/ai-and-ml/generative-ai/multi-agent-workflows-often-fail-heres-how-to-engineer-ones-that-dont/)
- [GitHub Blog: Agent HQ](https://github.blog/news-insights/company-news/pick-your-agent-use-claude-and-codex-on-agent-hq/)

### Community Practitioners
- [Boris Cherny (Claude Code creator) — Setup thread](https://twitter-thread.com/t/2007179832300581177)
- [Bas Nijholt: On Agentic Coding](https://www.nijho.lt/post/agentic-coding/)
- [incident.io: Git Worktrees + Claude Code](https://incident.io/blog/shipping-faster-with-claude-code-and-git-worktrees)
- [HumanLayer: Writing a Good CLAUDE.md](https://www.humanlayer.dev/blog/writing-a-good-claude-md)
- [Arize AI: CLAUDE.md Prompt Optimization (+10.87% gains)](https://arize.com/blog/claude-md-best-practices-learned-from-optimizing-claude-code-with-prompt-learning/)
- [Simon Willison: ultrathink discovery + best practices](https://simonwillison.net/2025/Apr/19/claude-code-best-practices/)
- [Thomas Landgraf: Context Engineering](https://thomaslandgraf.substack.com/p/context-engineering-for-claude-code)
- [Sankalp: Claude Code 2.0 Guide](https://sankalp.bearblog.dev/my-experience-with-claude-code-20-and-how-to-get-better-at-using-coding-agents/)
- [Spotify Engineering: Context Engineering for Background Agents](https://engineering.atspotify.com/2025/11/context-engineering-background-coding-agents-part-2)
- [Armin Ronacher: Agentic Coding](https://lucumr.pocoo.org/2025/6/12/agentic-coding/)
- [24 Claude Code Tips](https://dev.to/oikon/24-claude-code-tips-claudecodeadventcalendar-52b5)
- [Ask HN: How Do You Actually Use Claude Code Effectively?](https://news.ycombinator.com/item?id=44362244)

### IDE vs CLI Comparisons
- [builder.io: Cursor vs Claude Code](https://www.builder.io/blog/cursor-vs-claude-code)
- [arize.com: Power User's Playbook](https://arize.com/blog/claude-code-vs-cursor-a-power-users-playbook/)
- [claudelog.com: CLI vs VS Code Extension](https://claudelog.com/faqs/claude-code-cli-vs-vscode-extension-comparison/)
- [graphite.com: AI Workflow Patterns](https://graphite.com/guides/programming-with-ai-workflows-claude-copilot-cursor)
- [starkinsider.com: Dual AI Workflow](https://www.starkinsider.com/2025/10/claude-vs-cursor-dual-ai-coding-workflow.html)

---

## Open Questions

- **Codex CLI in Stop Hooks:** Does `codex exec --sandbox read-only` work reliably within a Claude Code Stop Hook? The `claude-review-loop` plugin documents edge cases around timing and incomplete work.
- **Agent Teams graduation:** When do Agent Teams become stable enough for production use? Current known limitations (no session resumption, task status lag) make them impractical today.
- **`ultrathink` across model tiers:** Does the keyword trigger the same token allocation on Sonnet 4.6 vs Opus 4.6? The source code analysis was version-specific.
- **Codex as primary executor:** At 2–3x token efficiency vs Claude Code, is Codex worth using as the primary executor for well-specified tasks rather than just reviewer? Depends on your token bill composition and how often tasks are truly well-specified upfront.
