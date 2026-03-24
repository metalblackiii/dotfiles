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
      elif .category == "application config" then "path_dotconfig"
      elif .category == "database credentials" then "path_mylogin_cnf"
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
      elif .category == "skill cleanup" then "allow_skill_cleanup"
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

# ---------------------------------------------------------------------------
# Integration tests: path exemption (exempt_when_path)
#
# These run the actual hook as a subprocess with controlled cwd and command,
# verifying the full deny → exempt → ask downgrade behavior.
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# Derive safe path and test directory from bash-permissions.json so tests
# are portable across forks with different repo layouts (~/repos/, ~/src/, etc.)
# ---------------------------------------------------------------------------

EXEMPT_PATH=$(jq -r '.deny[] | select(.exempt_when_path) | .exempt_when_path' "$RULES_FILE" | head -1)

if [[ -z "$EXEMPT_PATH" ]]; then
  printf '\n%b--- Path Exemption Integration (SKIPPED — no exempt_when_path rules) ---%b\n' "$YELLOW" "$NC"
else
  printf '\n%b--- Path Exemption Integration ---%b\n' "$BOLD" "$NC"

  HOOK_SCRIPT="${SCRIPT_DIR}/bash-permissions.sh"

  # Expand ~ and ensure trailing slash
  SAFE_DIR="${EXEMPT_PATH/#\~/$HOME}"
  [[ "$SAFE_DIR" != */ ]] && SAFE_DIR="${SAFE_DIR}/"

  # Find a real subdirectory under the safe path to use as test cwd.
  # Falls back to a temp dir created under the safe path if none exists.
  # Creates parent dirs if needed so the test works on fresh clones.
  SAFE_CWD=""
  if [[ -d "$SAFE_DIR" ]]; then
    SAFE_CWD=$(find "$SAFE_DIR" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | head -1)
  fi
  CLEANUP_SAFE_CWD=false
  if [[ -z "$SAFE_CWD" ]]; then
    mkdir -p "$SAFE_DIR" 2>/dev/null || true
    if [[ -d "$SAFE_DIR" ]]; then
      SAFE_CWD=$(mktemp -d "${SAFE_DIR}exempt-test-XXXXXX")
      CLEANUP_SAFE_CWD=true
    fi
  fi

  if [[ -z "$SAFE_CWD" ]]; then
    printf '  %bSKIP%b  cannot create test dir under %s — skipping exemption tests\n' "$YELLOW" "$NC" "$SAFE_DIR"
  else

  # Relative form for cd-based tests (e.g., ~/repos/dotfiles)
  SAFE_CWD_TILDE="${SAFE_CWD/#$HOME/~}"

  test_hook_decision() {
    local expect="$1" cwd="$2" cmd="$3"
    local input
    input=$(jq -n --arg cmd "$cmd" '{"tool_input":{"command":$cmd}}')
    local output
    output=$(cd "$cwd" 2>/dev/null && printf '%s' "$input" | bash "$HOOK_SCRIPT" 2>/dev/null) || true
    local actual
    if [[ -z "$output" ]]; then
      actual="allow"
    else
      actual=$(printf '%s' "$output" | jq -r '.hookSpecificOutput.permissionDecision // "allow"')
    fi
    total=$((total + 1))
    if [[ "$actual" == "$expect" ]]; then
      pass=$((pass + 1))
      printf "${GREEN}  OK${NC}  %-5s %-22s cwd=%-30s %s\n" "$expect" "[exempt]" "$cwd" "$cmd"
    else
      fail=$((fail + 1))
      printf "${RED}FAIL${NC}  expected=%-5s got=%-5s %-22s cwd=%-30s %s\n" "$expect" "$actual" "[exempt]" "$cwd" "$cmd"
    fi
  }

  # rm inside safe path (cwd-based) → ask
  test_hook_decision "ask" "$SAFE_CWD" "rm -rf dist"
  test_hook_decision "ask" "$SAFE_CWD" "rm -r node_modules"
  test_hook_decision "ask" "$SAFE_CWD" "rm file.txt"

  # rm with explicit safe path reference → ask (regardless of cwd)
  test_hook_decision "ask" "/tmp" "rm -rf ${SAFE_CWD}/dist"
  test_hook_decision "ask" "/tmp" "rm -r ${SAFE_CWD}/node_modules"
  test_hook_decision "ask" "/tmp" "rm ${SAFE_CWD}/old-file.txt"

  # rm via cd into safe path → ask (effective cwd detection)
  test_hook_decision "ask" "/tmp" "cd ${SAFE_CWD_TILDE} && rm -rf dist"
  test_hook_decision "ask" "/tmp" "cd ${SAFE_CWD} && rm -r build"

  # rm outside safe path → deny
  test_hook_decision "deny" "/tmp" "rm -rf /tmp/something"
  test_hook_decision "deny" "/tmp" "rm file.txt"
  test_hook_decision "deny" "$HOME" "rm -rf something"
  test_hook_decision "deny" "$HOME/Documents" "rm -r old-folder"

  # rm with mixed safe/unsafe paths → deny (conservative)
  test_hook_decision "deny" "$SAFE_CWD" "rm -rf ${SAFE_CWD}/dist /etc/bad"
  test_hook_decision "deny" "$SAFE_CWD" "rm -rf dist /tmp/other"

  # rm with path traversal → deny (.. can escape safe directory)
  test_hook_decision "deny" "$SAFE_CWD" "rm -rf ../../Documents"
  test_hook_decision "deny" "$SAFE_CWD" "rm -rf ../../../etc"
  test_hook_decision "deny" "$SAFE_CWD" "rm -r foo/../../../tmp"

  # rm with quoted absolute paths → deny (quotes don't hide unsafe paths)
  test_hook_decision "deny" "$SAFE_CWD" "rm -rf \"/tmp/something\""
  test_hook_decision "deny" "$SAFE_CWD" "rm -rf '/etc/bad'"

  # rm with $HOME expanded to unsafe path → deny
  test_hook_decision "deny" "$SAFE_CWD" 'rm -rf $HOME/Documents'
  test_hook_decision "deny" "$SAFE_CWD" 'rm -rf ${HOME}/Documents'

  # rm with $HOME expanded to safe path → ask (expansion resolves correctly)
  test_hook_decision "ask" "$SAFE_CWD" "rm -rf \$HOME${SAFE_DIR#$HOME}subdir/dist"

  # rm with unresolved shell variables → deny (can't verify target)
  test_hook_decision "deny" "$SAFE_CWD" 'rm -rf $TMPDIR/something'
  test_hook_decision "deny" "$SAFE_CWD" 'rm -rf $XDG_DATA_HOME/app'
  test_hook_decision "deny" "$SAFE_CWD" 'rm -rf ${SOME_VAR}/path'

  # chown → always deny (no exemption, separate rule)
  test_hook_decision "deny" "$SAFE_CWD" "chown root file.txt"

  # Non-rm commands remain unaffected by exemption
  test_hook_decision "deny" "$SAFE_CWD" "sudo ls"
  test_hook_decision "deny" "$SAFE_CWD" "kill 1234"

  # git commit messages containing deny-layer words → not denied (prose, not commands)
  # Covers both command-format rules (rm, chown, sudo) and regex-format rules (awk, sed, git clean)
  test_hook_decision "ask" "$SAFE_CWD" 'git commit -m "removed old rm logic"'
  test_hook_decision "ask" "$SAFE_CWD" 'git commit -m "fix: rm cleanup and $HOME expansion"'
  test_hook_decision "ask" "$SAFE_CWD" 'git commit -m "chown and sudo references in docs"'
  test_hook_decision "ask" "$SAFE_CWD" 'git commit -m "docs: use awk instead of grep"'
  test_hook_decision "ask" "$SAFE_CWD" 'git commit -m "docs: mention git clean -f and git checkout -- usage"'
  test_hook_decision "ask" "$SAFE_CWD" 'git commit -m "refactor: replace sed -i with Edit tool"'
  test_hook_decision "ask" "$SAFE_CWD" 'git commit --message "docs: use awk instead of grep"'
  test_hook_decision "ask" "$SAFE_CWD" 'git commit -am "docs: mention git clean -f usage"'

  # Known limitation: semicolons in message text disable the simple-commit
  # skip (regex can't distinguish prose ; from command separators). When
  # combined with $HOME (which expands to an absolute path outside the safe
  # root), the exemption also fails → hard deny. This specific combo requires
  # manual commit or rephrasing.
  test_hook_decision "ask" "$SAFE_CWD" 'git commit -m "fix: rm old logic; update tests"'
  test_hook_decision "deny" "$SAFE_CWD" 'git commit -m "rm and $HOME expansion; updated"'

  # git commit without inline message → deny/paths layers still enforced
  test_hook_decision "deny" "$SAFE_CWD" 'git commit -F ~/.gitconfig'
  test_hook_decision "deny" "$SAFE_CWD" 'git commit --template ~/.aws/credentials'
  test_hook_decision "deny" "$SAFE_CWD" 'git commit --amend --no-edit ~/.ssh/id_rsa'

  # Heredoc body should not poison path-exemption (is_path_exempt uses CMD_NO_HEREDOC)
  test_hook_decision "ask" "$SAFE_CWD" $'rm -rf dist <<\'EOF\'\n/tmp/other\nEOF'

  # --- Symlink escape detection ---
  # Verify paths that appear under the safe directory but resolve outside it
  # (via symlinks) are correctly denied. Inspired by Symphony's path_safety.rs.
  #
  # Uses a dedicated temp dir under the safe root instead of SAFE_CWD, which
  # may be an existing repo without write access.
  #
  # Known gap: no test coverage for safe_path itself being a symlink (the
  # safe_resolved codepath). That would require temporarily modifying the
  # JSON rules file or injecting a custom exempt_when_path, which is fragile.
  # The codepath is defensive — fails open when realpath is unavailable.
  if command -v realpath &>/dev/null; then
    SYMLINK_TEST_DIR=$(mktemp -d "${SAFE_DIR}symlink-test-XXXXXX" 2>/dev/null) || SYMLINK_TEST_DIR=""
    if [[ -n "$SYMLINK_TEST_DIR" && -d "$SYMLINK_TEST_DIR" ]]; then
      printf '\n  %b--- Symlink Escape Detection ---%b\n' "$BOLD" "$NC"
      SYMLINK_TARGET=$(mktemp -d)
      SYMLINK_PATH="${SYMLINK_TEST_DIR}/escape-link"
      ln -sf "$SYMLINK_TARGET" "$SYMLINK_PATH"

      # Path through symlink escaping safe dir → deny
      test_hook_decision "deny" "/tmp" "rm -rf ${SYMLINK_PATH}/something"
      test_hook_decision "deny" "/tmp" "rm ${SYMLINK_PATH}/file.txt"

      # Real (non-symlink) path under safe dir → still ask
      REAL_SUBDIR="${SYMLINK_TEST_DIR}/real-subdir"
      mkdir -p "$REAL_SUBDIR"
      test_hook_decision "ask" "/tmp" "rm -rf ${REAL_SUBDIR}/dist"

      # Symlink inside safe dir pointing to another safe location → ask (not deny)
      SAFE_INTERNAL_TARGET="${SYMLINK_TEST_DIR}/internal-target"
      mkdir -p "$SAFE_INTERNAL_TARGET"
      SAFE_INTERNAL_LINK="${SYMLINK_TEST_DIR}/internal-link"
      ln -sf "$SAFE_INTERNAL_TARGET" "$SAFE_INTERNAL_LINK"
      test_hook_decision "ask" "/tmp" "rm -rf ${SAFE_INTERNAL_LINK}/file"

      # Clean up symlink test artifacts
      rm -rf "$SYMLINK_TEST_DIR" "$SYMLINK_TARGET" 2>/dev/null || true
    else
      printf '\n  %bSKIP%b  cannot create writable dir under %s — skipping symlink tests\n' "$YELLOW" "$NC" "$SAFE_DIR"
    fi
  else
    printf '\n  %bSKIP%b  realpath not available — skipping symlink tests\n' "$YELLOW" "$NC"
  fi

  # Clean up temp dir if we created one
  if $CLEANUP_SAFE_CWD && [[ -d "$SAFE_CWD" ]]; then
    rmdir "$SAFE_CWD" 2>/dev/null || true
  fi

  fi  # end SAFE_CWD availability check
fi

# ---------------------------------------------------------------------------
# Integration tests: heredoc body stripping
#
# Heredoc bodies are prose/data — path-layer regexes should not match against
# them. These tests verify that sensitive keywords inside heredoc bodies pass,
# while the same keywords in the command line (outside heredocs) still deny.
# ---------------------------------------------------------------------------

printf '\n%b--- Heredoc Body Stripping ---%b\n' "$BOLD" "$NC"

HOOK_SCRIPT="${HOOK_SCRIPT:-${SCRIPT_DIR}/bash-permissions.sh}"

test_hook_heredoc() {
  local expect="$1" label="$2" cmd="$3"
  local input
  input=$(jq -n --arg cmd "$cmd" '{"tool_input":{"command":$cmd}}')
  local output
  output=$(printf '%s' "$input" | bash "$HOOK_SCRIPT" 2>/dev/null) || true
  local actual
  if [[ -z "$output" ]]; then
    actual="allow"
  else
    actual=$(printf '%s' "$output" | jq -r '.hookSpecificOutput.permissionDecision // "allow"')
  fi
  total=$((total + 1))
  if [[ "$actual" == "$expect" ]]; then
    pass=$((pass + 1))
    printf "${GREEN}  OK${NC}  %-5s %-22s %s\n" "$expect" "[heredoc]" "$label"
  else
    fail=$((fail + 1))
    printf "${RED}FAIL${NC}  expected=%-5s got=%-5s %-22s %s\n" "$expect" "$actual" "[heredoc]" "$label"
  fi
}

# Heredoc body with sensitive keywords → should NOT be blocked
test_hook_heredoc "allow" "secrets in heredoc body" \
  $'/path/to/script.sh <<\'EOF\'\nResearch /secrets/ directory patterns\nEOF'
test_hook_heredoc "allow" ".env in heredoc body" \
  $'/path/to/script.sh <<\'EOF\'\nCheck .env file handling and .env.local config\nEOF'
test_hook_heredoc "allow" ".pem in heredoc body" \
  $'/path/to/script.sh <<\'EOF\'\nAnalyze server.pem certificate rotation\nEOF'
test_hook_heredoc "allow" "~/.ssh in heredoc body" \
  $'some-tool <<EOF\nAccess ~/.ssh/id_rsa for key rotation\nEOF'
test_hook_heredoc "allow" "~/.aws in heredoc body" \
  $'some-tool <<\'PROMPT\'\nCheck ~/.aws/credentials setup\nPROMPT'
test_hook_heredoc "allow" "~/.zshrc in heredoc body" \
  $'script.sh <<\'END\'\nEdit ~/.zshrc for path changes\nEND'
test_hook_heredoc "allow" "mixed sensitive words in body" \
  $'research.sh <<\'EOF\'\nReview /secrets/ and .env and ~/.ssh/ patterns\nEOF'
test_hook_heredoc "allow" "<<- heredoc variant" \
  $'script.sh <<-\'EOF\'\n\tMentions /secrets/ and .env\n\tEOF'

# Sensitive paths in command line (outside heredoc) → should still deny
test_hook_heredoc "deny" "secrets in command args" \
  "cat /app/secrets/db.yml"
test_hook_heredoc "deny" ".env in command args" \
  "cat .env"
test_hook_heredoc "deny" "sensitive path before heredoc" \
  $'cat /app/secrets/key <<\'EOF\'\ninnocent body\nEOF'
test_hook_heredoc "deny" "sensitive path after heredoc" \
  $'script.sh <<\'EOF\'\ninnocent body\nEOF\ncat .env'

# Edge cases — state machine correctness
test_hook_heredoc "allow" "multiple heredocs with sensitive bodies" \
  $'cmd1 <<\'A\'\n/secrets/ stuff\nA\ncmd2 <<\'B\'\n.env stuff\nB'
test_hook_heredoc "allow" "empty heredoc" \
  $'script.sh <<\'EOF\'\nEOF'

# Non-identifier delimiters (dots, hyphens, digits)
test_hook_heredoc "allow" "dotted delimiter with sensitive body" \
  $'script.sh <<\'END.JSON\'\n/secrets/ and .env\nEND.JSON'
test_hook_heredoc "deny" "dotted delimiter with path after heredoc" \
  $'script.sh <<\'END.JSON\'\ninnocent\nEND.JSON\ncat .env'
test_hook_heredoc "allow" "numeric delimiter" \
  $'script.sh <<123\ncat .env\n123'
test_hook_heredoc "allow" "hyphenated delimiter" \
  $'script.sh <<\'END-DATA\'\n~/.ssh/id_rsa\nEND-DATA'

# Deny-layer: heredoc body should not trigger deny rules
test_hook_heredoc "allow" "sudo in heredoc body (deny bypass)" \
  $'script.sh <<\'EOF\'\nsudo ls\nEOF'
test_hook_heredoc "allow" "kill in heredoc body (deny bypass)" \
  $'script.sh <<\'EOF\'\nkill 1234\nEOF'

# Multiple heredocs on same command line
test_hook_heredoc "allow" "two heredocs on one line" \
  $'cmd <<\'A\' <<\'B\'\nbodyA\nA\nsudo ls\nB'
test_hook_heredoc "allow" "two heredocs mixed sensitive content" \
  $'cmd <<\'X\' <<\'Y\'\n/secrets/ data\nX\n.env content\nY'

# <<- with tab-stripped closing delimiter
test_hook_heredoc "deny" "<<- with tabbed closer then sensitive cmd" \
  $'script <<-\'EOF\'\nbody\n\tEOF\ncat .env'
test_hook_heredoc "allow" "<<- with tabbed closer (body only)" \
  $'script <<-\'EOF\'\n\t/secrets/ stuff\n\tEOF'

# Here-strings (<<<) must not be misparsed as heredocs
test_hook_heredoc "deny" "herestring followed by sensitive path" \
  $'printf x <<< "$foo"\ncat .env'
test_hook_heredoc "deny" "herestring with quoted value" \
  $'cmd <<<\'text\'\ncat /app/secrets/key'


printf '\nResults: %d/%d passed' "$pass" "$total"
if [[ "$fail" -gt 0 ]]; then
  printf ", ${RED}%d FAILED${NC}" "$fail"
fi
printf '\n'

exit "$fail"
