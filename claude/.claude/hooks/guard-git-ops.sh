#!/usr/bin/env bash
set -euo pipefail

# Guard: enforce ask-permission rules for git operations.
#
# The settings.json "ask" rules for git commit/push don't fire when commands
# are compound (&&, ||, ;) or use heredocs — a known Claude Code bug (#30519).
# This hook catches those cases and tells the model to use standalone commands
# so the ask rule triggers properly.
#
# Exit 0 = allow (standalone command — ask rule will handle it)
# Exit 2 = block (compound command — ask rule was bypassed)

command -v jq &>/dev/null || exit 0

INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
[ -z "$CMD" ] && exit 0

# Git operations that require explicit user approval (mirrors settings.json ask list)
GIT_ASK_PATTERNS=(
  "\bgit\s+commit\b"
  "\bgit\s+push\b"
  "\bgit\s+stash\s+drop\b"
  "\bgit\s+restore\b"
  "\bgh\s+pr\s+create\b"
  "\bgh\s+pr\s+merge\b"
  "\bgh\s+pr\s+close\b"
  "\bgh\s+issue\s+close\b"
  "\bnpm\s+deprecate\b"
  "\bgh\s+repo\s+archive\b"
)

# Check if the command contains any ask-protected git operation
MATCHED_PATTERN=""
for pattern in "${GIT_ASK_PATTERNS[@]}"; do
  if echo "$CMD" | grep -qE "$pattern"; then
    MATCHED_PATTERN="$pattern"
    break
  fi
done

# No protected operation found — allow
[ -z "$MATCHED_PATTERN" ] && exit 0

# Detect compound command syntax that bypasses ask rules
IS_COMPOUND=false
if echo "$CMD" | grep -qE '&&|\|\||;'; then
  IS_COMPOUND=true
elif echo "$CMD" | grep -cE '.' | grep -qv '^1$'; then
  # Multiline command (heredoc, etc.)
  IS_COMPOUND=true
fi

if [ "$IS_COMPOUND" = true ]; then
  echo "BLOCKED: This compound command bypassed the ask-permission rule." >&2
  echo "The settings.json 'ask' rules only match standalone commands." >&2
  echo "Split this into separate commands so the permission prompt fires." >&2
  echo "For example, run 'git add' first, then 'git commit' as its own command." >&2
  exit 2
fi

# Standalone command — let it through so the ask rule prompts the user
exit 0
