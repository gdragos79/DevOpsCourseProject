#!/usr/bin/env bash
set -euo pipefail

SSH_KEY="${HOME}/.ssh/id_ed25519_bluegreen_orchestrator"

BLUE_HOST="$(printf '%s' "${APP_BLUE_SSH_HOST:-}" | tr -d '\r\n')"
BLUE_USER="$(printf '%s' "${APP_BLUE_SSH_USER:-deploy}" | tr -d '\r\n')"
GREEN_HOST="$(printf '%s' "${APP_GREEN_SSH_HOST:-}" | tr -d '\r\n')"
GREEN_USER="$(printf '%s' "${APP_GREEN_SSH_USER:-deploy}" | tr -d '\r\n')"
TARGET_COLOR="$(printf '%s' "${TARGET_COLOR:-}" | tr -d '\r\n')"

if [[ "$TARGET_COLOR" == "blue" ]]; then
  TARGET_HOST="$BLUE_HOST"
  TARGET_USER="$BLUE_USER"
elif [[ "$TARGET_COLOR" == "green" ]]; then
  TARGET_HOST="$GREEN_HOST"
  TARGET_USER="$GREEN_USER"
else
  echo "Invalid TARGET_COLOR: $TARGET_COLOR"
  exit 1
fi

echo "Running remote smoke tests on ${TARGET_COLOR} (${TARGET_USER}@${TARGET_HOST})"

ssh -i "$SSH_KEY" "${TARGET_USER}@${TARGET_HOST}" bash <<'EOF'
set -euo pipefail

curl -fsS http://127.0.0.1:3000/api/health >/dev/null
curl -fsS http://127.0.0.1:3000/api/db >/dev/null
curl -fsSI http://127.0.0.1/ >/dev/null
EOF

echo "Frontend, backend health, and DB probe succeeded on ${TARGET_COLOR}"