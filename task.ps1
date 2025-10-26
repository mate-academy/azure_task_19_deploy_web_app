# Parameters
$ResourceGroupName = "mate-azure-task-19"
$Location = "East US"

# Create Resource Group
Write-Host "Creating Resource Group..."
New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Force

# Create ACR using Azure CLI (більш стабільно)
Write-Host "Creating Azure Container Registry..."
$timestamp = (Get-Date).ToString("yyyyMMddHHmmss")
$acrName = "acr$timestamp"

# Створюємо ACR через Azure CLI
az acr create `
    --resource-group $ResourceGroupName `
    --name $acrName `
    --sku Basic `
    --admin-enabled true `
    --location $Location

Write-Host "ACR created: $acrName"

# Get ACR login server
$acrLoginServer = az acr show --name $acrName --query loginServer --output tsv
Write-Host "ACR Login Server: $acrLoginServer"

# Build container image using ACR Tasks
Write-Host "Building container image using ACR Tasks..."
az acr build `
    --registry $acrName `
    --image todoapp:v1 `
    --file ./app/Dockerfile `
    ./app

Write-Host "Container image built successfully!"

# Create App Service Plan using Azure CLI
Write-Host "Creating App Service Plan..."
$appServicePlanName = "asp$timestamp"

az appservice plan create `
    --name $appServicePlanName `
    --resource-group $ResourceGroupName `
    --location $Location `
    --is-linux `
    --sku B1

Write-Host "App Service Plan created: $appServicePlanName"

# Create Web App using Azure CLI
Write-Host "Creating Web App..."
$webAppName = "webapp$timestamp"

# Спочатку створюємо Web App
az webapp create `
    --name $webAppName `
    --resource-group $ResourceGroupName `
    --plan $appServicePlanName `
    --runtime "PYTHON:3.9"

# Отримуємо credentials ACR
$acrUsername = az acr credential show --name $acrName --query username --output tsv
$acrPassword = az acr credential show --name $acrName --query passwords[0].value --output tsv

# Налаштовуємо контейнер для Web App
az webapp config container set `
    --name $webAppName `
    --resource-group $ResourceGroupName `
    --docker-custom-image-name "$acrLoginServer/todoapp:v1" `
    --docker-registry-server-url "https://$acrLoginServer" `
    --docker-registry-server-user $acrUsername `
    --docker-registry-server-password $acrPassword

Write-Host "Web App created: $webAppName"

# Перевіряємо чи образ існує в ACR
Write-Host "Checking if image exists in ACR..."
$repositoryList = az acr repository list --name $acrName --output tsv
if ($repositoryList -contains "todoapp") {
    Write-Host "✓ Image found in ACR: todoapp"
    $tags = az acr repository show-tags --name $acrName --repository todoapp --output tsv
    Write-Host "✓ Available tags: $tags"
} else {
    Write-Host "✗ Image not found in ACR"
}

Write-Host "`n=== DEPLOYMENT SUMMARY ==="
Write-Host "✓ Resource Group: $ResourceGroupName"
Write-Host "✓ ACR: $acrLoginServer"
Write-Host "✓ Container Image: $acrLoginServer/todoapp:v1"
Write-Host "✓ App Service Plan: $appServicePlanName"
Write-Host "✓ Web App: $webAppName"
Write-Host "✓ Web App URL: https://$webAppName.azurewebsites.net"

# Перевіряємо статус Web App
Write-Host "`nChecking Web App status..."
Start-Sleep -Seconds 30

$webAppStatus = az webapp show --name $webAppName --resource-group $ResourceGroupName --query state --output tsv
Write-Host "✓ Web App State: $webAppStatus"

Write-Host "`nDeployment completed! The container might take a few minutes to start."
Write-Host "Visit: https://$webAppName.azurewebsites.net"