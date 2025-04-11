<#
.SYNOPSIS
Azure Web App Deployment Script for todoapp
#>

# 1. Налаштування середовища
$resourceGroup = "mate-azure-task-19"
$location = "WestEurope" # Спробуйте змінити регіон на підтримуваний
$acrName = "mateacr123"
$appServicePlan = "mate-appservice-plan"
$webAppName = "mate-todoapp-$(Get-Random -Minimum 100 -Maximum 999)"
$imageTag = "v1"

# 2. Автентифікація в Azure
Connect-AzAccount -TenantId "c71216fc-4300-4d81-b498-00203c0446e0"

# 3. Створення ресурсної групи
if (-not (Get-AzResourceGroup -Name $resourceGroup -ErrorAction SilentlyContinue)) {
    New-AzResourceGroup -Name $resourceGroup -Location $location
}

# 4. Створення ACR (якщо не існує)
if (-not (Get-AzContainerRegistry -ResourceGroupName $resourceGroup | Where-Object { $_.Name -eq $acrName })) {
    New-AzContainerRegistry `
      -ResourceGroupName $resourceGroup `
      -Name $acrName `
      -Sku Basic `
      -EnableAdminUser `
      -Location $location
}

# Отримання ACR credentials
$acrCredentials = Get-AzContainerRegistryCredential -ResourceGroupName $resourceGroup -Name $acrName
$dockerUsername = $acrCredentials.Username
$dockerPassword = $acrCredentials.Password

# Перетворення пароля в SecureString
$secureDockerPassword = ConvertTo-SecureString $dockerPassword -AsPlainText -Force

# Отримання URL реєстру
$acrLoginServer = (Get-AzContainerRegistry -ResourceGroupName $resourceGroup -Name $acrName).LoginServer

# 5. Створення App Service Plan (якщо не існує)
if (-not (Get-AzAppServicePlan -ResourceGroupName $resourceGroup | Where-Object { $_.Name -eq $appServicePlan })) {
    Write-Host "App Service Plan не знайдено. Створюємо новий план..."
    New-AzAppServicePlan `
      -ResourceGroupName $resourceGroup `
      -Name $appServicePlan `
      -Location $location `
      -Tier "Free" `
      -WorkerSize "Small"
}

# 6. Клонування репозиторію та збірка образу
if (-not (Test-Path "./azure_task_19_deploy_web_app")) {
    git clone https://github.com/mate-academy/azure_task_19_deploy_web_app.git
}
cd azure_task_19_deploy_web_app/app

docker build -t todoapp . 

# 7. Тегування та публікація образу
docker tag todoapp "${acrLoginServer}/todoapp:${imageTag}"
$dockerPassword | docker login "${acrLoginServer}" --username $dockerUsername --password-stdin
docker push "${acrLoginServer}/todoapp:${imageTag}"

# 8. Розгортання Web App
New-AzWebApp `
  -ResourceGroupName $resourceGroup `
  -Name $webAppName `
  -AppServicePlan $appServicePlan `
  -Location $location `
  -ContainerImageName "${acrLoginServer}/todoapp:${imageTag}" `
  -ContainerRegistryUrl $acrLoginServer `
  -ContainerRegistryUser $dockerUsername `
  -ContainerRegistryPassword $secureDockerPassword

# 9. Отримання URL додатку
$webApp = Get-AzWebApp -ResourceGroupName $resourceGroup -Name $webAppName
Write-Host "Додаток успішно розгорнуто: https://$($webApp.DefaultHostName)"

# Генерація артефактів
cd ..
./scripts/generate-artifacts.ps1

# Валідація артефактів
./scripts/validate-artifacts.ps1

# Інструкція для очищення (виконати після перевірки)
Write-Host "Для видалення ресурсів виконайте:"
Write-Host "Remove-AzResourceGroup -Name '$resourceGroup' -Force"
