#!/usr/bin/env bash
set -euo pipefail
if [ "$TARGET_COLOR" = "blue" ]; then
  TARGET_HOST="$APP_BLUE_SSH_HOST"
  TARGET_USER="$APP_BLUE_SSH_USER"
else
  TARGET_HOST="$APP_GREEN_SSH_HOST"
  TARGET_USER="$APP_GREEN_SSH_USER"
fi
ssh ${TARGET_USER}@${TARGET_HOST} "curl -fsS http://127.0.0.1:3000/api/health && curl -fsS http://127.0.0.1:3000/api/db >/dev/null && curl -fsSI http://127.0.0.1/ >/dev/null"
echo "Frontend, backend health, and DB probe succeeded on ${TARGET_COLOR}"
