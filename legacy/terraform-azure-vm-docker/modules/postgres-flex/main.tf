resource "azurerm_private_dns_zone" "this" {
  name                = var.private_dns_zone_name
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  for_each = {
    for index, vnet_id in var.virtual_network_ids : tostring(index) => vnet_id
  }

  name                  = "${var.name}-vnet-link-${each.key}"
  private_dns_zone_name = azurerm_private_dns_zone.this.name
  resource_group_name   = var.resource_group_name
  virtual_network_id    = each.value
  tags                  = var.tags
}

resource "azurerm_postgresql_flexible_server" "this" {
  name                          = var.name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  version                       = var.server_version
  public_network_access_enabled = false
  delegated_subnet_id           = var.delegated_subnet_id
  private_dns_zone_id           = azurerm_private_dns_zone.this.id
  administrator_login           = var.administrator_login
  administrator_password        = var.administrator_password
  storage_mb                    = var.storage_mb
  sku_name                      = var.sku_name
  backup_retention_days         = var.backup_retention_days
  zone                          = var.zone
  tags                          = var.tags

  high_availability {
    mode                      = var.ha_mode
    standby_availability_zone = var.ha_standby_zone
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.this]
}

resource "azurerm_postgresql_flexible_server_database" "this" {
  name      = var.database_name
  server_id = azurerm_postgresql_flexible_server.this.id
  collation = var.collation
  charset   = var.charset
}
