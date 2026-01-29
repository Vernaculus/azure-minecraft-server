# Project Overview: Azure Minecraft Server Platform

## Scope

Deploy a production-grade Minecraft 1.21.1 vanilla server on Azure supporting up to 10 concurrent players. Implement Infrastructure as Code (Terraform), configuration management (Ansible), security hardening (Azure NSG, Linux UFW, SSH), automated backups to Azure Blob Storage, and basic monitoring. Demonstrate AZ-104 Azure Administrator competencies across compute, networking, storage, identities & governance, and monitoring domains.

## Technical Stack

- **Cloud Platform**: Microsoft Azure
- **Infrastructure as Code**: Terraform (azurerm provider)
- **Configuration Management**: Ansible
- **Compute**: Azure Linux VM (Ubuntu 22.04 LTS, Standard_D2as_v6: 2 vCPU, 8 GB RAM, AMD EPYC v6)
- **Networking**: VNet, subnet, NSG with least-privilege rules, static public IP
- **Storage**: Managed disk (30 GB Standard SSD) + Azure Storage Account for backups
- **Application**: Minecraft Java Edition 1.21.1 server (vanilla, max 10 players)

## Success Criteria

### Functional Requirements
- [x] Server accessible via Minecraft client on port 25565 from public internet
- [x] Supports 10 concurrent players with acceptable performance (<100ms latency, stable TPS)
- [x] Server runs as systemd service under non-root `minecraft` user
- [x] World data persists across VM reboots
- [x] RCON enabled for remote management and automation

### Infrastructure Requirements
- [x] All Azure resources provisioned via Terraform (no manual portal clicks)
- [x] VM configuration managed via Ansible playbooks (idempotent, repeatable)
- [x] Remote Terraform state stored in Azure Storage backend
- [x] All resources tagged for governance (env, app, owner, costCenter)

### Security Requirements
- [x] NSG allows only SSH (port 22) from administrator IP and Minecraft (port 25565) publicly
- [x] SSH password authentication disabled; key-based auth only
- [x] Linux firewall (UFW) configured with default-deny inbound policy
- [x] SSH root login disabled
- [x] fail2ban active for SSH brute-force protection
- [x] Automatic security updates enabled (unattended-upgrades)
- [x] RCON protected by UFW firewall (port 25575 blocked externally)
- [x] Passwordless sudo configured with comprehensive logging

### Operational Requirements
- [ ] Daily automated backups of world data to Azure Blob Storage (cron + Azure CLI)
- [ ] Azure Monitor VM insights enabled with at least one alert (CPU or availability)
- [x] Intelligent reboot management (player-aware countdown system)
- [ ] Estimated monthly cost: $50-70 depending on usage (8 hours/day)
- [ ] VM auto-shutdown configured for cost optimization

### Documentation & Portfolio Requirements
- [x] Clean GitHub repository with clear folder structure
- [x] README with architecture overview, deployment instructions, and tech stack
- [x] Meaningful Git commit history with descriptive messages
- [x] Phase-based testing documentation (TESTING-NOTES-PHASE5.md)
- [ ] Tagged release (v1.0.0) at project completion
- [ ] Screenshots: Azure resources, NSG rules, Ansible output, in-game connection
- [ ] Architecture diagram with all components

## Out of Scope

- Multi-region deployment or high availability
- Modded server support (vanilla only)
- Custom domain/DNS configuration beyond Azure DNS label
- Advanced monitoring (Application Insights, custom dashboards)
- CI/CD pipeline automation
- Player whitelisting/permission management (basic `server.properties` only)

## Estimated Effort

**Total**: 40-45 hours over 7 phases (6-hour work sessions)

## AZ-104 Skills Demonstrated

- **Manage Azure identities and governance (20-25%)**: RBAC, tagging, resource organization
- **Implement and manage storage (15-20%)**: Managed disks, blob storage, backup strategies
- **Deploy and manage Azure compute resources (20-25%)**: VM deployment, sizing, power management
- **Configure and manage virtual networking (15-20%)**: VNet, subnet, NSG, public IP
- **Monitor and maintain Azure resources (10-15%)**: Azure Monitor, alerts, Log Analytics

## Phase 1 Progress (Jan 20, 2026)

- ✅ Remote state configured in Azure Storage
- ✅ Provider locked to azurerm v4.x
- ✅ Resource group deployed: rg-minecraft-dev-scus
- ✅ Tagging and naming conventions established

## Phase 2 Progress (Jan 21, 2026)

- ✅ Network module created with modular Terraform structure
- ✅ VNet deployed: vnet-minecraft-dev-scus (10.10.0.0/16)
- ✅ Subnet deployed: snet-minecraft-app (10.10.1.0/24)
- ✅ NSG configured with 3 rules:
  - Allow SSH (22) from admin IP only
  - Allow Minecraft (25565) from Internet
  - Deny all other inbound traffic
- ✅ Static public IP provisioned: pip-minecraft-dev-scus
- ✅ Network interface (NIC) created for VM attachment
- ✅ Network architecture documented

## Phase 3 Progress (Jan 21, 2026)

- ✅ Compute module created with full VM specification
- ✅ VM deployed: vm-minecraft-dev-scus (Standard_D2as_v6)
- ✅ Ubuntu 22.04 LTS (Gen2) with SSH key authentication
- ✅ 30 GB StandardSSD_LRS OS disk
- ✅ Network interface attached to subnet
- ✅ SSH access validated from admin workstation
- ✅ Overcame Azure capacity constraints through SKU discovery

## Phase 4 Progress (Jan 22, 2026)

- ✅ Ansible project structure initialized
  - ansible.cfg with optimizations (pipelining, fact caching)
  - inventory/hosts.ini with VM connection details
  - playbooks/site.yml with role orchestration
- ✅ Ansible connectivity validated (ping test, facts gathering)
- ✅ system_hardening role implemented (12 tasks, 3 handlers)
- ✅ Security packages installed:
  - fail2ban (intrusion prevention)
  - unattended-upgrades (automated patching)
  - ufw (host firewall)
  - nmap (network diagnostics)
- ✅ fail2ban configured:
  - SSH jail active and monitoring
  - 5 failures in 10 minutes = 10 minute ban
- ✅ unattended-upgrades configured:
  - Daily security/stable update checks
  - Manual reboot via intelligent script (no auto-reboot)
- ✅ UFW firewall deployed:
  - Default-deny inbound policy
  - SSH (22/tcp) rate-limited
  - Minecraft (25565/tcp) allowed
- ✅ SSH hardened:
  - Root login disabled
  - Password authentication disabled
  - Key-only authentication enforced
  - Max 3 auth attempts
  - 30 second login grace time
- ✅ All security services validated and enabled on boot

## Phase 5 Progress (Jan 28, 2026)

- ✅ minecraft_server role implemented
  - Java 21 (OpenJDK) installation
  - Minecraft 1.21.1 server JAR download
  - systemd service with Aikar's JVM flags (6GB heap)
  - server.properties template with RCON enabled
  - minecraft system user with /opt/minecraft home
- ✅ RCON integration:
  - mcrcon client compiled and installed
  - RCON password file created automatically (0600, root:root)
  - Port 25575 protected by UFW (filtered from external access)
- ✅ Intelligent reboot management:
  - check-reboot-required script with player detection
  - Auto-reboot when 0 players online
  - 10-minute countdown when players active
  - scheduled-reboot.sh for manual maintenance
- ✅ Critical bug fixes (AMSP-5.5):
  - Fixed missing rcon_password file (automation failure)
  - Fixed regex escaping in player detection (false 0-player readings)
  - Validated RCON security (UFW blocks external access)
- ✅ Comprehensive testing:
  - Player connections validated
  - RCON commands tested (list, say, time query)
  - Auto-reboot logic verified (0 players path)
  - 10-minute countdown tested end-to-end (with player)
  - Security validated via nmap (port 25575 filtered)

## Current Phase: Phase 6 - End-to-End Validation & Documentation

**Objectives:**
- Comprehensive validation of all integrated systems
- Backup automation to Azure Blob Storage
- Azure Monitor and alerting setup
- Architecture diagrams and screenshots
- Final documentation polish
- Cost analysis and optimization validation

**Remaining Work:**
- [ ] Daily automated backups to Azure Blob Storage
- [ ] Azure Monitor VM insights and alerts
- [ ] Architecture diagram creation
- [ ] Screenshot capture (Azure Portal, in-game, monitoring)
- [ ] Cost breakdown documentation
- [ ] Git tag v1.0.0 release

