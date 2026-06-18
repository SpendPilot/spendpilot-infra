locals {
  name         = lower("${var.prefix}-${var.environment}")
  compact_name = substr(replace(lower("${var.prefix}${var.environment}"), "-", ""), 0, 18)
  rg_name      = var.resource_group_name

  aks_context_name         = "${local.name}-aks"
  database_url             = "postgresql+psycopg://${var.postgres_admin_login}:${var.postgres_admin_password}@${module.postgres.fqdn}:5432/${module.postgres.database_name}?sslmode=require"
  key_vault_name           = trimspace(var.key_vault_name) != "" ? trimspace(var.key_vault_name) : substr("${local.name}-kv", 0, 24)
  frontdoor_enabled        = var.frontdoor_enabled
  frontdoor_apex_host_name = trimspace(var.frontdoor_apex_host_name)
  frontdoor_www_host_name  = trimspace(var.frontdoor_www_host_name)
  frontend_redirect_uris = distinct(
    concat(
      var.frontend_redirect_uris,
      local.frontdoor_enabled ? ["https://${azurerm_cdn_frontdoor_endpoint.this[0].host_name}/login"] : [],
      local.frontdoor_apex_host_name != "" ? ["https://${local.frontdoor_apex_host_name}/login"] : [],
      local.frontdoor_www_host_name != "" ? ["https://${local.frontdoor_www_host_name}/login"] : [],
    )
  )

  argocd_server_service_name = "argocd-server"

  tags = merge(
    {
      application = "spendpilot"
      environment = var.environment
      managed_by  = "terraform"
      stack       = "platform-bootstrap"
    },
    var.tags,
  )
}
