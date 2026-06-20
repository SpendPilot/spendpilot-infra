output "resource_group_name" {
  value = module.resource_group.name
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
