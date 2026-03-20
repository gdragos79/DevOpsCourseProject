#!/usr/bin/env bash
set -euo pipefail
: "${TARGET_COLOR:?TARGET_COLOR is required}"
: "${RELEASE_TAG:?RELEASE_TAG is required}"
: "${GHCR_USERNAME:?GHCR_USERNAME is required}"
: "${GHCR_TOKEN:?GHCR_TOKEN is required}"

if [ "$TARGET_COLOR" = "blue" ]; then
  TARGET_HOST="$APP_BLUE_SSH_HOST"
  TARGET_USER="$APP_BLUE_SSH_USER"
else
  TARGET_HOST="$APP_GREEN_SSH_HOST"
  TARGET_USER="$APP_GREEN_SSH_USER"
fi

echo "Deploying ${RELEASE_TAG} to ${TARGET_COLOR} (${TARGET_USER}@${TARGET_HOST})"
ssh ${TARGET_USER}@${TARGET_HOST} "GHCR_USERNAME='${GHCR_USERNAME}' GHCR_TOKEN='${GHCR_TOKEN}' RELEASE_TAG='${RELEASE_TAG}' bash -s" <<'EOF'
set -euo pipefail
APP_ROOT="/home/deploy/myproject/app"
ENV_FILE="${APP_ROOT}/env/app.env"
COMPOSE_FILE="${APP_ROOT}/docker-compose.yml"
cd "$APP_ROOT"

echo "$GHCR_TOKEN" | docker login ghcr.io -u "$GHCR_USERNAME" --password-stdin

if grep -q '^TAG=' "$ENV_FILE"; then
  sed -i "s/^TAG=.*/TAG=${RELEASE_TAG}/" "$ENV_FILE"
else
  echo "TAG=${RELEASE_TAG}" >> "$ENV_FILE"
fi

docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" pull
docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" up -d

echo "Deployed ${RELEASE_TAG} to idle environment using ${ENV_FILE}."
EOF
