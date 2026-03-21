#!/usr/bin/env bash
set -euo pipefail

SSH_KEY="${HOME}/.ssh/id_ed25519_bluegreen_orchestrator"
APP_DIR="/home/deploy/myproject/app"
ENV_FILE="${APP_DIR}/env/app.env"
COMPOSE_FILE="${APP_DIR}/docker-compose.yml"

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

APP_DIR="${APP_DIR}"
ENV_FILE="${ENV_FILE}"
COMPOSE_FILE="${COMPOSE_FILE}"
RELEASE_TAG="${RELEASE_TAG}"
GHCR_USERNAME="${GHCR_USERNAME_CLEAN}"
GHCR_TOKEN="${GHCR_TOKEN_CLEAN}"

cd "\$APP_DIR"

echo "\$GHCR_TOKEN" | docker login ghcr.io -u "\$GHCR_USERNAME" --password-stdin

if [ -f "$ENV_FILE" ]; then
  sed -i "s/^TAG=.*/TAG=${RELEASE_TAG}/" "$ENV_FILE"
else
  echo "Missing $ENV_FILE"
  exit 1
fi

echo "Env file found. Current tag value:"
grep '^TAG=' "$ENV_FILE" || true

docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" pull
docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" up -d

docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" config >/dev/null
EOF