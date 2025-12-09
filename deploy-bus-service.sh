#!/usr/bin/env bash
set -euo pipefail

##############################################
# Config
##############################################
RESOURCE_GROUP="rg-dineshdemo"
AKS_NAME="DineshDemo"
NAMESPACE="dineshdemo"
ACR_LOGIN_SERVER="dineshdemoacr.azurecr.io"
IMAGE_NAME="bus-service"

IMAGE_TAG="${1:-latest}"

echo "Deploying ${IMAGE_NAME}:${IMAGE_TAG} to AKS cluster ${AKS_NAME} (rg: ${RESOURCE_GROUP})"

##############################################
# Get AKS credentials
##############################################
az aks get-credentials \
  --resource-group "${RESOURCE_GROUP}" \
  --name "${AKS_NAME}" \
  --overwrite-existing

##############################################
# Namespace
##############################################
kubectl apply -f k8s/namespace-dineshdemo.yaml

##############################################
# Dapr components (secrets + pubsub etc.)
##############################################
kubectl apply -f k8s/secret-servicebus.yaml
kubectl apply -f k8s/dapr-pubsub-servicebus.yaml

##############################################
# App deployment (deployment + service + HPA)
##############################################
kubectl apply -f k8s/bus-service.yaml
kubectl apply -f k8s/bus-service-hpa.yaml

##############################################
# Update deployment image with given tag
##############################################
kubectl set image deployment/bus-service \
  bus-service="${ACR_LOGIN_SERVER}/${IMAGE_NAME}:${IMAGE_TAG}" \
  -n "${NAMESPACE}"

echo "Deployment triggered successfully."
kubectl get pods -n "${NAMESPACE}"
