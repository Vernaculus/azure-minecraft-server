# Configures where Terraform stores its state file
# State tracks what resources exist in Azure vs your code
terraform {
  backend "azurerm" {
    # Name of the resource group containing the storage account
    resource_group_name = "rg-terraform-state-eus"

    # Name of the storage account (must be globally unique, 3-24 chars, lowercase/numbers only)
    storage_account_name = "sttfstatemcdev"

    # Name of the blob container within the storage account
    container_name = "tfstate"

    # Name of the state file (unique per environment/project)
    key = "minecraft-dev.tfstate"
  }
}

