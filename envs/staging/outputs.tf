output "resource_group_name" {
  value = var.deploy_runtime_resources ? module.resource_group[0].name : null
}

output "public_host_name" {
  value = var.public_host_name
}

output "shared_ai_contract" {
  value = data.terraform_remote_state.nonprod_shared.outputs.shared_ai_contract
}

output "document_intelligence_endpoint" {
  value = data.terraform_remote_state.nonprod_shared.outputs.shared_document_intelligence_endpoint
}

output "foundry_endpoint" {
  value = data.terraform_remote_state.nonprod_shared.outputs.shared_foundry_endpoint
}

output "frontdoor_origin_contract" {
  value = {
    environment          = var.environment
    origin_hostname      = trimspace(var.frontdoor_origin_hostname_override) != "" ? trimspace(var.frontdoor_origin_hostname_override) : (trimspace(var.gateway_public_hostname) != "" ? trimspace(var.gateway_public_hostname) : (trimspace(var.gateway_public_ip) != "" ? trimspace(var.gateway_public_ip) : null))
    origin_host_header   = trimspace(var.public_host_name) != "" ? trimspace(var.public_host_name) : (trimspace(var.frontdoor_origin_hostname_override) != "" ? trimspace(var.frontdoor_origin_hostname_override) : (trimspace(var.gateway_public_hostname) != "" ? trimspace(var.gateway_public_hostname) : (trimspace(var.gateway_public_ip) != "" ? trimspace(var.gateway_public_ip) : null)))
    gateway_public_ip    = trimspace(var.gateway_public_ip) != "" ? trimspace(var.gateway_public_ip) : null
    gateway_public_fqdn  = trimspace(var.gateway_public_hostname) != "" ? trimspace(var.gateway_public_hostname) : null
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
    service_bus_fully_qualified_namespace = var.deploy_runtime_resources ? module.email_delivery[0].service_bus_fully_qualified_namespace : null
    service_bus_queue_name                = var.deploy_runtime_resources ? module.email_delivery[0].service_bus_queue_name : null
    function_app_name                     = var.deploy_runtime_resources ? module.email_delivery[0].function_app_name : null
    function_app_default_hostname         = var.deploy_runtime_resources ? module.email_delivery[0].function_app_default_hostname : null
    communication_service_endpoint        = var.deploy_runtime_resources ? module.email_delivery[0].communication_service_endpoint : null
    email_sender_address                  = var.deploy_runtime_resources ? module.email_delivery[0].email_sender_address : null
  }
}

output "service_bus_fully_qualified_namespace" {
  value = var.deploy_runtime_resources ? module.email_delivery[0].service_bus_fully_qualified_namespace : null
}

output "service_bus_queue_name" {
  value = var.deploy_runtime_resources ? module.email_delivery[0].service_bus_queue_name : null
}

output "email_sender_function_app_name" {
  value = var.deploy_runtime_resources ? module.email_delivery[0].function_app_name : null
}

output "email_sender_address" {
  value = var.deploy_runtime_resources ? module.email_delivery[0].email_sender_address : null
}
