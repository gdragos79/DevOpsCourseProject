#!/usr/bin/env bash
set -euo pipefail

SSH_KEY="${HOME}/.ssh/id_ed25519_bluegreen_orchestrator"

BLUE_HOST="$(printf '%s' "${APP_BLUE_SSH_HOST:-}" | tr -d '\r\n')"
BLUE_USER="$(printf '%s' "${APP_BLUE_SSH_USER:-deploy}" | tr -d '\r\n')"
GREEN_HOST="$(printf '%s' "${APP_GREEN_SSH_HOST:-}" | tr -d '\r\n')"
GREEN_USER="$(printf '%s' "${APP_GREEN_SSH_USER:-deploy}" | tr -d '\r\n')"
TARGET_COLOR="$(printf '%s' "${TARGET_COLOR:-}" | tr -d '\r\n')"
RELEASE_TAG="$(printf '%s' "${RELEASE_TAG:-}" | tr -d '\r\n')"
GHCR_USERNAME_CLEAN="$(printf '%s' "${GHCR_USERNAME:-}" | tr -d '\r\n')"
GHCR_TOKEN_CLEAN="$(printf '%s' "${GHCR_TOKEN:-}" | tr -d '\r\n')"

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

echo "Deploying ${RELEASE_TAG} to ${TARGET_COLOR} (${TARGET_USER}@${TARGET_HOST})"

ssh -i "$SSH_KEY" "${TARGET_USER}@${TARGET_HOST}" bash <<EOF
set -euo pipefail

cd /home/deploy/myproject/app

echo "${GHCR_TOKEN_CLEAN}" | docker login ghcr.io -u "${GHCR_USERNAME_CLEAN}" --password-stdin

if [ -f /home/deploy/myproject/app/env/app.env ]; then
  sed -i "s/^TAG=.*/TAG=${RELEASE_TAG}/" /home/deploy/myproject/app/env/app.env
else
  echo "Missing /home/deploy/myproject/app/env/app.env"
  exit 1
fi

docker compose -f /home/deploy/myproject/app/docker-compose.yml pull
docker compose -f /home/deploy/myproject/app/docker-compose.yml up -d
EOF