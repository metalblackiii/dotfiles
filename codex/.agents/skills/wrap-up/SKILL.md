---
name: wrap-up
description: Use when user says "wrap up", "close session", "end session",
  "wrap things up", "close out this task", or invokes /wrap-up
---

# Session Wrap-Up

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

Group proposals by type:

| Type | Where | When to propose |
|------|-------|-----------------|
| Project convention | Project instruction file (CLAUDE.md / AGENTS.md / `.claude/rules/`) | Permanent rule that should guide all future sessions |
| Auto memory | Memory files | Pattern or insight the agent should remember |
| Local context | CLAUDE.local.md / project-local notes | Personal/ephemeral notes not for version control |
| Skill or hook | Spec only (don't create) | Repetitive pattern worth automating |

**Constraints:**
- Never edit global config (`~/.claude/`, `~/.codex/`, `~/.agents/`) — route those through the dotfiles repo
- Never commit or push — wait for explicit approval
- For skill/hook ideas, describe the spec; don't create the files
- If nothing warrants a change, say so — not every session needs config edits

Present proposals as a numbered list:

```
Proposed changes:

1. [Project convention] Add retry policy to project instructions for worker error handling
   Reason: We hit 429/400 crashes twice and had to debug the same issue

2. [Auto memory] Save that service X requires Y header for auth
   Reason: Spent 20 minutes discovering this; should be instant next time

3. [Skill idea] Post-deploy health check
   Reason: Manually checked service health 3 times this session

No change needed:
- Discovered how Z works, but already documented in project instructions
```

Wait for the user to approve, modify, or reject each item before applying.
