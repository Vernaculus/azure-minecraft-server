# Azure Minecraft Server - Cost Estimate

## Monthly Cost Breakdown

### Compute - VM (Standard_D2as_v6)
- Specs: 2 vCPU, 8 GB RAM, AMD EPYC v6
- Hourly rate: $0.096/hour
- Usage scenarios:
  - 8 hours/day (240 hours/month): $23.04/month
  - 12 hours/day (360 hours/month): $34.56/month
  - 24/7 operation (720 hours/month): $69.12/month

### Storage - OS Disk
- Type: 30 GB Standard SSD (E4)
- Cost: $2.40/month (always charged, even when VM deallocated)

### Storage - Backup Blobs
- Container: minecraft-backups
- Daily growth: ~60 MB (boot + shutdown backups)
- Retention: 7 days (lifecycle policy)
- Maximum storage: 420 MB (0.4 GB)
- Cost: $0.01/month (negligible)

### Networking
- Static Public IP: $3.60/month
- Outbound data transfer: ~$1.00/month (minimal gameplay traffic)

### Key Vault
- Secret storage: $0.03/month (1 secret)
- Operations: Free tier (first 10,000 operations)

## Total Monthly Cost

| Usage Pattern | Total Cost |
|---------------|------------|
| 8 hours/day (recommended) | $30.08/month |
| 12 hours/day | $41.60/month |
| 24/7 operation | $76.16/month |

## Cost Optimization Strategies

1. Deallocate VM when not in use
   - Stops compute charges immediately
   - Storage and networking charges continue
   - Command: `az vm deallocate --name vm-minecraft-dev-scus --resource-group rg-minecraft-dev-scus`

2. Lifecycle policy for backups
   - Automatically deletes backups older than 7 days
   - Prevents storage cost growth
   - Already implemented via Terraform

3. Single region deployment
   - No cross-region data transfer costs
   - All resources in South Central US

4. Standard SSD vs Premium
   - Standard SSD sufficient for Minecraft workload
   - Premium would add $6-8/month with no performance benefit

## Cost Comparison

| Alternative | Monthly Cost | Notes |
|-------------|--------------|-------|
| Current (Azure VM) | $30-76 | Full control, IaC managed |
| Managed Minecraft host | $10-25 | Limited control, no IaC learning |
| AWS EC2 equivalent | $35-80 | Similar pricing, different tooling |
| On-premise hardware | $0 ongoing | High upfront cost, electricity, maintenance |

## Conclusion

Estimated monthly cost: **$30-40** with typical 8-10 hour/day usage pattern.

This represents excellent value for a learning project demonstrating:
- Infrastructure as Code (Terraform)
- Configuration Management (Ansible)
- Cloud security best practices
- Automated backup strategies
- Cost optimization techniques

Last updated: February 5, 2026

