# Ensure PowerShell 7
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Error "This script requires PowerShell 7. Please run with 'pwsh' command."
    exit 1
}

# Login to Azure
Connect-AzAccount

# Set variables
$resourceGroupName = "mate-azure-task-19"
$location = "eastus"
$acrName = "mateacr$(Get-Random -Maximum 9999)"
$appName = "todoapp$(Get-Random -Maximum 9999)"
$dockerImageName = "todoapp"
$dockerImageTag = "v1"
$appFolderPath = ".\app"  # Assuming app files are in current directory\app

# Verify app folder exists
if (-not (Test-Path -Path $appFolderPath)) {
    throw "App folder not found at $appFolderPath. Please ensure the app files are in the correct location."
}

# Create resource group
Write-Host "Creating resource group..."
New-AzResourceGroup -Name $resourceGroupName -Location $location

# Create Azure Container Registry (Basic SKU)
Write-Host "Creating Azure Container Registry..."
$acr = New-AzContainerRegistry `
    -ResourceGroupName $resourceGroupName `
    -Name $acrName `
    -Sku Basic `
    -EnableAdminUser `
    -Location $location

# Login to ACR
Write-Host "Logging in to ACR..."
$creds = Get-AzContainerRegistryCredential -Registry $acr
docker login "$($acr.Name).azurecr.io" -u $creds.Username -p $creds.Password
if ($LASTEXITCODE -ne 0) {
    throw "Failed to login to ACR"
}

# Build Docker image
Write-Host "Building Docker image..."
Set-Location -Path $appFolderPath
docker build -t "$($acr.Name).azurecr.io/$dockerImageName`:$dockerImageTag" .
if ($LASTEXITCODE -ne 0) {
    throw "Failed to build Docker image"
}

# Push image to ACR
Write-Host "Pushing Docker image to ACR..."
docker push "$($acr.Name).azurecr.io/$dockerImageName`:$dockerImageTag"
if ($LASTEXITCODE -ne 0) {
    throw "Failed to push Docker image to ACR"
}

# Create App Service plan (Free tier)
Write-Host "Creating App Service plan..."
$appServicePlan = New-AzAppServicePlan `
    -ResourceGroupName $resourceGroupName `
    -Name "todoapp-plan" `
    -Location $location `
    -Tier "Free" `
    -WorkerSize "Small"

# Create Web App for Containers
Write-Host "Creating Web App for Containers..."
$webApp = New-AzWebApp `
    -ResourceGroupName $resourceGroupName `
    -Name $appName `
    -Location $location `
    -AppServicePlan $appServicePlan.Name `
    -ContainerImageName "$($acr.Name).azurecr.io/$dockerImageName`:$dockerImageTag"

# Configure ACR credentials
Write-Host "Configuring ACR credentials..."
$appConfig = @{
    DOCKER_REGISTRY_SERVER_URL      = "https://$($acr.Name).azurecr.io"
    DOCKER_REGISTRY_SERVER_USERNAME = $creds.Username
    DOCKER_REGISTRY_SERVER_PASSWORD = $creds.Password
}
Set-AzWebApp -ResourceGroupName $resourceGroupName -Name $webApp.Name -AppSettings $appConfig

Write-Host "Deployment completed successfully!"
Write-Host "Web App URL: https://$($webApp.DefaultHostName)"