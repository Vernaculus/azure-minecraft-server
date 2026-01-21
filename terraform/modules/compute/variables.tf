# Resource group name where VM will be created
variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

# Azure region for VM
variable "location" {
  description = "Azure region"
  type        = string
}

# VM size SKU
variable "vm_size" {
  description = "Azure VM size"
  type        = string
}

# Admin username for SSH
variable "admin_username" {
  description = "Admin username"
  type        = string
}

# SSH public key for authentication
variable "admin_ssh_key" {
  description = "SSH public key"
  type        = string
}

# Network interface ID to attach
variable "network_interface_id" {
  description = "ID of the network interface"
  type        = string
}

# OS disk size
variable "os_disk_size_gb" {
  description = "OS disk size in GB"
  type        = number
}

# OS disk storage type
variable "os_disk_type" {
  description = "Storage account type for OS disk"
  type        = string
}

# Project name for resource naming
variable "project_name" {
  description = "Project name"
  type        = string
}

# Environment for resource naming
variable "environment" {
  description = "Environment"
  type        = string
}

# Tags to apply
variable "tags" {
  description = "Tags for resources"
  type        = map(string)
}

