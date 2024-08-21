$location = "uksouth"
$resourceGroupName = "mate-azure-task-19"

$virtualNetworkName = "todoapp"
$vnetAddressPrefix = "10.20.30.0/24"
$webSubnetName = "webservers"
$webSubnetIpRange = "10.20.30.0/26"
$mngSubnetName = "management"
$mngSubnetIpRange = "10.20.30.128/26"

$sshKeyName = "linuxboxsshkey"
$sshKeyPublicKey = Get-Content "~/.ssh/id_rsa.pub"

$vmImage = "Ubuntu2204"
$vmSize = "Standard_B1s"
$webVmName = "webserver"
$jumpboxVmName = "jumpbox"

$repoUrl = "git@github.com:gaupt/azure_task_19_deploy_web_app.git"

$acrName = "mateacr"  # Make sure the name is globally unique
$acrSku = "Basic"
$appName = "mate-webapp"
$planName = "mate-appservice-plan"

Write-Host "Creating a resource group $resourceGroupName ..."
New-AzResourceGroup -Name $resourceGroupName -Location $location

Write-Host "Creating web network security group..."
$webHttpRule = New-AzNetworkSecurityRuleConfig -Name "web" -Description "Allow HTTP" `
   -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 -SourceAddressPrefix `
   Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 80,443
$webNsg = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Location $location -Name `
   $webSubnetName -SecurityRules $webHttpRule

Write-Host "Creating mngSubnet network security group..."
$mngSshRule = New-AzNetworkSecurityRuleConfig -Name "ssh" -Description "Allow SSH" `
   -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 -SourceAddressPrefix `
   Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 22
$mngNsg = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Location $location -Name `
   $mngSubnetName -SecurityRules $mngSshRule

Write-Host "Creating a virtual network ..."
$webSubnet = New-AzVirtualNetworkSubnetConfig -Name $webSubnetName -AddressPrefix $webSubnetIpRange -NetworkSecurityGroup $webNsg
$mngSubnet = New-AzVirtualNetworkSubnetConfig -Name $mngSubnetName -AddressPrefix $mngSubnetIpRange -NetworkSecurityGroup $mngNsg
$virtualNetwork = New-AzVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $resourceGroupName -Location $location -AddressPrefix $vnetAddressPrefix -Subnet $webSubnet,$mngSubnet

Write-Host "Creating a SSH key resource ..."
New-AzSshKey -Name $sshKeyName -ResourceGroupName $resourceGroupName -PublicKey $sshKeyPublicKey

Write-Host "Creating a web server VM ..."

for (($zone = 1); ($zone -le 2); ($zone++) ) {
   $vmName = "$webVmName-$zone"
   New-AzVm `
   -ResourceGroupName $resourceGroupName `
   -Name $vmName `
   -Location $location `
   -image $vmImage `
   -size $vmSize `
   -SubnetName $webSubnetName `
   -VirtualNetworkName $virtualNetworkName `
   -SshKeyName $sshKeyName 
   $Params = @{
      ResourceGroupName  = $resourceGroupName
      VMName             = $vmName
      Name               = 'CustomScript'
      Publisher          = 'Microsoft.Azure.Extensions'
      ExtensionType      = 'CustomScript'
      TypeHandlerVersion = '2.1'
      Settings          = @{fileUris = @('https://raw.githubusercontent.com/mate-academy/azure_task_18_configure_load_balancing/main/install-app.sh'); commandToExecute = './install-app.sh'}
   }
   Set-AzVMExtension @Params
}

Write-Host "Creating a public IP ..."
$publicIP = New-AzPublicIpAddress -Name $jumpboxVmName -ResourceGroupName $resourceGroupName -Location $location -Sku Basic -AllocationMethod Dynamic -DomainNameLabel $dnsLabel
Write-Host "Creating a management VM ..."
New-AzVm `
-ResourceGroupName $resourceGroupName `
-Name $jumpboxVmName `
-Location $location `
-image $vmImage `
-size $vmSize `
-SubnetName $mngSubnetName `
-VirtualNetworkName $virtualNetworkName `
-SshKeyName $sshKeyName `
-PublicIpAddressName $jumpboxVmName

Write-Host "Deploying Azure Container Registry $acrName ..."
New-AzContainerRegistry -ResourceGroupName $resourceGroupName -Name $acrName -Sku $acrSku -Location $location

#Write-Host "Registering the ContainerRegistry resource provider..."
#Register-AzResourceProvider -ProviderNamespace "Microsoft.ContainerRegistry"

# Clone the repository
git clone $repoUrl
cd ./azure_task_19_deploy_web_app/app  # Navigate to the app directory

# Build the Docker image
docker build -t todoapp:v1 .

$acrLoginServer = "$acrName.azurecr.io"

# Tag the Docker image with the full name
docker tag todoapp:v1 $acrLoginServer/todoapp:v1

# Log in to ACR
az acr login --name $acrName

# Push the Docker image to ACR
docker push $acrLoginServer/todoapp:v1

Write-Host "Creating App Service plan $planName ..."
New-AzAppServicePlan -ResourceGroupName $resourceGroupName -Name $planName -Location $location -Tier Free -NumberOfWorkers 1

Write-Host "Creating Web App $appName ..."
New-AzWebApp -ResourceGroupName $resourceGroupName -Name $appName -Location $location -AppServicePlan $planName -ContainerImageName "$acrLoginServer/todoapp:v1"

# Configure the Web App to use ACR credentials
Write-Host "Configuring Web App $appName to use ACR credentials ..."
$acrCredentials = (az acr credential show --name $acrName --resource-group $resourceGroupName | ConvertFrom-Json)
$acrUsername = $acrCredentials.username
$acrPassword = $acrCredentials.passwords[0].value

az webapp config container set --name $appName --resource-group $resourceGroupName --docker-custom-image-name "$acrLoginServer/todoapp:v1" --docker-registry-server-url "https://$acrLoginServer" --docker-registry-server-user $acrUsername --docker-registry-server-password $acrPassword
