#!/bin/bash

# This script prompts the user to enter Azure configuration values
# and exports them as environment variables

echo "========================================="
echo "Azure Configuration Setup"
echo "========================================="
echo ""


# Prompt for Subscription ID with default
#read -p "Enter your Azure Subscription ID [default: YOUR_DEFAULT_SUBSCRIPTION_ID]: " SUBSCRIPTION_ID
#SUBSCRIPTION_ID=${SUBSCRIPTION_ID:-YOUR_DEFAULT_SUBSCRIPTION_ID}

# Prompt for Tenant ID with default
#read -p "Enter your Azure Tenant ID [default: YOUR_DEFAULT_TENANT_ID]: " TENANT_ID
#TENANT_ID=${TENANT_ID:-YOUR_DEFAULT_TENANT_ID}

# Prompt for Resource Group with default
#read -p "Enter your Azure Resource Group [default: YOUR_DEFAULT_RESOURCE_GROUP]: " RESOURCE_GROUP
#RESOURCE_GROUP=${RESOURCE_GROUP:-YOUR_DEFAULT_RESOURCE_GROUP}

# Prompt for Location (with default)
#read -p "Enter your Azure Location [default: eastus]: " LOCATION
#LOCATION=${LOCATION:-eastus}

# Save to ~/.azure_env
cat <<EOF > ~/.azure_env
export SUBSCRIPTION_ID='$SUBSCRIPTION_ID'
export TENANT_ID='$TENANT_ID'
export RESOURCE_GROUP='$RESOURCE_GROUP'
export LOCATION='$LOCATION'
EOF

# Source the file for current session
source ~/.azure_env

# Optionally, add to .bashrc for future sessions
if ! grep -q "source ~/.azure_env" ~/.bashrc; then
  echo "source ~/.azure_env" >> ~/.bashrc
fi

echo ""
echo "========================================="
echo "Configuration Summary:"
echo "========================================="
echo "SUBSCRIPTION_ID: $SUBSCRIPTION_ID"
echo "TENANT_ID: $TENANT_ID"
echo "RESOURCE_GROUP: $RESOURCE_GROUP"
echo "LOCATION: $LOCATION"
echo "CLUSTER_NAME: $CLUSTER_NAME"
echo "========================================="
echo ""
