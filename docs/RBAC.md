# Role-Based Access Control (RBAC) Architecture

## Overview

This project implements least-privilege access control using Azure Managed Identity and RBAC role assignments. No credentials are stored on the VM or in code.

## RBAC Roles Used

### 1. VM Managed Identity - Storage Blob Data Contributor

Principal: vm-minecraft-dev-scus (System-Assigned Managed Identity)
Scope: Storage Account (stmcbackupdev2o7f0p)
Role: Storage Blob Data Contributor
Justification: VM needs write access to upload backups to Azure Blob Storage

Permissions Granted:
- Read blobs
- Write blobs
- Delete blobs (for manual cleanup if needed)
- List containers

Why This Role:
- Narrower than Storage Account Contributor (no management plane access)
- VM cannot modify storage account settings
- Cannot access other storage accounts
- Follows principle of least privilege

Terraform Implementation:

resource "azurerm_role_assignment" "vm_blob_contributor" {
  scope                = azurerm_storage_account.backups.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_linux_virtual_machine.main.identity[0].principal_id
}

---

### 2. VM Managed Identity - Key Vault Secrets User

Principal: vm-minecraft-dev-scus (System-Assigned Managed Identity)
Scope: Key Vault (kv-minecraft-dev-scus)
Role: Key Vault Secrets User
Justification: VM needs read-only access to retrieve RCON password during Ansible deployment

Permissions Granted:
- Read secret values
- List secrets (metadata only)

Permissions NOT Granted:
- Cannot create/update/delete secrets
- Cannot modify Key Vault settings
- Cannot access keys or certificates

Why This Role:
- Read-only access prevents VM compromise from modifying secrets
- Scoped to specific Key Vault only
- No management plane access

Terraform Implementation:

resource "azurerm_role_assignment" "vm_keyvault_access" {
  scope                = azurerm_key_vault.minecraft.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_linux_virtual_machine.main.identity[0].principal_id
}

---

### 3. Terraform Service Principal - Contributor

Principal: Your Azure CLI identity (interactive login)
Scope: Resource Group (rg-minecraft-dev-scus)
Role: Contributor (implicit via subscription access)
Justification: Terraform needs full resource management within resource group

Permissions Granted:
- Create/read/update/delete all Azure resources
- Assign RBAC roles to resources
- Deploy VMs, networks, storage, Key Vault

Permissions NOT Granted:
- Cannot modify subscription settings
- Cannot create/delete resource groups outside scope
- Cannot modify Azure AD tenant settings

Why This Role:
- Standard role for IaC deployments
- Allows full automation of infrastructure
- Scoped to resource group limits blast radius

---

### 4. Admin User - Key Vault Administrator

Principal: Your user account
Scope: Key Vault (kv-minecraft-dev-scus)
Role: Key Vault Administrator
Justification: Manage secrets manually for initial setup and rotation

Permissions Granted:
- Full control over secrets, keys, certificates
- Modify Key Vault settings
- Assign Key Vault access policies

Why This Role:
- Required for initial RCON password generation
- Allows secret rotation without Terraform re-deployment
- Standard practice for key management

Terraform Implementation:

resource "azurerm_role_assignment" "terraform_keyvault_admin" {
  scope                = azurerm_key_vault.minecraft.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

---

## Security Principles Applied

### 1. Least Privilege
- Each identity has minimum permissions needed
- VM cannot modify infrastructure (no Contributor role)
- VM cannot create/delete secrets (read-only Key Vault access)

### 2. Separation of Duties
- Terraform manages infrastructure
- VM consumes infrastructure (no management access)
- Admin manages secrets separately

### 3. No Credentials in Code
- Managed Identity eliminates credential storage
- No connection strings or passwords in files
- Secrets retrieved at runtime via Azure RBAC

### 4. Scope Limitation
- Roles assigned at resource level (not subscription-wide)
- VM can only access specific storage account
- VM can only access specific Key Vault

### 5. Defense in Depth
- RBAC controls access at Azure control plane
- NSG controls network access
- UFW controls host-level access
- Each layer provides independent security

---

## RBAC Verification Commands

Check VM Managed Identity Role Assignments:

az role assignment list \
  --assignee $(az vm show --name vm-minecraft-dev-scus --resource-group rg-minecraft-dev-scus --query "identity.principalId" -o tsv) \
  --output table

Check Key Vault Access Policies:

az keyvault show --name kv-minecraft-dev-scus --query "properties.accessPolicies" -o table

Test VM Can Access Storage (from VM):

ssh mcadmin@VM_IP "az storage blob list --account-name stmcbackupdev2o7f0p --container-name minecraft-backups --auth-mode login"

---

## Multi-Environment Scaling

For production deployment, consider:

1. Separate Managed Identities per environment
2. Production Key Vault with stricter access policies
3. Network isolation (Private Endpoints for Key Vault/Storage)
4. Azure Policy to enforce RBAC best practices
5. Conditional Access for admin users

---

Last updated: February 5, 2026

