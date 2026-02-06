# Creates the Linux virtual machine for Minecraft server
resource "azurerm_linux_virtual_machine" "main" {
  # VM name follows naming convention
  name = "vm-${var.project_name}-${var.environment}-scus"

  # Resource group where VM will be created
  resource_group_name = var.resource_group_name

  # Azure region
  location = var.location

  # VM size determines vCPU and RAM (B1ms = 1 core, 2GB)
  size = var.vm_size

  # Admin username for SSH login
  admin_username = var.admin_username

  # Disable password authentication for security (SSH keys only)
  disable_password_authentication = true

  # Network interface to attach (from network module)
  network_interface_ids = [var.network_interface_id]

  # SSH public key configuration
  admin_ssh_key {
    # Username must match admin_username
    username = var.admin_username

    # SSH public key from variables (e.g., ssh-ed25519 AAA...)
    public_key = var.admin_ssh_key
  }

  # OS disk configuration
  os_disk {
    # Disk name follows convention
    name = "osdisk-${var.project_name}-${var.environment}-scus"

    # Caching improves read performance
    caching = "ReadWrite"

    # Storage type (StandardSSD_LRS = standard SSD with local redundancy)
    storage_account_type = var.os_disk_type

    # Disk size in GB
    disk_size_gb = var.os_disk_size_gb
  }

  # Source image defines the operating system
  source_image_reference {
    # Publisher of the image
    publisher = "Canonical"

    # Image offer (Ubuntu Server)
    offer = "0001-com-ubuntu-server-jammy"

    # SKU specifies Ubuntu version (22.04 LTS)
    sku = "22_04-lts-gen2"

    # Use latest patch version available
    version = "latest"
  }

  # ADDED: Enable system-assigned managed identity
  # This creates an Azure AD identity for the VM automatically
  # No credentials to manage - Azure handles authentication via metadata endpoint
  # VM can use this identity to authenticate to Key Vault and retrieve secrets
  identity {
    type = "SystemAssigned"
  }

  # Apply governance tags
  tags = var.tags
}

# ============================================================================
# RBAC: Grant VM Managed Identity Access to Key Vault
# ============================================================================

# Grant VM's managed identity "Key Vault Secrets User" role
# This allows the VM to READ secrets but NOT modify/delete them (least-privilege)
# VM uses Azure Instance Metadata Service (IMDS) to authenticate to Key Vault
resource "azurerm_role_assignment" "vm_keyvault_access" {
  # Scope: Grant access only to this specific Key Vault (not subscription-wide)
  scope = var.key_vault_id

  # Built-in Azure role for reading secrets (no write/delete permissions)
  # Role ID: 4633458b-17de-408a-b874-0445c86b69e6
  role_definition_name = "Key Vault Secrets User"

  # Principal: VM's system-assigned managed identity
  # Azure automatically populates this after VM creation
  principal_id = azurerm_linux_virtual_machine.main.identity[0].principal_id
}

# ============================================================================
# AZURE MONITOR AGENT EXTENSION
# ============================================================================
# Installs Azure Monitor Agent on the VM for metrics and log collection
# Uses VM's managed identity for authentication (no credentials needed)
# Data collection configured by Data Collection Rule (in monitoring module)

resource "azurerm_virtual_machine_extension" "azure_monitor_agent" {
  name                       = "AzureMonitorLinuxAgent"
  virtual_machine_id         = azurerm_linux_virtual_machine.main.id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorLinuxAgent"
  type_handler_version       = "1.28"
  auto_upgrade_minor_version = true

  # Settings for the extension
  # Authentication via managed identity (no credentials needed)
  settings = jsonencode({
    workspaceId = "placeholder" # Not needed with DCR-based collection
  })

  tags = var.tags

  # Ensure VM and its managed identity are fully created first
  depends_on = [
    azurerm_linux_virtual_machine.main,
    azurerm_role_assignment.vm_keyvault_access
  ]
}

