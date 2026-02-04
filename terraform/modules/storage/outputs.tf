output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.backups.name
}

output "storage_account_id" {
  description = "Resource ID of storage account"
  value       = azurerm_storage_account.backups.id
}

output "blob_endpoint" {
  description = "Blob service endpoint URL"
  value       = azurerm_storage_account.backups.primary_blob_endpoint
}

output "container_name" {
  description = "Name of the backup container"
  value       = azurerm_storage_container.minecraft_backups.name
}


