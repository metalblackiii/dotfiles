#!/usr/bin/env bash
set -euo pipefail

# Consolidated guard hook — enforces deny and ask rules from settings.json.
#
# WHY: Claude Code's permission matching breaks on compound commands (&&, ||, ;)
# and heredocs (#30519). This hook uses regex against the full command string,
# so compound syntax can't bypass it.
#
# Three layers:
#   1. DENY_PATTERNS  — blocked unconditionally (mirrors settings.json deny list)
#   2. PATH_PATTERNS  — blocked if command references sensitive file paths
#   3. ASK_PATTERNS   — blocked only if embedded in a compound command
#                        (standalone commands pass through to the ask rule)
#
# Exit 0 = allow
# Exit 2 = block (stderr is sent back to Claude as feedback)

command -v jq &>/dev/null || exit 0

INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
[ -z "$CMD" ] && exit 0

# =============================================================================
# Layer 1: DENY — blocked unconditionally
# =============================================================================

DENY_PATTERNS=(
  # Destructive filesystem
  "\brm\s+-(rf|r)\b"
  "\bchown\b"

  # Process management
  "\bkill\b"
  "\bkillall\b"
  "\bpkill\b"
  "\blaunchctl\b"

  # Privilege escalation
  "\bsudo\b"

  # Tool preference enforcement (use built-in Read/Edit/Write/Grep/WebFetch)
  "\bsed\s+"
  "\bawk\s+"
  "\bxargs\b"
  "\bpython3\s+-c\b"
  "\bpython\s+-c\b"
  "\bwget\b"
  "\becho\s+.*>"
  "\bprintf\s+.*>"

  # Package registry mutations
  "\bnpm\s+publish\b"
  "\bnpm\s+unpublish\b"

  # GitHub destructive
  "\bgh\s+repo\s+delete\b"

  # Docker privileged
  "\bdocker\s+run\s+--privileged\b"
  "\bdocker\s+run\s+-v\s+/:/host\b"
  "\bdocker\s+run\s+-v\s+/var/run/docker\.sock:"

  # AWS mutations
  "\baws\s+[a-z-]+\s+delete\b"
  "\baws\s+[a-z-]+\s+put\b"
  "\baws\s+[a-z-]+\s+create\b"
  "\baws\s+[a-z-]+\s+update\b"
  "\baws\s+[a-z-]+\s+terminate\b"
  "\baws\s+[a-z-]+\s+remove\b"
  "\baws\s+[a-z-]+\s+modify\b"
  "\baws\s+[a-z-]+\s+start\b"
  "\baws\s+[a-z-]+\s+stop\b"
  "\baws\s+[a-z-]+\s+invoke\b"
  "\baws\s+s3\s+rm\b"
  "\baws\s+s3\s+cp\b"
  "\baws\s+s3\s+mv\b"
  "\baws\s+s3\s+sync\b"

  # Infrastructure as Code
  "\bcdk\s+deploy\b"
  "\bcdk\s+destroy\b"
  "\bcdk\s+bootstrap\b"
  "\bnpx\s+cdk\b"
  "\bterraform\s+apply\b"
  "\bterraform\s+destroy\b"
  "\bnpm\s+run\s+deploy\b"
  "\bnpm\s+run\s+destroy\b"
  "\bserverless\s+deploy\b"
  "\bsls\s+deploy\b"
  "\bserverless\s+remove\b"
  "\bsls\s+remove\b"

  # Kubernetes / Helm
  "\bhelm\s+install\b"
  "\bhelm\s+upgrade\b"
  "\bhelm\s+delete\b"
  "\bhelm\s+uninstall\b"
  "\bhelm\s+rollback\b"
  "\bkubectl\s+apply\b"
  "\bkubectl\s+delete\b"
  "\bkubectl\s+create\b"
  "\bkubectl\s+replace\b"
  "\bkubectl\s+patch\b"
  "\bkubectl\s+scale\b"
  "\bkubectl\s+rollout\b"
  "\bkubectl\s+exec\b"
  "\bkubectl\s+edit\b"
  "\bkubectl\s+drain\b"
  "\bkubectl\s+cordon\b"
  "\bkubectl\s+taint\b"

  # Destructive git
  "\bgit\s+reset\s+--hard\b"
  "\bgit\s+clean\s+-f"
  "\bgit\s+push\s+--force\b"
  "\bgit\s+push\s+-f\b"
  "\bgit\s+checkout\s+--\s+"
  "\bgit\s+branch\s+-D\b"
)

for pattern in "${DENY_PATTERNS[@]}"; do
  if echo "$CMD" | grep -qE "$pattern"; then
    echo "BLOCKED: Command matches denied pattern." >&2
    echo "This operation is not allowed via Claude Code." >&2
    echo "Run it manually in your terminal if needed." >&2
    exit 2
  fi
done

# =============================================================================
# Layer 2: SENSITIVE PATHS — blocked if command references protected files
# =============================================================================

escape_regex() {
  printf '%s' "$1" | sed 's/[.[\*^$()+?{|\\]/\\&/g'
}

HOME_DIR="${HOME:-$(eval echo ~)}"
HOME_ESC=$(escape_regex "$HOME_DIR")

PATH_PATTERNS=(
  # .env files (but not .environment, .envoy, etc.)
  "(^|\s)\.env($|\s|[^a-zA-Z0-9])"
  "(^|\s)[^ ]*/\.env($|\s|[^a-zA-Z0-9])"

  # secrets/ directory
  "/secrets/"

  # Certificate and key files (as filenames, not jq filters like .key)
  "[^. ][^ ]*\.(pem|key)($|\s)"

  # Home credential directories
  "(^|\s)(~|${HOME_ESC})/\.aws/"
  "(^|\s)(~|${HOME_ESC})/\.ssh/"

  # Shell and git config
  "(^|\s)(~|${HOME_ESC})/\.(zshrc|bashrc|bash_profile|gitconfig)($|\s)"
)

for pattern in "${PATH_PATTERNS[@]}"; do
  if echo "$CMD" | grep -qE "$pattern"; then
    echo "BLOCKED: Command references a sensitive path." >&2
    echo "Sensitive files (.env, secrets, keys, credentials, shell config) are off-limits." >&2
    exit 2
  fi
done

# =============================================================================
# Layer 3: ASK — blocked only when embedded in compound commands
#
# Standalone commands pass through so the settings.json ask rule can prompt
# the user. Compound commands bypass ask rules, so we catch them here.
# =============================================================================

ASK_PATTERNS=(
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
  "\bcurl\b"
  "\bchmod\b"
  "\bbrew\b"
)

MATCHED_ASK=""
for pattern in "${ASK_PATTERNS[@]}"; do
  if echo "$CMD" | grep -qE "$pattern"; then
    MATCHED_ASK="$pattern"
    break
  fi
done

if [ -n "$MATCHED_ASK" ]; then
  IS_COMPOUND=false
  if echo "$CMD" | grep -qE '&&|\|\||;'; then
    IS_COMPOUND=true
  elif [ "$(echo "$CMD" | grep -cE '.')" -gt 1 ]; then
    IS_COMPOUND=true
  fi

  if [ "$IS_COMPOUND" = true ]; then
    echo "BLOCKED: This compound command bypassed the ask-permission rule." >&2
    echo "The settings.json 'ask' rules only match standalone commands." >&2
    echo "Split this into separate commands so the permission prompt fires." >&2
    echo "For example, run 'git add' first, then 'git commit' as its own command." >&2
    exit 2
  fi
fi

exit 0
