#!/usr/bin/env bash
set -euo pipefail
: "${BUILD_TAG:?BUILD_TAG is required}"
: "${GHCR_USERNAME:?GHCR_USERNAME is required}"
: "${GHCR_TOKEN:?GHCR_TOKEN is required}"
APP_ROOT="/home/deploy/myproject/app"
ENV_FILE="${APP_ROOT}/env/app.env"
COMPOSE_FILE="${APP_ROOT}/docker-compose.yml"
echo "Deploying build tag ${BUILD_TAG} to staging at ${APP_ROOT}"
mkdir -p "$APP_ROOT"
cd "$APP_ROOT"

echo "$GHCR_TOKEN" | docker login ghcr.io -u "$GHCR_USERNAME" --password-stdin

if grep -q '^TAG=' "$ENV_FILE"; then
  sed -i "s/^TAG=.*/TAG=${BUILD_TAG}/" "$ENV_FILE"
else
  echo "TAG=${BUILD_TAG}" >> "$ENV_FILE"
fi

docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" pull
docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" up -d

echo "Staging deploy complete. Active image tag in ${ENV_FILE} is now ${BUILD_TAG}."
