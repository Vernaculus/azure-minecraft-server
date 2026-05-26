## Architecture

    +-----------------------------------------------------------------------+
    |                         Azure Subscription                            |
    |                                                                       |
    |   +---------------------------------------------------------------+   |
    |   |           rg-minecraft-dev-scus  (Resource Group)             |   |
    |   |                                                               |   |
    |   |   +-------------------------------------------------------+   |   |
    |   |   |         vnet-minecraft-dev-scus  (VNet 10.10.0.0/16)  |   |   |
    |   |   |                                                       |   |   |
    |   |   |   +---------------------------------------------+     |   |   |
    |   |   |   |            nsg-minecraft-app  (NSG)         |     |   |   |
    |   |   |   |   Priority 100  -- SSH :22   (admin IP /32) |     |   |   |
    |   |   |   |   Priority 110  -- TCP :25565  (Internet)   |     |   |   |
    |   |   |   |   Priority 4000 -- Deny All Inbound         |     |   |   |
    |   |   |   +--------------------+------------------------+     |   |   |
    |   |   |                        |                              |   |   |
    |   |   |   +--------------------v-------------------------+    |   |   |
    |   |   |   |   vm-minecraft-dev-scus  (Ubuntu 22.04)      |    |   |   |
    |   |   |   |   Standard_D2as_v6  |  pip (static IP)       |    |   |   |
    |   |   |   |   osdisk-minecraft-dev-scus  (30GB SSD)      |    |   |   |
    |   |   |   |                                              |    |   |   |
    |   |   |   |   +---------------------------------------+  |    |   |   |
    |   |   |   |   |   Host Firewall  (UFW + fail2ban)     |  |    |   |   |
    |   |   |   |   |   SSH rate-limited  |  key-only auth  |  |    |   |   |
    |   |   |   |   |   RCON bound to localhost only        |  |    |   |   |
    |   |   |   |   +---------------------------------------+  |    |   |   |
    |   |   |   |                                              |    |   |   |
    |   |   |   |   +---------------------------------------+  |    |   |   |
    |   |   |   |   |   Azure Monitor Agent (VM Extension)  |  |    |   |   |
    |   |   |   |   |   rsyslog --> Log Analytics Workspace |  |    |   |   |
    |   |   |   |   +---------------------------------------+  |    |   |   |
    |   |   |   |                                              |    |   |   |
    |   |   |   |          Managed Identity (RBAC)             |    |   |   |
    |   |   |   +--------+------------------------------+------+    |   |   |
    |   |   |            |                              |           |   |   |
    |   |   |   +--------v--------------+   +-----------v--------+  |   |   |
    |   |   |   |  kv-minecraft-dev     |   | stmcbackupdev2o7f0p|  |   |   |
    |   |   |   |  (Azure Key Vault)    |   | (Blob Storage)     |  |   |   |
    |   |   |   |  RCON secret stored   |   | minecraft-backups/ |  |   |   |
    |   |   |   |  Key Vault Secrets    |   | 7-day lifecycle    |  |   |   |
    |   |   |   |  User role on VM MI   |   | policy (auto-del)  |  |   |   |
    |   |   |   +-----------------------+   +--------------------+  |   |   |
    |   |   +-------------------------------------------------------+   |   |
    |   +---------------------------------------------------------------+   |
    +-----------------------------------------------------------------------+

    Provisioned via:  Terraform (modular) + Ansible (roles)
    Secrets:          Azure Key Vault + Managed Identity -- zero credentials on VM
    Backups:          Event-driven (boot/shutdown) --> Blob Storage via managed identity
    Monitoring:       Azure Monitor Agent --> Log Analytics (via Terraform VM extension)
    Security layers:  NSG --> UFW --> fail2ban --> SSH key-only --> RCON localhost-only
