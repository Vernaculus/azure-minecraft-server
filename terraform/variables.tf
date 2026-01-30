# Defines the Azure region where all resources will be created
variable "location" {
  # Human-readable explanation of this variable
  description = "Azure region for all resources"

  # Data type (string, number, bool, list, map, etc.)
  type = string

  # Default value used if no override provided
  default = "South Central US"
}

# Project name used in resource naming convention
variable "project_name" {
  description = "Project name used in resource naming"
  type        = string
  default     = "minecraft"
}

# Environment name (dev, staging, prod)
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

# Tags applied to all resources for governance
variable "tags" {
  description = "Common tags for all resources"

  # Map type: key-value pairs like { "key" = "value" }
  type = map(string)

  default = {
    env        = "dev"
    app        = "minecraft"
    owner      = "cloud-ops"
    costCenter = "platform-ops"
    managedBy  = "terraform"
  }
}

# Azure VM size SKU
variable "vm_size" {
  description = "Azure VM SKU for the Minecraft server"
  type        = string
  default     = "Standard_D2as_v6" # AMD EPYC v6, available now
}

# SSH public key for VM authentication
variable "admin_ssh_key" {
  description = "SSH public key for VM admin user"
  type        = string

  # No default; must be provided (use sensitive = true for secrets)
  # Will read from command line, env var, or .tfvars file
}

# Azure subscription ID where resources will be created
variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
  # No default for security; must be provided via tfvars or env var
}

# Virtual network address space (CIDR notation)
variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["10.10.0.0/16"]
}

# Subnet address prefix for application tier
variable "subnet_app_prefix" {
  description = "Address prefix for the application subnet"
  type        = list(string)
  default     = ["10.10.1.0/24"]
}

# Your public IP for SSH access (CIDR format: x.x.x.x/32)
variable "admin_source_ip" {
  description = "Public IP address allowed for SSH (CIDR notation)"
  type        = string
  # Must be provided in terraform.tfvars for security
}

# VM admin username for SSH login
variable "admin_username" {
  description = "Administrator username for VM"
  type        = string
  default     = "mcadmin"
}

# OS disk size in GB
variable "os_disk_size_gb" {
  description = "Size of OS disk in GB"
  type        = number
  default     = 30
}

# OS disk storage account type
variable "os_disk_type" {
  description = "Storage account type for OS disk"
  type        = string
  default     = "StandardSSD_LRS"
}

# ADDED: Short location code for naming (scus = South Central US)
variable "location_short" {
  description = "Short code for Azure region (used in resource naming)"
  type        = string
  default     = "scus"
}

