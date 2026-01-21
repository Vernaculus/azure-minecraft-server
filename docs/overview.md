# Project Overview: Azure Minecraft Server Platform

## Scope

Deploy a production-grade Minecraft 1.21.1 vanilla server on Azure supporting up to 5 concurrent players. Implement Infrastructure as Code (Terraform), configuration management (Ansible), security hardening (Azure NSG, Linux UFW, SSH), automated backups to Azure Blob Storage, and basic monitoring. Demonstrate AZ-104 Azure Administrator competencies across compute, networking, storage, identities & governance, and monitoring domains.

## Technical Stack

- **Cloud Platform**: Microsoft Azure
- **Infrastructure as Code**: Terraform (azurerm provider)
- **Configuration Management**: Ansible
- **Compute**: Azure Linux VM (Ubuntu 22.04 LTS, Standard_B1ms: 1 vCPU, 2 GB RAM)
- **Networking**: VNet, subnet, NSG with least-privilege rules, static public IP
- **Storage**: Managed disk (20 GB Standard SSD) + Azure Storage Account for backups
- **Application**: Minecraft Java Edition 1.21.1 server (vanilla, max 5 players)

## Success Criteria

### Functional Requirements
- [ ] Server accessible via Minecraft client on port 25565 from public internet
- [ ] Supports 5 concurrent players with acceptable performance (<100ms latency, stable TPS)
- [ ] Server runs as systemd service under non-root `minecraft` user
- [ ] World data persists across VM reboots

### Infrastructure Requirements
- [ ] All Azure resources provisioned via Terraform (no manual portal clicks)
- [ ] VM configuration managed via Ansible playbooks (idempotent, repeatable)
- [ ] Remote Terraform state stored in Azure Storage backend
- [ ] All resources tagged for governance (env, app, owner, costCenter)

### Security Requirements
- [ ] NSG allows only SSH (port 22) from administrator IP and Minecraft (port 25565) publicly
- [ ] SSH password authentication disabled; key-based auth only
- [ ] Linux firewall (UFW) configured with default-deny inbound policy
- [ ] SSH root login disabled
- [ ] fail2ban active for SSH brute-force protection
- [ ] Automatic security updates enabled (unattended-upgrades)

### Operational Requirements
- [ ] Daily automated backups of world data to Azure Blob Storage (cron + Azure CLI)
- [ ] Azure Monitor VM insights enabled with at least one alert (CPU or availability)
- [ ] Estimated monthly cost: $12–15 with auto-shutdown schedule (8 hours/day)
- [ ] VM auto-shutdown configured for cost optimization

### Documentation & Portfolio Requirements
- [ ] Clean GitHub repository with clear folder structure
- [ ] README with architecture diagram, deployment instructions, and tech stack
- [ ] Meaningful Git commit history with descriptive messages
- [ ] Tagged release (v1.0.0) at project completion
- [ ] Screenshots: Azure resources, NSG rules, Ansible output, in-game connection

## Out of Scope

- Multi-region deployment or high availability
- Modded server support (vanilla only)
- Custom domain/DNS configuration beyond Azure DNS label
- Advanced monitoring (Application Insights, custom dashboards)
- CI/CD pipeline automation
- Player whitelisting/permission management (basic `server.properties` only)

## Estimated Effort

**Total**: 40–45 hours over 7 days (6-hour workdays)

## AZ-104 Skills Demonstrated

- **Manage Azure identities and governance (20–25%)**: RBAC, tagging, resource organization
- **Implement and manage storage (15–20%)**: Managed disks, blob storage, backup strategies
- **Deploy and manage Azure compute resources (20–25%)**: VM deployment, sizing, power management
- **Configure and manage virtual networking (15–20%)**: VNet, subnet, NSG, public IP
- **Monitor and maintain Azure resources (10–15%)**: Azure Monitor, alerts, Log Analytics

## Day 1 Progress

- ✅ Remote state configured in Azure Storage
- ✅ Provider locked to azurerm v4.x
- ✅ Resource group deployed: rg-minecraft-dev-eus
- ✅ Tagging and naming conventions established

## Day 2 Progress

- ✅ Network module created with modular Terraform structure
- ✅ VNet deployed: vnet-minecraft-dev-eus (10.10.0.0/16)
- ✅ Subnet deployed: snet-minecraft-app (10.10.1.0/24)
- ✅ NSG configured with 3 rules:
  - Allow SSH (22) from admin IP only
  - Allow Minecraft (25565) from Internet
  - Deny all other inbound traffic
- ✅ Static public IP provisioned: pip-minecraft-dev-eus
- ✅ Network interface (NIC) created for VM attachment
- ✅ Network architecture documented
