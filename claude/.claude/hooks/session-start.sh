#!/usr/bin/env bash
set -euo pipefail

# HOME may be empty in hook context, so use fallback
USER_HOME="${HOME:-$(eval echo ~)}"
SKILLS_DIR="${USER_HOME}/.claude/skills"
USING_SKILLS="${SKILLS_DIR}/using-skills/SKILL.md"

if [ ! -f "$USING_SKILLS" ]; then
    # No using-skills skill found — emit empty context
    cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": ""
  }
}
EOF
    exit 0
fi

# Read the skill file content (strip frontmatter)
skill_content=""
in_frontmatter=false
frontmatter_done=false
while IFS= read -r line; do
    if ! $frontmatter_done; then
        if [[ "$line" == "---" ]]; then
            if $in_frontmatter; then
                frontmatter_done=true
            else
                in_frontmatter=true
            fi
            continue
        fi
        if $in_frontmatter; then
            continue
        fi
    fi
    skill_content="${skill_content}${line}
"
done < "$USING_SKILLS"

# Count available skills for context
skill_count=0
if [ -d "$SKILLS_DIR" ]; then
    skill_count=$(find -L "$SKILLS_DIR" -name "SKILL.md" 2>/dev/null | wc -l | tr -d ' ')
fi

# Escape for JSON embedding
escape_for_json() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//$'\n'/\\n}"
    s="${s//$'\r'/\\r}"
    s="${s//$'\t'/\\t}"
    printf '%s' "$s"
}

escaped_content=$(escape_for_json "$skill_content")

cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "<EXTREMELY_IMPORTANT>\\nYou have ${skill_count} specialized skills installed.\\n\\n${escaped_content}\\n</EXTREMELY_IMPORTANT>"
  }
}
EOF
