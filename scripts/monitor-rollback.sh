#!/usr/bin/env bash
set -euo pipefail
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
  if [ "$PREVIOUS_COLOR" = "blue" ]; then
    INCLUDE_FILE='include /etc/nginx/upstreams/blue.conf;'
  else
    INCLUDE_FILE='include /etc/nginx/upstreams/green.conf;'
  fi
  ssh ${PROXY_SSH_USER}@${PROXY_SSH_HOST} "printf '%s\n' \"${INCLUDE_FILE}\" | sudo tee /etc/nginx/upstreams/active.conf >/dev/null && sudo nginx -t && sudo systemctl reload nginx"
  echo "Rollback executed to ${PREVIOUS_COLOR}"
  exit 1
fi
echo "Rollback window finished successfully"
