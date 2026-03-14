#!/usr/bin/env bash
set -euo pipefail

# Regression tests for bash-permissions.json deny/paths/allow layer regexes.
#
# WHY: Guard hook regexes must balance security coverage against false positives.
# This test runs the same grep -E engine the hook uses against curated cases,
# covering deny (tool preference), paths (sensitive file detection), and allow
# (branch-conditional auto-accept) layers.
#
# Patterns are extracted from bash-permissions.json by category + content, not
# array position, so reordering the JSON won't silently break the mapping.
# Both "commands" and "regex" entry types are handled, matching the hook.
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

if ! command -v jq &>/dev/null; then
  printf 'Error: jq is required to run tests\n' >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Regex-escape a literal string for use with grep -E.
# Replicates the hook's regex_escape function.
# ---------------------------------------------------------------------------
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

# Replicates the hook's command_to_regex: "git commit" → \bgit\s+commit\b
command_to_regex() {
  local escaped
  escaped=$(regex_escape "$1")
  escaped="${escaped// /\\s+}"
  printf '%s' "\\b${escaped}\\b"
}

HOME_ESC=$(regex_escape "${HOME:-$(eval echo ~)}")

# ---------------------------------------------------------------------------
# Extract patterns into a lookup file: name<TAB>type<TAB>value<TAB>branch
#
# Keyed by category + content (not array index) so JSON reordering won't
# silently break the test-name → pattern mapping.
# Handles both "commands" and "regex" entry types for the allow layer.
# ---------------------------------------------------------------------------
LOOKUP_FILE=$(mktemp)
trap 'rm -f "$LOOKUP_FILE"' EXIT
TAB=$'\t'

jq -r --arg home_esc "$HOME_ESC" '
  # --- Paths layer ---
  (.paths // [] | .[] |
    (
      if .category == ".env files" then
        if (.regex | test("\\[\\^ \\]")) then "path_env_pathed"
        else "path_env_bare"
        end
      elif .category == "secrets directory" then "path_secrets"
      elif .category == "certificate/key files" then "path_cert_key"
      elif .category == "home credentials" then
        if (.regex | test("\\.aws")) then "path_aws" else "path_ssh" end
      elif .category == "shell/git config" then "path_shell_config"
      elif .category == "private local config" then "path_local_config"
      else ("path_unknown_" + .category)
      end
    ) as $name |
    [$name, "regex", (.regex | gsub("__HOME__"; $home_esc)), ""] | join("\t")
  ),

  # --- Allow layer ---
  (.allow // [] | .[] |
    (
      if .category == "local dev testing" then "allow_curl_local"
      elif .category == "personal feature branch" then
        if ((.regex // "") + ((.commands // []) | join(" ")) | test("git")) then "allow_git_ops"
        else "allow_gh_pr"
        end
      else ("allow_unknown_" + .category)
      end
    ) as $name |
    .branch // "" as $branch |
    if has("commands") then
      .commands[] | [$name, "command", ., $branch] | join("\t")
    else
      [$name, "regex", .regex, $branch] | join("\t")
    end
  )
' "$RULES_FILE" > "$LOOKUP_FILE"

# --- Deny layer (category-based selection, already stable) ---
PAT_SED=$(jq -r '.deny[] | select(.category == "tool preference") | .regex' "$RULES_FILE" | head -1)
PAT_ECHO=$(jq -r '.deny[] | select(.category == "tool preference (no redirect)") | .regex' "$RULES_FILE" | head -1)
PAT_PRINTF=$(jq -r '.deny[] | select(.category == "tool preference (no redirect)") | .regex' "$RULES_FILE" | tail -1)

get_deny_pattern() {
  case "$1" in
    sed)    printf '%s' "$PAT_SED" ;;
    echo)   printf '%s' "$PAT_ECHO" ;;
    printf) printf '%s' "$PAT_PRINTF" ;;
    *)      printf '' ;;
  esac
}

# ---------------------------------------------------------------------------
# Test execution
# ---------------------------------------------------------------------------
pass=0
fail=0
total=0
current_section=""

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

while IFS= read -r line; do
  [[ "$line" =~ ^[[:space:]]*# ]] && continue
  [[ -z "${line// /}" ]] && continue

  # Parse first two columns (shared by all formats)
  expect="${line%%	*}"
  rest="${line#*	}"
  pat_name="${rest%%	*}"
  remaining="${rest#*	}"

  # Print section header on layer transitions
  case "$pat_name" in
    path_*)
      if [[ "$current_section" != "paths" ]]; then
        current_section="paths"
        printf '\n%b--- Paths Layer ---%b\n' "$BOLD" "$NC"
      fi
      ;;
    allow_*)
      if [[ "$current_section" != "allow" ]]; then
        current_section="allow"
        printf '\n%b--- Allow Layer ---%b\n' "$BOLD" "$NC"
      fi
      ;;
    *)
      if [[ "$current_section" != "deny" ]]; then
        current_section="deny"
        printf '%b--- Deny Layer ---%b\n' "$BOLD" "$NC"
      fi
      ;;
  esac

  case "$pat_name" in
    # ------ Paths layer: 3-column, __HOME__ expansion ------
    path_*)
      cmd="$remaining"
      cmd="${cmd//__HOME__/$HOME}"

      # Look up pattern by name from the lookup file
      found=false
      matched=false
      while IFS="$TAB" read -r _name _type _value _branch; do
        found=true
        if [[ "$_type" == "command" ]]; then
          pattern=$(command_to_regex "$_value")
        else
          pattern="$_value"
        fi
        if printf '%s' "$cmd" | grep -qE "$pattern" 2>/dev/null; then
          matched=true
          break
        fi
      done < <(grep "^${pat_name}${TAB}" "$LOOKUP_FILE")

      if ! $found; then
        printf "${YELLOW}SKIP${NC} unknown path pattern '%s': %s\n" "$pat_name" "$cmd"
        continue
      fi
      total=$((total + 1))
      if $matched; then actual="DENY"; else actual="PASS"; fi
      ;;

    # ------ Allow layer: 4-column (expect, pattern, branch, command) ------
    allow_*)
      branch="${remaining%%	*}"
      cmd="${remaining#*	}"

      found=false
      actual="ASK"
      while IFS="$TAB" read -r _name _type _value _branch_regex; do
        found=true
        if [[ "$_type" == "command" ]]; then
          pattern=$(command_to_regex "$_value")
        else
          pattern="$_value"
        fi
        if printf '%s' "$cmd" | grep -qE "$pattern" 2>/dev/null; then
          # Regex matched — check branch condition if present
          if [[ -z "$_branch_regex" ]] || { [[ "$branch" != "-" ]] && printf '%s' "$branch" | grep -qE "$_branch_regex" 2>/dev/null; }; then
            actual="ALLOW"
            break
          fi
        fi
      done < <(grep "^${pat_name}${TAB}" "$LOOKUP_FILE")

      if ! $found; then
        printf "${YELLOW}SKIP${NC} unknown allow pattern '%s': %s\n" "$pat_name" "$cmd"
        continue
      fi
      total=$((total + 1))
      ;;

    # ------ Deny layer: 3-column (existing behavior) ------
    *)
      cmd="$remaining"
      pattern="$(get_deny_pattern "$pat_name")"
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
      ;;
  esac

  if [[ "$actual" == "$expect" ]]; then
    pass=$((pass + 1))
    printf "${GREEN}  OK${NC}  %-5s %-22s %s\n" "$expect" "[$pat_name]" "$cmd"
  else
    fail=$((fail + 1))
    printf "${RED}FAIL${NC}  expected=%-5s got=%-5s %-22s %s\n" "$expect" "$actual" "[$pat_name]" "$cmd"
  fi
done < "$CASES_FILE"

printf '\nResults: %d/%d passed' "$pass" "$total"
if [[ "$fail" -gt 0 ]]; then
  printf ", ${RED}%d FAILED${NC}" "$fail"
fi
printf '\n'

exit "$fail"
