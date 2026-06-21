#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <environment>" >&2
  exit 1
fi

environment_name="$1"

case "$environment_name" in
  dev|prod)
    ;;
  *)
    exit 0
    ;;
esac

if [[ "$environment_name" == "dev" ]]; then
  resource_group_name="spendpilot-rg"
  cluster_name="spendpilot-dev-aks"
  az aks get-credentials \
    --resource-group "$resource_group_name" \
    --name "$cluster_name" \
    --admin \
    --overwrite-existing \
    --file "envs/${environment_name}/.generated-kubeconfig" \
    1>/dev/null
  exit 0
fi

resource_group_name="rg-spendpilot-prod"
cluster_name="spendpilot-prod-aks"

az aks get-credentials \
  --resource-group "$resource_group_name" \
  --name "$cluster_name" \
  --admin \
  --overwrite-existing \
  --file "envs/${environment_name}/.generated-kubeconfig" \
  1>/dev/null
