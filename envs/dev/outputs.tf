output "resource_group_name" {
  value = module.resource_group.name
}

output "aks_cluster_name" {
  value = module.aks_cluster.name
}

output "aks_cluster_id" {
  value = module.aks_cluster.id
}

output "acr_login_server" {
  value = module.container_registry.login_server
}

output "shared_acr_login_server" {
  value = data.azurerm_container_registry.global_shared.login_server
}

output "postgres_fqdn" {
  value = module.postgres.fqdn
}

output "postgres_dr_replica_enabled" {
  value = var.postgres_dr_replica_enabled
}

output "postgres_dr_replica_location" {
  value = var.postgres_dr_replica_enabled ? azurerm_postgresql_flexible_server.postgres_dr_replica[0].location : null
}

output "postgres_dr_replica_server_name" {
  value = var.postgres_dr_replica_enabled ? azurerm_postgresql_flexible_server.postgres_dr_replica[0].name : null
}

output "postgres_dr_replica_fqdn" {
  value = var.postgres_dr_replica_enabled ? azurerm_postgresql_flexible_server.postgres_dr_replica[0].fqdn : null
}

output "postgres_dr_replica_private_dns_zone_name" {
  value = var.postgres_dr_replica_enabled ? azurerm_private_dns_zone.postgres_dr[0].name : null
}

output "frontend_login_url" {
  value = trimspace(var.public_host_name) != "" ? "https://${trimspace(var.public_host_name)}/login" : null
}

output "backend_api_audience" {
  value = local.backend_audience
}

output "backend_api_scope" {
  value = "${local.backend_audience}/access_as_user"
}

output "frontend_client_id" {
  value = azuread_application.frontend_spa.client_id
}

output "backend_client_id" {
  value = azuread_application.backend_api.client_id
}

output "entra_admin_consent_url_template" {
  value = "https://login.microsoftonline.com/<tenant-id-or-domain>/v2.0/adminconsent?client_id=${azuread_application.frontend_spa.client_id}&scope=${urlencode("${local.backend_audience}/.default")}&redirect_uri=${urlencode("https://${trimspace(var.public_host_name)}/login")}"
}

output "workload_identity_client_id" {
  value = azurerm_user_assigned_identity.workload.client_id
}

output "key_vault_name" {
  value = azurerm_key_vault.workload.name
}

output "key_vault_uri" {
  value = azurerm_key_vault.workload.vault_uri
}

output "key_vault_database_url_secret_name" {
  value = var.key_vault_database_url_secret_name
}

output "key_vault_dev_auth_secret_name" {
  value = var.key_vault_dev_auth_secret_name
}

output "storage_account_url" {
  value = azurerm_storage_account.documents.primary_blob_endpoint
}

output "document_intelligence_endpoint" {
  value = data.terraform_remote_state.nonprod_shared.outputs.shared_document_intelligence_endpoint
}

output "foundry_endpoint" {
  value = data.terraform_remote_state.nonprod_shared.outputs.shared_foundry_endpoint
}

output "shared_ai_contract" {
  value = data.terraform_remote_state.nonprod_shared.outputs.shared_ai_contract
}

output "github_actions_client_id" {
  value = azuread_application.github_actions.client_id
}

output "github_actions_tenant_id" {
  value = data.azurerm_client_config.current.tenant_id
}

output "github_actions_subscription_id" {
  value = data.azurerm_client_config.current.subscription_id
}

output "argocd_server_service_type" {
  value = var.argocd_server_service_type
}

output "argocd_server_public_ip" {
  value = try(data.kubernetes_service_v1.argocd_server.status[0].load_balancer[0].ingress[0].ip, null)
}

output "argocd_server_public_hostname" {
  value = try(data.kubernetes_service_v1.argocd_server.status[0].load_balancer[0].ingress[0].hostname, null)
}

output "argocd_server_url" {
  value = trimspace(try(data.kubernetes_service_v1.argocd_server.status[0].load_balancer[0].ingress[0].hostname, "")) != "" ? "https://${trimspace(data.kubernetes_service_v1.argocd_server.status[0].load_balancer[0].ingress[0].hostname)}" : try(
    trimspace(data.kubernetes_service_v1.argocd_server.status[0].load_balancer[0].ingress[0].ip) != "" ? "https://${trimspace(data.kubernetes_service_v1.argocd_server.status[0].load_balancer[0].ingress[0].ip)}" : null,
    null,
  )
}

output "gateway_public_ip" {
  value = try(data.kubernetes_service.gateway.status[0].load_balancer[0].ingress[0].ip, null)
}

output "gateway_public_hostname" {
  value = try(data.kubernetes_service.gateway.status[0].load_balancer[0].ingress[0].hostname, null)
}

output "public_host_name" {
  value = var.public_host_name
}

output "frontdoor_origin_contract" {
  value = {
    environment          = var.environment
    namespace            = var.namespace
    origin_hostname      = trimspace(var.frontdoor_origin_hostname_override) != "" ? trimspace(var.frontdoor_origin_hostname_override) : try(data.kubernetes_service.gateway.status[0].load_balancer[0].ingress[0].ip, data.kubernetes_service.gateway.status[0].load_balancer[0].ingress[0].hostname, null)
    origin_host_header   = trimspace(var.public_host_name) != "" ? trimspace(var.public_host_name) : (trimspace(var.frontdoor_origin_hostname_override) != "" ? trimspace(var.frontdoor_origin_hostname_override) : try(data.kubernetes_service.gateway.status[0].load_balancer[0].ingress[0].ip, data.kubernetes_service.gateway.status[0].load_balancer[0].ingress[0].hostname, null))
    gateway_public_ip    = try(data.kubernetes_service.gateway.status[0].load_balancer[0].ingress[0].ip, null)
    gateway_public_fqdn  = try(data.kubernetes_service.gateway.status[0].load_balancer[0].ingress[0].hostname, null)
    health_probe_path    = "/health"
    http_port            = 80
    https_port           = 443
    origin_protocol      = var.frontdoor_origin_use_https ? "Https" : "Http"
    forwarding_protocol  = var.frontdoor_origin_use_https ? "HttpsOnly" : "HttpOnly"
    frontend_hostnames   = [var.public_host_name]
    api_path_prefixes    = ["/api/auth", "/api/admin", "/api/finance", "/api/documents", "/api/ai", "/health", "/ready"]
    frontend_path_prefix = "/*"
  }
}

output "email_delivery_contract" {
  value = {
    service_bus_fully_qualified_namespace = module.email_delivery.service_bus_fully_qualified_namespace
    service_bus_queue_name                = module.email_delivery.service_bus_queue_name
    function_app_name                     = module.email_delivery.function_app_name
    function_app_default_hostname         = module.email_delivery.function_app_default_hostname
    communication_service_endpoint        = module.email_delivery.communication_service_endpoint
    email_sender_address                  = module.email_delivery.email_sender_address
  }
}

output "service_bus_fully_qualified_namespace" {
  value = module.email_delivery.service_bus_fully_qualified_namespace
}

output "service_bus_queue_name" {
  value = module.email_delivery.service_bus_queue_name
}

output "email_sender_function_app_name" {
  value = module.email_delivery.function_app_name
}

output "email_sender_address" {
  value = module.email_delivery.email_sender_address
}
