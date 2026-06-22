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

data "terraform_remote_state" "identities" {
  backend = "azurerm"

  config = {
    resource_group_name  = var.backend_resource_group_name
    storage_account_name = var.backend_storage_account_name
    container_name       = var.backend_container_name
    key                  = var.identities_state_key
  }
}

module "resource_group" {
  count  = var.deploy_runtime_resources ? 1 : 0
  source = "../../modules/resource-group"

  name     = var.resource_group_name
  location = var.location
  tags     = local.tags
}

module "email_delivery" {
  count  = var.deploy_runtime_resources ? 1 : 0
  source = "../../modules/email-delivery"

  name                         = "${var.prefix}-${var.environment}"
  location                     = module.resource_group[0].location
  resource_group_name          = module.resource_group[0].name
  tags                         = local.tags
  github_actions_principal_id  = try(data.terraform_remote_state.identities.outputs.github_actions_service_principal_object_id, "")
  email_data_location          = var.email_data_location
  email_domain_name            = var.email_domain_name
  email_domain_management      = var.email_domain_management
  function_sender_username     = var.email_sender_username
  function_sender_display_name = var.email_sender_display_name
}
