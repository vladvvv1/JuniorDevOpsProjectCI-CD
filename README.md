Створення storage account for state files. (для того, щоб при перезапускав workflows я не получав помилок, що вже щось створено).

RESOURCE_GROUP_NAME="tfstate-rg"
STORAGE_ACCOUNT_NAME="tfstate${RANDOM}"
CONTAINER_NAME="tfstate"

# Створення RG та Storage Account
az group create --name $RESOURCE_GROUP_NAME --location westeurope
az storage account create --resource-group $RESOURCE_GROUP_NAME --name $STORAGE_ACCOUNT_NAME --sku Standard_LRS --encryption-services blob
az storage container create --name $CONTAINER_NAME --account-name $STORAGE_ACCOUNT_NAME

echo "Ваш Storage Account Name: $STORAGE_ACCOUNT_NAME"

# Step 1: Provisioning the Base Infrastructure (Without the Kubernetes Job)

```bash
cd ~/DevOpsJuniorProject/terraform
terraform init

# Provision only the network, database, ACR, and AKS cluster
terraform apply \
  -target=module.network \
  -target=module.dns \
  -target=module.acr \
  -target=module.database \
  -target=module.aks.azurerm_kubernetes_cluster.aks \
  -target=module.aks.azurerm_role_assignment.aks_acr_pull
```

# Step 2: Authentication and Docker Image Upload

```bash
# Automatically retrieve the generated ACR and AKS names
ACR_NAME=$(az acr list --resource-group app-rg --query "[0].name" -o tsv)
AKS_NAME=$(az aks list --resource-group app-rg --query "[0].name" -o tsv)

# Authenticate to the registry and configure kubectl
az acr login --name $ACR_NAME
az aks get-credentials --resource-group app-rg --name $AKS_NAME

# 1) Build and push the database migration image
cd ~/DevOpsJuniorProject/database
docker build -t ${ACR_NAME}.azurecr.io/db-migration:v1 .
docker push ${ACR_NAME}.azurecr.io/db-migration:v1

# 2) Build and push the web application image
cd ~/DevOpsJuniorProject/PhotographerPortoflioBeta2
docker build -t ${ACR_NAME}.azurecr.io/nodejs-app:latest .
docker push ${ACR_NAME}.azurecr.io/nodejs-app:latest
```

# Step 3: Run the Full Terraform Deployment (Database Migration)

```bash
cd ~/DevOpsJuniorProject/terraform

# Terraform can now access the images in ACR
# and successfully execute kubernetes_job.db_migration
terraform apply
```

# Step 4: Deploy the Application to Kubernetes

Make sure the `image` field in `~/DevOpsJuniorProject/k8s/deployment.yaml` contains the correct ACR image URL (or update it before applying).

```bash
cd ~/DevOpsJuniorProject/k8s

# Apply the Kubernetes manifests
# In deployment.yaml the path to docker image and DATABASE_URL should be changed due to you acr updated name.
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
```

# Step 5: Verify the Deployment

```bash
# Check pod status (should be Running or Completed)
kubectl get pods

# Retrieve the external LoadBalancer IP
kubectl get svc
```

The website will be accessible at:

`http://<EXTERNAL-IP>`

Make sure to use the `http://` protocol and open the URL in an incognito window.

```bash
# Глянути логи додатку
kubectl logs -l app=nodejs-app -f
```
TODO:
##DONE Доробити міграцію бд
Замутити шось з змінними в deployemnt.yaml
Видалити app-subnet