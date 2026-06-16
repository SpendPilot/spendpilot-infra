output "resource_group_name" {
  value = module.resource_group.name
}

output "acr_id" {
  value = var.create_acr ? module.container_registry[0].id : null
}

output "acr_login_server" {
  value = var.create_acr ? module.container_registry[0].login_server : null
}
