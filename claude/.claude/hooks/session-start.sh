#!/usr/bin/env bash
set -euo pipefail

# HOME may be empty in hook context, so use fallback
USER_HOME="${HOME:-$(eval echo ~)}"
SKILLS_DIR="${USER_HOME}/.claude/skills"

SKILL_COUNT=0
SKILL_LIST=""

if [ -d "$SKILLS_DIR" ]; then
    # Parse each SKILL.md frontmatter for name + description
    # Skip skills with disable-model-invocation: true
    # Use -L to follow symlinks (skills dir may be symlinked from dotfiles)
    while IFS= read -r skill_file; do
        in_frontmatter=false
        name=""
        description=""
        disabled=false

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
                elif [[ "$line" =~ ^disable-model-invocation:\ *true ]]; then
                    disabled=true
                fi
            fi
        done < "$skill_file"

        # Skip skills that have opted out of model invocation
        if $disabled; then
            continue
        fi

        # Fall back to directory name if no name in frontmatter
        if [ -z "$name" ]; then
            name=$(basename "$(dirname "$skill_file")")
        fi

        if [ -n "$description" ]; then
            SKILL_COUNT=$((SKILL_COUNT + 1))
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

Before responding to a user request, check if any installed skills apply.

**For non-trivial tasks** (features, debugging, architecture, reviews, deployments):
1. Check which skills apply
2. Invoke the relevant skill(s)
3. Follow the skill's guidance
4. THEN respond to the user

**For trivial tasks** (single-line fixes, typos, simple questions, file reads):
- Proceed directly. Skills add overhead here with no benefit.

## Installed Skills
${SKILL_LIST}

## Red Flags

If you're thinking:
- \"Let me just...\" → STOP. Is this actually trivial, or are you rationalizing?
- \"This won't take long...\" → STOP. Check for skills first.
- \"I need to explore first...\" → Skills guide exploration.
- \"After I gather context...\" → Skills guide context gathering.

## The Iron Law

Skills are not optional when applicable. Invoke first, work second. But don't invoke skills for work that genuinely doesn't benefit from them.

</EXTREMELY_IMPORTANT>"
  }
}
EOF
