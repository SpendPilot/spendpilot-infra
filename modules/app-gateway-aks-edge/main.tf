resource "azurerm_public_ip" "this" {
  name                = "${var.name}-pip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.zones
  tags                = var.tags
}

resource "azurerm_web_application_firewall_policy" "this" {
  name                = "${var.name}-waf"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  policy_settings {
    enabled                     = true
    mode                        = var.waf_mode
    request_body_check          = true
    file_upload_limit_in_mb     = 100
    max_request_body_size_in_kb = 128
  }

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = var.waf_rule_set_version
    }
  }
}

resource "azurerm_application_gateway" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  zones               = var.zones
  tags                = var.tags
  firewall_policy_id  = azurerm_web_application_firewall_policy.this.id

  dynamic "identity" {
    for_each = length(var.identity_ids) > 0 ? [1] : []

    content {
      type         = "UserAssigned"
      identity_ids = var.identity_ids
    }
  }

  sku {
    name = "WAF_v2"
    tier = "WAF_v2"
  }

  autoscale_configuration {
    min_capacity = var.min_capacity
    max_capacity = var.max_capacity
  }

  gateway_ip_configuration {
    name      = "gateway-ip-config"
    subnet_id = var.subnet_id
  }

  frontend_ip_configuration {
    name                 = "public-frontend"
    public_ip_address_id = azurerm_public_ip.this.id
  }

  frontend_port {
    name = "http"
    port = 80
  }

  dynamic "frontend_port" {
    for_each = trimspace(var.tls_certificate_secret_id) != "" && trimspace(var.tls_host_name) != "" ? [1] : []

    content {
      name = "https"
      port = 443
    }
  }

  backend_address_pool {
    name         = "gateway-pool"
    ip_addresses = var.backend_ip_addresses
  }

  backend_http_settings {
    name                  = "gateway-http"
    cookie_based_affinity = "Disabled"
    path                  = "/"
    port                  = var.backend_port
    protocol              = var.backend_protocol
    request_timeout       = 60
    probe_name            = "gateway-probe"
  }

  probe {
    name                                      = "gateway-probe"
    protocol                                  = var.backend_protocol
    path                                      = var.probe_path
    host                                      = trimspace(var.probe_host) != "" ? trimspace(var.probe_host) : var.backend_ip_addresses[0]
    interval                                  = 30
    timeout                                   = 30
    unhealthy_threshold                       = 3
    pick_host_name_from_backend_http_settings = false

    match {
      status_code = ["200-399"]
    }
  }

  http_listener {
    name                           = "http-listener"
    frontend_ip_configuration_name = "public-frontend"
    frontend_port_name             = "http"
    protocol                       = "Http"
    host_name                      = trimspace(var.listener_host_name) != "" ? trimspace(var.listener_host_name) : null
  }

  dynamic "ssl_certificate" {
    for_each = trimspace(var.tls_certificate_secret_id) != "" && trimspace(var.tls_host_name) != "" ? [1] : []

    content {
      name                = "https-cert"
      key_vault_secret_id = var.tls_certificate_secret_id
    }
  }

  dynamic "http_listener" {
    for_each = trimspace(var.tls_certificate_secret_id) != "" && trimspace(var.tls_host_name) != "" ? [1] : []

    content {
      name                           = "https-listener"
      frontend_ip_configuration_name = "public-frontend"
      frontend_port_name             = "https"
      protocol                       = "Https"
      host_name                      = var.tls_host_name
      ssl_certificate_name           = "https-cert"
      require_sni                    = true
    }
  }

  dynamic "http_listener" {
    for_each = trimspace(var.tls_certificate_secret_id) != "" && trimspace(var.tls_host_name) != "" ? [1] : []

    content {
      name                           = "http-redirect-listener"
      frontend_ip_configuration_name = "public-frontend"
      frontend_port_name             = "http"
      protocol                       = "Http"
      host_name                      = var.tls_host_name
    }
  }

  dynamic "redirect_configuration" {
    for_each = trimspace(var.tls_certificate_secret_id) != "" && trimspace(var.tls_host_name) != "" ? [1] : []

    content {
      name                 = "http-to-https"
      redirect_type        = "Permanent"
      target_listener_name = "https-listener"
      include_path         = true
      include_query_string = true
    }
  }

  request_routing_rule {
    name                       = "bootstrap-rule"
    rule_type                  = "Basic"
    http_listener_name         = "http-listener"
    backend_address_pool_name  = "gateway-pool"
    backend_http_settings_name = "gateway-http"
    priority                   = 100
  }

  dynamic "request_routing_rule" {
    for_each = trimspace(var.tls_certificate_secret_id) != "" && trimspace(var.tls_host_name) != "" ? [1] : []

    content {
      name                       = "https-route"
      rule_type                  = "Basic"
      http_listener_name         = "https-listener"
      backend_address_pool_name  = "gateway-pool"
      backend_http_settings_name = "gateway-http"
      priority                   = var.https_rule_priority
    }
  }

  dynamic "request_routing_rule" {
    for_each = trimspace(var.tls_certificate_secret_id) != "" && trimspace(var.tls_host_name) != "" ? [1] : []

    content {
      name                        = "http-redirect-route"
      rule_type                   = "Basic"
      http_listener_name          = "http-redirect-listener"
      redirect_configuration_name = "http-to-https"
      priority                    = var.http_redirect_priority
    }
  }
}
