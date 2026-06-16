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

  backend_address_pool {
    name = "frontend-pool"
  }

  backend_address_pool {
    name = "api-pool"
  }

  backend_address_pool {
    name = "static-pool"
  }

  backend_http_settings {
    name                  = "frontend-http"
    cookie_based_affinity = "Disabled"
    port                  = var.frontend_backend_port
    protocol              = "Http"
    request_timeout       = 60
    probe_name            = "frontend-probe"
  }

  backend_http_settings {
    name                  = "api-http"
    cookie_based_affinity = "Disabled"
    port                  = var.api_backend_port
    protocol              = "Http"
    request_timeout       = 60
    probe_name            = "api-probe"
  }

  backend_http_settings {
    name                  = "static-http"
    cookie_based_affinity = "Disabled"
    port                  = var.static_backend_port
    protocol              = "Http"
    request_timeout       = 60
    probe_name            = "static-probe"
  }

  probe {
    name                                      = "frontend-probe"
    protocol                                  = "Http"
    path                                      = "/"
    host                                      = "127.0.0.1"
    interval                                  = 30
    timeout                                   = 30
    unhealthy_threshold                       = 3
    pick_host_name_from_backend_http_settings = false

    match {
      status_code = ["200-399"]
    }
  }

  probe {
    name                                      = "api-probe"
    protocol                                  = "Http"
    path                                      = "/health"
    host                                      = "127.0.0.1"
    interval                                  = 30
    timeout                                   = 30
    unhealthy_threshold                       = 3
    pick_host_name_from_backend_http_settings = false

    match {
      status_code = ["200-399"]
    }
  }

  probe {
    name                                      = "static-probe"
    protocol                                  = "Http"
    path                                      = "/"
    host                                      = "127.0.0.1"
    interval                                  = 30
    timeout                                   = 30
    unhealthy_threshold                       = 3
    pick_host_name_from_backend_http_settings = false

    match {
      status_code = ["200-399"]
    }
  }

  http_listener {
    name                           = "primary-http-listener"
    frontend_ip_configuration_name = "public-frontend"
    frontend_port_name             = "http"
    protocol                       = "Http"
    host_name                      = var.primary_host_name
  }

  http_listener {
    name                           = "static-http-listener"
    frontend_ip_configuration_name = "public-frontend"
    frontend_port_name             = "http"
    protocol                       = "Http"
    host_name                      = var.static_host_name
  }

  url_path_map {
    name                               = "spendpilot-path-map"
    default_backend_address_pool_name  = "frontend-pool"
    default_backend_http_settings_name = "frontend-http"

    path_rule {
      name                       = "api-rule"
      paths                      = ["/api/*"]
      backend_address_pool_name  = "api-pool"
      backend_http_settings_name = "api-http"
    }
  }

  request_routing_rule {
    name               = "primary-path-routing-rule"
    rule_type          = "PathBasedRouting"
    http_listener_name = "primary-http-listener"
    url_path_map_name  = "spendpilot-path-map"
    priority           = 100
  }

  request_routing_rule {
    name                       = "static-host-routing-rule"
    rule_type                  = "Basic"
    http_listener_name         = "static-http-listener"
    backend_address_pool_name  = "static-pool"
    backend_http_settings_name = "static-http"
    priority                   = 110
  }
}
