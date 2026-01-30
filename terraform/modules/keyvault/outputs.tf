# ============================================================================
# KEY VAULT MODULE OUTPUTS
# ============================================================================

# Key Vault ID for RBAC role assignments
# Used by compute module to grant VM managed identity access
output "key_vault_id" {
  description = "The resource ID of the Key Vault"
  value       = azurerm_key_vault.minecraft.id
}

# Key Vault URI for Ansible azure_keyvault_secret lookup plugin
# Format: https://{vault-name}.vault.azure.net/
output "key_vault_uri" {
  description = "The URI of the Key Vault (for Ansible secret retrieval)"
  value       = azurerm_key_vault.minecraft.vault_uri
}

# Key Vault name for reference in other modules/scripts
output "key_vault_name" {
  description = "The name of the Key Vault"
  value       = azurerm_key_vault.minecraft.name
}

# RCON secret name for Ansible playbooks
# Ansible will use this name to retrieve the secret value
output "rcon_secret_name" {
  description = "Name of the RCON password secret in Key Vault"
  value       = azurerm_key_vault_secret.rcon_password.name
}

