#!/bin/sh

source ~/.bashrc

set -o errexit
set -o nounset
set -o pipefail

echo "Setting up environment ..."

echo "Display subscription details "
az account show 

# Create the resource group
echo "Creating resource group '$RESOURCE_GROUP' in '$LOCATION'"
az group create --name $RESOURCE_GROUP --location $LOCATION --output table

# Check for the creation success and print a confirmation
if [ $? -eq 0 ]; then
  echo "Successfully created resource group '$RESOURCE_GROUP'."
else
  echo "Failed to create resource group '$RESOURCE_GROUP'."
fi

echo "Create a connected cluster ..."
az connectedk8s connect --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --location $LOCATION

echo "Enable features on connected cluster ..."
az connectedk8s enable-features --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --features cluster-connect custom-locations   

echo "Install extension - AIO CertMgr"
az k8s-extension create --resource-group $RESOURCE_GROUP --cluster-name $CLUSTER_NAME --name "aio-certmgr" --cluster-type connectedClusters --extension-type microsoft.iotoperations.platform --scope cluster --release-namespace cert-manager

echo "Install extension - workloadorchestration"
az k8s-extension create --resource-group $RESOURCE_GROUP --cluster-name $CLUSTER_NAME --cluster-type connectedClusters --name "workloadorchestration" --extension-type Microsoft.workloadorchestration --scope cluster --release-train stable --version 2.1.11 --auto-upgrade false --config redis.persistentVolume.storageClass=local-path --config redis.persistentVolume.size=20Gi

clusterId=$(az connectedk8s show --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --query id --output tsv)
extensionId=$(az k8s-extension show --resource-group $RESOURCE_GROUP --cluster-name $CLUSTER_NAME  --name "workloadorchestration" --cluster-type connectedClusters --query id --output tsv)
spoid=$(az ad sp show --id bc313c14-388c-4e7d-a58e-70017303ee3b --query id -o tsv)

echo $clusterId 
echo $extensionId
echo $spoid

az connectedk8s enable-features --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --custom-locations-oid $spoid --features cluster-connect custom-locations

echo "Enable customlocation on connected cluster"
az customlocation create --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --namespace default --host-resource-id $clusterId --cluster-extension-ids $extensionId --location $LOCATION --subscription $SUBSCRIPTION_ID

echo "Display customLocationId ..."
custLocId=$(az customlocation show --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --query id -o tsv)
echo $custLocId

echo "Cluster ready for WORKLOADORCHESTRATION usage"

# Solutioning
echo "WORKLOADORCHESTRATION setup for a sample application"

# Install location extension
az extension add --name workload-orchestration -y

echo "Setup context, site, references and targets"

# Create context
echo "create context ..."
az workload-orchestration context create --resource-group $RESOURCE_GROUP --location $LOCATION --context-name $RESOURCE_GROUP-context --capabilities '[{"name":"grocery","description":"grocery"},{"name":"apparel","description":"apparel"},{"name":"home","description":"home"},{"name":"petrol","description":"petrol"}]' --hierarchies '[{"name":"corporate","description":"corporate"},{"name":"local","description":"local"}]' 

# Create Site and link to context
echo "create site ..."
az rest   --method put   --url "https://management.azure.com/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Edge/sites/$RESOURCE_GROUP-site?api-version=2025-03-01-preview"   --body '{"properties":{"displayName":"Retail","description":"Retail Stores","labels":{"level":"corporate"}}}' --resource "https://management.azure.com"

echo "link site with context ..."
az workload-orchestration context site-reference create --subscription $SUBSCRIPTION_ID --resource-group $RESOURCE_GROUP --context-name $RESOURCE_GROUP-context --name $RESOURCE_GROUP-siteref --site-id "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Edge/sites/$RESOURCE_GROUP-site"

# Create targets
echo "create targets ..."

# update customlocation.json
custLocId=$(az customlocation show --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --query id -o tsv)
yq -i ".name = \"$custLocId\"" workloadorchestration/targets/customlocation.json

# create targets
az workload-orchestration target create   --resource-group "$RESOURCE_GROUP"   --location "$LOCATION"   --name "${RESOURCE_GROUP}-corporate"   --display-name "${RESOURCE_GROUP}-corporate"   --hierarchy-level "corporate"   --capabilities '["grocery","home","apparel","petrol"]'   --description "all capabilities"   --solution-scope "retailapp"   --target-specification @workloadorchestration/targets/targetspecs.json   --extended-location @workloadorchestration/targets/customlocation.json   --context-id "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Edge/contexts/$RESOURCE_GROUP-context"
az workload-orchestration target create   --resource-group "$RESOURCE_GROUP"   --location "$LOCATION"   --name "${RESOURCE_GROUP}-localstore-1"   --display-name "${RESOURCE_GROUP}-localstore-1"   --hierarchy-level "local"   --capabilities '["grocery","home"]'   --description "grocery and home store"   --solution-scope "retailapp"   --target-specification @workloadorchestration/targets/targetspecs.json   --extended-location @workloadorchestration/targets/customlocation.json   --context-id "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Edge/contexts/$RESOURCE_GROUP-context"
az workload-orchestration target create   --resource-group "$RESOURCE_GROUP"   --location "$LOCATION"   --name "${RESOURCE_GROUP}-localstore-2"   --display-name "${RESOURCE_GROUP}-localstore-2"   --hierarchy-level "local"   --capabilities '["apparel"]'   --description "apparel store"   --solution-scope "retailapp"   --target-specification @workloadorchestration/targets/targetspecs.json   --extended-location @workloadorchestration/targets/customlocation.json   --context-id "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Edge/contexts/$RESOURCE_GROUP-context"

# create solutions
echo "create solutions ..."
# Create schema 
echo "create solution schema ..."
az workload-orchestration schema create --resource-group $RESOURCE_GROUP --schema-file workloadorchestration/solution/retail-app-schema.yaml --schema-name retail-app-schema --version 1.0.0

echo "create solution template ..."
az workload-orchestration solution-template create --resource-group $RESOURCE_GROUP --location $LOCATION --config-template-file workloadorchestration/solution/retail-app-template.yaml --solution-template-name retail-app-solution-gh --version 1.0.0 --capabilities '["grocery","home"]' --specification @workloadorchestration/solution/app-specs.json --enable-external-validation false --description "retail app solution - grocery and home"
az workload-orchestration solution-template create --resource-group $RESOURCE_GROUP --location $LOCATION --config-template-file workloadorchestration/solution/retail-app-template.yaml --solution-template-name retail-app-solution-a --version 1.0.0 --capabilities '["apparel"]' --specification @workloadorchestration/solution/app-specs.json --enable-external-validation false --description "retail app solution - apparel"
az workload-orchestration solution-template create --resource-group $RESOURCE_GROUP --location $LOCATION --config-template-file workloadorchestration/solution/retail-app-template.yaml --solution-template-name retail-app-solution-p --version 1.0.0 --capabilities '["petrol"]' --specification @workloadorchestration/solution/app-specs.json --enable-external-validation false --description "retail app solution - petrol"



