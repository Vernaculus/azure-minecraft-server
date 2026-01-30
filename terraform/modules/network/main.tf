# Creates the virtual network (VNet) for all resources
resource "azurerm_virtual_network" "main" {
  # Name follows convention: vnet-project-env-region
  name = "vnet-${var.project_name}-${var.environment}-scus"

  # Address space defines the IP range available
  address_space = var.vnet_address_space

  # Location inherits from resource group
  location = var.location

  # Parent resource group
  resource_group_name = var.resource_group_name

  # Apply governance tags
  tags = var.tags
}

# Creates a subnet within the VNet for application tier
resource "azurerm_subnet" "app" {
  # Name identifies the subnet purpose
  name = "snet-${var.project_name}-app"

  # Parent resource group
  resource_group_name = var.resource_group_name

  # Parent virtual network
  virtual_network_name = azurerm_virtual_network.main.name

  # Subnet IP range (subset of VNet address space)
  address_prefixes = var.subnet_app_prefix

  # Allows subnet resources to securely access Key Vault via Azure backbone
  service_endpoints = ["Microsoft.KeyVault"]
}

# Creates Network Security Group (NSG) for subnet-level firewall
resource "azurerm_network_security_group" "app" {
  # Name follows convention
  name                = "nsg-${var.project_name}-app"
  location            = var.location
  resource_group_name = var.resource_group_name

  # Security rule: Allow SSH only from admin IP
  security_rule {
    # Rule name describes purpose
    name = "Allow-SSH-From-Admin"

    # Priority determines rule order (100-4096, lower = higher priority)
    priority = 100

    # Direction: Inbound or Outbound
    direction = "Inbound"

    # Access: Allow or Deny
    access = "Allow"

    # Protocol: Tcp, Udp, Icmp, or * (all)
    protocol = "Tcp"

    # Source port (client port, usually random, so *)
    source_port_range = "*"

    # Destination port (SSH server listens on 22)
    destination_port_range = "22"

    # Source IP (your public IP from variables)
    source_address_prefix = var.admin_source_ip

    # Destination (any VM in this NSG)
    destination_address_prefix = "*"
  }

  # Security rule: Allow Minecraft traffic from internet
  security_rule {
    name              = "Allow-Minecraft-25565"
    priority          = 110
    direction         = "Inbound"
    access            = "Allow"
    protocol          = "Tcp"
    source_port_range = "*"

    # Minecraft Java Edition default port
    destination_port_range = "25565"

    # Internet = any public IP address
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  # Security rule: Deny all other inbound traffic (explicit deny)
  security_rule {
    name = "Deny-All-Inbound"

    # Low priority = evaluated last (after allow rules)
    priority  = 4000
    direction = "Inbound"
    access    = "Deny"

    # Deny all protocols
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = var.tags
}

# Associates the NSG with the subnet (applies rules to all VMs in subnet)
resource "azurerm_subnet_network_security_group_association" "app" {
  # Reference to the subnet
  subnet_id = azurerm_subnet.app.id

  # Reference to the NSG
  network_security_group_id = azurerm_network_security_group.app.id
}

# Creates a static public IP address
resource "azurerm_public_ip" "main" {
  name                = "pip-${var.project_name}-${var.environment}-scus"
  location            = var.location
  resource_group_name = var.resource_group_name

  # Static = IP doesn't change when VM stops (required for consistent server address)
  allocation_method = "Static"

  # SKU Standard required for availability zones and other features
  sku = "Standard"

  tags = var.tags
}

# Creates a network interface card (NIC) to attach to VM
resource "azurerm_network_interface" "main" {
  name                = "nic-${var.project_name}-${var.environment}-scus"
  location            = var.location
  resource_group_name = var.resource_group_name

  # IP configuration binds the NIC to subnet and public IP
  ip_configuration {
    # Configuration name (arbitrary)
    name = "ipconfig1"

    # Which subnet this NIC connects to
    subnet_id = azurerm_subnet.app.id

    # Private IP assigned automatically from subnet range
    private_ip_address_allocation = "Dynamic"

    # Attach the public IP to this NIC
    public_ip_address_id = azurerm_public_ip.main.id
  }

  tags = var.tags
}

