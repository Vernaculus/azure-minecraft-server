# Day 5 Testing Results - Jan 28, 2026

## ✅ Successfully Validated
- Passwordless sudo for mcadmin
- Sudo logging to /var/log/sudo.log and /var/log/sudo-io/
- mcrcon installation and compilation
- RCON commands (list, say, time query)
- Player count detection (0 vs N players)
- Auto-reboot with 0 players online
- Manual scheduled-reboot.sh with countdown
- 10-minute countdown with player online (check-reboot-required)

## 🐛 Issues Found - Require Fixes

### Issue 1: RCON Bind Address (SECURITY)
**Severity:** Medium (mitigated by UFW)
**Location:** ansible/roles/minecraft_server/templates/server.properties.j2
**Problem:** RCON listening on *:25575 instead of 127.0.0.1:25575
**Fix:** Add `rcon.bind=127.0.0.1` to template

### Issue 2: Missing rcon_password File
**Severity:** High (scripts fail without it)
**Location:** ansible/roles/minecraft_server/tasks/main.yml
**Problem:** Scripts expect /opt/minecraft/rcon_password but role doesn't create it
**Fix:** Add task to create file with correct permissions (0600, root:root)

### Issue 3: Regex Escaping in Reboot Script
**Severity:** High (causes instant reboots)
**Location:** ansible/roles/system_hardening/tasks/main.yml (check-reboot-required script)
**Problem:** `grep -oP 'There are \\\\K[0-9]+'` should be `grep -oP 'There are \\K[0-9]+'`
**Fix:** Reduce backslash escaping from 4 to 2 in Ansible template

## 📋 Manual Workarounds Applied During Testing
- Created /opt/minecraft/rcon_password manually
- Fixed regex via sed command on VM
- No .gitignore or other tracked file changes needed

