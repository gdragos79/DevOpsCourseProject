#!/usr/bin/env bash
set -euo pipefail
: "${TARGET_COLOR:?TARGET_COLOR is required}"

if [[ "$TARGET_COLOR" != "blue" && "$TARGET_COLOR" != "green" ]]; then
  echo "TARGET_COLOR must be blue or green"
  exit 1
fi

sudo -n /usr/local/bin/myproject-switch-proxy "$TARGET_COLOR"
echo "Proxy switched to ${TARGET_COLOR}"
