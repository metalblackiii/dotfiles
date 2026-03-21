#!/usr/bin/env bash
# Waypoint — PostToolUse:Edit|Write failure hook
# Delegates to `waypoint hook post-failure` to suggest trap search.

WAYPOINT="${HOME}/.cargo/bin/waypoint"
if [[ ! -x "$WAYPOINT" ]]; then
  exit 0
fi

INPUT=$(cat)
echo "$INPUT" | "$WAYPOINT" hook post-failure
