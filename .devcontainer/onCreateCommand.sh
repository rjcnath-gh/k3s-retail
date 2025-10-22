#!/bin/sh

set -o errexit
set -o nounset
set -o pipefail

echo "Starting On Create Command"

# Copy the custom first run notice over
sudo cp .devcontainer/welcome.txt /usr/local/etc/vscode-dev-containers/first-run-notice.txt

# Create k3d cluster and forwarded ports
k3d cluster delete
k3d cluster create \
-p '1883:1883@loadbalancer' \
-p '8883:8883@loadbalancer'

# add extensions
echo "UPDATING to the latest Azure CLI ..."
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

echo "INSTALLING Extensions ..."
az extension add --name customlocation
az extension add --name k8s-extension
az extension add --name connectedk8s


