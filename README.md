# Azure Minecraft Server - Infrastructure as Code

Automated Minecraft server deployment on Azure using Terraform and Ansible. This project demonstrates infrastructure as code, configuration management, and security best practices in a cloud environment.

## Project Overview

This is a learning project that deploys a production-ready Minecraft server on Azure with:
- Infrastructure provisioning via Terraform
- Configuration management via Ansible
- Multi-layered security (NSG, UFW, fail2ban, SSH hardening)
- Automated security patching with intelligent reboot management
- Cost optimization (deallocate when not in use)

## Architecture

- **Cloud Provider**: Microsoft Azure
- **Region**: South Central US
- **Compute**: Standard_D2as_v6 (2 vCPU, 8 GB RAM)
- **OS**: Ubuntu 22.04 LTS
- **Network**: VNet with NSG, static public IP
- **Storage**: 30 GB Standard SSD + Azure Blob for backups

## Project Status

✅ **Day 1 Complete** - Foundation established (Jan 20, 2026)
- Remote Terraform state configured in Azure Storage
- Azure provider and subscription configured
- Resource Group deployed with governance tags
- Variables and outputs structure implemented

✅ **Day 2 Complete** - Network foundation deployed (Jan 21, 2026)
- VNet and subnet with proper IP addressing (10.10.0.0/16)
- NSG with least-privilege security rules
- Static public IP for consistent server address
- Network module with outputs for VM integration

✅ **Day 3 Complete** - Compute deployed and validated (Jan 21, 2026)
- Standard_D2as_v6 VM (2 vCPU, 8 GB RAM, AMD EPYC v6)
- Ubuntu 22.04 LTS with SSH key authentication
- 30 GB Standard SSD OS disk
- Successfully validated SSH access
- **Challenge**: Overcame Azure capacity constraints through systematic SKU discovery

✅ **Day 4 Complete** - OS Hardening with Ansible (Jan 22, 2026)
- Ansible project structure initialized (inventory, playbooks, roles)
- fail2ban intrusion prevention (5 failures = 10min ban)
- Unattended security updates (intelligent reboot management)
- UFW firewall (default-deny, SSH rate-limited, Minecraft allowed)
- SSH hardening (root disabled, password auth disabled, key-only)
- **Security**: Multi-layered defense (NSG + UFW + fail2ban + SSH hardening)
- **Operations**: Intelligent reboot manager (auto-reboot if no players, countdown if active)

🚧 **Current**: Day 5 - Minecraft Server Installation

**Next**: Minecraft 1.21.1 server deployment, systemd service configuration

## Prerequisites

- Azure subscription with appropriate permissions
- Azure CLI installed and authenticated
- Terraform >= 1.0
- Ansible >= 2.9
- SSH key pair generated

## Quick Start

### 1. Clone and Configure

    git clone https://github.com/Vernaculus/azure-minecraft-server.git
    cd azure-minecraft-server/terraform
    cp example.tfvars terraform.tfvars
    # Edit terraform.tfvars with your values

### 2. Deploy Infrastructure

    terraform init
    terraform plan
    terraform apply

### 3. Configure Server (Ansible)

    cd ../ansible
    # Update inventory/hosts.ini with VM public IP
    ansible-playbook playbooks/site.yml

### 4. Connect to Minecraft

    # Server address: <VM_PUBLIC_IP>:25565
    # Add to Minecraft multiplayer server list

## Daily Operations

### Starting the Server

    # 1. Start the VM
    az vm start --name vm-minecraft-dev-scus --resource-group rg-minecraft-dev-scus

    # 2. Check for pending security reboots
    ssh mcadmin@<VM_PUBLIC_IP> 'sudo /usr/local/bin/check-reboot-required'

    # If reboot required:
    #   - No Minecraft running: Automatically reboots
    #   - Minecraft running, no players: Automatically reboots  
    #   - Minecraft running with players: 10-minute countdown, then reboots

### Stopping the Server

    # Stop Minecraft gracefully
    ssh mcadmin@<VM_PUBLIC_IP> 'sudo systemctl stop minecraft'

    # Deallocate VM to stop billing
    az vm deallocate --name vm-minecraft-dev-scus --resource-group rg-minecraft-dev-scus

### Manual Maintenance Reboot

    # Schedule reboot with custom countdown (e.g., 5 minutes)
    ssh mcadmin@<VM_PUBLIC_IP> 'sudo /usr/local/bin/scheduled-reboot.sh 5'

## Security Features

- **Network**: NSG (Azure) + UFW (host firewall) with default-deny
- **SSH**: Key-only authentication, root login disabled, fail2ban active
- **Updates**: Automated security patching with intelligent reboot management
- **Monitoring**: fail2ban for intrusion detection, system logs
- **RCON**: Localhost-only binding, strong password, firewall-blocked from internet

## Documentation

- [Project Overview](docs/overview.md) - Detailed project plan and requirements
- [Prerequisites](docs/prerequisites.md) - Backend setup and configuration
- [Networking](docs/networking.md) - Network architecture and NSG rules
- [Compute Sizing](docs/compute-sizing.md) - VM SKU selection rationale
- [Security Architecture](docs/security.md) - Defense-in-depth strategy and threat model

## Repository Structure

    azure-minecraft-server/
    ├── terraform/
    │   ├── main.tf                 # Root module orchestration
    │   ├── variables.tf            # Input variables
    │   ├── outputs.tf              # Output values
    │   ├── example.tfvars          # Example configuration
    │   └── modules/
    │       ├── network/            # VNet, NSG, Public IP
    │       └── compute/            # VM, NIC, Storage
    ├── ansible/
    │   ├── ansible.cfg             # Ansible configuration
    │   ├── inventory/
    │   │   └── hosts.ini           # VM inventory
    │   ├── playbooks/
    │   │   └── site.yml            # Main orchestration playbook
    │   └── roles/
    │       ├── system_hardening/   # Security configuration
    │       ├── minecraft_server/   # Server installation
    │       └── backup_to_blob/     # Automated backups
    └── docs/                       # Project documentation

## Cost Optimization

- **Deallocate when not in use**: Stops compute charges (pay only for storage)
- **Standard SSD**: Balance of performance and cost
- **Single VM**: No redundancy needed for personal server
- **Estimated Monthly Cost**: ~$50-70 (if running 8 hours/day)

## Lessons Learned

- Azure capacity constraints require flexible VM sizing strategies
- Infrastructure as code enables rapid rebuild after failures
- Defense-in-depth security is critical for internet-facing servers
- Automated patching requires intelligent scheduling for cost-optimized VMs

## Contributing

This is a personal learning project. Feel free to fork and adapt for your own use.

## License

MIT License - See LICENSE file for details

## Contact

Josh Hall - Vernaculus on GitHub
