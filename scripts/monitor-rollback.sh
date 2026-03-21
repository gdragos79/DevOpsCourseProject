#!/usr/bin/env bash
set -euo pipefail
: "${TARGET_COLOR:?TARGET_COLOR is required}"
: "${PREVIOUS_COLOR:?PREVIOUS_COLOR is required}"

if [[ "$TARGET_COLOR" != "blue" && "$TARGET_COLOR" != "green" ]]; then
  echo "TARGET_COLOR must be blue or green"
  exit 1
fi

if [[ "$PREVIOUS_COLOR" != "blue" && "$PREVIOUS_COLOR" != "green" ]]; then
  echo "PREVIOUS_COLOR must be blue or green"
  exit 1
fi

FRONTEND_URL="${PUBLIC_FRONTEND_URL:-http://127.0.0.1/}"
BACKEND_HEALTH_URL="${PUBLIC_BACKEND_HEALTH_URL:-http://127.0.0.1/api/health}"

echo "Monitoring frontend URL: ${FRONTEND_URL}"
echo "Monitoring backend health URL: ${BACKEND_HEALTH_URL}"

failures=0
for i in $(seq 1 10); do
  if curl -fsSI "$FRONTEND_URL" >/dev/null && curl -fsS "$BACKEND_HEALTH_URL" >/dev/null; then
    echo "Minute $i: healthy"
  else
    failures=$((failures + 1))
    echo "Minute $i: unhealthy"
    break
  fi
  sleep 60
done

if [ "$failures" -gt 0 ]; then
  sudo -n /usr/local/bin/myproject-switch-proxy "$PREVIOUS_COLOR"
  echo "Rollback executed to ${PREVIOUS_COLOR}"
  exit 1
fi

echo "Rollback window finished successfully"
