terraform {
  required_version = ">= 1.8.0"

  backend "azurerm" {
    resource_group_name  = "terra-rg"
    storage_account_name = "lijazterracount"
    container_name       = "terracontainer"
    key                  = "prod.tfstate"
    subscription_id      = "e1f5b4be-e0ba-4ccb-8708-a949458fcd83"
    tenant_id            = "920e9322-340c-4fbc-bf09-dc8fd6636182"
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}
