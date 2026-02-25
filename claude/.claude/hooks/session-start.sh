#!/usr/bin/env bash
set -euo pipefail

# HOME may be empty in hook context, so use fallback
USER_HOME="${HOME:-$(eval echo ~)}"
SKILLS_DIR="${USER_HOME}/.claude/skills"
USING_SKILLS="${SKILLS_DIR}/using-skills/SKILL.md"

if [ ! -f "$USING_SKILLS" ]; then
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

# Read using-skills content
using_skills_content=$(cat "$USING_SKILLS" 2>&1 || echo "Error reading using-skills skill")

# Escape string for JSON embedding using bash parameter substitution.
# Each ${s//old/new} is a single C-level pass - orders of magnitude
# faster than the character-by-character loop this replaces.
escape_for_json() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//$'\n'/\\n}"
    s="${s//$'\r'/\\r}"
    s="${s//$'\t'/\\t}"
    printf '%s' "$s"
}

using_skills_escaped=$(escape_for_json "$using_skills_content")
session_context="<EXTREMELY_IMPORTANT>\nYou have specialized skills installed.\n\n**Below is the full content of your 'using-skills' skill - your introduction to using skills. For all other skills, use the 'Skill' tool:**\n\n${using_skills_escaped}\n</EXTREMELY_IMPORTANT>"

cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "${session_context}"
  }
}
EOF

exit 0
