# Outputs the resource group name after creation
output "resource_group_name" {
  # Human-readable description shown in CLI
  description = "The name of the resource group"

  # Value to output (references the RG resource from main.tf)
  value = azurerm_resource_group.main.name
}

# Outputs the resource group ID (full Azure resource path)
output "resource_group_id" {
  description = "The ID of the resource group"

  # Azure resource ID (looks like: /subscriptions/xxx/resourceGroups/xxx)
  value = azurerm_resource_group.main.id
}

# Outputs the location for reference
output "location" {
  description = "The Azure region"
  value       = azurerm_resource_group.main.location
}

