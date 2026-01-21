# Creates an Azure Resource Group to contain all project resources
resource "azurerm_resource_group" "main" {
  # Resource type: azurerm_resource_group
  # Local name: main (used within Terraform to reference this)

  # Actual name in Azure (follows naming convention: rg-project-env-region)
  name = "rg-${var.project_name}-${var.environment}-scus"

  # Azure region from variables.tf
  location = var.location

  # Apply tags from variables.tf to this resource
  tags = var.tags
}

# Calls the network module to create VNet, NSG, public IP, and NIC
module "network" {
  # Path to the network module directory
  source = "./modules/network"

  # Pass variables from root to module
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  vnet_address_space  = var.vnet_address_space
  subnet_app_prefix   = var.subnet_app_prefix
  admin_source_ip     = var.admin_source_ip
  project_name        = var.project_name
  environment         = var.environment
  tags                = var.tags
}

# Calls the compute module to create the VM
module "compute" {
  # Path to the compute module directory
  source = "./modules/compute"

  # Pass variables from root to module
  resource_group_name  = azurerm_resource_group.main.name
  location             = azurerm_resource_group.main.location
  vm_size              = var.vm_size
  admin_username       = var.admin_username
  admin_ssh_key        = var.admin_ssh_key
  network_interface_id = module.network.nic_id
  os_disk_size_gb      = var.os_disk_size_gb
  os_disk_type         = var.os_disk_type
  project_name         = var.project_name
  environment          = var.environment
  tags                 = var.tags
}
