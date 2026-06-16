locals {
  tags = merge({
    application = "spendpilot"
    environment = var.environment
    managed_by  = "terraform"
    scope       = "runtime"
  }, var.tags)
}

module "resource_group" {
  source = "../../modules/resource-group"

  name     = var.resource_group_name
  location = var.location
  tags     = local.tags
}
