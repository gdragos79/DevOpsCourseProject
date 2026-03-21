#!/usr/bin/env bash
set -euo pipefail
: "${TARGET_COLOR:?TARGET_COLOR is required}"
: "${PREVIOUS_COLOR:?PREVIOUS_COLOR is required}"
: "${PUBLIC_FRONTEND_URL:?PUBLIC_FRONTEND_URL is required}"
: "${PUBLIC_BACKEND_HEALTH_URL:?PUBLIC_BACKEND_HEALTH_URL is required}"

if [[ "$TARGET_COLOR" != "blue" && "$TARGET_COLOR" != "green" ]]; then
  echo "TARGET_COLOR must be blue or green"
  exit 1
fi

if [[ "$PREVIOUS_COLOR" != "blue" && "$PREVIOUS_COLOR" != "green" ]]; then
  echo "PREVIOUS_COLOR must be blue or green"
  exit 1
fi

failures=0
for i in $(seq 1 10); do
  if curl -fsSI "$PUBLIC_FRONTEND_URL" >/dev/null && curl -fsS "$PUBLIC_BACKEND_HEALTH_URL" >/dev/null; then
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
