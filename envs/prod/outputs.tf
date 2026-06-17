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

output "backend_api_audience" {
  value = "api://${azuread_application.backend_api.client_id}"
}

output "backend_api_scope" {
  value = "api://${azuread_application.backend_api.client_id}/access_as_user"
}

output "frontend_client_id" {
  value = azuread_application.frontend_spa.client_id
}

output "backend_client_id" {
  value = azuread_application.backend_api.client_id
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
    auth_backend_audience          = "api://${azuread_application.backend_api.client_id}"
    auth_api_scope                 = "api://${azuread_application.backend_api.client_id}/access_as_user"
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
    postgres_database_url_template = "postgresql+psycopg://${var.postgres_admin_login}:<postgres_admin_password>@${module.postgres.fqdn}:5432/${module.postgres.database_name}?sslmode=require"
  }
}
