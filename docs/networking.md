# Network Architecture

## Design Decisions

### IP Address Space
- **VNet CIDR**: 10.10.0.0/16 (65,536 addresses)
- **Subnet CIDR**: 10.10.1.0/24 (256 addresses for application tier)
- **Private IP**: Dynamically assigned from subnet pool (e.g., 10.10.1.4)
- **Rationale**: /16 VNet provides room for future subnets (data tier, management, etc.)

### Security Model
- **NSG Attachment**: Subnet-level (applies rules to all VMs in subnet)
- **Inbound Strategy**: Default-deny with explicit allow rules
- **Outbound Strategy**: Allow all (default Azure behavior for apt updates, Azure services)
- **Port Security**: SSH restricted to admin IP; Minecraft open to Internet

### Public Access
- **Public IP Type**: Static (prevents IP change when VM deallocates)
- **SKU**: Standard (required for availability zones, future HA)

## Resource Naming Convention

Following Azure best practices for naming:

| Resource Type | Name | Purpose |
|---------------|------|---------|
| Virtual Network | `vnet-minecraft-dev-eus` | Main network container |
| Subnet | `snet-minecraft-app` | Application tier subnet |
| Network Security Group | `nsg-minecraft-app` | Firewall for app subnet |
| Public IP | `pip-minecraft-dev-eus` | External IP address |
| Network Interface | `nic-minecraft-dev-eus` | VM network adapter |

Pattern: `{type}-{project}-{tier/env}-{region}`

## Network Security Group Rules

### Rule Priority Model
- **100-999**: Allow rules for specific services
- **1000-3999**: Reserved for future allow rules
- **4000**: Explicit deny-all (ensures no implicit allows)

### Implemented Rules

| Priority | Name | Direction | Action | Protocol | Source | Dest Port | Purpose |
|----------|------|-----------|--------|----------|--------|-----------|---------|
| 100 | Allow-SSH-From-Admin | Inbound | Allow | TCP | Admin IP/32 | 22 | Secure administrative access |
| 110 | Allow-Minecraft-25565 | Inbound | Allow | TCP | Internet | 25565 | Player connections |
| 4000 | Deny-All-Inbound | Inbound | Deny | * | * | * | Explicit default-deny |

### Security Considerations

**Admin IP Protection**:
- SSH only allowed from specific administrator IP (defined in `terraform.tfvars`)
- Prevents brute-force attacks from Internet
- Must update if admin IP changes (common with home ISPs)

**Minecraft Port Exposure**:
- Port 25565 open to Internet (required for public server)
- Application-level security via Minecraft whitelist or online-mode
- Consider restricting to specific IP ranges if private server

**Outbound Traffic**:
- Default Azure NSG allows all outbound (no explicit rules needed)
- Required for: apt updates, Azure Storage backups, Minecraft downloads
- Can restrict later if enhanced security needed

## Network Topology

Internet
|
| (SSH: Admin IP only, Minecraft: Public)
|
┌──▼────────────────────────────────────┐
│ Public IP (Static) │
│ pip-minecraft-dev-eus │
└──┬────────────────────────────────────┘
|
┌──▼────────────────────────────────────┐
│ Network Interface (NIC) │
│ nic-minecraft-dev-eus │
│ Private IP: 10.10.1.x (Dynamic) │
└──┬────────────────────────────────────┘
|
┌──▼────────────────────────────────────┐
│ Subnet: snet-minecraft-app │
│ 10.10.1.0/24 │
│ ┌─────────────────────────────────┐ │
│ │ NSG: nsg-minecraft-app │ │
│ │ - Allow SSH (22) from admin │ │
│ │ - Allow Minecraft (25565) │ │
│ │ - Deny all other inbound │ │
│ └─────────────────────────────────┘ │
└───────────────────────────────────────┘
|
┌────────────▼──────────────────────────┐
│ VNet: vnet-minecraft-dev-eus │
│ 10.10.0.0/16 │
│ (Room for future subnets) │
└───────────────────────────────────────┘ 


## Potential Future Enhancements

### Additional Subnets (Not Implemented)
- **snet-minecraft-data** (10.10.2.0/24): Separate backend database if needed
- **snet-minecraft-mgmt** (10.10.3.0/24): Azure Bastion or jump box
- **AzureBastionSubnet** (10.10.255.0/26): Azure Bastion for secure RDP/SSH

### Advanced Security
- **Application Security Groups (ASGs)**: Tag-based security rules
- **Azure Firewall**: Centralized egress filtering
- **DDoS Protection Standard**: Enhanced DDoS mitigation (cost: $2,944/month - overkill for lab)

### Monitoring
- **NSG Flow Logs**: Traffic analysis and security auditing
- **Network Watcher**: Connection troubleshooting and topology visualization

## Troubleshooting

### Cannot SSH to VM
1. Verify admin source IP: `curl ifconfig.me`
2. Check NSG effective rules: `az network nsg rule list`
3. Confirm public IP: `az network public-ip show --name pip-minecraft-dev-eus`
4. Test connectivity: `nc -zv <public-ip> 22`

### Cannot Connect to Minecraft
1. Verify port 25565 in NSG rules
2. Check UFW rules on VM (Day 4 work)
3. Confirm Minecraft server running: `systemctl status minecraft`
4. Test port: `nc -zv <public-ip> 25565`

### Public IP Changed Unexpectedly
- Should not happen with Static allocation
- Verify SKU is Standard and allocation is Static
- Check Azure Service Health for platform issues

## Cost Considerations

| Resource | Monthly Cost (East US) |
|----------|------------------------|
| VNet | Free |
| Subnet | Free |
| NSG | Free |
| Public IP (Static, Standard) | ~$3.60 |
| Network Interface | Free |
| **Total Network Cost** | **~$3.60/month** |

Bandwidth charges apply for outbound data >5GB/month (~$0.087/GB), but minimal for 5-player server.

## References

- [Azure VNet Documentation](https://learn.microsoft.com/azure/virtual-network/)
- [NSG Security Rules](https://learn.microsoft.com/azure/virtual-network/network-security-groups-overview)
- [Azure Naming Conventions](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming)

