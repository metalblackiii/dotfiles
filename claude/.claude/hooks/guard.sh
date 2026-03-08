#!/usr/bin/env bash
set -euo pipefail

# Guard hook — enforces deny/ask/path rules from guard-rules.json.
#
# WHY: Claude Code's glob-based permission matching is unreliable for compound
# commands and heredocs. This hook uses regex against the full command string
# and emits structured JSON decisions via the PreToolUse hook API.
#
# Rules live in guard-rules.json (single source of truth). Each rule is either:
#   "commands": ["git commit", "rm -rf"]  — human-readable, converted to regex
#   "regex": "\\baws\\s+[a-z-]+\\s+delete\\b"  — raw regex escape hatch
#
# Layers:
#   deny  → permissionDecision "deny"  (blocked, reason shown to Claude)
#   paths → permissionDecision "deny"  (sensitive file access blocked)
#   ask   → permissionDecision "ask"   (forces user confirmation prompt)
#
# Exit 0 + JSON stdout = structured control
# Exit 0 + no output   = allow

command -v jq &>/dev/null || exit 0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RULES_FILE="${SCRIPT_DIR}/guard-rules.json"
[[ -f "$RULES_FILE" ]] || exit 0

# Fail open on malformed rules to avoid blocking all commands
jq empty "$RULES_FILE" 2>/dev/null || exit 0

INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
[[ -z "$CMD" ]] && exit 0

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

emit_decision() {
  local decision="$1"
  local reason="$2"
  local escaped_reason
  escaped_reason=$(printf '%s' "$reason" | jq -Rs '.')
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"%s","permissionDecisionReason":%s}}\n' \
    "$decision" "$escaped_reason"
  exit 0
}

# Convert "git commit" → \bgit\s+commit\b
command_to_regex() {
  printf '%s' "$1" \
    | sed 's/[.[\*^$()+?{|\\]/\\&/g; s/ /\\s+/g; s/^/\\b/; s/$/\\b/'
}

# Check a layer's rules against $CMD.
# Extracts all rules in one jq call, then iterates in bash.
# Args: $1=layer name, $2=decision, $3=default reason
# If a rule has a "nudge" field, it replaces the default reason.
check_layer() {
  local layer="$1" decision="$2" default_reason="$3"

  while IFS=$'\t' read -r value entry_type nudge; do
    [[ -z "$value" ]] && continue
    local pattern
    if [[ "$entry_type" == "command" ]]; then
      pattern=$(command_to_regex "$value")
    else
      pattern="$value"
    fi
    if echo "$CMD" | grep -qE "$pattern"; then
      emit_decision "$decision" "${nudge:-$default_reason}"
    fi
  done < <(
    jq -r --arg layer "$layer" '
      .[$layer] // [] | .[] |
      .nudge // "" as $nudge |
      if has("commands") then
        .commands[] | [., "command", $nudge] | join("\t")
      else
        [.regex, "regex", $nudge] | join("\t")
      end
    ' "$RULES_FILE"
  )
}

# ---------------------------------------------------------------------------
# Layer 1: DENY — blocked unconditionally
# ---------------------------------------------------------------------------

check_layer "deny" "deny" \
  "This operation is not allowed via Claude Code. Run it manually if needed."

# ---------------------------------------------------------------------------
# Layer 2: SENSITIVE PATHS — blocked if command references protected files
# Uses __HOME__ placeholder in rules, expanded at runtime.
# ---------------------------------------------------------------------------

HOME_DIR="${HOME:-$(eval echo ~)}"
HOME_ESC=$(printf '%s' "$HOME_DIR" | sed 's/[.[\*^$()+?{|\\]/\\&/g')

while IFS= read -r regex; do
  [[ -z "$regex" ]] && continue
  local_pattern="${regex//__HOME__/$HOME_ESC}"
  if echo "$CMD" | grep -qE "$local_pattern"; then
    emit_decision "deny" \
      "Sensitive files (.env, secrets, keys, credentials, shell config) are off-limits."
  fi
done < <(jq -r '.paths // [] | .[].regex' "$RULES_FILE")

# ---------------------------------------------------------------------------
# Layer 3: ASK — forces user confirmation for all matches
# Reason is shown to the user (not Claude), so no evasion hints leak.
# ---------------------------------------------------------------------------

check_layer "ask" "ask" \
  "Guard hook: protected command pattern matched."

exit 0
