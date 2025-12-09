#!/usr/bin/env bash
set -euo pipefail

RESOURCE_GROUP="rg-dineshdemo"
AKS_NAME="DineshDemo"

echo "Getting AKS credentials..."
az aks get-credentials \
  --resource-group "${RESOURCE_GROUP}" \
  --name "${AKS_NAME}" \
  --overwrite-existing

echo "Installing / upgrading Dapr on AKS..."
# This uses the Dapr Helm chart via the Dapr CLI
# Assumes 'dapr' CLI is available on the agent or machine
dapr init -k --wait

echo "Dapr status:"
dapr status -k
