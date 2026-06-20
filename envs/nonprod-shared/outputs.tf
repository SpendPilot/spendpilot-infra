output "resource_group_name" {
  value = module.resource_group.name
}

output "shared_document_intelligence_id" {
  value = azurerm_cognitive_account.document_intelligence.id
}

output "shared_document_intelligence_name" {
  value = azurerm_cognitive_account.document_intelligence.name
}

output "shared_document_intelligence_endpoint" {
  value = azurerm_cognitive_account.document_intelligence.endpoint
}

output "shared_foundry_id" {
  value = azurerm_cognitive_account.foundry.id
}

output "shared_foundry_name" {
  value = azurerm_cognitive_account.foundry.name
}

output "shared_foundry_endpoint" {
  value = azurerm_cognitive_account.foundry.endpoint
}

output "shared_foundry_model_deployment_name" {
  value = azurerm_cognitive_deployment.foundry_model.name
}

output "shared_ai_contract" {
  value = {
    document_intelligence = {
      id       = azurerm_cognitive_account.document_intelligence.id
      name     = azurerm_cognitive_account.document_intelligence.name
      endpoint = azurerm_cognitive_account.document_intelligence.endpoint
    }
    foundry = {
      id                    = azurerm_cognitive_account.foundry.id
      name                  = azurerm_cognitive_account.foundry.name
      endpoint              = azurerm_cognitive_account.foundry.endpoint
      model_deployment_name = azurerm_cognitive_deployment.foundry_model.name
      model_name            = var.openai_model_name
      model_version         = var.openai_model_version
    }
  }
}

output "dev_origin_contract" {
  value = local.dev_origin_contract
}

output "staging_origin_contract" {
  value = local.staging_origin_contract
}

output "origin_contracts" {
  value = {
    dev     = local.dev_origin_contract
    staging = local.staging_origin_contract
  }
}

output "root_domain_name" {
  value = var.root_domain_name
}

output "nonprod_hostname_contract" {
  value = {
    dev_public_host_name     = var.dev_public_host_name
    staging_public_host_name = var.staging_public_host_name
  }
}

output "frontdoor_endpoint_hostname" {
  value = var.frontdoor_enabled && length(azurerm_cdn_frontdoor_endpoint.this) > 0 ? azurerm_cdn_frontdoor_endpoint.this[0].host_name : null
}

output "frontdoor_default_url" {
  value = var.frontdoor_enabled && length(azurerm_cdn_frontdoor_endpoint.this) > 0 ? "https://${azurerm_cdn_frontdoor_endpoint.this[0].host_name}" : null
}

output "dev_frontdoor_custom_domain_validation" {
  value = length(azurerm_cdn_frontdoor_custom_domain.dev) > 0 ? {
    host_name        = azurerm_cdn_frontdoor_custom_domain.dev[0].host_name
    resource_id      = azurerm_cdn_frontdoor_custom_domain.dev[0].id
    validation_token = azurerm_cdn_frontdoor_custom_domain.dev[0].validation_token
  } : null
}

output "staging_frontdoor_custom_domain_validation" {
  value = length(azurerm_cdn_frontdoor_custom_domain.staging) > 0 ? {
    host_name        = azurerm_cdn_frontdoor_custom_domain.staging[0].host_name
    resource_id      = azurerm_cdn_frontdoor_custom_domain.staging[0].id
    validation_token = azurerm_cdn_frontdoor_custom_domain.staging[0].validation_token
  } : null
}

output "frontdoor_route_status" {
  value = {
    dev_route_enabled     = length(azurerm_cdn_frontdoor_route.dev) > 0
    staging_route_enabled = length(azurerm_cdn_frontdoor_route.staging) > 0
  }
}
