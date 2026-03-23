#!/usr/bin/env bash
# dbq — agent-safe MySQL query wrapper
# Uses --login-path for credentials (never exposed to the agent).
# Enforces correct flag ordering and hardening defaults.
#
# Usage: dbq <login-path> <database> <sql>
# Example: dbq local global "SELECT COUNT(*) FROM tenant"

set -euo pipefail

if [[ $# -lt 3 ]]; then
  echo "Usage: dbq <login-path> <database> <sql>" >&2
  exit 1
fi

LOGIN_PATH="$1"
DATABASE="$2"
SQL="$3"

# --login-path MUST be the first option — MySQL 9.x rejects it otherwise.
# Hardening flags:
#   --init-command: enforce read-only session (blocks INSERT/UPDATE/DELETE on real tables)
#   --safe-updates: block UPDATE/DELETE without key or LIMIT
#   --connect-timeout: fail fast on unreachable hosts
#   --quick: stream results instead of buffering
#   --commands=FALSE: disable client-side commands (source, system)
#   --local-infile=0: disable LOAD DATA LOCAL
mysql \
  --login-path="$LOGIN_PATH" \
  --batch \
  --quick \
  --connect-timeout=5 \
  --init-command="SET SESSION TRANSACTION READ ONLY" \
  --safe-updates \
  --commands=FALSE \
  --skip-system-command \
  --local-infile=0 \
  "$DATABASE" \
  --execute="$SQL"
