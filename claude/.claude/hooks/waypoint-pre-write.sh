#!/usr/bin/env bash
# Waypoint — PreToolUse:Edit|Write hook
# Delegates to `waypoint hook pre-write` for trap warnings.

WAYPOINT="${HOME}/.cargo/bin/waypoint"
if [[ ! -x "$WAYPOINT" ]]; then
  exit 0
fi

INPUT=$(cat)
echo "$INPUT" | "$WAYPOINT" hook pre-write
