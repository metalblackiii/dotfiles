#!/usr/bin/env bash
set -euo pipefail

INCLUDE_DONE=false

usage() {
  cat <<'EOF'
Usage: sprint-status.sh [options]

Options:
  --include-done    Show completed items (hidden by default)
  -h, --help        Show help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --include-done)
      INCLUDE_DONE=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

for dep in ptjira jq; do
  if ! command -v "$dep" >/dev/null 2>&1; then
    echo "Missing dependency: $dep" >&2
    exit 1
  fi
done

BOARD_ID="1062"
BOARD_NAME="Phoenix"

# Resolve current user's account ID for board URL
ACCOUNT_ID="$(ptjira whoami --json | jq -r '.accountId')"
if [[ -z "$ACCOUNT_ID" || "$ACCOUNT_ID" == "null" ]]; then
  BOARD_URL="https://practicetek.atlassian.net/jira/software/c/projects/NEB/boards/${BOARD_ID}"
else
  ENCODED_ID="$(printf '%s' "$ACCOUNT_ID" | jq -sRr @uri)"
  BOARD_URL="https://practicetek.atlassian.net/jira/software/c/projects/NEB/boards/${BOARD_ID}?assignee=${ENCODED_ID}"
fi

JQL='assignee = currentUser() AND project = NEB AND sprint in openSprints() ORDER BY rank ASC'

raw="$(ptjira search "$JQL" --max-results 50 --json)"

issue_count="$(jq '.issues | length' <<< "$raw")"
if [[ "$issue_count" -eq 0 ]]; then
  echo "No sprint items found for current user."
  exit 0
fi

# Filter and format with jq
jq -r --argjson include_done "$INCLUDE_DONE" --arg board_name "$BOARD_NAME" --arg board_url "$BOARD_URL" '
  def pad($n): . + (" " * ([$n - length, 0] | max));
  def trunc($n): if length > $n then .[:$n] + "…" else . end;
  def cat_rank:
    if . == "To Do" then 0
    elif . == "In Progress" then 1
    else 2
    end;

  [.issues[] | {
    key,
    summary: (.fields.summary | trunc(68)),
    status: .fields.status.name,
    category: (.fields.status.statusCategory.name // "Unknown"),
    assignee: (.fields.assignee.displayName // "Unassigned"),
    priority: (.fields.priority.name // "—"),
    _sort: ((.fields.status.statusCategory.name // "Unknown") | cat_rank)
  }]
  # Count Done before filtering so the hidden count is accurate
  | (map(select(.category == "Done")) | length) as $done_total
  | if $include_done then . else map(select(.category != "Done")) end
  | (length) as $visible
  | (map(select(.category == "To Do")) | length) as $todo
  | (map(select(.category == "In Progress")) | length) as $wip
  | (map(select(.category == "Done")) | length) as $done

  | "# Sprint Status  ·  [\($board_name) Board](\($board_url))\n",
    (if $include_done then
      "\($visible) items — To Do: \($todo) | In Progress: \($wip) | Done: \($done)\n"
    else
      "\($visible) active items — To Do: \($todo) | In Progress: \($wip)" +
      (if $done_total > 0 then " (+ \($done_total) done, hidden)" else "" end) + "\n"
    end),
    (group_by(._sort) | .[] | group_by(.status) | sort_by(.[0].status) | .[] |
      "[\(.[0].category)] \(.[0].status) (\(length))",
      (.[] | "  [\(.key)](https://practicetek.atlassian.net/browse/\(.key))  \(.priority | pad(8))  \(.summary)"),
      "")
' <<< "$raw"
