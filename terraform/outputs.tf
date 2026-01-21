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

# Outputs the public IP for easy access
output "minecraft_public_ip" {
  description = "Public IP address to connect to Minecraft server"
  value       = module.network.public_ip_address
}

# Outputs the VNet ID
output "vnet_id" {
  description = "Virtual network ID"
  value       = module.network.vnet_id
}

# Outputs the subnet ID
output "subnet_id" {
  description = "Application subnet ID"
  value       = module.network.subnet_id
}

# Outputs the VM name for reference
output "vm_name" {
  description = "Name of the Minecraft server VM"
  value       = module.compute.vm_name
}

# Outputs the VM ID
output "vm_id" {
  description = "VM resource ID"
  value       = module.compute.vm_id
}

# Outputs the private IP
output "vm_private_ip" {
  description = "Private IP address of the VM"
  value       = module.compute.private_ip_address
}

