#!/usr/bin/env bash
set -euo pipefail

# Find all skills (optional - for your reference, not injected)
SKILLS_DIR="${HOME}/.claude/skills"
SKILL_COUNT=0
if [ -d "$SKILLS_DIR" ]; then
    SKILL_COUNT=$(find "$SKILLS_DIR" -name "SKILL.md" | wc -l | tr -d ' ')
fi

cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "<EXTREMELY_IMPORTANT>

You have ${SKILL_COUNT} specialized skills installed. These represent YOUR personal development methodology and best practices.

## The Rule

Before responding to ANY user request, ask yourself: \"Could any of my skills apply to this task?\"

If the answer is YES (even 1% chance):
1. Use the Skill tool to invoke the relevant skill
2. Follow its guidance
3. THEN respond to the user

If the answer is \"I don't know what skills I have\":
1. You're rationalizing
2. The Skill tool knows what's available
3. Check for skills anyway

## Skill Triggers

Match the task to the skill:
- **Writing/editing code** → self-documenting-code
- **Bug or test failure** → systematic-debugging
- **New feature or fix** → test-driven-development
- **Architecture or refactoring** → software-design
- **About to claim done** → verification-before-completion

The Skill tool's description field tells you when each skill applies. Trust those descriptions.

## Red Flags

If you're thinking:
- \"Let me just...\" → STOP. Check for skills first.
- \"This won't take long...\" → STOP. Check for skills first.
- \"I need to explore first...\" → STOP. Skills guide exploration.
- \"After I gather context...\" → STOP. Skills guide context gathering.

**No exploration, no clarifying questions, no work until you've checked for applicable skills.**

## The Iron Law

Skills are not optional when applicable. Invoke first, work second.

</EXTREMELY_IMPORTANT>"
  }
}
EOF
