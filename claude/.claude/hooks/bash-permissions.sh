#!/usr/bin/env bash
set -euo pipefail

# Bash permissions hook — enforces deny/ask/path rules from bash-permissions.json.
#
# WHY: Claude Code's glob-based permission matching is unreliable for compound
# commands and heredocs. This hook uses regex against the full command string
# and emits structured JSON decisions via the PreToolUse hook API.
#
# Rules live in bash-permissions.json (single source of truth). Each rule is either:
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
RULES_FILE="${SCRIPT_DIR}/bash-permissions.json"
[[ -f "$RULES_FILE" ]] || exit 0

# Fail open on malformed rules to avoid blocking all commands
jq empty "$RULES_FILE" 2>/dev/null || exit 0

INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
[[ -z "$CMD" ]] && exit 0

# Strip /dev/null redirects so they don't false-positive on redirect-detection rules
CMD_CLEAN=$(printf '%s' "$CMD" | jq -Rr 'gsub("[0-9]*&?>[[:space:]]*/dev/null"; "") | gsub("[0-9]*>&[0-9]+"; "")')

# WHY: Commit messages are prose — pattern matches against words like "rm" or
# paths like "~/.gitconfig" inside them are false positives. Detect inline-message
# git commit commands once, reuse in both deny and paths layers.
#
# Only skips for -m (inline message) commits. File-referencing forms like
# git commit -F <file> or --template <file> are real file accesses and must
# still be checked. Compound commands (&&, |, ;) are never skipped.
_is_simple_commit=false
if printf '%s' "$CMD_CLEAN" | grep -qE '^\s*(rtk\s+)?git\b.*\bcommit\b.*\s(-[a-z]*m|--message)\s' && \
   ! printf '%s' "$CMD_CLEAN" | grep -qE '[;&|]'; then
  _is_simple_commit=true
fi

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

# Escape regex metacharacters in a literal string for use with grep -E.
regex_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//./\\.}"
  s="${s//\[/\\[}"
  s="${s//\*/\\*}"
  s="${s//^/\\^}"
  s="${s//\$/\\$}"
  s="${s//\(/\\(}"
  s="${s//\)/\\)}"
  s="${s//+/\\+}"
  s="${s//\?/\\?}"
  s="${s//\{/\\{}"
  s="${s//|/\\|}"
  printf '%s' "$s"
}

# Convert "git commit" → \bgit\s+commit\b
command_to_regex() {
  local escaped
  escaped=$(regex_escape "$1")
  escaped="${escaped// /\\s+}"
  printf '%s' "\\b${escaped}\\b"
}

# Resolve the effective git directory from the command.
# If the command contains "cd <path> &&", use the last cd target;
# otherwise fall back to cwd. Lazy — only called when a rule needs it.
_GIT_DIR=""
effective_git_dir() {
  if [[ -z "$_GIT_DIR" ]]; then
    local cd_target
    local cd_line
    cd_line=$(printf '%s' "$CMD_CLEAN" | grep -oE '\bcd[[:space:]]+[^&;|]+' | tail -1)
    cd_target=""
    if [[ "$cd_line" =~ ^cd[[:space:]]+(.*[^[:space:]]) ]]; then
      cd_target="${BASH_REMATCH[1]}"
    fi
    if [[ -n "$cd_target" ]]; then
      # Expand ~ to $HOME
      _GIT_DIR="${cd_target/#\~/$HOME}"
    else
      _GIT_DIR="."
    fi
  fi
  printf '%s' "$_GIT_DIR"
}

# ---------------------------------------------------------------------------
# Path exemption: downgrades deny → ask when a command is scoped to a safe
# directory (e.g., ~/repos/). Conservative — denies when in doubt.
#
# A command is exempt if:
#   1. No absolute paths outside the safe directory appear in the command, AND
#   2. The effective cwd is under the safe directory, OR the command explicitly
#      references the safe directory.
# ---------------------------------------------------------------------------
is_path_exempt() {
  local safe_path="${1/#\~/$HOME}"
  # Ensure trailing slash for prefix matching
  [[ "$safe_path" != */ ]] && safe_path="${safe_path}/"

  # Normalize the command for path analysis:
  #   1. Expand ~ and $HOME/${HOME} to the actual home directory
  #   2. Strip shell quotes so "/tmp/foo" is detected as an absolute path
  local cmd_expanded
  cmd_expanded=$(printf '%s' "$CMD_CLEAN" | sed "s|~|${HOME}|g; s/['\"]//g")
  cmd_expanded="${cmd_expanded//\$HOME/$HOME}"
  cmd_expanded="${cmd_expanded//\$\{HOME\}/$HOME}"

  # Reject path traversal — .. can escape the safe directory via relative paths
  if printf '%s' "$cmd_expanded" | grep -qE '(^|[[:space:]/])\.\.([[:space:]/]|$)'; then
    return 1  # not exempt — traversal could escape safe directory
  fi

  # Reject commands containing unresolved shell variables ($VAR, ${VAR}).
  # WHY: We expand $HOME above, but any other variable is opaque — we can't
  # know where it resolves. Broad check (entire command, not just path args)
  # because reliably parsing which tokens are paths in arbitrary shell is fragile.
  if printf '%s' "$cmd_expanded" | grep -qE '\$\{?[A-Za-z_]'; then
    return 1  # not exempt — unresolved variable could target anywhere
  fi

  # Check for absolute paths outside the safe directory.
  # Extract tokens that look like absolute paths (start with /).
  local has_unsafe_absolute=false
  while IFS= read -r abs_path; do
    [[ -z "$abs_path" ]] && continue
    abs_path="${abs_path#"${abs_path%%[![:space:]]*}"}"  # trim leading space
    [[ "$abs_path" == /dev/null ]] && continue
    [[ "$abs_path" == "${safe_path}"* ]] && continue
    has_unsafe_absolute=true
    break
  done < <(printf '%s' "$cmd_expanded" | grep -oE '(^|[[:space:]])/[^[:space:]]+')

  if $has_unsafe_absolute; then
    return 1  # not exempt — unsafe absolute path found
  fi

  # Check if the command explicitly references the safe directory
  if printf '%s' "$cmd_expanded" | grep -qF "$safe_path"; then
    return 0  # exempt — explicit safe reference
  fi

  # Check if effective cwd is under the safe directory
  local cwd
  cwd=$(effective_git_dir)
  [[ "$cwd" == "." ]] && cwd="$PWD"
  cwd=$(cd "$cwd" 2>/dev/null && pwd -P) || cwd=""
  if [[ -n "$cwd" && "$cwd/" == "${safe_path}"* ]]; then
    return 0  # exempt — working directory is safe
  fi

  return 1  # not exempt
}

# Check a layer's rules against $CMD.
# Extracts all rules in one jq call, then iterates in bash.
# Args: $1=layer name, $2=decision, $3=default reason
# If a rule has a "nudge" field, it replaces the default reason.
check_layer() {
  local layer="$1" decision="$2" default_reason="$3"

  while IFS=$'\t' read -r value entry_type nudge exempt_path exempt_decision; do
    [[ -z "$value" ]] && continue
    # Restore empty fields from sentinel (bash read collapses consecutive tabs)
    [[ "$nudge" == "_" ]] && nudge=""
    [[ "$exempt_path" == "_" ]] && exempt_path=""
    [[ "$exempt_decision" == "_" ]] && exempt_decision=""
    local pattern
    if [[ "$entry_type" == "command" ]]; then
      pattern=$(command_to_regex "$value")
    else
      pattern="$value"
    fi
    if echo "$CMD_CLEAN" | grep -qE "$pattern"; then
      # Skip all deny-layer matches for simple git commit commands — every
      # match is against message prose, not an actual command invocation.
      # Compound commands (&&, |, ;) are not considered simple commits.
      # Not applied to ask layer: git commit's own ask rule must still fire.
      if $_is_simple_commit && [[ "$layer" == "deny" ]]; then
        continue
      fi
      # If the rule has a path exemption, check before emitting deny
      if [[ -n "$exempt_path" ]] && is_path_exempt "$exempt_path"; then
        emit_decision "${exempt_decision:-ask}" \
          "Bash permissions hook: protected command pattern matched (path-exempted to ${exempt_decision:-ask})."
      else
        emit_decision "$decision" "${nudge:-$default_reason}"
      fi
    fi
  done < <(
    jq -r --arg layer "$layer" '
      .[$layer] // [] | .[] |
      (if .nudge then .nudge else "_" end) as $nudge |
      (if .exempt_when_path then .exempt_when_path else "_" end) as $exempt_path |
      (if .exempt_decision then .exempt_decision else "_" end) as $exempt_decision |
      if has("commands") then
        .commands[] | [., "command", $nudge, $exempt_path, $exempt_decision] | join("\t")
      else
        [.regex, "regex", $nudge, $exempt_path, $exempt_decision] | join("\t")
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
HOME_ESC=$(regex_escape "$HOME_DIR")

if ! $_is_simple_commit; then
  while IFS= read -r regex; do
    [[ -z "$regex" ]] && continue
    local_pattern="${regex//__HOME__/$HOME_ESC}"
    if echo "$CMD_CLEAN" | grep -qE "$local_pattern"; then
      emit_decision "deny" \
        "Sensitive files (.env, secrets, keys, credentials, shell config) are off-limits."
    fi
  done < <(jq -r '.paths // [] | .[].regex' "$RULES_FILE")
fi

# ---------------------------------------------------------------------------
# Layer 3: ALLOW — auto-accept trusted patterns (exit silently to bypass ask)
# ---------------------------------------------------------------------------

_CURRENT_BRANCH=""
current_branch() {
  if [[ -z "$_CURRENT_BRANCH" ]]; then
    local git_dir
    git_dir=$(effective_git_dir)
    _CURRENT_BRANCH=$(git -C "$git_dir" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
  fi
  printf '%s' "$_CURRENT_BRANCH"
}

while IFS=$'\t' read -r value entry_type branch_regex; do
  [[ -z "$value" ]] && continue
  if [[ "$entry_type" == "command" ]]; then
    allow_pattern=$(command_to_regex "$value")
  else
    allow_pattern="$value"
  fi
  if echo "$CMD_CLEAN" | grep -qE "$allow_pattern"; then
    # If rule has a branch condition, verify it before allowing
    if [[ -n "$branch_regex" ]]; then
      branch=$(current_branch)
      [[ -z "$branch" ]] && continue
      echo "$branch" | grep -qE "$branch_regex" || continue
    fi
    exit 0  # no output = allow
  fi
done < <(
  jq -r '
    .allow // [] | .[] |
    .branch // "" as $branch |
    if has("commands") then
      .commands[] | [., "command", $branch] | join("\t")
    else
      [.regex, "regex", $branch] | join("\t")
    end
  ' "$RULES_FILE"
)

# ---------------------------------------------------------------------------
# Layer 4: ASK — forces user confirmation for all matches
# Reason is shown to the user (not Claude), so no evasion hints leak.
# ---------------------------------------------------------------------------

check_layer "ask" "ask" \
  "Bash permissions hook: protected command pattern matched."

exit 0
