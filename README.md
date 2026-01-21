# Azure Minecraft Server

Secure, cost-optimized Minecraft 1.21.1 server (5 players) on Azure B1ms VM. Built with Terraform and Ansible to demonstrate Azure Administrator skills.

## Features

- Infrastructure as Code with Terraform
- Configuration management with Ansible
- Security hardening (NSG, UFW, SSH keys, fail2ban)
- Automated backups to Azure Blob Storage
- Azure Monitor alerts
- Cost optimization with auto-shutdown

## Tech Stack

- **Cloud**: Microsoft Azure
- **IaC**: Terraform
- **Config Mgmt**: Ansible
- **OS**: Ubuntu 22.04 LTS
- **Compute**: Standard_D2as_v6 (2 vCPU, 8 GB RAM, AMD EPYC v6)

## AZ-104 Skills Demonstrated

- Compute resource management
- Virtual networking and security
- Storage solutions
- Monitoring and backup
- Governance and tagging

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
- Public IP: 4.150.29.71
- **Challenge**: Overcame Azure capacity constraints through systematic SKU discovery

🚧 **Current**: Day 4 - OS Hardening with Ansible

**Next**: System security configuration (UFW, fail2ban, SSH hardening)

## Documentation

See `docs/overview.md` for detailed project scope and success criteria.

## License

MIT License - See LICENSE file for details.
