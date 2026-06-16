locals {
  tags = merge({
    application = "spendpilot"
    environment = var.environment
    managed_by  = "terraform"
    scope       = "nonprod-shared"
  }, var.tags)
}

data "terraform_remote_state" "dev" {
  count   = var.read_dev_state ? 1 : 0
  backend = "azurerm"

  config = {
    resource_group_name  = var.backend_resource_group_name
    storage_account_name = var.backend_storage_account_name
    container_name       = var.backend_container_name
    key                  = "dev.tfstate"
  }
}

data "terraform_remote_state" "staging" {
  count   = var.read_staging_state ? 1 : 0
  backend = "azurerm"

  config = {
    resource_group_name  = var.backend_resource_group_name
    storage_account_name = var.backend_storage_account_name
    container_name       = var.backend_container_name
    key                  = "staging.tfstate"
  }
}

locals {
  dev_origin_contract     = var.read_dev_state ? try(data.terraform_remote_state.dev[0].outputs.frontdoor_origin_contract, null) : null
  staging_origin_contract = var.read_staging_state ? try(data.terraform_remote_state.staging[0].outputs.frontdoor_origin_contract, null) : null
}

module "resource_group" {
  source = "../../modules/resource-group"

  name     = var.resource_group_name
  location = var.location
  tags     = local.tags
}
