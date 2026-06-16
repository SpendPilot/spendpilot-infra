#!/usr/bin/env bash
set -euo pipefail

APP_DIR=${APP_DIR:-/opt/business-ai-app}
cd "$APP_DIR"
docker compose -f docker-compose.vmss.yml pull
docker compose -f docker-compose.vmss.yml up -d
