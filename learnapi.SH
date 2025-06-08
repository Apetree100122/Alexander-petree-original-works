version: '3.8'

services:
  storage:
    image: mcr.microsoft.com/azure-storage/azurite
    ports:
      - "10000:10000"
      - "10001:10001"
      - "10002:10002"
    volumes:
      - azurite-data:/data
    environment:
      AZURITE_ACCOUNTS: "devstoreaccount1:password"

  learning-api:
    image: python:3.11
    command: bash -c "pip install flask && FLASK_APP=app.py flask run --host=0.0.0.0"
    volumes:
      - ./app.py:/app.py
    ports:
      - "5000:5000"
    working_dir: /

volumes:
  azurite-data:



  #!/bin/bash

# Variables
RESOURCE_GROUP="bonsai-rg-LIGHTTOTHEDARK-24d69b3b-d093-41c6-a847-0c0461e88247"
LOCATION="westus2"
STORAGE_ACCOUNT="lighttothedark"
WORKSPACE="lighttothedark-24d69b3b-d093-41c6-a847-0c0461e88247"
AKS_CLUSTER="Three"
CONTAINER_REGISTRY="lighttothedark"

# Create Resource Group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create Storage Account
az storage account create \
  --name $STORAGE_ACCOUNT \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --sku Standard_LRS

# Create Log Analytics Workspace
az monitor log-analytics workspace create \
  --resource-group $RESOURCE_GROUP \
  --workspace-name $WORKSPACE \
  --location $LOCATION

# Create Container Registry
az acr create \
  --resource-group $RESOURCE_GROUP \
  --name $CONTAINER_REGISTRY \
  --sku Basic \
  --location $LOCATION

# Create AKS Cluster
az aks create \
  --resource-group $RESOURCE_GROUP \
  --name $AKS_CLUSTER \
  --node-count 1 \
  --enable-addons monitoring \
  --workspace-resource-id "/subscriptions/33af1e61-072c-48f1-bd41-b60da094e056/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.OperationalInsights/workspaces/$WORKSPACE" \
  --generate-ssh-keys \
  --location $LOCATION

echo "All resources provisioned. You can now access them from web, mobile, or desktop apps on any OS."
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "workspaceName": { "type": "string", "defaultValue": "LIGHTTOTHEDARK" },
    "location": { "type": "string", "defaultValue": "westus2" },
    "storageSku": { "type": "string", "defaultValue": "Standard_LRS" },
    "aksClusterName": { "type": "string", "defaultValue": "Three" },
    "containerRegistryName": { "type": "string", "defaultValue": "lighttothedark" }
  },
  "resources": [
    {
      "type": "Microsoft.Storage/storageAccounts",
      "apiVersion": "2022-09-01",
      "name": "[parameters('containerRegistryName')]",
      "location": "[parameters('location')]",
      "sku": { "name": "[parameters('storageSku')]" },
      "kind": "StorageV2",
      "properties": {}
    },
    {
      "type": "Microsoft.OperationalInsights/workspaces",
      "apiVersion": "2022-10-01",
      "name": "[concat(parameters('workspaceName'), '-workspace')]",
      "location": "[parameters('location')]",
      "properties": {
        "sku": { "name": "PerGB2018" },
        "retentionInDays": 30
      }
    },
    {
      "type": "Microsoft.ContainerRegistry/registries",
      "apiVersion": "2023-01-01-preview",
      "name": "[parameters('containerRegistryName')]",
      "location": "[parameters('location')]",
      "sku": { "name": "Basic" },
      "properties": {}
    },
    {
      "type": "Microsoft.ContainerService/managedClusters",
      "apiVersion": "2023-05-02-preview",
      "name": "[parameters('aksClusterName')]",
      "location": "[parameters('location')]",
      "identity": { "type": "SystemAssigned" },
      "properties": {
        "dnsPrefix": "[concat(parameters('aksClusterName'), '-dns')]",
        "agentPoolProfiles": [
          {
            "name": "nodepool1",
            "count": 1,
            "vmSize": "Standard_DS2_v2",
            "osType": "Linux",
            "mode": "System"
          }
        ],
        "linuxProfile": {
          "adminUsername": "azureuser",
          "ssh": { "publicKeys": [ { "keyData": "REPLACE_WITH_YOUR_SSH_KEY" } ] }
        },
        "networkProfile": { "networkPlugin": "azure" }
      }
    }
  ],
  "outputs": {
    "storageAccountName": { "type": "string", "value": "[parameters('containerRegistryName')]" },
    "workspaceName": { "type": "string", "value": "[concat(parameters('workspaceName'), '-workspace')]" },
    "aksClusterName": { "type": "string", "value": "[parameters('aksClusterName')]" },
    "containerRegistryName": { "type": "string", "value": "[parameters('containerRegistryName')]" }
  }
}

from flask import Flask
app = Flask(__name__)

@app.route("/")
def hello():
    return "Learning API operational! Access from web, mobile, or desktop."
