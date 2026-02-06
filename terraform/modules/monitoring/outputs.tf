# ============================================================================
# MONITORING MODULE OUTPUTS
# ============================================================================

output "workspace_id" {
  description = "Log Analytics Workspace resource ID"
  value       = azurerm_log_analytics_workspace.minecraft.id
}

output "workspace_customer_id" {
  description = "Log Analytics Workspace ID (GUID) for agent configuration"
  value       = azurerm_log_analytics_workspace.minecraft.workspace_id
}

output "action_group_id" {
  description = "Action Group resource ID"
  value       = azurerm_monitor_action_group.admin_email.id
}

output "data_collection_rule_id" {
  description = "Data Collection Rule resource ID"
  value       = azurerm_monitor_data_collection_rule.vm_insights.id
}

