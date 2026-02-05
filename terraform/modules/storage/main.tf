# Azure Storage Account for Minecraft backups
# Uses managed identity for secure, credential-free access

# Storage Account
resource "azurerm_storage_account" "backups" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS" # Locally redundant (cheapest)

  # Security settings
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false

  # Network rules - allow VM subnet + admin workstation
  network_rules {
    default_action             = "Deny"
    bypass                     = ["AzureServices"]
    virtual_network_subnet_ids = [var.vm_subnet_id]
    ip_rules                   = [split("/", var.admin_source_ip)[0]]
  }

  tags = var.tags
}

# Lifecycle Management Policy - Auto-delete backups older than 7 days
resource "azurerm_storage_management_policy" "backup_retention" {
  storage_account_id = azurerm_storage_account.backups.id

  rule {
    name    = "delete-old-minecraft-backups"
    enabled = true

    filters {
      blob_types   = ["blockBlob"]
      prefix_match = ["minecraft-backups/minecraft-world"]
    }

    actions {
      base_blob {
        delete_after_days_since_modification_greater_than = 7
      }
    }
  }
}

# Blob Container for world backups
resource "azurerm_storage_container" "minecraft_backups" {
  name                  = "minecraft-backups"
  storage_account_name  = azurerm_storage_account.backups.name
  container_access_type = "private"
}

# RBAC: Grant VM managed identity permission to upload backups
resource "azurerm_role_assignment" "vm_blob_contributor" {
  scope                = azurerm_storage_account.backups.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.vm_managed_identity_principal_id
}

