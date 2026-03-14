#!/usr/bin/env bash
set -euo pipefail

# Regression tests for bash-permissions.json deny-layer regex patterns.
#
# WHY: The deny-layer regexes must balance coverage (blocking real sed/echo>/
# printf> commands) against false positives (blocking commit messages, compound
# commands, filenames that mention these tools). This test runs the same
# grep -E engine the hook uses against curated test cases.
#
# Usage: bash bash-permissions-test.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CASES_FILE="${SCRIPT_DIR}/bash-permissions-test-cases.txt"
RULES_FILE="${SCRIPT_DIR}/bash-permissions.json"

if [[ ! -f "$CASES_FILE" ]]; then
  printf 'Error: test cases file not found: %s\n' "$CASES_FILE" >&2
  exit 1
fi

if [[ ! -f "$RULES_FILE" ]]; then
  printf 'Error: rules file not found: %s\n' "$RULES_FILE" >&2
  exit 1
fi

# Extract patterns from bash-permissions.json (single source of truth).
# Falls back to hardcoded values only if jq is unavailable.
if command -v jq &>/dev/null; then
  PAT_SED=$(jq -r '.deny[] | select(.category == "tool preference") | .regex' "$RULES_FILE" | head -1)
  PAT_ECHO=$(jq -r '.deny[] | select(.category == "tool preference (no redirect)") | .regex' "$RULES_FILE" | head -1)
  PAT_PRINTF=$(jq -r '.deny[] | select(.category == "tool preference (no redirect)") | .regex' "$RULES_FILE" | tail -1)
else
  printf 'Warning: jq not found, using hardcoded patterns\n' >&2
  PAT_SED='(^|[|;&(])\s*([A-Z_]+=\S*\s+)*sed\s+'
  PAT_ECHO='\becho\s+[^;&|]*>'
  PAT_PRINTF='\bprintf\s+[^;&|]*>'
fi

get_pattern() {
  case "$1" in
    sed)    printf '%s' "$PAT_SED" ;;
    echo)   printf '%s' "$PAT_ECHO" ;;
    printf) printf '%s' "$PAT_PRINTF" ;;
    *)      printf '' ;;
  esac
}

pass=0
fail=0
total=0

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

while IFS= read -r line; do
  [[ "$line" =~ ^[[:space:]]*# ]] && continue
  [[ -z "${line// /}" ]] && continue

  # Parse: EXPECT<tab>PATTERN_NAME<tab>COMMAND
  expect="${line%%	*}"
  rest="${line#*	}"
  pat_name="${rest%%	*}"
  cmd="${rest#*	}"

  pattern="$(get_pattern "$pat_name")"
  if [[ -z "$pattern" ]]; then
    printf "${YELLOW}SKIP${NC} unknown pattern '%s': %s\n" "$pat_name" "$cmd"
    continue
  fi

  total=$((total + 1))

  if printf '%s' "$cmd" | grep -qE "$pattern" 2>/dev/null; then
    actual="DENY"
  else
    actual="PASS"
  fi

  if [[ "$actual" == "$expect" ]]; then
    pass=$((pass + 1))
    printf "${GREEN}  OK${NC}  %-5s %-9s %s\n" "$expect" "[$pat_name]" "$cmd"
  else
    fail=$((fail + 1))
    printf "${RED}FAIL${NC}  expected=%-5s got=%-5s %-9s %s\n" "$expect" "$actual" "[$pat_name]" "$cmd"
  fi
done < "$CASES_FILE"

printf '\nResults: %d/%d passed' "$pass" "$total"
if [[ "$fail" -gt 0 ]]; then
  printf ", ${RED}%d FAILED${NC}" "$fail"
fi
printf '\n'

exit "$fail"
