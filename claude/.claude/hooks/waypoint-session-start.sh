#!/usr/bin/env bash
# Waypoint — SessionStart hook
# Delegates to `waypoint hook session-start` for journal context injection.

WAYPOINT="${HOME}/.cargo/bin/waypoint"
if [[ ! -x "$WAYPOINT" ]]; then
  exit 0
fi

INPUT=$(cat)
echo "$INPUT" | "$WAYPOINT" hook session-start
