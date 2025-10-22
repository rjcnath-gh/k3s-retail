FROM mcr.microsoft.com/devcontainers/universal:3-linux

# Install Step CLI
# RUN wget https://dl.smallstep.com/gh-release/cli/docs-cli-install/v0.23.4/step-cli_0.23.4_amd64.deb && \
#    sudo dpkg -i step-cli_0.23.4_amd64.deb && \
#    rm ./step-cli_0.23.4_amd64.deb

# Install k9s
# RUN wget https://github.com/derailed/k9s/releases/download/v0.28.0/k9s_Linux_amd64.tar.gz && \
#    tar xf k9s_Linux_amd64.tar.gz --directory=/usr/local/bin k9s && \
#    chmod +x /usr/local/bin/k9s && \
#    rm -rf k9s_Linux_amd64.tar.gz

# Install pinned Azure CLI (reproducible). Update the version as needed.
# ARG AZ_CLI_VERSION=2.78.0-1~focal
# RUN set -euo pipefail \
#    && curl -sL https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add - \
#    && sudo apt-add-repository https://packages.microsoft.com/repos/azure-cli/ \
#    && sudo apt-get update -y \
#    && sudo apt-get install -y --no-install-recommends azure-cli=${AZ_CLI_VERSION}

# curl -L https://aka.ms/InstallAzureCli | bash    
# Install yq
FROM mcr.microsoft.com/devcontainers/universal:3-linux

# Ensure we run as root for package installation (change back if needed)
USER root

# Install wget and certificates for HTTPS downloads
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
 && apt-get install -y --no-install-recommends wget ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# Download and install yq into PATH
RUN wget -q -O /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 \
 && chmod +x /usr/local/bin/yq

# (Optional) switch back to non-root user expected by the base image, e.g.:
USER vscode
