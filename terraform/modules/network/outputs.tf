# Outputs the VNet ID for reference by other modules
output "vnet_id" {
  description = "ID of the virtual network"
  value       = azurerm_virtual_network.main.id
}

# Outputs the subnet ID (needed for VM creation)
output "subnet_id" {
  description = "ID of the application subnet"
  value       = azurerm_subnet.app.id
}

# Outputs the NSG ID for reference
output "nsg_id" {
  description = "ID of the network security group"
  value       = azurerm_network_security_group.app.id
}

# Outputs the public IP address (for connecting to server)
output "public_ip_address" {
  description = "Public IP address of the server"
  value       = azurerm_public_ip.main.ip_address
}

# Outputs the NIC ID (required for VM attachment)
output "nic_id" {
  description = "ID of the network interface"
  value       = azurerm_network_interface.main.id
}

