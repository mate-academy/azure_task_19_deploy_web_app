$location = "uksouth"
$resourceGroupName = "mate-azure-task-19"

$virtualNetworkName = "todoapp"
$sshKeyName = "linuxboxsshkey"
$sshKeyPublicKey = Get-Content "~/.ssh/id_rsa.pub"

$vmImage = "Ubuntu2204"
$vmSize = "Standard_B1s"
$webVmName = "webserver"
$jumpboxVmName = "jumpbox"
$webAppName = "task19"
$repoUrl = "git@github.com:gaupt/azure_task_19_deploy_web_app.git"

$acrName = "mateacr"  # Make sure the name is globally unique
$acrSku = "Basic"
$appName = "mate-webapp"
$planName = "mate-appservice-plan"
$registryName = "task-19-todoapp"

Write-Host "Creating a resource group $resourceGroupName ..."
New-AzResourceGroup -Name $resourceGroupName -Location $location

Write-Host "Creating a SSH key resource ..."
New-AzSshKey -Name $sshKeyName -ResourceGroupName $resourceGroupName -PublicKey $sshKeyPublicKey
# Enter to azure connect
Write-Host "Sign in to your Azure subscription..."
Connect-AzAccount

Write-Host "Registering the ContainerRegistry resource provider..."
Register-AzResourceProvider -ProviderNamespace "Microsoft.ContainerRegistry"

Write-Host "Deploying Azure Container Registry $acrName ..."
New-AzContainerRegistry -ResourceGroupName $resourceGroupName -Name $acrName -Sku $acrSku -Location $location

#Connections to registry
#Connect-AzContainerRegistry -Name $acrName

Write-Host "Log in to registry ..."
#Connect-AzContainerRegistry -Name $acrName
az acr login --name $acrName --expose-token

# Clone the repository
cd ./app  # Navigate to the app directory

# Build the Docker image
sudo docker build -t todoapp:v1 .

$acrLoginServer = "$acrName.azurecr.io"

# Tag the Docker image with the full name
sudo docker tag todoapp:v1 $acrLoginServer/todoapp:v1
# connect container registry
#Connect-AzContainerRegistry -Name $acrName
# Log in to ACR
#az acr login --name $acrName

# Push the Docker image to ACR
#sudo docker push $acrLoginServer/todoapp:v1
# Push the Docker image to ACR and wait for it to finish
Start-Process -FilePath "sudo" -ArgumentList "docker push $acrLoginServer/todoapp:v1" -Wait

# Pause the script
Read-Host -Prompt "Press Enter to continue..."

#Write-Host "Creating App Service plan $planName ..."
#New-AzAppServicePlan -ResourceGroupName $resourceGroupName -Name $planName -Location $location -Tier Free -NumberOfWorkers 1 -Linux

#Write-Host "Creating Web App $appName ..."
#New-AzWebApp -ResourceGroupName $resourceGroupName -Name $appName -Location $location -AppServicePlan $planName -ContainerImageName "$acrLoginServer/todoapp:v1"

# Assuming the previous steps were successful, and you have the necessary variables set up:
Write-Host "Creating Web App $appName as a container-based app..."

# Create the App Service Plan (if not already created)
$plan = Get-AzAppServicePlan -ResourceGroupName $resourceGroupName -Name $planName
if (-not $plan) {
    Write-Host "Creating App Service Plan $planName..."
    New-AzAppServicePlan -ResourceGroupName $resourceGroupName -Name $planName -Location $location -Tier Free -NumberOfWorkers 1 -Linux
}

# Create the Web App with container settings
$webApp = New-AzWebApp -ResourceGroupName $resourceGroupName -Name $appName -Location $location -AppServicePlan $planName -ContainerImageName "DOCKER|$acrLoginServer/todoapp:v1"

# Configure the Web App to use ACR credentials
Write-Host "Configuring Web App $appName to use ACR credentials ..."
$acrCredentials = (az acr credential show --name $acrName --resource-group $resourceGroupName --debug | ConvertFrom-Json)
# Configure the Web App to use a Docker container
$containerConfig = New-Object Microsoft.Azure.Commands.WebApps.Models.WebAppContainer
$containerConfig.ContainerRegistryServerUrl = "https://$acrLoginServer"
$containerConfig.ContainerRegistryImageName = "$acrLoginServer/todoapp:v1"

az acr credential show

$acrUsername = $acrCredentials.username
$acrPassword = $acrCredentials.passwords[0].value

# Apply the container settings to the Web App
Set-AzWebApp -ResourceGroupName $resourceGroupName -Name $webAppName -ContainerSettings $containerConfig

az webapp config container set --name $appName --resource-group $resourceGroupName --docker-custom-image-name "$acrLoginServer/todoapp:v1" --docker-registry-server-url "https://$acrLoginServer" --docker-registry-server-user $acrUsername --docker-registry-server-password $acrPassword
