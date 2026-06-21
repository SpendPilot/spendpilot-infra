output "resource_group_name" {
  value = module.resource_group.name
}

output "aks_cluster_name" {
  value = module.aks_cluster.name
}

output "aks_cluster_id" {
  value = module.aks_cluster.id
}

output "aks_oidc_issuer_url" {
  value = module.aks_cluster.oidc_issuer_url
}

output "shared_acr_login_server" {
  value = data.azurerm_container_registry.global_shared.login_server
}

output "workload_identity_client_id" {
  value = azurerm_user_assigned_identity.workload.client_id
}

output "app_config_map_name" {
  value = var.app_config_map_name
}

output "app_secret_name" {
  value = var.app_secret_name
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

output "storage_container_name" {
  value = azurerm_storage_container.documents.name
}

output "document_intelligence_endpoint" {
  value = azurerm_cognitive_account.document_intelligence.endpoint
}

output "foundry_endpoint" {
  value = azurerm_cognitive_account.foundry.endpoint
}

output "foundry_model_deployment_name" {
  value = azurerm_cognitive_deployment.foundry_model.name
}

output "postgres_fqdn" {
  value = module.postgres.fqdn
}

output "postgres_database_name" {
  value = module.postgres.database_name
}

output "postgres_database_url_template" {
  value = "postgresql+psycopg://${var.postgres_admin_login}:<postgres_admin_password>@${module.postgres.fqdn}:5432/${module.postgres.database_name}?sslmode=require"
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

output "backend_api_audience" {
  value = var.backend_application_id_uri
}

output "backend_api_scope" {
  value = "${var.backend_application_id_uri}/access_as_user"
}

output "auth_authority" {
  value = var.auth_authority
}

output "supported_sign_in_audience" {
  value = "AzureADandPersonalMicrosoftAccount"
}

output "frontend_client_id" {
  value = azuread_application.frontend_spa.client_id
}

output "backend_client_id" {
  value = azuread_application.backend_api.client_id
}

output "tenant_admin_consent_contract" {
  value = {
    supported_sign_in_audience = "AzureADandPersonalMicrosoftAccount"
    authority                  = var.auth_authority
    frontend_client_id         = azuread_application.frontend_spa.client_id
    backend_application_id_uri = var.backend_application_id_uri
    delegated_scope            = "${var.backend_application_id_uri}/access_as_user"
    admin_consent_scope        = "${var.backend_application_id_uri}/.default"
    redirect_uri_hint          = "Use any registered HTTPS login redirect URI for the SPA, such as https://costpilot.online/login"
    admin_consent_url_template = "https://login.microsoftonline.com/<tenant-id-or-domain>/v2.0/adminconsent?client_id=${azuread_application.frontend_spa.client_id}&scope=${urlencode("${var.backend_application_id_uri}/.default")}&redirect_uri=${urlencode("https://costpilot.online/login")}"
    governance_model = {
      first_user_in_tenant_becomes = "org_owner"
      subsequent_users_become      = "employee"
      personal_accounts            = "personal Microsoft accounts get isolated workspaces unless they are invited into an org tenant as guest users"
    }
  }
}

output "frontdoor_endpoint_hostname" {
  value = local.frontdoor_enabled && length(azurerm_cdn_frontdoor_endpoint.this) > 0 ? azurerm_cdn_frontdoor_endpoint.this[0].host_name : null
}

output "frontdoor_default_url" {
  value = local.frontdoor_enabled && length(azurerm_cdn_frontdoor_endpoint.this) > 0 ? "https://${azurerm_cdn_frontdoor_endpoint.this[0].host_name}" : null
}

output "frontend_login_urls" {
  value = distinct(concat(
    local.frontdoor_enabled && length(azurerm_cdn_frontdoor_endpoint.this) > 0 ? ["https://${azurerm_cdn_frontdoor_endpoint.this[0].host_name}/login"] : [],
    local.frontdoor_apex_host_name != "" ? ["https://${local.frontdoor_apex_host_name}/login"] : [],
    local.frontdoor_www_host_name != "" ? ["https://${local.frontdoor_www_host_name}/login"] : [],
  ))
}

output "frontdoor_apex_validation" {
  value = length(azurerm_cdn_frontdoor_custom_domain.apex) > 0 ? {
    host_name        = azurerm_cdn_frontdoor_custom_domain.apex[0].host_name
    resource_id      = azurerm_cdn_frontdoor_custom_domain.apex[0].id
    validation_token = azurerm_cdn_frontdoor_custom_domain.apex[0].validation_token
  } : null
}

output "frontdoor_www_validation" {
  value = length(azurerm_cdn_frontdoor_custom_domain.www) > 0 ? {
    host_name        = azurerm_cdn_frontdoor_custom_domain.www[0].host_name
    resource_id      = azurerm_cdn_frontdoor_custom_domain.www[0].id
    validation_token = azurerm_cdn_frontdoor_custom_domain.www[0].validation_token
  } : null
}

output "frontdoor_origin_target" {
  value = {
    hostname_or_ip      = azurerm_cdn_frontdoor_origin.kgateway[0].host_name
    origin_host_header  = azurerm_cdn_frontdoor_origin.kgateway[0].origin_host_header
    forwarding_protocol = var.frontdoor_origin_use_https ? "HttpsOnly" : "HttpOnly"
    probe_protocol      = var.frontdoor_origin_use_https ? "Https" : "Http"
    probe_path          = "/health"
  }
}

output "prod_edge_transition_contract" {
  value = {
    target_public_hostname      = local.frontdoor_apex_host_name
    frontdoor_enabled           = local.frontdoor_enabled
    frontdoor_endpoint_hostname = local.frontdoor_enabled && length(azurerm_cdn_frontdoor_endpoint.this) > 0 ? azurerm_cdn_frontdoor_endpoint.this[0].host_name : null
    dns_cutover_required        = true
    rollback_strategy           = "Revert the Front Door-focused Terraform change set and restore DNS to the last known good public edge if runtime validation fails."
  }
}

output "public_host_name" {
  value = local.frontdoor_apex_host_name
}

output "frontdoor_origin_contract" {
  value = {
    environment          = var.environment
    namespace            = var.namespace
    origin_hostname      = trimspace(var.frontdoor_origin_hostname_override) != "" ? trimspace(var.frontdoor_origin_hostname_override) : (trimspace(try(data.kubernetes_service_v1.gateway[0].status[0].load_balancer[0].ingress[0].hostname, "")) != "" ? trimspace(data.kubernetes_service_v1.gateway[0].status[0].load_balancer[0].ingress[0].hostname) : try(data.kubernetes_service_v1.gateway[0].status[0].load_balancer[0].ingress[0].ip, null))
    origin_host_header   = local.frontdoor_apex_host_name != "" ? local.frontdoor_apex_host_name : (trimspace(var.frontdoor_origin_hostname_override) != "" ? trimspace(var.frontdoor_origin_hostname_override) : try(data.kubernetes_service_v1.gateway[0].status[0].load_balancer[0].ingress[0].hostname, data.kubernetes_service_v1.gateway[0].status[0].load_balancer[0].ingress[0].ip, null))
    gateway_public_ip    = try(data.kubernetes_service_v1.gateway[0].status[0].load_balancer[0].ingress[0].ip, null)
    gateway_public_fqdn  = trimspace(try(data.kubernetes_service_v1.gateway[0].status[0].load_balancer[0].ingress[0].hostname, "")) != "" ? trimspace(data.kubernetes_service_v1.gateway[0].status[0].load_balancer[0].ingress[0].hostname) : null
    health_probe_path    = "/health"
    http_port            = 80
    https_port           = 443
    origin_protocol      = var.frontdoor_origin_use_https ? "Https" : "Http"
    forwarding_protocol  = var.frontdoor_origin_use_https ? "HttpsOnly" : "HttpOnly"
    frontend_hostnames   = compact([local.frontdoor_apex_host_name, local.frontdoor_www_host_name])
    api_path_prefixes    = ["/api/auth", "/api/admin", "/api/finance", "/api/documents", "/api/ai", "/health", "/ready"]
    frontend_path_prefix = "/*"
  }
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

output "gitops_values_contract" {
  value = {
    frontend_image_repository      = "${data.azurerm_container_registry.global_shared.login_server}/spend-control-frontend"
    identity_image_repository      = "${data.azurerm_container_registry.global_shared.login_server}/spend-control-identity"
    finance_image_repository       = "${data.azurerm_container_registry.global_shared.login_server}/spend-control-finance"
    documents_image_repository     = "${data.azurerm_container_registry.global_shared.login_server}/spend-control-documents"
    config_map_name                = var.app_config_map_name
    secret_name                    = var.app_secret_name
    service_account_name           = var.service_account_name
    auth_frontend_client_id        = azuread_application.frontend_spa.client_id
    auth_backend_client_id         = azuread_application.backend_api.client_id
    auth_backend_audience          = var.backend_application_id_uri
    auth_api_scope                 = "${var.backend_application_id_uri}/access_as_user"
    azure_managed_identity_client  = azurerm_user_assigned_identity.workload.client_id
    azure_document_intelligence    = azurerm_cognitive_account.document_intelligence.endpoint
    azure_storage_account_url      = azurerm_storage_account.documents.primary_blob_endpoint
    azure_storage_container_name   = azurerm_storage_container.documents.name
    azure_foundry_endpoint         = azurerm_cognitive_account.foundry.endpoint
    azure_foundry_model_deployment = azurerm_cognitive_deployment.foundry_model.name
    key_vault_name                 = azurerm_key_vault.workload.name
    key_vault_uri                  = azurerm_key_vault.workload.vault_uri
    key_vault_database_url_secret  = var.key_vault_database_url_secret_name
    key_vault_dev_auth_secret      = var.key_vault_dev_auth_secret_name
    frontend_default_host          = local.frontdoor_enabled && length(azurerm_cdn_frontdoor_endpoint.this) > 0 ? azurerm_cdn_frontdoor_endpoint.this[0].host_name : null
    frontend_apex_host             = local.frontdoor_apex_host_name
    frontend_www_host              = local.frontdoor_www_host_name
    postgres_database_url_template = "postgresql+psycopg://${var.postgres_admin_login}:<postgres_admin_password>@${module.postgres.fqdn}:5432/${module.postgres.database_name}?sslmode=require"
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
    email_domain_verification_records     = module.email_delivery.email_domain_verification_records
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
