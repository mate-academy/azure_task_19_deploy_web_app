# Deploy a Web App

To improve the sales of your web app, you decided to deploy a free-to-use, publicly available instance. The infrastructure has to be as cheap and simple as possible, and you are not concerned with security and private networking — it's a perfect use case for Azure App Services. 

In this task, you will deploy a web app to Azure App Services (Azure Web App). 

## Prerequisites

Before completing any task in the module, make sure that you followed all the steps described in the **Environment Setup** topic, in particular: 

1. Ensure you have an [Azure](https://azure.microsoft.com/en-us/free/) account and subscription.

2. Create a resource group called *“mate-resources”* in the Azure subscription.

3. In the *“mate-resources”* resource group, create a storage account (any name) and a *“task-artifacts”* container.

4. Install [PowerShell 7](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell?view=powershell-7.4) on your computer. All tasks in this module use PowerShell 7. To run it in the terminal, execute the following command: 
    ```
    pwsh
    ```

5. Install [Azure module for PowerShell 7](https://learn.microsoft.com/en-us/powershell/azure/install-azure-powershell?view=azps-11.3.0): 
    ```
    Install-Module -Name Az -Repository PSGallery -Force
    ```
If you are a Windows user, before running this command, please also run the following: 
    ```
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
    ```

6. Log in to your Azure account using PowerShell:
    ```
    Connect-AzAccount -TenantId <your Microsoft Entra ID tenant id>
    ```

## Requirements

Today you will mostly work in Azure Portal. To complete this task, perform the following steps: 

1. Create a resource group called `mate-azure-task-19`;

2. Follow the [tutorial](https://learn.microsoft.com/en-us/azure/container-registry/container-registry-get-started-portal?tabs=azure-powershell) to deploy [Azure Container Registry](https://learn.microsoft.com/en-us/azure/container-registry/container-registry-intro). Azure Container Registry (or ACR for short) — is an Azure PaaS service for private Docker container registry, which is fully integrated with other Azure products, like App Services. **When deploying the ACR, make sure to use `Basic` SKU**;

3. Clone this repository, build a Docker image for the application in the `/app` folder, and push it to the ACR you deployed in the previous step. The image must be called `todoapp` (so the full image name will look like this: `<acr-name>.azurecr.io/todoapp:v1`).  

4. Follow the [tutorial](https://learn.microsoft.com/en-us/training/modules/deploy-run-container-app-service/5-exercise-deploy-web-app?pivots=csharp) to create a Web App for containers. Use the image you pushed to the ACR in the previous step;

5. Check that the app is working, and enjoy the simplicity of the Azure Web Apps :sunglasses:;

6. Run artifacts generation script `scripts/generate-artifacts.ps1`;

7. Test yourself using the script `scripts/validate-artifacts.ps1`;

8. Make sure that changes `result.json` are committed to the repo, and submit the solution for review; 

9. When the solution is validated, delete the resources you deployed.


## How to Complete Tasks in This Module 

Tasks in this module are relying on 2 PowerShell scripts: 

- `scripts/generate-artifacts.ps1` generates the task “artifacts” and uploads them to cloud storage. An “artifact” is evidence of a task completed by you. Each task will have its own script, which will gather the required artifacts. The script also adds a link to the generated artifact in the `artifacts.json` file in this repository — make sure to commit changes to this file after you run the script. 
- `scripts/validate-artifacts.ps1` validates the artifacts generated by the first script. It loads information about the task artifacts from the `artifacts.json` file.

Here is how to complete tasks in this module:

1. Clone task repository;

2. Make sure you completed the steps described in the Prerequisites section;

3. Complete the task described in the Requirements section;

4. Run `scripts/generate-artifacts.ps1` to generate task artifacts. The script will update the file `artifacts.json` in this repo;

5. Run `scripts/validate-artifacts.ps1` to test yourself. If tests are failing — follow the recommendations from the test script error message to fix or re-deploy your infrastructure. When you are ready to test yourself again — **re-generate the artifacts** (step 4) and re-run tests again; 

6. When all tests will pass — commit your changes and submit the solution for review. 

Pro tip: if you are stuck with any of the implementation steps, run `scripts/generate-artifacts.ps1` and `scripts/validate-artifacts.ps1`. The validation script might give you a hint on what to do.  
