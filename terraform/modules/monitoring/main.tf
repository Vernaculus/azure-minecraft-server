# ============================================================================
# AZURE MONITOR MODULE
# Purpose: Multi-layer observability for Minecraft infrastructure
# Architecture: Host metrics (Azure platform) + Guest metrics (AMA) + App logs
# Resources: Log Analytics, Action Groups, Metric Alerts, Data Collection Rules
# ============================================================================

# Data source to get current subscription for resource ID construction
data "azurerm_client_config" "current" {}

# ============================================================================
# LOG ANALYTICS WORKSPACE
# ============================================================================
# Central repository for logs and metrics from all Azure resources
# Retention: 30 days (free tier allows 31 days max)
# Used by: VM Insights, Container Insights, Alert queries, Dashboards
#
# Cost optimization: PerGB2018 pricing tier with 30-day retention
# Estimated ingestion: ~500MB/month for single VM (well under 5GB free tier)

resource "azurerm_log_analytics_workspace" "minecraft" {
  name                = var.workspace_name
  location            = var.location
  resource_group_name = var.resource_group_name

  # Pricing tier
  # PerGB2018 = Pay-as-you-go (recommended for production)
  # Free = 500MB/day limit (good for dev/testing)
  sku = "PerGB2018"

  # How long to retain logs (30-730 days for PerGB2018)
  # 30 days = minimum, balances cost vs. troubleshooting history
  retention_in_days = 30

  # Prevent accidental deletion via Terraform destroy
  # Must explicitly disable before destroy
  lifecycle {
    prevent_destroy = false # Set to true in production
  }

  tags = var.tags
}

# ============================================================================
# ACTION GROUP - Email Notifications
# ============================================================================
# Defines WHO gets notified WHEN an alert fires
# Can include: Email, SMS, webhook, Azure Function, Logic App
# Production consideration: Add PagerDuty/Slack webhooks for 24/7 coverage

resource "azurerm_monitor_action_group" "admin_email" {
  name                = "ag-minecraft-admin-email"
  resource_group_name = var.resource_group_name
  short_name          = "mcadmin" # Max 12 chars, appears in SMS

  # Email receiver configuration
  # Multiple receivers can be added for redundancy
  email_receiver {
    name          = "Admin Email"
    email_address = var.admin_email

    # Use common alert schema (recommended)
    # Provides consistent JSON format across all alert types
    use_common_alert_schema = true
  }

  tags = var.tags
}

# ============================================================================
# METRIC ALERT: VM CPU > 80% (Host-Level)
# ============================================================================
# Monitors VM CPU percentage using host-level metrics
# Source: Azure platform (no agent required)
# Latency: Real-time (1-minute intervals)
# 
# Threshold rationale:
# - 80% = High enough to avoid false positives during normal gameplay
# - 5 min window = Filters out temporary spikes (backups, world generation)
# - Players typically cause 30-50% CPU, >80% indicates resource constraint

resource "azurerm_monitor_metric_alert" "vm_cpu_high" {
  name                = "alert-vm-cpu-high"
  resource_group_name = var.resource_group_name

  # Scope: Which resources this alert monitors (VM ID)
  scopes = [var.vm_id]

  # Description shown in alert notifications
  description = "VM CPU usage is above 80% for 5 minutes"

  # How often to check the metric (1, 5, 15, 30 min, 1 hour, etc.)
  # 1 min = fastest detection, minimal delay in alerting
  frequency = "PT1M" # ISO 8601 duration: PT1M = 1 minute

  # Time window to aggregate metrics over
  # 5 min = must be high for 5 consecutive minutes to alert
  window_size = "PT5M" # ISO 8601: PT5M = 5 minutes

  # Alert severity (0=Critical, 1=Error, 2=Warning, 3=Informational, 4=Verbose)
  # Sev 2 = Warning (not critical, but needs attention for capacity planning)
  severity = 2

  # Criteria for triggering alert
  criteria {
    # Metric name from Azure Monitor metrics list
    metric_name      = "Percentage CPU"
    metric_namespace = "Microsoft.Compute/virtualMachines"

    # Aggregation type: Average, Minimum, Maximum, Total, Count
    # Average = smooths out spikes, best for CPU monitoring
    aggregation = "Average"

    # Operator: GreaterThan, LessThan, Equals, etc.
    operator = "GreaterThan"

    # Threshold value (percentage for CPU)
    threshold = 80
  }

  # Action to take when alert fires
  action {
    action_group_id = azurerm_monitor_action_group.admin_email.id
  }

  tags = var.tags
}

# ============================================================================
# LOG ANALYTICS QUERY ALERT: Disk Space > 90% (Guest-Level)
# ============================================================================
# Monitors OS disk usage using guest-level performance counters
# Source: Azure Monitor Agent → Perf table
# Latency: 2-5 minute delay (agent collection + ingestion)
#
# Why guest metrics for disk space?
# - Host metrics show disk I/O but NOT space usage percentage
# - Only guest-level metrics can query filesystem space from within OS
# - Critical for preventing: Failed world saves, log truncation, system instability
#
# KQL Query Architecture:
# - Uses Perf table (populated by performance_counter data source)
# - Filters to Logical Disk object and % Free Space counter
# - Checks root filesystem (/) or _Total for aggregate disk usage
# - Alert fires when UsedPercent > 90% for any evaluation period

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "disk_space_high" {
  name                = "alert-disk-space-high"
  resource_group_name = var.resource_group_name
  location            = var.location

  description = "OS disk usage is above 90%"
  enabled     = true

  # How often to run the query
  evaluation_frequency = "PT5M" # Every 5 minutes

  # Time window for query data
  window_duration = "PT15M" # Last 15 minutes

  # Severity (1 = Error - more critical than CPU, can cause data loss)
  severity = 1

  # Scope: Log Analytics workspace where data is collected
  scopes = [azurerm_log_analytics_workspace.minecraft.id]

  # KQL query to check disk usage from guest performance counters
  criteria {
    query = <<-QUERY
      Perf
      | where ObjectName == "Logical Disk" and CounterName == "% Free Space"
      | where InstanceName == "/" or InstanceName == "_Total"
      | summarize AvgFreePercent = avg(CounterValue) by Computer
      | extend UsedPercent = 100 - AvgFreePercent
      | where UsedPercent > 90
      | project Computer, UsedPercent
    QUERY

    # Time aggregation method
    time_aggregation_method = "Average"

    # Threshold: Compare UsedPercent column against this value
    threshold = 90
    operator  = "GreaterThan"

    # Specify which column contains the metric value to evaluate
    metric_measure_column = "UsedPercent"

    # Specify which column identifies the resource
    resource_id_column = "Computer"

    # Number of violations before alerting
    # Immediate alerting (1/1) appropriate for disk space issues
    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  # Action when alert fires
  action {
    action_groups = [azurerm_monitor_action_group.admin_email.id]
  }

  tags = var.tags

  # This alert requires Azure Monitor Agent data
  # Will show "no data" until agent populates Perf table (~5 min after install)
  skip_query_validation = true
}

# ============================================================================
# METRIC ALERT: Key Vault Access Failures
# ============================================================================
# Detects authentication or permission issues with Key Vault
# Source: Azure Key Vault service metrics (platform-level)
# Important because: Ansible automation retrieves RCON password from Key Vault
# Failure modes: Expired RBAC, deleted role assignments, network issues

resource "azurerm_monitor_metric_alert" "keyvault_failures" {
  name                = "alert-keyvault-access-failures"
  resource_group_name = var.resource_group_name
  scopes              = [var.key_vault_id]
  description         = "Key Vault access failures detected (authentication or authorization)"

  frequency   = "PT5M"
  window_size = "PT5M" # Alert immediately on failures

  # Sev 2 = Warning (doesn't affect running server, but breaks automation)
  severity = 2

  criteria {
    # ServiceApiResult metric with failed dimension filter
    metric_name      = "ServiceApiResult"
    metric_namespace = "Microsoft.KeyVault/vaults"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 0 # Any failure triggers alert

    # Filter to only failed SecretGet operations
    dimension {
      name     = "ActivityName"
      operator = "Include"
      values   = ["SecretGet"]
    }

    # Filter to authentication/authorization failures
    dimension {
      name     = "StatusCode"
      operator = "Include"
      values   = ["403", "401"] # 403=Forbidden (RBAC), 401=Unauthorized (auth)
    }
  }

  action {
    action_group_id = azurerm_monitor_action_group.admin_email.id
  }

  tags = var.tags
}

# ============================================================================
# DATA COLLECTION RULE - Multi-Layer Monitoring
# ============================================================================
# Defines WHAT to collect from VMs and WHERE to send it
# Replaces legacy OMS agent with modern Azure Monitor Agent (AMA)
#
# Architecture Decision: Why both host and guest metrics?
# ┌─────────────────────────────────────────────────────────────────┐
# │ Layer 1: Host Metrics (Azure Platform)                          │
# │ - CPU %, Network I/O, Disk I/O                                  │
# │ - No agent required, real-time, used for fast CPU alerting      │
# ├─────────────────────────────────────────────────────────────────┤
# │ Layer 2: Guest Metrics (Azure Monitor Agent)                    │
# │ - Disk space %, detailed memory, per-process stats              │
# │ - Requires agent, 1-2 min delay, provides filesystem insights   │
# ├─────────────────────────────────────────────────────────────────┤
# │ Layer 3: Application Logs (Syslog via AMA)                      │
# │ - Minecraft logs, auth events, cron jobs, systemd services      │
# │ - Requires agent + rsyslog, 2-5 min delay, for troubleshooting  │
# └─────────────────────────────────────────────────────────────────┘
#
# Production pattern: Use all three layers for comprehensive observability

resource "azurerm_monitor_data_collection_rule" "vm_insights" {
  name                = "dcr-minecraft-vm-insights"
  resource_group_name = var.resource_group_name
  location            = var.location

  # Where to send collected data
  destinations {
    log_analytics {
      workspace_resource_id = azurerm_log_analytics_workspace.minecraft.id
      name                  = "minecraft-workspace"
    }
  }

  # Data flows: Maps data sources to destinations
  # Multiple streams can go to same destination
  data_flow {
    streams      = ["Microsoft-InsightsMetrics", "Microsoft-Syslog", "Microsoft-Perf"]
    destinations = ["minecraft-workspace"]
  }

  # ============================================================================
  # DATA SOURCES - Guest-Level Metrics and Logs
  # ============================================================================
  # Performance counter paths use Linux format (forward slashes)
  # Windows uses backslashes: Processor(*)\\% Processor Time
  # Linux uses forward slashes: Processor(*)/% Processor Time
  #
  # Common mistake: Using Windows paths on Linux (doesn't work!)
  # Detection: Check azuremonitoragent logs for "counter not found" errors
  
  data_sources {
    # Syslog collection for application and system logs
    # Critical for: Auth failures, cron job status, daemon errors, Minecraft logs
    # Rsyslog forwards these to Azure Monitor Agent socket
    syslog {
      streams = ["Microsoft-Syslog"]
      facility_names = [
        "auth",      # SSH login attempts, sudo usage, PAM events
        "authpriv",  # Private authentication messages (sensitive)
        "cron",      # Scheduled backup job logs, automated tasks
        "daemon",    # Systemd service logs (minecraft.service, azuremonitoragent)
        "syslog"     # General system messages, kernel logs
      ]
      log_levels = [
        "Error",    # Critical issues requiring immediate action
        "Warning",  # Potential problems to investigate
        "Info"      # Operational events (backups, restarts, player joins)
      ]
      name = "syslogDataSource"
    }

    # Performance counters for Linux guest metrics
    # Complements host metrics with OS-level detail unavailable from Azure platform
    # Sampling frequency: 60s balances detail vs. cost (5GB free tier = ~500MB/month)
    performance_counter {
      streams                       = ["Microsoft-Perf", "Microsoft-InsightsMetrics"]
      sampling_frequency_in_seconds = 60 # Collect every 60 seconds
      
      counter_specifiers = [
        # CPU metrics (guest perspective includes per-process breakdown)
        "Processor(*)/% Processor Time",
        "Processor(*)/% Idle Time",
        "Processor(*)/% User Time",
        
        # Memory metrics (detailed guest-level breakdown)
        # Host metrics only show total allocated, not actual usage
        "Memory(*)/% Used Memory",
        "Memory(*)/Available MBytes Memory",
        "Memory(*)/Used Memory MBytes",
        
        # Disk metrics (CRITICAL: guest-level shows filesystem % used)
        # Host metrics only show I/O operations, not space consumption
        # This is why disk alert requires guest metrics
        "Logical Disk(*)/% Used Space",
        "Logical Disk(*)/% Free Space",
        "Logical Disk(*)/Free Megabytes",
        "Logical Disk(*)/Disk Bytes/sec",
        "Logical Disk(*)/Disk Read Bytes/sec",
        "Logical Disk(*)/Disk Write Bytes/sec",
        
        # Network metrics (guest-level includes per-interface detail)
        # Useful for: Diagnosing Minecraft traffic patterns, DDoS detection
        "Network(*)/Total Bytes Transmitted",
        "Network(*)/Total Bytes Received",
        "Network(*)/Total Bytes"
      ]
      name = "perfCounterDataSource"
    }
  }

  tags = var.tags
}

# ============================================================================
# DATA COLLECTION RULE ASSOCIATION
# ============================================================================
# Links the Data Collection Rule to the VM
# VM must have Azure Monitor Agent (AMA) installed
# Installation method: Terraform VM extension (see modules/compute/main.tf)
# Association creates binding: VM → DCR → Log Analytics Workspace

resource "azurerm_monitor_data_collection_rule_association" "vm_insights" {
  name                    = "dcra-minecraft-vm"
  target_resource_id      = var.vm_id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.vm_insights.id

  description = "Associates VM with monitoring data collection rule"
}

