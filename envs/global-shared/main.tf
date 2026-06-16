locals {
  name         = lower("${var.prefix}-${var.environment}")
  compact_name = substr(replace(lower("${var.prefix}${var.environment}"), "-", ""), 0, 18)
  tags = merge({
    application = "spendpilot"
    environment = var.environment
    managed_by  = "terraform"
    scope       = "global-shared"
  }, var.tags)
}

module "resource_group" {
  source = "../../modules/resource-group"

  name     = var.resource_group_name
  location = var.location
  tags     = local.tags
}

module "container_registry" {
  count  = var.create_acr ? 1 : 0
  source = "../../modules/container-registry"

  name                = var.acr_name != "" ? var.acr_name : substr("${local.compact_name}acr", 0, 50)
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name
  sku                 = var.acr_sku
  tags                = local.tags
}
