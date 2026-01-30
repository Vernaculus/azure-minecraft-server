# Azure Key Vault Integration

## Overview

This project uses Azure Key Vault for centralized secrets management, replacing hardcoded credentials with secure, encrypted storage. The Key Vault stores the Minecraft RCON password and is accessed by both Terraform (for deployment) and the VM's managed identity (for runtime operations).

## Architecture

### Key Components

- Key Vault: kv-minecraft-dev-scus
- Vault URI: https://kv-minecraft-dev-scus.vault.azure.net/
- Secrets Stored:
  - minecraft-rcon-password: 24-character random password for Minecraft RCON

### Authentication Flow

    Terraform Deployment --> Azure AD Authentication (az login)
                         |
                         v
                   Azure Key Vault
                  (RBAC Authorization)
                         ^
                         |
    VM Managed Identity -+ (via IMDS 169.254.169.254)

## Security Model

### RBAC Role Assignments

| Identity | Azure AD Principal | Role | Permissions | Justification |
|----------|-------------------|------|-------------|---------------|
| Terraform Executor | 3f1859ad-8d45-... | Key Vault Secrets Officer | Create, Read, Update, Delete secrets | Infrastructure deployment and management |
| VM Managed Identity | 25b0c8bd-4dcc-... | Key Vault Secrets User | Read secrets only | Application runtime access (least-privilege) |

### Network Security

Firewall Configuration:
- Default Action: Deny (zero-trust model)
- Allowed Sources:
  - VM subnet: 10.10.1.0/24 (via service endpoint)
  - Admin workstation: 40.136.232.48/32 (Terraform deployment)
- Bypass: Azure trusted services (Azure CLI, Azure Portal)

Service Endpoint:
- Subnet snet-minecraft-app has Microsoft.KeyVault service endpoint enabled
- Traffic flows through Azure backbone (not public internet)

### Data Protection

- Encryption at Rest: Azure-managed keys (transparent to application)
- Encryption in Transit: TLS 1.2+ enforced
- Soft Delete: 7-day retention period (protection against accidental deletion)
- Purge Protection: Enabled (prevents permanent deletion during retention)

## Access Patterns

### 1. Terraform Deployment

Authentication: Uses Azure CLI identity (az login)

Example - Secret Creation:

    resource "azurerm_key_vault_secret" "rcon_password" {
      name         = "minecraft-rcon-password"
      value        = random_password.rcon.result
      key_vault_id = azurerm_key_vault.minecraft.id
      content_type = "text/plain"
    }

Permissions Required:
- Microsoft.KeyVault/vaults/secrets/write
- Microsoft.KeyVault/vaults/secrets/read

### 2. Ansible Playbook (VM Managed Identity)

Authentication: VM's system-assigned managed identity via IMDS (Instance Metadata Service)

The Ansible playbook retrieves secrets using a three-step REST API workflow:

#### Step 1: Request OAuth Token from IMDS

    - name: Get OAuth token from Azure IMDS for Key Vault authentication
      ansible.builtin.uri:
        url: "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fvault.azure.net"
        method: GET
        headers:
          Metadata: "true"
        return_content: true
        status_code: 200
      register: imds_token_response
      tags:
        - keyvault
        - secrets

#### Step 2: Extract Access Token

    - name: Set Key Vault access token from IMDS response
      ansible.builtin.set_fact:
        keyvault_access_token: "{{ imds_token_response.json.access_token }}"
      no_log: true
      tags:
        - keyvault
        - secrets

#### Step 3: Retrieve Secret from Key Vault

    - name: Retrieve RCON password from Azure Key Vault
      ansible.builtin.uri:
        url: "https://kv-minecraft-dev-scus.vault.azure.net/secrets/minecraft-rcon-password?api-version=7.4"
        method: GET
        headers:
          Authorization: "Bearer {{ keyvault_access_token }}"
        return_content: true
        status_code: 200
      register: keyvault_secret_response
      no_log: true
      tags:
        - keyvault
        - secrets

#### Step 4: Extract Secret Value and Deploy

    - name: Set RCON password fact from Key Vault secret
      ansible.builtin.set_fact:
        minecraft_rcon_password: "{{ keyvault_secret_response.json.value }}"
      no_log: true
      tags:
        - keyvault
        - secrets

**Why REST API Instead of azure.azcollection Module?**

- IMDS endpoint (169.254.169.254) is only accessible from inside the VM
- The azure.azcollection modules run on the Ansible control node (workstation)
- REST API approach ensures authentication happens on the VM using managed identity
- No Azure SDK required on the control node (simpler dependency management)

Permissions Required:
- Microsoft.KeyVault/vaults/secrets/getSecret/action (Key Vault Secrets User role)

### 3. Manual Azure CLI Access

For administrators with appropriate RBAC roles:

    az keyvault secret show --vault-name kv-minecraft-dev-scus --name minecraft-rcon-password --query value -o tsv

    az keyvault secret list --vault-name kv-minecraft-dev-scus --query "[].name" -o table

## Implementation Details

### Terraform Configuration

Module Structure:

    terraform/modules/keyvault/
    ├── main.tf         # Key Vault resource, RBAC assignments, secrets
    ├── variables.tf    # Input variables (vault name, location, subnet ID, etc.)
    └── outputs.tf      # Vault URI, secret names for downstream consumption

Key Configuration Attributes:

    resource "azurerm_key_vault" "minecraft" {
      sku_name                   = "standard"
      rbac_authorization_enabled = true
      soft_delete_retention_days = 7
      purge_protection_enabled   = true
      
      network_acls {
        default_action             = "Deny"
        bypass                     = "AzureServices"
        virtual_network_subnet_ids = [var.subnet_id]
        ip_rules                   = [var.admin_source_ip]
      }
    }

### Random Password Generation

Terraform Resource:

    resource "random_password" "rcon" {
      length           = 24
      special          = true
      override_special = "!@#$%^&*()-_=+[]{}|;:,.<>?"
    }

Characteristics:
- Length: 24 characters
- Character set: Uppercase, lowercase, numbers, special characters
- Cryptographically secure random generation
- Terraform state stores hash only (not plaintext)

## Prerequisites

### Azure Permissions

The identity executing Terraform must have:

1. Contributor role at Resource Group level (minimum)
   - Required for: Creating Key Vault, assigning RBAC roles

2. User Access Administrator or Owner role (for RBAC assignments)
   - Required for: Granting VM managed identity access to Key Vault

Most Azure subscriptions grant these by default. Verify with:

    az role assignment list --assignee $(az ad signed-in-user show --query id -o tsv) --output table

### Ansible Dependencies

Install Azure collection for Key Vault lookups:

    ansible-galaxy collection install azure.azcollection
    pip3 install azure-identity azure-keyvault-secrets

## Troubleshooting

### Error: "ForbiddenByFirewall"

Symptom: Client address is not authorized and caller is not a trusted service

Cause: Your IP is not in Key Vault's ip_rules allowlist

Solution:
1. Add your IP to terraform/modules/keyvault/main.tf
2. Run terraform apply

### Error: "Forbidden - Caller is not authorized"

Symptom: Caller is not authorized to perform action on resource

Cause: Missing RBAC role assignment

Solution: Grant yourself admin access (temporary)

    az role assignment create --role "Key Vault Administrator" --assignee $(az ad signed-in-user show --query id -o tsv) --scope /subscriptions/{sub-id}/resourceGroups/rg-minecraft-dev-scus/providers/Microsoft.KeyVault/vaults/kv-minecraft-dev-scus

### Error: "SubnetsHaveNoServiceEndpointsConfigured"

Symptom: Subnets do not have ServiceEndpoints for Microsoft.KeyVault configured

Cause: Subnet missing Key Vault service endpoint

Solution: Ensure terraform/modules/network/main.tf includes service_endpoints = ["Microsoft.KeyVault"]

### Ansible Lookup Fails on VM

Symptom: Error retrieving secret from Key Vault: Authentication failed

Cause: VM managed identity not granted Key Vault access

Verification: On VM, test managed identity authentication

    curl 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fvault.azure.net' -H Metadata:true

Solution: Verify RBAC assignment exists in Azure Portal or via CLI

## Best Practices

### Secret Rotation

Recommendation: Rotate RCON password every 90 days

Process:
1. Generate new password in Terraform: terraform taint random_password.rcon && terraform apply
2. Ansible automatically retrieves new password on next run
3. Restart Minecraft service to apply new password

### Audit Logging

Enable Key Vault diagnostic logs (future enhancement):

    az monitor diagnostic-settings create --name keyvault-audit --resource /subscriptions/{sub-id}/resourceGroups/rg-minecraft-dev-scus/providers/Microsoft.KeyVault/vaults/kv-minecraft-dev-scus --logs '[{"category": "AuditEvent", "enabled": true}]' --workspace {log-analytics-workspace-id}

Tracks:
- Who accessed which secrets
- When secrets were accessed
- Failed authentication attempts

### Production Considerations

For production deployments, consider:

1. Separate Key Vaults per environment (dev/staging/prod)
2. Private endpoints instead of public access with firewall
3. Customer-managed keys (CMK) for encryption at rest
4. Azure Policy to enforce Key Vault standards
5. Service principal for Terraform (not personal identity)

## References

- Azure Key Vault Documentation: https://learn.microsoft.com/en-us/azure/key-vault/
- Managed Identities for Azure Resources: https://learn.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/
- Azure RBAC for Key Vault: https://learn.microsoft.com/en-us/azure/key-vault/general/rbac-guide
- Ansible Azure Collection: https://docs.ansible.com/ansible/latest/collections/azure/azcollection/index.html

## Related Documentation

- Architecture Overview (architecture.md)
- Security Hardening (security-hardening.md)
- Deployment Guide (deployment-guide.md)

