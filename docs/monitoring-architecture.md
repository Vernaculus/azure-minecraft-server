# Monitoring Architecture

## Overview
Multi-layer observability using Azure Monitor with both host and guest metrics.

## Monitoring Layers

### Layer 1: Host-Level Metrics (Azure Platform)
- **Source**: Azure Compute fabric
- **Agent Required**: No
- **Latency**: Real-time
- **Metrics**: CPU %, network I/O, disk I/O
- **Use Case**: Fast alerting on infrastructure issues

### Layer 2: Guest-Level Metrics (Azure Monitor Agent)
- **Source**: Linux OS via AMA
- **Agent Required**: Yes (installed via Terraform)
- **Latency**: 1-2 minute delay
- **Metrics**: Disk space %, detailed memory, process stats
- **Use Case**: Application-level insights, capacity planning

### Layer 3: Application Logs (Syslog)
- **Source**: Minecraft server, systemd, auth logs
- **Agent Required**: Yes (AMA + rsyslog)
- **Latency**: 2-5 minute delay
- **Use Case**: Troubleshooting, security auditing, player tracking

## Alert Strategy

| Alert | Layer | Why This Layer? |
|-------|-------|-----------------|
| CPU >80% | Host | Fast detection (1-min intervals) |
| Disk >90% | Guest | Only guest shows filesystem % |
| Key Vault failures | Azure Service | Built-in service metric |

## Design Decisions

**Why guest metrics when we have host metrics?**
- Host metrics don't show disk space % (only I/O)
- Guest metrics show per-process resource usage
- Provides redundancy if agent or host has issues

**Counter format: Linux vs Windows**
- Linux: `Processor(*)/% Processor Time` (forward slash)
- Windows: `Processor(*)\\% Processor Time` (backslash)
- Original configuration used Windows format

