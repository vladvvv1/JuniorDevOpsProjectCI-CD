# Azure Kubernetes & PostgreSQL Cloud Infrastructure for Photographer Portfolio

[![Azure](https://img.shields.io/badge/azure-%230072C6.svg?style=flat&logo=microsoftazure&logoColor=white)](https://azure.microsoft.com/)
[![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=flat&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![Kubernetes](https://img.shields.io/badge/kubernetes-%23326ce5.svg?style=flat&logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=flat&logo=docker&logoColor=white)](https://www.docker.com/)
[![Node.js](https://img.shields.io/badge/Node.js-339933?style=flat&logo=nodedotjs&logoColor=white)](https://nodejs.org/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=flat&logo=postgresql&logoColor=white)](https://www.postgresql.org/)
[![GitHub Actions](https://img.shields.io/badge/github%20actions-%232671E5.svg?style=flat&logo=githubactions&logoColor=white)](https://github.com/features/actions)

End-to-end cloud infrastructure and continuous delivery system provisioning a scalable photographer portfolio web service on Microsoft Azure. Infrastructure is modeled declaratively using modular Terraform with remote state management, container images are hosted on Azure Container Registry (ACR), compute is scheduled on Azure Kubernetes Service (AKS), and relational state is stored securely in Azure Database for PostgreSQL Flexible Server inside a private virtual network.

---

## Table of Contents

- [1. Project Overview](#1-project-overview)
- [2. Architecture](#2-architecture)
- [3. Architecture Diagram](#3-architecture-diagram)
- [4. Repository Structure](#4-repository-structure)
- [5. Technology Stack](#5-technology-stack)
- [6. Prerequisites](#6-prerequisites)
- [7. Azure Authentication](#7-azure-authentication)
- [8. Infrastructure Deployment and Cleanup](#8-infrastructure-deployment-and-cleanup)
  - [8.1 Remote State Setup](#81-remote-state-setup)
  - [8.2 Provisioning Infrastructure](#82-provisioning-infrastructure)
  - [8.3 Decommissioning Resources](#83-decommissioning-resources)
- [9. Database Configuration & Schema Migration](#9-database-configuration--schema-migration)
- [10. Environment Variables](#10-environment-variables)
- [11. Local Development](#11-local-development)
  - [11.1 Native Node.js Execution](#111-native-nodejs-execution)
  - [11.2 Local Database via Docker Compose](#112-local-database-via-docker-compose)
  - [11.3 Containerized Execution](#113-containerized-execution)
- [12. CI/CD Pipeline](#12-cicd-pipeline)
- [13. Kubernetes Application Deployment](#13-kubernetes-application-deployment)
- [14. Security Considerations](#14-security-considerations)
- [15. Troubleshooting](#15-troubleshooting)
- [16. Verification Commands](#16-verification-commands)

---

## 1. Project Overview

This repository automates the full provisioning, configuration, containerization, and deployment lifecycle for a dynamic Node.js photographer portfolio platform:

- **Modular Infrastructure as Code (IaC)**: Provisions an isolated Virtual Network, Network Security Groups, Azure Container Registry, Azure Kubernetes Service, Azure Key Vault, Private DNS Zone, and PostgreSQL Flexible Server via reusable Terraform modules.
- **Container Registry & Cluster Security**: Implements Azure Managed Identity with RBAC `AcrPull` authorization connecting AKS directly to ACR without static cluster credentials.
- **Automated Database Migrations**: Packages schema definitions (`01-init.sql`) and initial data sets (`02-import.sql`) into a dedicated migration container executed as an ephemeral Kubernetes Job prior to application rollout.
- **Continuous Integration & Delivery (CI/CD)**: GitHub Actions workflow triggers on commits to `main` or manual dispatch, executing infrastructure validation/application, image builds, secret provisioning, schema migration, and zero-downtime rolling deployment.

---

## 2. Architecture

```
Internet / End User
        │
        ▼ (Port 80)
┌─────────────────────────────────────────────────────────────┐
│ Azure Load Balancer (Public IP)                             │
└───────┬─────────────────────────────────────────────────────┘
        │
        ▼
┌─────────────────────────────────────────────────────────────┐
│ Virtual Network (10.0.0.0/16)                               │
│                                                             │
│   ┌─────────────────────────────────────────────────────┐   │
│   │ AKS Subnet: snet-aks (10.0.2.0/24)                  │   │
│   │                                                     │   │
│   │   ┌─────────────────────────────────────────────┐   │   │
│   │   │ Kubernetes Service (LoadBalancer)           │   │   │
│   │   │ Port 80 -> ContainerPort 3000               │   │   │
│   │   └──────────────────────┬──────────────────────┘   │   │
│   │                          ▼                          │   │
│   │   ┌─────────────────────────────────────────────┐   │   │
│   │   │ nodejs-app-deployment (2 Replicas)          │   │   │
│   │   │ - Express.js + Static Asset Server          │   │   │
│   │   │ - Fetches config & credentials from Secret  │   │   │
│   │   └──────────────────────┬──────────────────────┘   │   │
│   │                          │                          │   │
│   │   ┌──────────────────────┼──────────────────────┐   │   │
│   │   │ db-migration Job     │ (Ephemeral)          │   │   │
│   │   │ - Runs psql scripts  │                      │   │   │
│   │   └──────────────────────┼──────────────────────┘   │   │
│   └──────────────────────────┼──────────────────────────┘   │
│                              │ Port 5432 (NSG-Restricted)   │
│                              ▼                              │
│   ┌─────────────────────────────────────────────────────┐   │
│   │ Database Delegated Subnet: snet-db (10.0.3.0/24)    │   │
│   │                                                     │   │
│   │   Azure Database for PostgreSQL Flexible Server     │   │
│   │   - Public Access: Disabled                         │   │
│   │   - Private DNS: privatelink.postgres.database.azure.com│
│   └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
        ▲                                     ▲
        │ AcrPull                             │ Secure Secret Storage
┌───────┴───────────────┐             ┌───────┴───────────────┐
│ Azure Container       │             │ Azure Key Vault       │
│ Registry (ACR)        │             │ - Auto-generated      │
│ - nodejs-app          │             │   database password   │
│ - db-migration        │             │   with RBAC control   │
└───────────────────────┘             └───────────────────────┘
```

The system architecture enforces a multi-tier design:
1. **Network Layer**: A Virtual Network `10.0.0.0/16` segmented into `snet-app` (`10.0.1.0/24`), `snet-aks` (`10.0.2.0/24`), and `snet-db` (`10.0.3.0/24`).
2. **Access Control**: Network Security Group rules restrict inbound database traffic (port `5432`) strictly to the AKS subnet CIDR.
3. **Private Name Resolution**: The Azure Private DNS Zone (`privatelink.postgres.database.azure.com`) is linked to the VNet to resolve the internal FQDN of the PostgreSQL server.
4. **Secret Management**: Azure Key Vault generates and stores strong random database administrative passwords, retrieved during deployment to inject into Kubernetes Secrets.

---

## 3. Architecture Diagram

```mermaid
graph TD
    Client(["🌐 Client / Browser"]) -->|HTTP Port 80| ExtLB["Azure Public Load Balancer"]
    
    subgraph Azure_VNet["Azure Virtual Network (10.0.0.0/16)"]
        subgraph AKS_Subnet["snet-aks (10.0.2.0/24)"]
            ExtLB -->|Port 80 -> 3000| K8sSvc["k8s Service: nodejs-app-service"]
            K8sSvc --> Pod1["nodejs-app Pod 1"]
            K8sSvc --> Pod2["nodejs-app Pod 2"]
            MigJob["k8s Job: db-migration"] -.->|Runs on rollout| PostgreServer
            Pod1 -->|Port 5432 / TLS| PostgreServer
            Pod2 -->|Port 5432 / TLS| PostgreServer
        end

        subgraph DB_Subnet["snet-db (10.0.3.0/24)"]
            PostgreServer[("Azure PostgreSQL Flexible Server\nPrivate FQDN\nPublic Access: Disabled")]
        end

        DNS["Azure Private DNS Zone\nprivatelink.postgres.database.azure.com"] -. Resolves .-> PostgreServer
    end

    subgraph Management_and_Platform["Azure Platform Services"]
        ACR["Azure Container Registry (ACR)"]
        KV["Azure Key Vault\n(Secret: db-password)"]
    end

    ACR -.->|Managed Identity / AcrPull| AKS_Subnet
    KV -.->|Generates Admin Pass| PostgreServer

    subgraph CI_CD["GitHub Actions Pipeline"]
        GHA["Runner: ubuntu-latest"]
        GHA -->|1. terraform apply| Azure_VNet
        GHA -->|2. docker push| ACR
        GHA -->|3. kubectl apply secret & jobs| AKS_Subnet
    end
```

---

## 4. Repository Structure

```
DevOpsJuniorProject/
├── .github/
│   └── workflows/
│       └── deploy.yml              # End-to-end CI/CD workflow (Terraform + Docker + AKS)
├── app/
│   ├── client/                     # Frontend UI (HTML, CSS, Vanilla JS, image assets)
│   ├── server/                     # Backend Express application
│   │   └── src/
│   │       ├── config/             # Database connection pool & runtime configurations
│   │       ├── controllers/        # Request handlers (auth, contact messages, photos)
│   │       ├── middleware/         # Authentication & token verification middleware
│   │       ├── routes/             # API route definitions
│   │       └── index.js            # Express server entry point & static asset serving
│   ├── Dockerfile                  # Application container definition (Node.js 18 Alpine)
│   ├── docker-compose.yml          # Local database helper composition
│   └── package.json                # Server-side runtime and dev dependencies
├── database/
│   ├── csv_data/                   # Baseline seed datasets for initial import
│   │   ├── categories.csv
│   │   ├── contact_messages.csv
│   │   ├── photo_categories.csv
│   │   └── photos.csv
│   ├── 01-init.sql                 # DDL definitions (tables, constraints, foreign keys)
│   ├── 02-import.sql               # Data loading statements using PostgreSQL \copy
│   ├── Dockerfile                  # Migration image packaging psql, SQL scripts, and CSVs
│   └── docker-compose.yaml         # Local PostgreSQL standalone testing environment
├── k8s/
│   ├── deployment.yaml.tpl         # Application Deployment template (parameterized by envsubst)
│   ├── migration-job.yaml.tpl      # Kubernetes Batch Job template running schema migrations
│   └── service.yaml                # Public LoadBalancer Kubernetes Service on Port 80
└── terraform/
    ├── environments/
    │   └── prod/
    │       └── terraform.tfvars    # Environment-specific configuration overrides
    ├── modules/
    │   ├── acr/                    # Azure Container Registry (Basic SKU)
    │   ├── aks/                    # Azure Kubernetes Service with Managed Identity
    │   ├── database/               # Azure Database for PostgreSQL Flexible Server
    │   ├── dns/                    # Azure Private DNS Zone & VNet Link
    │   ├── keyvault/               # Azure Key Vault & random DB password generation
    │   └── networking/             # VNet, Subnets (snet-app, snet-aks, snet-db), NSGs
    ├── main.tf                     # Root module orchestration & resource wiring
    ├── outputs.tf                  # Infrastructure outputs required by CI/CD
    ├── provider.tf                 # Terraform provider constraints & remote azurerm backend
    └── variables.tf                # Input variable declarations with defaults
```

---

## 5. Technology Stack

- **Cloud Platform**: Microsoft Azure (Resource Groups, Virtual Networks, NSGs, Private DNS)
- **Container Orchestration**: Azure Kubernetes Service (AKS), Kubernetes CLI (`kubectl`)
- **Container Registry**: Azure Container Registry (ACR)
- **Containerization**: Docker, Docker Compose
- **Infrastructure as Code**: HashiCorp Terraform `>= 1.7.0` (AzureRM Provider `~> 5.13.0`)
- **Backend Application**: Node.js `18`, Express.js `5.x`, `pg` (Node-Postgres)
- **Frontend Application**: HTML5, Vanilla JavaScript, CSS3
- **Database Engine**: PostgreSQL `14` (Flexible Server) / PostgreSQL `15-alpine` (Docker)
- **CI/CD Automation**: GitHub Actions, Azure CLI (`az`), GNU `gettext` (`envsubst`)

---

## 6. Prerequisites

Ensure the following client binaries are installed on your local workstation:

- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) (`>= 2.50.0`)
- [Terraform](https://developer.hashicorp.com/terraform/install) (`>= 1.7.0`)
- [Docker Engine](https://docs.docker.com/engine/install/) (`>= 24.0.0`)
- [kubectl](https://kubernetes.io/docs/tasks/tools/) (`>= 1.28.0`)
- [Node.js](https://nodejs.org/) (`>= 18.x`) & `npm` / `pnpm`
- `gettext` package (provides `envsubst` for template processing)

---

## 7. Azure Authentication

### 7.1 Interactive CLI Login (Local Workstation)

```bash
az login
az account set --subscription "<YOUR_AZURE_SUBSCRIPTION_ID>"
```

### 7.2 Service Principal Creation (For CI/CD Pipelines)

The deployment pipeline relies on an Azure Active Directory Service Principal stored in GitHub Secrets as `AZURE_CREDENTIALS`:

```bash
az ad sp create-for-rbac \
  --name "sp-devops-portfolio" \
  --role "Contributor" \
  --scopes "/subscriptions/<YOUR_AZURE_SUBSCRIPTION_ID>" \
  --json-auth
```

Output format to store in GitHub Secret `AZURE_CREDENTIALS`:
```json
{
  "clientId": "<GUID>",
  "clientSecret": "<SECRET_VALUE>",
  "subscriptionId": "<GUID>",
  "tenantId": "<GUID>",
  "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
  "resourceManagerEndpointUrl": "https://management.azure.com/",
  "activeDirectoryGraphResourceId": "https://graph.windows.net/",
  "sqlManagementEndpointUrl": "https://management.core.windows.net:8443/",
  "galleryEndpointUrl": "https://gallery.azure.com/",
  "managementEndpointUrl": "https://management.core.windows.net/"
}
```

---

## 8. Infrastructure Deployment and Cleanup

### 8.1 Remote State Setup

The Terraform backend configuration in [terraform/provider.tf](file:///home/administrator/DevOpsJuniorProject/terraform/provider.tf) expects an Azure Blob Storage backend:

```bash
# Create dedicated resource group, storage account, and blob container
RESOURCE_GROUP_NAME="tfstate-rg"
STORAGE_ACCOUNT_NAME="tfstate$RANDOM"
CONTAINER_NAME="tfstate"
LOCATION="westeurope"

az group create --name $RESOURCE_GROUP_NAME --location $LOCATION

az storage account create \
  --name $STORAGE_ACCOUNT_NAME \
  --resource-group $RESOURCE_GROUP_NAME \
  --sku Standard_LRS \
  --encryption-services blob

az storage container create \
  --name $CONTAINER_NAME \
  --account-name $STORAGE_ACCOUNT_NAME
```

> [!IMPORTANT]
> If your remote state storage account name differs from `tfstate14845` in [terraform/provider.tf](file:///home/administrator/DevOpsJuniorProject/terraform/provider.tf), update the `storage_account_name` value or pass `-backend-config="storage_account_name=<YOUR_STORAGE_ACCOUNT>"` during `terraform init`.

### 8.2 Provisioning Infrastructure

Execute the Terraform deployment:

```bash
cd terraform

# Initialize provider plugins and remote state
terraform init

# Validate configuration syntax
terraform validate

# Review the execution plan
terraform plan

# Apply infrastructure changes
terraform apply -auto-approve
```

### 8.3 Decommissioning Resources

To remove all provisioned infrastructure and prevent ongoing Azure resource charges:

```bash
cd terraform
terraform destroy -auto-approve
```

---

## 9. Database Configuration & Schema Migration

The application uses PostgreSQL with five core relational tables:
- `users`: Administrator credentials with bcrypt password hashes.
- `categories`: Portfolio photo categories with slugs.
- `photos`: Stored image URLs, titles, descriptions, and timestamps.
- `photo_categories`: Many-to-many relationship mapping photos to categories.
- `contact_messages`: Submitted portfolio contact messages.

### Automated Kubernetes Migration
Schema initialization and data importing are packaged into [database/Dockerfile](file:///home/administrator/DevOpsJuniorProject/database/Dockerfile) and executed automatically via [k8s/migration-job.yaml.tpl](file:///home/administrator/DevOpsJuniorProject/k8s/migration-job.yaml.tpl).

The migration container connects securely through internal VNet DNS, executing:
```bash
PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -f 01-init.sql
PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -f 02-import.sql
```

---

## 10. Environment Variables

The Node.js backend reads its runtime configuration via [app/server/src/config/config.js](file:///home/administrator/DevOpsJuniorProject/app/server/src/config/config.js):

| Variable Name | Required | Default Value | Description |
|---|---|---|---|
| `PORT` | Optional | `3000` | Application HTTP listening port |
| `DATABASE_URL` | **Yes** (Prod) | `postgres://admin:mysecretpassword@localhost:5432/mydatabase` | Full PostgreSQL connection string (`postgres://user:pass@host:5432/dbname?sslmode=require`) |
| `JWT_SECRET` | **Yes** (Prod) | `super_secret_jwt_key_for_dev` | Secret key for signing and verifying JSON Web Tokens |
| `GMAIL_EMAIL` | Optional | `undefined` | Source email address for sending contact form emails |
| `GMAIL_PASSWORD` | Optional | `undefined` | Google App Password for SMTP authentication |
| `TELEGRAM_BOT_TOKEN` | Optional | `undefined` | Telegram Bot token for sending real-time contact notifications |
| `CHAT_ID` | Optional | `undefined` | Target Telegram group/channel chat ID |

---

## 11. Local Development

### 11.1 Native Node.js Execution

```bash
cd app

# Install dependencies
npm install

# Configure environment variables
cat <<EOF > .env
PORT=3000
DATABASE_URL=postgres://admin:mysecretpassword@localhost:5432/mydatabase
JWT_SECRET=local_development_jwt_secret_key
EOF

# Run application in development mode with nodemon
npm start
```

Access the application at `http://localhost:3000`.

### 11.2 Local Database via Docker Compose

Run the local PostgreSQL instance with schema auto-initialization:

```bash
cd database
docker compose up -d
```

This starts PostgreSQL on port `5432` with credentials `admin` / `mysecretpassword` and database `mydatabase`.

### 11.3 Containerized Execution

To build and run the application container locally:

```bash
cd app
docker build -t nodejs-app:local .
docker run -d -p 3000:3000 --name portfolio-app \
  -e DATABASE_URL="postgres://admin:mysecretpassword@host.docker.internal:5432/mydatabase" \
  nodejs-app:local
```

---

## 12. CI/CD Pipeline

The GitHub Actions workflow [.github/workflows/deploy.yml](file:////home/administrator/DevOpsJuniorProject/.github/workflows/deploy.yml) implements a single-pipeline automated release workflow:

```mermaid
flowchart LR
    A[Git Push to main] --> B[Azure Login]
    B --> C[Terraform Init & Apply]
    C --> D[Docker Build & Push to ACR]
    D --> E[Connect to AKS via az aks get-credentials]
    E --> F[Inject Kubernetes Secret app-db-secret]
    F --> G[Run Ephemeral DB Migration Job]
    G --> H[Apply Service & Rollout Deployment]
    H --> I[Verify Rollout & Expose Public Service]
```

### Pipeline Steps:
1. **Infrastructure Convergence**: Runs `terraform apply -auto-approve` to ensure all Azure resources exist and exports outputs (`ACR_LOGIN_SERVER`, `AKS_NAME`, `DB_HOST`, `DB_USER`, `DB_PASSWORD`) directly into the pipeline environment.
2. **Image Delivery**: Builds `db-migration` and `nodejs-app` tagged with `${{ github.sha }}` and pushes them to ACR.
3. **Cluster Secret Provisioning**: Dynamically constructs `DATABASE_URL` with masked credentials and creates/updates Kubernetes Secret `app-db-secret`.
4. **Controlled Schema Migration**: Applies [k8s/migration-job.yaml.tpl](file:///home/administrator/DevOpsJuniorProject/k8s/migration-job.yaml.tpl) using `envsubst` and waits for job completion (`kubectl wait --for=condition=complete`).
5. **Zero-Downtime Deployment**: Deploys [k8s/service.yaml](file:///home/administrator/DevOpsJuniorProject/k8s/service.yaml) and [k8s/deployment.yaml.tpl](file:///home/administrator/DevOpsJuniorProject/k8s/deployment.yaml.tpl), confirming deployment readiness via `kubectl rollout status`.

---

## 13. Kubernetes Application Deployment

If applying manifests manually against the provisioned AKS cluster:

```bash
# 1. Fetch cluster credentials
az aks get-credentials --resource-group app-rg --name <AKS_CLUSTER_NAME> --overwrite-existing

# 2. Populate environment variables for template rendering
export ACR_LOGIN_SERVER="<ACR_NAME>.azurecr.io"
export IMAGE_TAG="latest"
export JOB_NAME="db-migration-manual-$(date +%s)"

# 3. Create or update secret
kubectl create secret generic app-db-secret \
  --from-literal=DATABASE_URL="postgres://<DB_USER>:<DB_PASSWORD>@<DB_HOST>:5432/portfolio?sslmode=require" \
  --from-literal=DB_HOST="<DB_HOST>" \
  --from-literal=DB_USER="<DB_USER>" \
  --from-literal=DB_PASSWORD="<DB_PASSWORD>" \
  --dry-run=client -o yaml | kubectl apply -f -

# 4. Run migration job
envsubst '$ACR_LOGIN_SERVER $IMAGE_TAG $JOB_NAME' < k8s/migration-job.yaml.tpl | kubectl apply -f -
kubectl wait --for=condition=complete job/${JOB_NAME} --timeout=120s

# 5. Deploy application and service
kubectl apply -f k8s/service.yaml
envsubst '$ACR_LOGIN_SERVER $IMAGE_TAG' < k8s/deployment.yaml.tpl | kubectl apply -f -
```

---

## 14. Security Considerations

- **Private Database Network Isolation**: Azure Database for PostgreSQL Flexible Server has `public_network_access_enabled = false` and is placed into a delegated private subnet with Network Security Group ingress limited to port `5432` from AKS.
- **Role-Based Access Control (RBAC)**: AKS uses a System-Assigned Managed Identity granted the `AcrPull` role on ACR, avoiding static registry service credentials.
- **Dynamic Secret Generation**: Database passwords are generated using Terraform's `random_password` provider and synced to Azure Key Vault with RBAC authorization (`Key Vault Secrets Officer`).
- **Secret Masking**: Pipeline secrets and database connection strings are masked via `::add-mask::` before being injected into Kubernetes Secrets.

---

## 15. Troubleshooting

### 1. Database Connection Failures inside Kubernetes
- Verify that the Private DNS Zone `privatelink.postgres.database.azure.com` has an active virtual network link to the cluster VNet.
- Inspect NSG association on `snet-db` to verify port `5432` allows traffic from `10.0.2.0/24`.
- Confirm SSL enforcement: Ensure `?sslmode=require` is appended to the connection string.

### 2. Migration Job Times Out or Fails
```bash
# List failed jobs
kubectl get jobs

# View logs from migration container
kubectl logs -l job-name=<JOB_NAME>
```

### 3. Image Pull Errors (`ImagePullBackOff` / `ErrImagePull`)
- Verify the AKS kubelet identity has `AcrPull` permission:
  ```bash
  az role assignment list --assignee <AKS_KUBELET_OBJECT_ID> --scope <ACR_RESOURCE_ID>
  ```
- Confirm the image tag pushed to ACR matches the tag rendered in `k8s/deployment.yaml.tpl`.

### 4. External IP Pending on LoadBalancer Service
- Azure Load Balancer allocation can take 1–3 minutes. Check cloud-provider controller logs:
  ```bash
  kubectl describe svc nodejs-app-service
  ```

---

## 16. Verification Commands

```bash
# Check node readiness
kubectl get nodes -o wide

# Check pod status and restart count
kubectl get pods -l app=nodejs-app

# Inspect Kubernetes deployment rollout status
kubectl rollout status deployment/nodejs-app-deployment

# Retrieve external Load Balancer IP
kubectl get svc nodejs-app-service

# Stream live application logs
kubectl logs -l app=nodejs-app -f --tail=100

# Query database connectivity from pod
kubectl exec -it deployment/nodejs-app-deployment -- node -e "
import('./server/src/config/db.js').then(({pool}) => {
  pool.query('SELECT NOW()', (err, res) => {
    if (err) console.error(err);
    else console.log('Connected! DB time:', res.rows[0]);
    process.exit();
  });
});"
```
