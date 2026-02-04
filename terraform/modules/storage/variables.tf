variable "storage_account_name" {
  description = "Name of the storage account (must be globally unique, 3-24 chars, lowercase alphanumeric)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    error_message = "Storage account name must be 3-24 characters, lowercase alphanumeric only."
  }
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "vm_subnet_id" {
  description = "Subnet ID where VM resides (for storage firewall)"
  type        = string
}

variable "admin_source_ip" {
  description = "Admin workstation IP for storage firewall"
  type        = string
}

variable "vm_managed_identity_principal_id" {
  description = "Principal ID of VM's managed identity for RBAC"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

