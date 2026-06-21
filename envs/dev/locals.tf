locals {
  name           = lower("${var.prefix}-${var.environment}")
  compact_name   = substr(replace(lower("${var.prefix}${var.environment}"), "-", ""), 0, 18)
  frontend_repo  = "${data.azurerm_container_registry.global_shared.login_server}/spend-control-frontend"
  identity_repo  = "${data.azurerm_container_registry.global_shared.login_server}/spend-control-identity"
  finance_repo   = "${data.azurerm_container_registry.global_shared.login_server}/spend-control-finance"
  documents_repo = "${data.azurerm_container_registry.global_shared.login_server}/spend-control-documents"

  backend_audience           = "api://${local.name}-api"
  github_repository          = "${var.github_repository_owner}/${var.github_repository_name}"
  github_actions_oidc_issuer = "https://token.actions.githubusercontent.com"
  argocd_server_service_name = "argocd-server"
  key_vault_name             = trimspace(var.key_vault_name) != "" ? trimspace(var.key_vault_name) : substr("${local.name}-kv", 0, 24)
  frontend_redirect_uris = distinct(
    concat(
      var.frontend_redirect_uris,
      trimspace(var.public_host_name) != "" ? ["https://${trimspace(var.public_host_name)}/login"] : [],
    )
  )

  tags = merge(
    {
      application = "spend-control"
      environment = var.environment
      managed_by  = "terraform"
      stack       = "aks"
    },
    var.tags,
  )
}
