
echo 'export CODESPACES="FALSE"' >> ~/.bashrc
echo 'export CLUSTER_NAME=${CODESPACE_NAME%-*}-codespace' >> ~/.bashrc
source ~/.bashrc

# Prompt user for Azure configuration if not already set
# bash .devcontainer/prompt-azure-config.sh


# Source the Azure environment variables for current session
if [ -f ~/.azure_env ]; then
	source ~/.azure_env
	cp ~/.azure_env /tmp/azure_env_vars
fi


# Source ~/.bashrc to ensure all environment variables are available
source ~/.bashrc

#echo "Starting Azure CLI login process..."

# Initiate the interactive login. This will output a device code or open a browser.
# The user must manually complete the login process.
#az login --use-device-code --tenant "$TENANT_ID"

# Check the exit status of the previous command.
# A return value of 0 indicates success.
#if [ $? -eq 0 ]; then
#  echo "Azure login succeeded."
#  echo "Executing the post-login script..."
#  # Run your second script.
#  /bin/bash .devcontainer/postLoginOnboarding.sh
#else
#  echo "Azure login failed. The postLoginOnboarding script will not be executed."
#  exit 1
#fi