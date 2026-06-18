terraform {
  required_version = ">= 1.8.0"

  backend "azurerm" {
    resource_group_name  = "terraform-rg"
    storage_account_name = "lijaztf"
    container_name       = "states"
    key                  = "identities.tfstate"
    subscription_id      = "c00887fb-883e-4d8b-83ba-697054b43421"
    tenant_id            = "23009888-f985-4438-a6a8-32650f036be3"
  }

  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
    }

    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}

provider "azuread" {
  tenant_id = var.tenant_id
}
