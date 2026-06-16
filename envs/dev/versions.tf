terraform {
  required_version = ">= 1.8.0"

  backend "azurerm" {
    resource_group_name  = "terra-rg"
    storage_account_name = "lijazterracount"
    container_name       = "terracontainer"
    key                  = "spendpilot.tfstate"
    subscription_id      = "e1f5b4be-e0ba-4ccb-8708-a949458fcd83"
    tenant_id            = "920e9322-340c-4fbc-bf09-dc8fd6636182"
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
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.15"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.32"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.12"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "azuread" {}
