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

output "postgres_fqdn" {
  value = module.postgres.fqdn
}

output "frontdoor_endpoint_hostname" {
  value = azurerm_cdn_frontdoor_endpoint.this.host_name
}

output "frontend_login_url" {
  value = "https://${azurerm_cdn_frontdoor_endpoint.this.host_name}/login"
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
  value = "https://login.microsoftonline.com/<tenant-id-or-domain>/v2.0/adminconsent?client_id=${azuread_application.frontend_spa.client_id}&scope=${urlencode("${local.backend_audience}/.default")}&redirect_uri=${urlencode("https://${azurerm_cdn_frontdoor_endpoint.this.host_name}/login")}"
}

output "workload_identity_client_id" {
  value = azurerm_user_assigned_identity.workload.client_id
}

output "storage_account_url" {
  value = azurerm_storage_account.documents.primary_blob_endpoint
}

output "document_intelligence_endpoint" {
  value = azurerm_cognitive_account.document_intelligence.endpoint
}

output "foundry_endpoint" {
  value = azurerm_cognitive_account.foundry.endpoint
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

output "gateway_public_ip" {
  value = try(data.kubernetes_service.gateway.status[0].load_balancer[0].ingress[0].ip, null)
}

output "gateway_public_hostname" {
  value = try(data.kubernetes_service.gateway.status[0].load_balancer[0].ingress[0].hostname, null)
}

output "frontdoor_origin_contract" {
  value = {
    environment          = var.environment
    namespace            = var.namespace
    origin_hostname      = trimspace(var.frontdoor_origin_hostname_override) != "" ? trimspace(var.frontdoor_origin_hostname_override) : try(data.kubernetes_service.gateway.status[0].load_balancer[0].ingress[0].ip, data.kubernetes_service.gateway.status[0].load_balancer[0].ingress[0].hostname, null)
    origin_host_header   = trimspace(var.frontdoor_origin_hostname_override) != "" ? trimspace(var.frontdoor_origin_hostname_override) : try(data.kubernetes_service.gateway.status[0].load_balancer[0].ingress[0].ip, data.kubernetes_service.gateway.status[0].load_balancer[0].ingress[0].hostname, null)
    gateway_public_ip    = try(data.kubernetes_service.gateway.status[0].load_balancer[0].ingress[0].ip, null)
    gateway_public_fqdn  = try(data.kubernetes_service.gateway.status[0].load_balancer[0].ingress[0].hostname, null)
    health_probe_path    = "/health"
    http_port            = 80
    https_port           = 443
    origin_protocol      = var.frontdoor_origin_use_https ? "Https" : "Http"
    forwarding_protocol  = var.frontdoor_origin_use_https ? "HttpsOnly" : "HttpOnly"
    frontend_hostnames   = []
    api_path_prefixes    = ["/api/auth", "/api/admin", "/api/finance", "/api/documents", "/api/ai", "/health", "/ready"]
    frontend_path_prefix = "/*"
  }
}
