#!/usr/bin/env bash
# PostToolUse hook: auto-fix ESLint issues on edited JS/TS files.
# Finds the nearest project root and runs eslint --fix on just the changed file.
# Silent and non-blocking — errors are suppressed, exit is always 0.

set -uo pipefail

# Guard: jq required for JSON parsing
command -v jq &>/dev/null || exit 0

INPUT=$(cat)

FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
[ -z "$FILE_PATH" ] && exit 0

# Resolve to absolute path — prevents infinite loop on relative paths
FILE_PATH=$(realpath "$FILE_PATH" 2>/dev/null) || exit 0
[ -f "$FILE_PATH" ] || exit 0

# Only JS/TS files
case "$FILE_PATH" in
  *.js|*.mjs|*.cjs|*.ts|*.tsx|*.jsx) ;;
  *) exit 0 ;;
esac

# Walk up to nearest package.json to find project root
dir=$(dirname "$FILE_PATH")
PROJECT_ROOT=""
while [ "$dir" != "/" ]; do
  if [ -f "$dir/package.json" ]; then
    PROJECT_ROOT="$dir"
    break
  fi
  dir=$(dirname "$dir")
done
[ -z "$PROJECT_ROOT" ] && exit 0

# Run eslint --fix only if eslint is installed in the project
ESLINT_BIN="$PROJECT_ROOT/node_modules/.bin/eslint"
[ -x "$ESLINT_BIN" ] || exit 0

cd "$PROJECT_ROOT" && "$ESLINT_BIN" --fix "$FILE_PATH" >/dev/null 2>&1 || true

exit 0
