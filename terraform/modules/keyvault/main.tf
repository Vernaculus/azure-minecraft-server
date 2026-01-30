# ============================================================================
# AZURE KEY VAULT MODULE
# Purpose: Centralized secrets management for Minecraft server
# Security: RBAC-based access, network isolation, soft-delete protection
# ============================================================================

# Data source to get current Azure client configuration
# Used to retrieve tenant_id and object_id for Key Vault configuration
data "azurerm_client_config" "current" {}

# Azure Key Vault resource
# Stores sensitive secrets like RCON passwords securely with encryption
resource "azurerm_key_vault" "minecraft" {
  # Key Vault names must be globally unique (3-24 chars, alphanumeric + hyphens)
  name = var.key_vault_name

  # Deploy in same region as other resources for lower latency
  location = var.location

  # Place in same resource group for governance/tagging
  resource_group_name = var.resource_group_name

  # Tenant ID from current Azure subscription
  tenant_id = data.azurerm_client_config.current.tenant_id

  # Standard SKU supports secrets, keys, certificates
  # Premium SKU adds HSM-backed keys (not needed for this project)
  sku_name = "standard"

  # IMPORTANT: As of 2026, Azure RBAC is the recommended permission model
  # Setting to true enables Azure RBAC instead of legacy access policies
  # This aligns with AZ-104 best practices for identity and governance
  rbac_authorization_enabled = true

  # Soft-delete: Protects against accidental deletion (7-90 days retention)
  # Required for production workloads per Azure best practices
  soft_delete_retention_days = 7

  # Purge protection: Prevents permanent deletion during retention period
  # Critical for compliance and disaster recovery scenarios
  purge_protection_enabled = true

  # Network ACLs: Restrict access to specific networks/IPs
  # Default action denies all traffic except explicitly allowed sources
  network_acls {
    bypass         = "AzureServices" # Allow Azure-trusted services (Azure CLI, Ansible)
    default_action = "Deny"          # Deny all other traffic by default (zero-trust)

    # Allow access from VM subnet only (least-privilege principle)
    # VM's managed identity can retrieve secrets during Ansible execution
    virtual_network_subnet_ids = [var.subnet_id]

    # Allow access from admin workstation for Terraform/management operations
    # Required for initial secret creation and ongoing secret management
    ip_rules = [var.admin_source_ip]
  }

  # Apply consistent tagging for governance and cost tracking
  tags = var.tags
}

# Grant Terraform executor permission to manage Key Vault secrets
# NOTE: This self-granting pattern enables project reproducibility for demo/learning.
# The user running terraform must have "Owner" or "User Access Administrator" role
# at the resource group or subscription level for this to work.
# Production alternative: Pre-assign "Key Vault Administrator" role to Terraform
# service principal outside of Terraform code (via Azure AD or az cli).
resource "azurerm_role_assignment" "terraform_keyvault_admin" {
  # Scope: Grant access only to this specific Key Vault
  scope = azurerm_key_vault.minecraft.id

  # Built-in role that allows full secret management (create, read, update, delete)
  role_definition_name = "Key Vault Secrets Officer"

  # Principal: Current Azure identity executing Terraform (from az login)
  principal_id = data.azurerm_client_config.current.object_id
}

# Store RCON password as a secret in Key Vault
# Ansible will retrieve this value during minecraft_server role execution
resource "azurerm_key_vault_secret" "rcon_password" {
  # Secret name used by Ansible azure_keyvault_secret lookup plugin
  name = "minecraft-rcon-password"

  # Generated random password value (24 chars, complex)
  value = var.rcon_password

  # Reference to parent Key Vault
  key_vault_id = azurerm_key_vault.minecraft.id

  # Content type helps identify secret purpose in Azure Portal
  content_type = "text/plain"

  # Apply tags for secret lifecycle tracking
  tags = var.tags

  # Wait for RBAC role assignment to propagate before creating secret
  # Azure RBAC can take 5-10 seconds to become effective
  depends_on = [azurerm_role_assignment.terraform_keyvault_admin]
}

