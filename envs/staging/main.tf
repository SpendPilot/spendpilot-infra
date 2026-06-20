locals {
  tags = merge({
    application = "spendpilot"
    environment = var.environment
    managed_by  = "terraform"
    scope       = "runtime"
  }, var.tags)
}

data "terraform_remote_state" "nonprod_shared" {
  backend = "azurerm"

  config = {
    resource_group_name  = var.backend_resource_group_name
    storage_account_name = var.backend_storage_account_name
    container_name       = var.backend_container_name
    key                  = var.nonprod_shared_state_key
  }
}

module "resource_group" {
  source = "../../modules/resource-group"

  name     = var.resource_group_name
  location = var.location
  tags     = local.tags
}
