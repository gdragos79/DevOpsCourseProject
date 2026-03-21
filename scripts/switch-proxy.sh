#!/usr/bin/env bash
set -euo pipefail
: "${TARGET_COLOR:?TARGET_COLOR is required}"
: "${PROXY_SSH_USER:?PROXY_SSH_USER is required}"
: "${PROXY_SSH_HOST:?PROXY_SSH_HOST is required}"

if [[ "$TARGET_COLOR" != "blue" && "$TARGET_COLOR" != "green" ]]; then
  echo "TARGET_COLOR must be blue or green"
  exit 1
fi

ssh ${PROXY_SSH_USER}@${PROXY_SSH_HOST} "sudo -n /usr/local/bin/myproject-switch-proxy ${TARGET_COLOR}"
echo "Proxy switched to ${TARGET_COLOR}"
