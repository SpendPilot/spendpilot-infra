output "resource_group_name" {
  value = module.resource_group.name
}

output "application_gateway_public_ip" {
  value = module.app_gateway.public_ip_address
}

output "application_gateway_id" {
  value = module.app_gateway.id
}

output "edge_vnet_id" {
  value = module.edge_network.virtual_network_id
}

output "app_vnet_id" {
  value = module.app_network.virtual_network_id
}

output "data_vnet_id" {
  value = module.data_network.virtual_network_id
}

output "hub_firewall_public_ip" {
  value = azurerm_public_ip.firewall.ip_address
}

output "hub_firewall_private_ip" {
  value = azurerm_firewall.hub.ip_configuration[0].private_ip_address
}

output "frontend_scale_set_name" {
  value = module.frontend_vmss.name
}

output "backend_scale_set_name" {
  value = module.backend_vmss.name
}

output "data_ai_scale_set_name" {
  value = module.data_ai_vmss.name
}

output "static_app_vm_name" {
  value = module.static_app_vm.name
}

output "static_app_private_ip" {
  value = module.static_app_vm.private_ip_address
}

output "postgres_server_name" {
  value = module.postgres.server_name
}

output "postgres_fqdn" {
  value = module.postgres.fqdn
}

output "postgres_database_name" {
  value = module.postgres.database_name
}

output "ollama_private_load_balancer_ip" {
  value = var.ollama_lb_private_ip
}
