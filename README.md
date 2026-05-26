# Azure Containerized Web App Deployment

## 📖 Project Overview
Implemented a cost-effective PaaS (Platform as a Service) infrastructure on Microsoft Azure to host a publicly available web application. This project demonstrates the core ability to containerize an application using Docker, securely store the images, and deploy them utilizing Azure's managed services. The infrastructure configuration and deployment were validated using custom PowerShell testing scripts.

## 🛠 Architecture & Tech Stack
* **Cloud Provider:** Microsoft Azure
* **Compute & Hosting:** Azure App Services (Web App for Containers)
* **Container Registry:** Azure Container Registry (ACR)
* **Containerization:** Docker
* **Scripting & Automation:** PowerShell, Azure PowerShell module (Az)

## ⚙️ Implementation Details
The deployment process involved the following key engineering steps:
1. **Resource Isolation:** Provisioned a dedicated Azure Resource Group (`mate-azure-task-19`) to logically group and manage the infrastructure components.
2. **Private Container Registry:** Deployed and configured an Azure Container Registry (Basic SKU) for secure, private storage of the application's Docker images.
3. **Dockerization:** Built a Docker image (`todoapp:v1`) for the target web application locally and successfully authenticated and pushed it to the provisioned ACR.
4. **PaaS Deployment:** Configured an Azure Web App for Containers, integrating it with the ACR to pull the target image and serve the application publicly over the internet.
5. **Cost Optimization:** Followed best practices for cloud cost management by ensuring resources are tracked and can be easily decommissioned post-validation.

## 🧪 Validation & Quality Assurance
Infrastructure integrity and deployment success were strictly validated using custom PowerShell testing scripts. 
* Artifact generation (`generate-artifacts.ps1`) was used to collect data about the deployed cloud resources.
* Validation scripts (`validate-artifacts.ps1`) analyzed the artifacts to ensure all Azure services were provisioned correctly and matching the architectural requirements.

## 📝 Code Review & Approval
This implementation has successfully passed a rigorous code review process. The review focused on correct service configuration, adherence to requirements, and proper container deployment practices.

You can view the full discussion, mentor feedback, and final approval in the **[Pull Request #20](https://github.com/mate-academy/azure_task_19_deploy_web_app/pull/20)**.
