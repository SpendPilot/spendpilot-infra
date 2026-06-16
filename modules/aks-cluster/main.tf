resource "azurerm_kubernetes_cluster" "this" {
  name                              = var.name
  location                          = var.location
  resource_group_name               = var.resource_group_name
  node_resource_group               = var.node_resource_group_name
  dns_prefix                        = var.dns_prefix
  kubernetes_version                = var.kubernetes_version
  sku_tier                          = "Standard"
  private_cluster_enabled           = var.private_cluster_enabled
  oidc_issuer_enabled               = true
  workload_identity_enabled         = true
  image_cleaner_enabled             = true
  image_cleaner_interval_hours      = 48
  azure_policy_enabled              = true
  role_based_access_control_enabled = true
  tags                              = var.tags

  default_node_pool {
    name                 = "system"
    vm_size              = var.system_node_vm_size
    auto_scaling_enabled = true
    min_count            = var.system_node_min_count
    max_count            = var.system_node_max_count
    vnet_subnet_id       = var.system_subnet_id
    orchestrator_version = var.kubernetes_version
    max_pods             = 50

    upgrade_settings {
      max_surge = "33%"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  oms_agent {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    load_balancer_sku   = "standard"
    outbound_type       = "loadBalancer"
    service_cidr        = var.service_cidr
    dns_service_ip      = var.dns_service_ip
  }

  dynamic "api_server_access_profile" {
    for_each = var.private_cluster_enabled || length(var.authorized_ip_ranges) == 0 ? [] : [1]

    content {
      authorized_ip_ranges = var.authorized_ip_ranges
    }
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "apps" {
  name                  = "apps"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  vm_size               = var.user_node_vm_size
  mode                  = "User"
  auto_scaling_enabled  = true
  min_count             = var.user_node_min_count
  max_count             = var.user_node_max_count
  vnet_subnet_id        = var.user_subnet_id
  orchestrator_version  = var.kubernetes_version
  max_pods              = 50
  tags                  = var.tags

  upgrade_settings {
    max_surge = "10%"
  }
}
