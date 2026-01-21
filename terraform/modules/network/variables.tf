# Resource group name where network resources will be created
variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

# Azure region for network resources
variable "location" {
  description = "Azure region"
  type        = string
}

# VNet address space
variable "vnet_address_space" {
  description = "Address space for VNet"
  type        = list(string)
}

# Subnet prefix for app tier
variable "subnet_app_prefix" {
  description = "Address prefix for app subnet"
  type        = list(string)
}

# Admin source IP for SSH access
variable "admin_source_ip" {
  description = "Source IP for SSH (CIDR)"
  type        = string
}

# Project name for resource naming
variable "project_name" {
  description = "Project name"
  type        = string
}

# Environment for resource naming
variable "environment" {
  description = "Environment (dev/staging/prod)"
  type        = string
}

# Tags to apply to all network resources
variable "tags" {
  description = "Tags for resources"
  type        = map(string)
}

