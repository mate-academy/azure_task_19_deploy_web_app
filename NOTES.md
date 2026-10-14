### Note for Mentor — Azure Task 19

The application was successfully deployed to **Azure App Service** using a Docker image stored in **Azure Container Registry (Basic SKU)**. The application is publicly accessible and working correctly.

However, the `validate-artifacts.ps1` script fails when checking the Web App type.

**Reason:** I followed the latest Microsoft documentation and deployed the application using the newer **Azure App Service Site Containers** model instead of the classic Docker configuration.

The exported ARM template contains:
- `kind: app,linux`
- `linuxFxVersion: sitecontainers`

The validation script expects:
- `kind` to contain `container`
- `linuxFxVersion` to contain the ACR Docker image reference

Both deployment approaches use containers, but the validation script only supports the classic configuration.

**The infrastructure is deployed and functioning as required.** The validation failure is caused by a compatibility difference between the newer Azure deployment model and the existing validation script.

I would appreciate a manual review of the deployment.