output "resource_group_name" {
  value = module.resource_group.name
}

output "acr_id" {
  value = var.create_acr ? module.container_registry[0].id : null
}

output "acr_name" {
  value = var.create_acr ? module.container_registry[0].name : null
}

output "acr_login_server" {
  value = var.create_acr ? module.container_registry[0].login_server : null
}

output "dns_zone_name" {
  value = azurerm_dns_zone.public.name
}

output "dns_zone_id" {
  value = azurerm_dns_zone.public.id
}

output "dns_zone_resource_group_name" {
  value = module.resource_group.name
}

output "dns_zone_name_servers" {
  value = azurerm_dns_zone.public.name_servers
}
