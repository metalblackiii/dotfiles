---
name: reflect
description: Use when the user requests a session retrospective — reflecting on what worked, what didn't, and what to improve. Triggers include "reflect", "wrap up", "retro", or /reflect.
---

# Session Reflection

End-of-session post-mortem. Review what happened, surface what we learned,
and propose improvements. This is a conversation, not a monologue — ask
questions, confirm assumptions, let the user steer.

If the session was short or routine with nothing notable, say so and stop.

## Step 1: Retro

Review the session and present findings organized by these questions. Skip
any question with no findings. Be specific — name files, decisions, errors,
and turning points.

**What worked?**
Approaches, patterns, or decisions worth repeating. Things that went smoothly
or saved time. Architectural choices that paid off.

**What didn't work?**
Wrong turns, failed approaches, wasted effort. Be honest — this is the most
valuable part. Include things the agent got wrong, not just external blockers.

**What surprised us?**
Unexpected behavior, things we assumed wrong, undocumented quirks discovered.
Domain insights about the codebase, infrastructure, or problem space.

**What would we do differently?**
With hindsight, what's the better approach? Not just for the agent — include
process improvements, missing context that would have helped, or tooling gaps.

## Step 2: Propose Changes

Based on the retro, propose concrete changes. **Do not auto-apply.** Present
each proposal for the user to accept, reject, or modify.

### Scoping rule

Before proposing any change, ask: **where does this knowledge apply?**

| Scope | Signal | Route to |
|-------|--------|----------|
| This repo only | Repo-specific paths, conventions, test commands | Project memory or project CLAUDE.md |
| All repos for this user | Workflow preferences, git conventions, tool quirks | Dotfiles repo `shared/INSTRUCTIONS.md` (symlinked as CLAUDE.md / AGENTS.md) |
| Conditional/context-gated | Platform quirk that only matters in certain situations | Skill (with triggering conditions in description) |

**Project memory is project-scoped.** It is invisible in other repos. Never
put cross-project knowledge in project memory — it creates a false sense of
coverage and silently fails everywhere else.

### Proposal types

| Type | Where | When to propose |
|------|-------|-----------------|
| Project convention | Project CLAUDE.md / `.claude/rules/` | Permanent rule for this repo only |
| Project memory | Project memory files | Pattern specific to this repo's codebase |
| Global convention | Dotfiles repo `CLAUDE.md` | Workflow rule or preference that spans all repos |
| Skill (new or update) | Dotfiles repo `skills/` directory | Repeatable pattern, platform quirk, or context-gated knowledge worth encoding as a loadable skill |
| Local context | CLAUDE.local.md / project-local notes | Personal/ephemeral notes not for version control |

### Constraints

- Global config lives in the dotfiles repo (`~/repos/dotfiles/`) — edit there, not in `~/.claude/`, `~/.codex/`, or `~/.agents/` directly
- Never commit or push — wait for explicit approval
- For new skills, describe the spec (name, trigger, gist); create only after approval
- If nothing warrants a change, say so — not every session needs config edits

### Output format

Present proposals as a numbered list:

```
Proposed changes:

1. [Project memory] Save test runner command for this repo
   Reason: Burned 3 tries discovering the correct invocation

2. [Global convention] Add "verify repo context before cross-repo gh commands"
   Where: dotfiles CLAUDE.md → Git Preferences
   Reason: Ran gh commands in wrong repo context twice this session

3. [Skill — new] bash-json-workarounds
   Trigger: When parsing JSON from curl/API responses in Bash tool
   Gist: Bash tool summarizes large JSON; use curl -i or standalone scripts
   Reason: Hit this in two separate sessions, lost time each time

4. [Skill — update] reflect
   Change: Add scoping guidance for memory proposals
   Reason: Proposed cross-project knowledge as project memory

No change needed:
- Discovered how Z works, but already documented in project instructions
```

Wait for the user to approve, modify, or reject each item before applying.
