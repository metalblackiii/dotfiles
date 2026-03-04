#!/usr/bin/env bash
set -euo pipefail

# Guard: block Bash commands that reference sensitive file paths.
# Mirrors the Read tool deny rules from settings.json.
#
# Exit 0 = allow
# Exit 2 = block (stderr sent back to Claude as feedback)

command -v jq &>/dev/null || exit 0

INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
[ -z "$CMD" ] && exit 0

escape_regex() {
  printf '%s' "$1" | sed 's/[.[\*^$()+?{|\\]/\\&/g'
}

HOME_DIR="${HOME:-$(eval echo ~)}"
HOME_ESC=$(escape_regex "$HOME_DIR")

SENSITIVE_PATTERNS=(
  # .env files — .env, .env.local, .env.production, path/to/.env.xxx
  # [^a-zA-Z0-9] after .env avoids matching .environment, .envoy, etc.
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

for pattern in "${SENSITIVE_PATTERNS[@]}"; do
  if echo "$CMD" | grep -qE "$pattern"; then
    echo "BLOCKED: Command references a sensitive path." >&2
    echo "Sensitive files (.env, secrets, keys, credentials, shell config) are off-limits." >&2
    exit 2
  fi
done

exit 0
