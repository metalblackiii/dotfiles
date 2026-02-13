#!/usr/bin/env bash
set -euo pipefail

# HOME may be empty in hook context, so use fallback
USER_HOME="${HOME:-$(eval echo ~)}"
SKILLS_DIR="${USER_HOME}/.claude/skills"

SKILL_COUNT=0
SKILL_LIST=""

if [ -d "$SKILLS_DIR" ]; then
    # Parse each SKILL.md frontmatter for name + description
    # Use -L to follow symlinks (skills dir may be symlinked from dotfiles)
    while IFS= read -r skill_file; do
        SKILL_COUNT=$((SKILL_COUNT + 1))

        in_frontmatter=false
        name=""
        description=""

        while IFS= read -r line; do
            if [[ "$line" == "---" ]]; then
                if $in_frontmatter; then
                    break
                else
                    in_frontmatter=true
                    continue
                fi
            fi
            if $in_frontmatter; then
                if [[ "$line" =~ ^[Nn]ame:\ *(.*) ]]; then
                    name="${BASH_REMATCH[1]}"
                elif [[ "$line" =~ ^[Dd]escription:\ *(.*) ]]; then
                    description="${BASH_REMATCH[1]}"
                fi
            fi
        done < "$skill_file"

        # Fall back to directory name if no name in frontmatter
        if [ -z "$name" ]; then
            name=$(basename "$(dirname "$skill_file")")
        fi

        if [ -n "$description" ]; then
            # Escape double quotes for JSON safety
            description="${description//\"/\\\"}"
            SKILL_LIST="${SKILL_LIST}
- **${name}**: ${description}"
        fi
    done < <(find -L "$SKILLS_DIR" -name "SKILL.md" 2>/dev/null | sort)
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

## Installed Skills
${SKILL_LIST}

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
