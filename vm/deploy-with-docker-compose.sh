#!/usr/bin/env bash
set -euo pipefail

APP_DIR=${APP_DIR:-/opt/business-ai-app}
COMPOSE_FILE=${COMPOSE_FILE:-docker-compose.prod.yml}

cd "$APP_DIR"
docker compose -f "$COMPOSE_FILE" pull
docker compose -f "$COMPOSE_FILE" up -d
