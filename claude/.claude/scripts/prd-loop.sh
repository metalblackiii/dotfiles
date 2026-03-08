#!/usr/bin/env bash
# prd-loop.sh — Deterministic orchestrator for PRD implementation.
# Bash drives the loop. Claude orchestrates each phase. Codex implements.
# Fresh Claude context per phase — state lives on disk, not in conversation.
#
# Usage:
#   prd-loop.sh <path-to-prd.md>            # decompose + approve + execute
#   prd-loop.sh --resume                     # resume from existing .prd-loop/state.json
#   prd-loop.sh --status                     # show current phase status
#
# Workflow:
#   1. /create-prd                            # interactive: interview → lean PRD
#   2. prd-loop.sh docs/prd-<slug>.md        # decompose → approve phases → execute loop
#
# Architecture:
#   bash (this script)  → deterministic loop, state validation, circuit breaker
#   claude -p           → fresh context per phase: plan, spec, review, state update
#   codex exec          → fresh context per delegation: implements one spec

set -euo pipefail

readonly LOOP_DIR=".prd-loop"
readonly STATE_FILE="$LOOP_DIR/state.json"
readonly PROGRESS_FILE="$LOOP_DIR/progress.txt"
readonly MAX_PHASE_RETRIES=3
readonly MAX_CONSECUTIVE_FAILURES=3
# Pause between phases to avoid API rate limits on rapid sequential claude -p calls
readonly PHASE_COOLDOWN_SECS=3

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
readonly PROMPT_DIR="$SCRIPT_DIR/prd-loop-prompts"

die() { printf 'FATAL: %s\n' "$*" >&2; exit 1; }

command -v jq >/dev/null    || die "jq is required (brew install jq)"
command -v claude >/dev/null || die "claude CLI not found"
command -v codex >/dev/null  || die "codex CLI not found"

show_status() {
  [[ -f "$STATE_FILE" ]] || die "No state file found — run prd-loop.sh <prd.md> first"
  printf '\n  PRD: %s\n' "$(jq -r '.prd_path' "$STATE_FILE")"
  printf '  Updated: %s\n\n' "$(jq -r '.updated_at' "$STATE_FILE")"
  jq -r '.phases[] | "  \(.id) [\(.status)]\t\(.title)\(if .failed_count > 0 then " (failed: \(.failed_count))" else "" end)"' "$STATE_FILE"
  printf '\n'
  exit 0
}

# ── Arg Parsing ──────────────────────────────────────────────────────
case "${1:-}" in
  --status) show_status ;;
  --resume)
    [[ -f "$STATE_FILE" ]] || die "No state file to resume — run prd-loop.sh <prd.md> first"
    prd_path="$(jq -r '.prd_path' "$STATE_FILE")"
    [[ -f "$prd_path" ]] || die "PRD not found at $prd_path — has it moved?"
    printf '=== Resuming from existing state ===\n'
    ;;
  ""|--help|-h)
    printf 'Usage:\n'
    printf '  prd-loop.sh <path-to-prd.md>   Decompose PRD into phases and execute\n'
    printf '  prd-loop.sh --resume            Resume from existing .prd-loop/state.json\n'
    printf '  prd-loop.sh --status            Show current phase status\n'
    exit 0
    ;;
  *)
    prd_path="$1"
    [[ -f "$prd_path" ]] || die "PRD not found: $prd_path"
    prd_path="$(cd "$(dirname "$prd_path")" && pwd)/$(basename "$prd_path")"
    # Guard: existing state from a different PRD
    if [[ -f "$STATE_FILE" ]]; then
      existing_prd=$(jq -r '.prd_path' "$STATE_FILE")
      if [[ "$existing_prd" != "$prd_path" ]]; then
        die "State exists for a different PRD:\n  existing: $existing_prd\n  requested: $prd_path\nDelete $LOOP_DIR or use --resume to continue the existing run"
      fi
    fi
    ;;
esac

# ── Decompose ────────────────────────────────────────────────────────
if [[ ! -f "$STATE_FILE" ]]; then
  printf '=== Decomposing PRD into phases ===\n'
  mkdir -p "$LOOP_DIR/plans" "$LOOP_DIR/specs"

  decompose_prompt=$(sed \
    -e "s|{{PRD_PATH}}|$prd_path|g" \
    -e "s|{{STATE_FILE}}|$STATE_FILE|g" \
    -e "s|{{PROGRESS_FILE}}|$PROGRESS_FILE|g" \
    "$PROMPT_DIR/decompose.md"
  )

  if ! claude -p "$decompose_prompt"; then
    die "Claude decomposition failed — check auth, rate limits, or model availability"
  fi

  jq -e '.phases | length > 0' "$STATE_FILE" >/dev/null 2>&1 \
    || die "Decomposition produced no phases — $STATE_FILE missing or empty"

  # ── Human Approval Gate ──────────────────────────────────────────
  phase_count=$(jq '.phases | length' "$STATE_FILE")
  printf '\n=== Proposed %d phases ===\n\n' "$phase_count"
  jq -r '.phases[] | "  \(.id): \(.title)\n        \(.description)\n"' "$STATE_FILE"

  printf 'Review the phases above. You can also edit %s directly.\n' "$STATE_FILE"
  printf 'Proceed with execution? [y/N] '
  read -r confirm
  case "$confirm" in
    [yY]|[yY]es) printf '=== Starting execution loop ===\n' ;;
    *) printf 'Aborted. Edit %s and run: prd-loop.sh --resume\n' "$STATE_FILE"; exit 0 ;;
  esac
fi

# ── Branch Setup ────────────────────────────────────────────────────
branch=$(jq -r '.branch // empty' "$STATE_FILE" 2>/dev/null)
if [[ -z "$branch" ]]; then
  # Read branch from PRD metadata ("> Branch: <name>"), fall back to slug from filename
  prd_branch=$(sed -n 's/^> *Branch: *//p' "$prd_path" | tr -d '[:space:]')
  if [[ -n "$prd_branch" ]]; then
    branch="$prd_branch"
  else
    slug=$(basename "$prd_path" .md | sed 's/^prd-//')
    branch="prd-loop/$slug"
  fi
  git checkout -b "$branch"
  jq --arg b "$branch" '.branch = $b' "$STATE_FILE" > "$STATE_FILE.tmp" \
    && mv "$STATE_FILE.tmp" "$STATE_FILE"
  printf '=== Created branch: %s ===\n' "$branch"
else
  current=$(git branch --show-current)
  if [[ "$current" != "$branch" ]]; then
    git checkout "$branch" || die "Cannot switch to branch $branch — resolve manually"
  fi
  printf '=== On branch: %s ===\n' "$branch"
fi

# ── Clean Worktree Check ───────────────────────────────────────────
# git add -A in phase commits would sweep unrelated changes into phase commits
dirty=$(git diff --name-only 2>/dev/null | wc -l | tr -d ' ')
staged=$(git diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')
if [[ "$dirty" -gt 0 || "$staged" -gt 0 ]]; then
  die "Working tree is not clean ($dirty unstaged, $staged staged).\nCommit or stash unrelated changes before running the loop."
fi

# ── Main Loop ────────────────────────────────────────────────────────
while true; do
  # All done?
  remaining=$(jq '[.phases[] | select(.status == "pending" or .status == "in_progress" or .status == "failed")] | length' "$STATE_FILE")
  if [[ "$remaining" -eq 0 ]]; then
    printf '\n=== All phases complete ===\n'
    jq -r '.phases[] | "  \(.id) [\(.status)]: \(.title)"' "$STATE_FILE"
    break
  fi

  # Circuit breaker: consecutive failures across phases
  consecutive=$(jq '.consecutive_failures // 0' "$STATE_FILE")
  if [[ "$consecutive" -ge "$MAX_CONSECUTIVE_FAILURES" ]]; then
    die "$consecutive consecutive failures — review $STATE_FILE and $PROGRESS_FILE, then reset consecutive_failures to resume"
  fi

  # Pick next actionable phase
  next_id=$(jq -r '[.phases[] | select(.status == "pending" or .status == "in_progress" or .status == "failed")] | first | .id' "$STATE_FILE")
  next_title=$(jq -r ".phases[] | select(.id == \"$next_id\") | .title" "$STATE_FILE")
  failed_count=$(jq -r ".phases[] | select(.id == \"$next_id\") | .failed_count // 0" "$STATE_FILE")

  # Skip exhausted phases
  if [[ "$failed_count" -ge "$MAX_PHASE_RETRIES" ]]; then
    printf '=== Skipping %s (failed %d times) ===\n' "$next_id" "$failed_count"
    jq "(.phases[] | select(.id == \"$next_id\")) |= (.status = \"skipped\")" \
      "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"
    continue
  fi

  # Clean up any leftover changes from a previous failed attempt
  if [[ "$failed_count" -gt 0 ]]; then
    dirty_retry=$(git diff --name-only 2>/dev/null | wc -l | tr -d ' ')
    staged_retry=$(git diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$dirty_retry" -gt 0 || "$staged_retry" -gt 0 ]]; then
      printf '  Discarding %d dirty file(s) from previous attempt\n' "$((dirty_retry + staged_retry))"
      git checkout -- . 2>/dev/null
      git reset HEAD -- . 2>/dev/null
    fi
  fi

  printf '\n=== Phase: %s — %s (attempt %d/%d) ===\n' \
    "$next_id" "$next_title" "$((failed_count + 1))" "$MAX_PHASE_RETRIES"

  head_before=$(git rev-parse HEAD)

  # Build phase prompt from template
  phase_prompt=$(sed \
    -e "s|{{PHASE_ID}}|$next_id|g" \
    -e "s|{{STATE_FILE}}|$STATE_FILE|g" \
    -e "s|{{PROGRESS_FILE}}|$PROGRESS_FILE|g" \
    -e "s|{{PRD_PATH}}|$prd_path|g" \
    -e "s|{{LOOP_DIR}}|$LOOP_DIR|g" \
    "$PROMPT_DIR/phase.md"
  )

  # Fresh Claude instance — no accumulated context
  if ! claude -p "$phase_prompt"; then
    printf 'WARNING: Claude exited with error for phase %s\n' "$next_id" >&2
    # If state file is still valid, the phase prompt may have updated it before failing.
    # If not, increment consecutive_failures ourselves so the circuit breaker works.
    if jq -e '.' "$STATE_FILE" >/dev/null 2>&1; then
      jq ".consecutive_failures = ((.consecutive_failures // 0) + 1) | .updated_at = \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"" \
        "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"
    else
      die "$STATE_FILE is corrupt after Claude failure — check git for last good version"
    fi
    sleep "$PHASE_COOLDOWN_SECS"
    continue
  fi

  # Validate state is still parseable JSON
  jq -e '.' "$STATE_FILE" >/dev/null 2>&1 \
    || die "$STATE_FILE is invalid JSON after phase execution — check git for last good version"

  # Commit validation: catch silent failures where phase "completed" but nothing was committed
  phase_status=$(jq -r ".phases[] | select(.id == \"$next_id\") | .status" "$STATE_FILE")
  if [[ "$phase_status" == "completed" ]]; then
    head_after=$(git rev-parse HEAD)
    if [[ "$head_before" == "$head_after" ]]; then
      printf 'WARNING: Phase %s marked completed but no commits were made — possible silent failure\n' "$next_id" >&2
    else
      commit_count=$(git rev-list --count "$head_before".."$head_after")
      printf '  %s commit(s) in this phase\n' "$commit_count"
    fi
  fi

  printf '=== Phase %s: %s ===\n' "$next_id" "$phase_status"

  sleep "$PHASE_COOLDOWN_SECS"
done

printf '\n=== Run complete. Review %s for details ===\n' "$PROGRESS_FILE"
