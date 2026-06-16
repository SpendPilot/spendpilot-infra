resource "azurerm_virtual_network" "this" {
  name                = var.name
  address_space       = var.address_space
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_subnet" "this" {
  for_each = var.subnets

  name                 = each.key
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = each.value.address_prefixes

  dynamic "delegation" {
    for_each = each.value.delegation_service == null ? [] : [1]

    content {
      name = coalesce(each.value.delegation_name, "${each.key}-delegation")

      service_delegation {
        name    = each.value.delegation_service
        actions = each.value.delegation_actions
      }
    }
  }
}
