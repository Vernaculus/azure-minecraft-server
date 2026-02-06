# ============================================================================
# MONITORING MODULE VARIABLES
# ============================================================================

variable "workspace_name" {
  description = "Name of the Log Analytics workspace"
  type        = string

  validation {
    condition     = length(var.workspace_name) >= 4 && length(var.workspace_name) <= 63
    error_message = "Workspace name must be 4-63 characters"
  }
}

variable "location" {
  description = "Azure region for monitoring resources"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "vm_id" {
  description = "Resource ID of the VM to monitor"
  type        = string
}

variable "key_vault_id" {
  description = "Resource ID of the Key Vault to monitor"
  type        = string
}

variable "admin_email" {
  description = "Email address for alert notifications"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.admin_email))
    error_message = "Must be a valid email address"
  }
}

variable "tags" {
  description = "Tags to apply to monitoring resources"
  type        = map(string)
  default     = {}
}

