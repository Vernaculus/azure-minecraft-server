# Creates an Azure Resource Group to contain all project resources
resource "azurerm_resource_group" "main" {
  # Resource type: azurerm_resource_group
  # Local name: main (used within Terraform to reference this)

  # Actual name in Azure (follows naming convention: rg-project-env-region)
  name = "rg-${var.project_name}-${var.environment}-eus"

  # Azure region from variables.tf
  location = var.location

  # Apply tags from variables.tf to this resource
  tags = var.tags
}

