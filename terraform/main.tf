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

# Wait for service endpoint propagation
# Azure service endpoints take 30-90 seconds to fully propagate
# Without this delay, Key Vault network ACLs may fail to recognize subnet
resource "time_sleep" "wait_for_service_endpoint" {
  depends_on = [module.network]

  create_duration = "90s"
}

# Generate secure random password for RCON
# 24 characters with letters, numbers, and symbols
resource "random_password" "rcon" {
  length  = 24
  special = true
  # Exclude ambiguous characters to avoid manual entry errors
  override_special = "!@#$%^&*()-_=+[]{}|;:,.<>?"
}

# Deploy Azure Key Vault module
module "keyvault" {
  source = "./modules/keyvault"

  # Naming follows Azure conventions: kv-{app}-{env}-{region}
  key_vault_name      = "kv-minecraft-${var.environment}-${var.location_short}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name # FIXED: was module.resource_group.name

  # Restrict Key Vault access to VM subnet only
  subnet_id = module.network.subnet_id

  # Store generated RCON password in Key Vault
  rcon_password = random_password.rcon.result

  # Allow admin workstation access to Key Vault
  admin_source_ip = var.admin_source_ip

  # Apply consistent tagging
  tags = var.tags

  # Ensure Key Vault is created after network exists
  depends_on = [module.network]
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

  # Pass Key Vault ID to compute module for RBAC assignment
  key_vault_id = module.keyvault.key_vault_id

  # Ensure VM is created after Key Vault exists
  depends_on = [module.keyvault]
}

# Generate random suffix for globally unique storage account name
# Storage account names must be globally unique across all of Azure
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
  # Results in 6 lowercase alphanumeric characters (e.g., "a7k3m9")
}

# Storage Account for backups
module "storage" {
  source = "./modules/storage"

  storage_account_name             = "stmcbackupdev${random_string.suffix.result}"
  resource_group_name              = azurerm_resource_group.main.name
  location                         = var.location
  vm_subnet_id                     = module.network.subnet_id
  admin_source_ip                  = var.admin_source_ip
  vm_managed_identity_principal_id = module.compute.vm_identity_principal_id

  tags = var.tags
}

# Azure Monitor for alerting and observability
module "monitoring" {
  source = "./modules/monitoring"

  workspace_name      = "law-minecraft-${var.environment}-${var.location_short}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  vm_id               = module.compute.vm_id
  key_vault_id        = module.keyvault.key_vault_id
  admin_email         = var.admin_email

  tags = var.tags

  depends_on = [
    module.compute,
    module.keyvault
  ]
}

