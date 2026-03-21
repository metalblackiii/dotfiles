#!/usr/bin/env bash
# Waypoint — PreToolUse:Read hook
# Delegates to `waypoint hook pre-read` for advisory context injection.

WAYPOINT="${HOME}/.cargo/bin/waypoint"
if [[ ! -x "$WAYPOINT" ]]; then
  exit 0
fi

INPUT=$(cat)
echo "$INPUT" | "$WAYPOINT" hook pre-read
