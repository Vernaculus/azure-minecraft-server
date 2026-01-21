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

  # Apply governance tags
  tags = var.tags
}

