🚌 Bus-Service – Cloud Native Microservice (AKS + Dapr + .NET 8)

This repository contains the Bus-Service microservice for the Online Bus Ticketing System.
The service is implemented in .NET 8 Web API, containerized using Docker, and deployed on Azure Kubernetes Service (AKS) with Dapr sidecar, using Azure DevOps CI/CD pipelines.


📦 1. Prerequisites

Before running or deploying this service, ensure you have the following tools, accounts, and permissions.

🔧 Tools Required (Local Machine)
Tool	Version	Purpose
.NET SDK 8.0	Latest	Local development & build
Docker Desktop	Latest	Build & run containers
kubectl	Latest	Interact with AKS
Helm	v3.x	Package / deploy Kubernetes workload
Dapr CLI	Latest	Dapr sidecar runtime for local and AKS
Azure CLI	Latest	Deploy resources & authenticate
Git	Latest	Source control
🔐 Azure Subscriptions & Permissions

You need access to an Azure subscription with the following permissions:

Required Roles

Contributor on rg-dineshdemo

AcrPush on dineshdemoacr

Azure Kubernetes Service Cluster Admin (or at least “Azure Kubernetes Service RBAC Admin”)

Permission to create:

AKS clusters

Node pools

ACR

Managed Identities

Service Bus namespaces & topics

Azure Resources Pre-Created

Resource Group → rg-dineshdemo

Azure Container Registry → dineshdemoacr

Azure Function Apps (optional if using Functions)

Azure Service Bus Namespace → <your-servicebus>

💻 2. How to Run Locally

You have two options to run the service locally:

OPTION A — Run Locally with Dapr (dapr run)
dapr run \
  --app-id bus-service \
  --app-port 8080 \
  --dapr-http-port 3500 \
  --resources-path ./components \
  dotnet run --project ./BusService/BusService.csproj


Service available at → http://localhost:8080

Dapr sidecar available at → http://localhost:3500

Example: Publish an event (Service Bus pub/sub)
curl -X POST \
  http://localhost:3500/v1.0/publish/booking-pubsub/booking-created \
  -H "Content-Type: application/json" \
  -d '{"bookingId":"12345"}'

OPTION B — Run Locally via Docker Compose

docker-compose.yml example:

version: '3.8'
services:
  bus-service:
    build: ./BusService
    ports:
      - "8080:8080"
  dapr:
    image: "daprio/daprd:latest"
    command: [
      "./daprd",
      "-app-id", "bus-service",
      "-app-port", "8080",
      "-components-path", "/components"
    ]
    volumes:
      - "./components/:/components"
    network_mode: "service:bus-service"


Run:

docker-compose up --build

🚀 3. How to Deploy to Azure

You can deploy using IAC (Bicep) and Azure DevOps pipeline.

3.1 Deploy AKS via Bicep
az deployment group create \
  --resource-group rg-dineshdemo \
  --template-file infra/aks-dineshdemo.bicep \
  --parameters aksName=DineshDemo acrName=dineshdemoacr

3.2 Build & Push Container to ACR (Manual)
docker build -t dineshdemoacr.azurecr.io/bus-service:v1 .
az acr login -n dineshdemoacr
docker push dineshdemoacr.azurecr.io/bus-service:v1

3.3 Deploy Service to AKS (Manual)
az aks get-credentials -g rg-dineshdemo -n DineshDemo

kubectl apply -f k8s/namespace-dineshdemo.yaml
kubectl apply -f k8s/secret-servicebus.yaml
kubectl apply -f k8s/dapr-pubsub-servicebus.yaml
kubectl apply -f k8s/bus-service.yaml
kubectl apply -f k8s/bus-service-hpa.yaml

3.4 Deploy via Azure DevOps (CI/CD Pipeline)

Your YAML pipeline performs:

✔ Build image
✔ Push to ACR
✔ Deploy AKS infra
✔ Deploy microservice with Dapr + HPA

Add pipeline:

azure-pipelines/aks-bus-service.yml


Run pipeline → service deployed to AKS automatically.

⚙ 4. Environments, Config, and Secrets
4.1 Application Configuration

App-specific settings:

ASPNETCORE_ENVIRONMENT

Connection strings

Feature flags

Logging configs

4.2 Kubernetes Secrets (Dapr Components)

Stored in namespace: dineshdemo

Example:

apiVersion: v1
kind: Secret
metadata:
  name: servicebus-conn
stringData:
  connectionString: "<SB CONNECTION STRING>"

4.3 Dapr Components

Example: Service Bus Pub/Sub

apiVersion: dapr.io/v1alpha1
kind: Component
metadata:
  name: booking-pubsub
spec:
  type: pubsub.azure.servicebus
  version: v1

4.4 Key Vault (Recommended)

For production:

Store secrets in Key Vault

Use Managed Identity to access from AKS

Use CSI Secrets Store driver

🔍 5. Observability

The platform uses Azure Monitor + App Insights + Dapr Telemetry.

5.1 Logs

View logs for pods:

kubectl logs -n dineshdemo -l app=bus-service


View logs in Azure:

Azure Portal → AKS → Insights → Logs

Query example:

ContainerLog
| where ContainerName contains "bus-service"

5.2 Metrics

From Azure Portal:

AKS → Insights → Metrics

— pod CPU
— memory
— HPA scaling events
— request latency

5.3 Distributed Tracing (Dapr + .NET)

Correlation via traceparent header

Visible in Application Insights

Dapr sidecar automatically emits spans

5.4 Dashboards

Use:

Azure Monitor Workbooks

Grafana managed service (optional)

🛠 6. Operational Runbook

The following actions are provided as quick recovery or maintenance steps.

📌 Get Pod Status
kubectl get pods -n dineshdemo

📌 Restart the service
kubectl rollout restart deployment/bus-service -n dineshdemo

📌 Check HPA scaling
kubectl get hpa -n dineshdemo

📌 Roll Back Deployment
kubectl rollout undo deployment/bus-service -n dineshdemo

📌 Debug Dapr Sidecar
kubectl logs <pod-name> -c daprd -n dineshdemo

📌 Update Image Manually
kubectl set image deployment/bus-service \
  bus-service=dineshdemoacr.azurecr.io/bus-service:<tag> \
  -n dineshdemo

📌 Check Dapr Components
kubectl get components -n dineshdemo
kubectl describe component booking-pubsub -n dineshdemo

📚 7. References

https://docs.dapr.io

https://learn.microsoft.com/azure/aks

https://learn.microsoft.com/azure/container-registry

https://learn.microsoft.com/azure/azure-monitor

https://github.com/dapr/dotnet-sdk