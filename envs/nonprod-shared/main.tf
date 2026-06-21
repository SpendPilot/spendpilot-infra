locals {
  name                                        = lower("${var.prefix}-${var.environment}")
  alnum_name                                  = replace(local.name, "-", "")
  compact_name                                = substr(replace(lower("${var.prefix}${var.environment}"), "-", ""), 0, 32)
  document_intelligence_account_name          = trimspace(var.document_intelligence_account_name) != "" ? trimspace(var.document_intelligence_account_name) : "${local.name}-docint"
  document_intelligence_custom_subdomain_name = trimspace(var.document_intelligence_custom_subdomain_name) != "" ? trimspace(var.document_intelligence_custom_subdomain_name) : substr("${local.compact_name}doc", 0, 63)
  foundry_account_name                        = trimspace(var.foundry_account_name) != "" ? trimspace(var.foundry_account_name) : "${local.name}-foundry"
  foundry_custom_subdomain_name               = trimspace(var.foundry_custom_subdomain_name) != "" ? trimspace(var.foundry_custom_subdomain_name) : substr("${local.compact_name}ai", 0, 63)
  tags = merge({
    application = "spendpilot"
    environment = var.environment
    managed_by  = "terraform"
    scope       = "nonprod-shared"
  }, var.tags)
}

data "terraform_remote_state" "dev" {
  count   = var.read_dev_state ? 1 : 0
  backend = "azurerm"

  config = {
    resource_group_name  = var.backend_resource_group_name
    storage_account_name = var.backend_storage_account_name
    container_name       = var.backend_container_name
    key                  = var.dev_state_key
  }
}

data "terraform_remote_state" "staging" {
  count   = var.read_staging_state ? 1 : 0
  backend = "azurerm"

  config = {
    resource_group_name  = var.backend_resource_group_name
    storage_account_name = var.backend_storage_account_name
    container_name       = var.backend_container_name
    key                  = var.staging_state_key
  }
}

locals {
  dev_origin_contract     = var.read_dev_state ? try(data.terraform_remote_state.dev[0].outputs.frontdoor_origin_contract, null) : null
  staging_origin_contract = var.read_staging_state ? try(data.terraform_remote_state.staging[0].outputs.frontdoor_origin_contract, null) : null
  dev_origin_hostname     = try(trimspace(local.dev_origin_contract.origin_hostname), "")
  staging_origin_hostname = try(trimspace(local.staging_origin_contract.origin_hostname), "")
  has_dev_origin          = local.dev_origin_hostname != ""
  has_staging_origin      = local.staging_origin_hostname != ""
}

module "resource_group" {
  source = "../../modules/resource-group"

  name     = var.resource_group_name
  location = var.location
  tags     = local.tags
}

resource "azurerm_cognitive_account" "document_intelligence" {
  name                          = local.document_intelligence_account_name
  location                      = module.resource_group.location
  resource_group_name           = module.resource_group.name
  kind                          = "FormRecognizer"
  sku_name                      = var.document_intelligence_sku
  custom_subdomain_name         = local.document_intelligence_custom_subdomain_name
  public_network_access_enabled = true
  tags                          = local.tags
}

resource "azurerm_cognitive_account" "foundry" {
  name                          = local.foundry_account_name
  location                      = var.foundry_location
  resource_group_name           = module.resource_group.name
  kind                          = "AIServices"
  sku_name                      = var.foundry_sku_name
  custom_subdomain_name         = local.foundry_custom_subdomain_name
  public_network_access_enabled = true
  tags                          = local.tags
}

resource "azurerm_cognitive_deployment" "foundry_model" {
  name                 = replace(var.openai_model_name, ".", "-")
  cognitive_account_id = azurerm_cognitive_account.foundry.id

  model {
    format  = "OpenAI"
    name    = var.openai_model_name
    version = var.openai_model_version
  }

  sku {
    name     = var.openai_deployment_sku_name
    capacity = var.openai_deployment_capacity
  }
}

resource "azurerm_cdn_frontdoor_profile" "this" {
  count = var.frontdoor_enabled ? 1 : 0

  name                = "${local.name}-fd"
  resource_group_name = module.resource_group.name
  sku_name            = var.frontdoor_sku_name
  tags                = local.tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_cdn_frontdoor_endpoint" "this" {
  count = var.frontdoor_enabled ? 1 : 0

  name                     = "${local.name}-ep"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this[0].id

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_cdn_frontdoor_custom_domain" "dev" {
  count = var.frontdoor_enabled && trimspace(var.dev_public_host_name) != "" ? 1 : 0

  name                     = replace(var.dev_public_host_name, ".", "-")
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this[0].id
  host_name                = var.dev_public_host_name

  tls {
    certificate_type = "ManagedCertificate"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_cdn_frontdoor_custom_domain" "staging" {
  count = var.frontdoor_enabled && trimspace(var.staging_public_host_name) != "" ? 1 : 0

  name                     = replace(var.staging_public_host_name, ".", "-")
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this[0].id
  host_name                = var.staging_public_host_name

  tls {
    certificate_type = "ManagedCertificate"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_cdn_frontdoor_origin_group" "dev" {
  count = var.frontdoor_enabled && local.has_dev_origin ? 1 : 0

  name                     = "${local.name}-dev-og"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this[0].id
  session_affinity_enabled = false

  health_probe {
    interval_in_seconds = 30
    path                = try(local.dev_origin_contract.health_probe_path, "/health")
    protocol            = try(local.dev_origin_contract.origin_protocol, "Http")
    request_type        = "GET"
  }

  load_balancing {
    additional_latency_in_milliseconds = 0
    sample_size                        = 4
    successful_samples_required        = 3
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_cdn_frontdoor_origin_group" "staging" {
  count = var.frontdoor_enabled && local.has_staging_origin ? 1 : 0

  name                     = "${local.name}-staging-og"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this[0].id
  session_affinity_enabled = false

  health_probe {
    interval_in_seconds = 30
    path                = try(local.staging_origin_contract.health_probe_path, "/health")
    protocol            = try(local.staging_origin_contract.origin_protocol, "Http")
    request_type        = "GET"
  }

  load_balancing {
    additional_latency_in_milliseconds = 0
    sample_size                        = 4
    successful_samples_required        = 3
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_cdn_frontdoor_origin" "dev" {
  count = var.frontdoor_enabled && local.has_dev_origin ? 1 : 0

  name                           = "${local.name}-dev-origin"
  cdn_frontdoor_origin_group_id  = azurerm_cdn_frontdoor_origin_group.dev[0].id
  enabled                        = true
  host_name                      = local.dev_origin_hostname
  http_port                      = try(local.dev_origin_contract.http_port, 80)
  https_port                     = try(local.dev_origin_contract.https_port, 443)
  origin_host_header             = try(local.dev_origin_contract.origin_host_header, local.dev_origin_hostname)
  priority                       = 1
  weight                         = 1000
  certificate_name_check_enabled = false

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_cdn_frontdoor_origin" "staging" {
  count = var.frontdoor_enabled && local.has_staging_origin ? 1 : 0

  name                           = "${local.name}-staging-origin"
  cdn_frontdoor_origin_group_id  = azurerm_cdn_frontdoor_origin_group.staging[0].id
  enabled                        = true
  host_name                      = local.staging_origin_hostname
  http_port                      = try(local.staging_origin_contract.http_port, 80)
  https_port                     = try(local.staging_origin_contract.https_port, 443)
  origin_host_header             = try(local.staging_origin_contract.origin_host_header, local.staging_origin_hostname)
  priority                       = 1
  weight                         = 1000
  certificate_name_check_enabled = false

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_cdn_frontdoor_firewall_policy" "this" {
  count = var.frontdoor_enabled ? 1 : 0

  name                = "${local.alnum_name}waf"
  resource_group_name = module.resource_group.name
  sku_name            = var.frontdoor_sku_name
  enabled             = true
  mode                = "Prevention"
  tags                = local.tags

  managed_rule {
    type    = "DefaultRuleSet"
    version = "1.0"
    action  = "Block"
  }

  managed_rule {
    type    = "Microsoft_BotManagerRuleSet"
    version = "1.0"
    action  = "Block"
  }

  custom_rule {
    name                           = "AuthRateLimit"
    enabled                        = true
    priority                       = 1
    type                           = "RateLimitRule"
    action                         = "Block"
    rate_limit_duration_in_minutes = var.frontdoor_auth_rate_limit_duration_minutes
    rate_limit_threshold           = var.frontdoor_auth_rate_limit_threshold

    match_condition {
      match_variable = "RequestUri"
      operator       = "BeginsWith"
      match_values   = ["/api/auth"]
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_cdn_frontdoor_route" "dev" {
  count = var.frontdoor_enabled && local.has_dev_origin && length(azurerm_cdn_frontdoor_custom_domain.dev) > 0 ? 1 : 0

  name                          = "${local.name}-dev-route"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.this[0].id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.dev[0].id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.dev[0].id]
  cdn_frontdoor_custom_domain_ids = [
    azurerm_cdn_frontdoor_custom_domain.dev[0].id,
  ]
  enabled                = true
  forwarding_protocol    = try(local.dev_origin_contract.forwarding_protocol, "HttpOnly")
  https_redirect_enabled = true
  patterns_to_match      = ["/*"]
  supported_protocols    = ["Http", "Https"]
  link_to_default_domain = false

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_cdn_frontdoor_route" "staging" {
  count = var.frontdoor_enabled && local.has_staging_origin && length(azurerm_cdn_frontdoor_custom_domain.staging) > 0 ? 1 : 0

  name                          = "${local.name}-staging-route"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.this[0].id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.staging[0].id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.staging[0].id]
  cdn_frontdoor_custom_domain_ids = [
    azurerm_cdn_frontdoor_custom_domain.staging[0].id,
  ]
  enabled                = true
  forwarding_protocol    = try(local.staging_origin_contract.forwarding_protocol, "HttpOnly")
  https_redirect_enabled = true
  patterns_to_match      = ["/*"]
  supported_protocols    = ["Http", "Https"]
  link_to_default_domain = false

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_cdn_frontdoor_security_policy" "this" {
  count = var.frontdoor_enabled ? 1 : 0

  name                     = "${local.name}-security"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this[0].id

  security_policies {
    firewall {
      cdn_frontdoor_firewall_policy_id = azurerm_cdn_frontdoor_firewall_policy.this[0].id

      association {
        domain {
          cdn_frontdoor_domain_id = azurerm_cdn_frontdoor_endpoint.this[0].id
        }

        dynamic "domain" {
          for_each = toset(concat(
            azurerm_cdn_frontdoor_custom_domain.dev[*].id,
            azurerm_cdn_frontdoor_custom_domain.staging[*].id,
          ))

          content {
            cdn_frontdoor_domain_id = domain.value
          }
        }

        patterns_to_match = ["/*"]
      }
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}
