# Defines the minimum Terraform version and required providers
terraform {
  # Minimum Terraform CLI version needed to run this code
  required_version = ">= 1.5.0"

  # List of external providers this project needs
  required_providers {
    # Azure Resource Manager provider for creating Azure resources
    azurerm = {
      # Official HashiCorp provider source
      source = "hashicorp/azurerm"

      # Use version 4.x (any 4.x release, but not 5.0+)
      version = "~> 4.0"
    }

    # ADDED: Random provider for generating secure passwords
    random = {
      # Official HashiCorp provider source
      source = "hashicorp/random"

      # Use version 3.6.x (latest stable)
      version = "~> 3.6"
    }
  }
}

# Configure the Azure provider with feature flags
provider "azurerm" {
  # Explicitly specify which subscription to use
  subscription_id = var.subscription_id

  # Enable all optional features (required block, even if empty)
  features {
    # Feature flags control provider behavior (e.g., soft-delete on Key Vault)
    # Empty means use defaults
  }
}

