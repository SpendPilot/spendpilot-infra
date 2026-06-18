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

  name                   = var.acr_name != "" ? var.acr_name : substr("${local.compact_name}acr", 0, 50)
  location               = module.resource_group.location
  resource_group_name    = module.resource_group.name
  sku                    = var.acr_sku
  anonymous_pull_enabled = var.acr_anonymous_pull_enabled
  tags                   = local.tags
}

# Hostinger remains the registrar for the root domain.
# Azure DNS becomes authoritative only after the Hostinger nameservers
# are delegated to the Azure DNS nameservers created for this zone.
# This shared DNS zone must outlive environment-specific infrastructure.
resource "azurerm_dns_zone" "public" {
  name                = var.root_domain_name
  resource_group_name = module.resource_group.name
  tags                = local.tags

  lifecycle {
    prevent_destroy = true
  }
}
