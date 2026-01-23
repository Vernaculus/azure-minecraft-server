# Security Architecture

## Defense-in-Depth Strategy

This project implements multiple layers of security controls, ensuring that if one layer is bypassed, others still protect the system.

### Layer 1: Azure Network Security Group (NSG)
**Location**: Cloud perimeter (Azure network)

**Rules**:
- Priority 100: Allow SSH (22/tcp) from admin IP only (configured in terraform.tfvars)
- Priority 110: Allow Minecraft (25565/tcp) from Internet
- Priority 4000: Deny all other inbound traffic

**Purpose**: First line of defense, blocks traffic before it reaches the VM

### Layer 2: UFW Host Firewall
**Location**: VM operating system

**Rules**:
- Default policy: DENY inbound, ALLOW outbound
- SSH (22/tcp): LIMIT (rate-limited to 6 connections per 30 seconds per IP)
- Minecraft (25565/tcp): ALLOW
- All other ports: BLOCKED

**Purpose**: Defense-in-depth redundancy with NSG, protects if NSG misconfigured

### Layer 3: fail2ban Intrusion Prevention
**Location**: VM user-space monitoring daemon

**Configuration**:
- Monitors: /var/log/auth.log via systemd journal
- Threshold: 5 failed SSH attempts in 10 minutes
- Action: Ban IP for 10 minutes via iptables
- Backend: systemd

**Purpose**: Active response to brute-force attacks, adapts to attacker behavior

### Layer 4: SSH Hardening
**Location**: SSH daemon configuration (/etc/ssh/sshd_config)

**Settings**:
- PermitRootLogin: no
- PasswordAuthentication: no
- ChallengeResponseAuthentication: no
- PermitEmptyPasswords: no
- LoginGraceTime: 30 seconds
- MaxAuthTries: 3
- Protocol: 2

**Purpose**: Eliminates password-based attacks, reduces attack surface

### Layer 5: Automated Patching
**Location**: systemd timer (daily)

**Configuration**:
- Source: Ubuntu security and stable repositories
- Schedule: Daily via apt-daily-upgrade.timer
- Auto-reboot: Intelligent (based on server state and player count)
- Notifications: System log, MOTD, in-game chat (if players present)

**Purpose**: Closes known vulnerabilities before exploitation

## Automated Reboot Management

**Challenge**: Cost-optimized VMs are deallocated during off-hours, can't reboot at fixed time.

**Solution**: Intelligent reboot manager that adapts to server state:

1. **No Minecraft running**: Displays reboot required, exits (admin decision)
2. **Minecraft running, 0 players**: Automatic immediate reboot
3. **Minecraft running, N players**: 10-minute countdown with warnings every minute

**Player Experience** (in-game chat messages):

    [SYSTEM] WARNING: Server will restart in 10 minutes
    [SYSTEM] Reason: Critical security updates require reboot
    [SYSTEM] Please save your progress and prepare to log out!
    [SYSTEM] WARNING: Server restarting in 9 minutes!
    [SYSTEM] WARNING: Server restarting in 8 minutes!
    ...
    [SYSTEM] WARNING: 10 SECONDS UNTIL RESTART!
    [SYSTEM] Restarting in 3... 2... 1...

**Security**:
- RCON bound to localhost only (127.0.0.1), not internet-accessible
- Strong 32-character random password
- UFW blocks external access to RCON port (25575)
- Password stored in root-only file (0600 permissions)

## Threat Model

### Threats Mitigated

| Threat | Mitigation | Layer |
|--------|-----------|-------|
| SSH Brute-Force | fail2ban + key-only auth | Layer 3 & 4 |
| Credential Stuffing | Password auth disabled | Layer 4 |
| Unpatched CVEs | unattended-upgrades | Layer 5 |
| Port Scanning | NSG + UFW default-deny | Layer 1 & 2 |
| Root Compromise | Root login disabled, sudo only | Layer 4 |
| DoS (Connection Exhaustion) | SSH rate-limiting, reduced LoginGraceTime | Layer 2 & 4 |
| Lateral Movement | Single-purpose VM, minimal packages | Architecture |

### Residual Risks (Accepted)

| Risk | Impact | Likelihood | Mitigation Plan |
|------|--------|-----------|-----------------|
| Zero-day in SSH | HIGH | LOW | Monitor CVEs, update immediately |
| DDoS on Minecraft port | MEDIUM | MEDIUM | Accept (DDoS Protection Standard too expensive) |
| Azure platform compromise | HIGH | VERY LOW | Out of scope, trust Azure |
| Minecraft server exploit | MEDIUM | LOW | Keep server updated, whitelist if private |

## Security Validation

### Automated Tests

Test SSH password auth blocked:

    ssh -o PubkeyAuthentication=no mcadmin@<VM_PUBLIC_IP>
    # Expected: Permission denied (publickey)

Test root login blocked:

    ssh root@<VM_PUBLIC_IP>
    # Expected: Permission denied (publickey)

Test UFW firewall active:

    sudo ufw status verbose
    # Expected: Status: active, SSH LIMIT, Minecraft ALLOW

Test fail2ban monitoring:

    sudo fail2ban-client status sshd
    # Expected: Jail enabled, filter active

Test unattended-upgrades configured:

    cat /etc/apt/apt.conf.d/50unattended-upgrades | grep Automatic-Reboot
    # Expected: "false" (manual reboot management)

Test reboot notification system (dry-run):

    sudo touch /var/run/reboot-required
    sudo /usr/local/bin/check-reboot-required
    # Expected: Displays reboot warning, updates MOTD

Verify RCON is NOT accessible from internet:

    nmap -p 25575 <VM_PUBLIC_IP>
    # Expected: filtered or closed

Verify RCON works locally:

    ssh mcadmin@<VM_PUBLIC_IP>
    mcrcon -H 127.0.0.1 -P 25575 -p <password> "list"
    # Expected: Player list displayed

### Manual Audit Checklist

- [ ] NSG rules match documented configuration
- [ ] UFW status shows correct rules
- [ ] SSH config matches hardened settings
- [ ] fail2ban jail active and monitoring
- [ ] unattended-upgrades configured (auto-reboot disabled)
- [ ] Intelligent reboot scripts present and executable
- [ ] No unnecessary services running
- [ ] All security services enabled on boot
- [ ] RCON bound to localhost only
- [ ] RCON password file has 0600 permissions

## Compliance Considerations

The security controls align with:

- **CIS Ubuntu 22.04 Benchmark**: SSH hardening, firewall configuration
- **NIST Cybersecurity Framework**: Identify, Protect, Detect (fail2ban), Respond
- **Azure Security Benchmark**: Network segmentation, access control, vulnerability management

## Incident Response

### SSH Brute-Force Detected

1. Check fail2ban status: `sudo fail2ban-client status sshd`
2. Review banned IPs: Look for patterns (country, ASN)
3. Check auth logs: `sudo grep 'Failed password' /var/log/auth.log`
4. If massive attack: Consider changing SSH port (security by obscurity, but effective)

### Security Patch Available

1. Patches auto-install daily via unattended-upgrades
2. Reboot handled by intelligent manager:
   - No players: Auto-reboot
   - Players online: 10-minute countdown
3. For urgent CVE: `sudo apt update && sudo apt upgrade -y`
4. Manual reboot: `sudo /usr/local/bin/check-reboot-required`

### VM Compromised

1. Immediately deallocate VM: `az vm deallocate --name vm-minecraft-dev-scus --resource-group rg-minecraft-dev-scus`
2. Take snapshot of disk for forensics
3. Review NSG flow logs (if enabled)
4. Rebuild from Terraform/Ansible (infrastructure as code)
5. Rotate SSH keys: Generate new keypair, update Terraform

## References

- [CIS Ubuntu 22.04 Benchmark](https://www.cisecurity.org/benchmark/ubuntu_linux)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)
- [Azure Security Benchmark](https://learn.microsoft.com/security/benchmark/azure/)
- [fail2ban Documentation](https://www.fail2ban.org/wiki/index.php/Main_Page)
- [UFW Documentation](https://help.ubuntu.com/community/UFW)
- [Minecraft RCON Protocol](https://wiki.vg/RCON)
 
