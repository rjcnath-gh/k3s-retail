# k3s setup with Codespaces

## Reproducible Azure CLI in the devcontainer

This repository's devcontainer pins the Azure CLI to a known-good version and performs a small cleanup on Codespace creation to avoid a common import mismatch between the system's `/opt/az` site-packages and extension-vendored `azure` packages.

- The `Dockerfile` installs `azure-cli` (pinned via `ARG AZ_CLI_VERSION`) so Codespaces built from this image have a reproducible CLI bundle.
- The devcontainer `postCreateCommand` runs `az upgrade --yes` (idempotent) and removes user `pip --user` azure packages that can shadow the CLI installation. This prevents errors like "cannot import name 'get_arm_endpoints' from 'azure.mgmt.core.tools'".

If you need a different CLI version, update `ARG AZ_CLI_VERSION` in the `Dockerfile` and rebuild the Codespace. Note: the Dockerfile now strictly requires the specified package version; the build will fail if the exact `AZ_CLI_VERSION` is not available from the apt repository.
