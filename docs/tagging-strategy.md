# Azure Resource Tagging Strategy

## Overview

Consistent resource tagging enables cost tracking, resource organization, automation, and governance across Azure environments.

## Current Tag Schema

All resources in this project use the following tags:

Tag Key     | Tag Value      | Purpose
----------- | -------------- | --------------------------------------------------------
env         | dev            | Environment identifier (dev/staging/prod)
app         | minecraft      | Application identifier
managedBy   | terraform      | Indicates IaC management
owner       | cloud-ops      | Team responsible for maintenance
costCenter  | platform-ops   | Billing department for cost allocation

## Tag Implementation

Tags are defined as Terraform locals and applied to all resources:

locals {
  common_tags = {
    env        = var.environment
    app        = "minecraft"
    managedBy  = "terraform"
    owner      = "cloud-ops"
    costCenter = "platform-ops"
  }
}

## Tagged Resources

All Azure resources receive tags:

1. Resource Group - rg-minecraft-dev-scus
2. Virtual Network - vnet-minecraft-dev-scus
3. Subnet - snet-minecraft-app
4. Network Security Group - nsg-minecraft-app
5. Public IP - pip-minecraft-dev-scus
6. Network Interface - nic-minecraft-dev-scus
7. Virtual Machine - vm-minecraft-dev-scus
8. Storage Account - stmcbackupdev2o7f0p
9. Key Vault - kv-minecraft-dev-scus

## Benefits

### Cost Allocation
- Filter Azure Cost Management by costCenter tag
- Track spending per application (app tag)
- Separate dev vs production costs (env tag)

### Resource Discovery
- Find all Terraform-managed resources (managedBy tag)
- Locate resources by owner for incident response
- Group resources by application

### Automation
- Target specific environments in scripts
- Implement auto-shutdown policies by env tag
- Apply governance policies selectively

### Governance
- Enforce naming conventions
- Audit manual vs IaC deployments
- Track resource lifecycle

## Multi-Environment Expansion

For production deployment, extend tag values:

Environment (env):
- dev - Development/testing
- staging - Pre-production validation
- prod - Production workloads

Cost Center (costCenter):
- platform-ops - Infrastructure team
- game-servers - Application team
- shared-services - Common resources

Owner (owner):
- cloud-ops - Infrastructure team
- app-team - Application developers
- security-team - Security resources

## Tag Verification

View Tags on Resource Group:

az group show --name rg-minecraft-dev-scus --query tags

View Tags on VM:

az vm show --name vm-minecraft-dev-scus --resource-group rg-minecraft-dev-scus --query tags

List All Resources by Tag:

az resource list --tag env=dev --output table

Filter Resources by Multiple Tags:

az resource list --tag app=minecraft --tag managedBy=terraform --output table

## Cost Analysis Using Tags

View Costs by Environment:
1. Navigate to: Azure Portal - Cost Management + Billing
2. Select: Cost Analysis
3. Add filter: Tag = env
4. Group by: Tag value

View Costs by Application:
1. Navigate to: Cost Analysis
2. Add filter: Tag = app
3. Group by: Tag value
4. Export report for billing

## Best Practices

1. Consistency - Use same tag keys across all resources
2. Automation - Apply tags via Terraform, not manually
3. Validation - Use Azure Policy to enforce required tags
4. Documentation - Keep tag schema documented (this file)
5. Review - Audit tags quarterly for accuracy

## Tag Enforcement (Future Enhancement)

Consider Azure Policy to enforce tagging:

Policy: Require specific tags on resources
Effect: Deny resource creation without required tags
Required tags: env, app, managedBy, owner, costCenter

## Azure CLI Tag Management

Add Tag to Existing Resource:

az resource tag --tags newKey=newValue --ids /subscriptions/.../resourceId

Update Tag Value:

az resource tag --tags env=prod --ids /subscriptions/.../resourceId

Remove Tag:

az resource tag --tags env= --ids /subscriptions/.../resourceId

---

Last updated: February 5, 2026

