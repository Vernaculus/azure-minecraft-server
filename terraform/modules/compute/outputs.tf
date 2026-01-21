# Outputs the VM ID for reference
output "vm_id" {
  description = "ID of the virtual machine"
  value       = azurerm_linux_virtual_machine.main.id
}

# Outputs the VM name
output "vm_name" {
  description = "Name of the virtual machine"
  value       = azurerm_linux_virtual_machine.main.name
}

# Outputs the private IP address
output "private_ip_address" {
  description = "Private IP address of the VM"
  value       = azurerm_linux_virtual_machine.main.private_ip_address
}

