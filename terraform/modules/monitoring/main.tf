# ============================================================================
# AZURE MONITOR MODULE
# Purpose: Alerting, metrics, and observability for Minecraft infrastructure
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
# METRIC ALERT: VM CPU > 80%
# ============================================================================
# Monitors VM CPU percentage and alerts when sustained high usage detected
# Why 80%? High enough to avoid false positives, low enough to catch issues
# Why 5 minutes? Filters out temporary spikes (backups, world generation)

resource "azurerm_monitor_metric_alert" "vm_cpu_high" {
  name                = "alert-vm-cpu-high"
  resource_group_name = var.resource_group_name

  # Scope: Which resources this alert monitors (VM ID)
  scopes = [var.vm_id]

  # Description shown in alert notifications
  description = "VM CPU usage is above 80% for 5 minutes"

  # How often to check the metric (1, 5, 15, 30 min, 1 hour, etc.)
  # 1 min = fastest detection, but can cause alert fatigue
  frequency = "PT1M" # ISO 8601 duration: PT1M = 1 minute

  # Time window to aggregate metrics over
  # 5 min = must be high for 5 consecutive minutes to alert
  window_size = "PT5M" # ISO 8601: PT5M = 5 minutes

  # Alert severity (0=Critical, 1=Error, 2=Warning, 3=Informational, 4=Verbose)
  # Sev 2 = Warning (not critical, but needs attention)
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
# LOG ANALYTICS QUERY ALERT: Disk Space > 90%
# ============================================================================
# Monitors OS disk usage to prevent out-of-space errors
# Uses InsightsMetrics table populated by Azure Monitor Agent
# Critical because: Minecraft world saves fail, logs stop writing, system instability
# Note: Requires Azure Monitor Agent installed (done via Ansible)

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

  # KQL query to check disk usage
  # Queries InsightsMetrics table for disk space data from Azure Monitor Agent
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

    # Threshold: Number of results > 0 means alert
    threshold = 90
    operator  = "GreaterThan"

    # ADDED: Specify which column contains the metric value to evaluate
    metric_measure_column = "UsedPercent"

    # ADDED: Specify which column identifies the resource
    resource_id_column = "Computer"

    # Number of violations before alerting
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
  # Will show "no data" until agent is installed via Ansible
  skip_query_validation = true
}

# ============================================================================
# METRIC ALERT: Key Vault Access Failures
# ============================================================================
# Detects authentication or permission issues with Key Vault
# Important because: Ansible can't retrieve RCON password, deployments fail

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

    # Filter to only failed requests
    dimension {
      name     = "ActivityName"
      operator = "Include"
      values   = ["SecretGet"]
    }

    dimension {
      name     = "StatusCode"
      operator = "Include"
      values   = ["403", "401"] # Forbidden, Unauthorized
    }
  }

  action {
    action_group_id = azurerm_monitor_action_group.admin_email.id
  }

  tags = var.tags
}

# ============================================================================
# DATA COLLECTION RULE - VM Insights
# ============================================================================
# Defines WHAT logs/metrics to collect from VMs and WHERE to send them
# Replaces legacy OMS agent with Azure Monitor Agent (AMA)

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

  # Data flows: defines which data sources go to which destinations
  data_flow {
    streams      = ["Microsoft-InsightsMetrics", "Microsoft-Syslog", "Microsoft-Perf"]
    destinations = ["minecraft-workspace"]
  }

  # Performance counters to collect (CPU, memory, disk, network)
  data_sources {
    performance_counter {
      streams                       = ["Microsoft-Perf"]
      sampling_frequency_in_seconds = 60 # Collect every 60 seconds
      counter_specifiers = [
        "Processor(*)\\% Processor Time",
        "Memory(*)\\Available MBytes",
        "LogicalDisk(*)\\% Free Space",
        "LogicalDisk(*)\\Disk Bytes/sec",
        "Network Interface(*)\\Bytes Total/sec"
      ]
      name = "perfCounterDataSource"
    }

    # Syslog collection (auth, cron, daemon logs)
    syslog {
      streams = ["Microsoft-Syslog"]
      facility_names = [
        "auth",
        "authpriv",
        "cron",
        "daemon",
        "syslog"
      ]
      log_levels = [
        "Error",
        "Warning",
        "Info"
      ]
      name = "syslogDataSource"
    }
  }

  tags = var.tags
}

# ============================================================================
# DATA COLLECTION RULE ASSOCIATION
# ============================================================================
# Links the Data Collection Rule to the VM
# VM must have Azure Monitor Agent (AMA) installed (done via Ansible)

resource "azurerm_monitor_data_collection_rule_association" "vm_insights" {
  name                    = "dcra-minecraft-vm"
  target_resource_id      = var.vm_id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.vm_insights.id

  description = "Associates VM with monitoring data collection rule"
}

