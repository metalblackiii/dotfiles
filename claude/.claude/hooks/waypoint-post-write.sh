#!/usr/bin/env bash
# Waypoint — PostToolUse:Edit|Write hook
# Delegates to `waypoint hook post-write` for incremental map updates.

WAYPOINT="${HOME}/.cargo/bin/waypoint"
if [[ ! -x "$WAYPOINT" ]]; then
  exit 0
fi

INPUT=$(cat)
echo "$INPUT" | "$WAYPOINT" hook post-write
