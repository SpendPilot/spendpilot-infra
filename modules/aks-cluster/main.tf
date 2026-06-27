resource "azurerm_kubernetes_cluster" "this" {
  name                                = var.name
  location                            = var.location
  resource_group_name                 = var.resource_group_name
  node_resource_group                 = var.node_resource_group_name
  dns_prefix                          = var.dns_prefix
  kubernetes_version                  = var.kubernetes_version
  sku_tier                            = "Standard"
  private_cluster_enabled             = var.private_cluster_enabled
  private_cluster_public_fqdn_enabled = var.private_cluster_public_fqdn_enabled
  private_dns_zone_id                 = var.private_dns_zone_id
  oidc_issuer_enabled                 = true
  workload_identity_enabled           = true
  image_cleaner_enabled               = true
  image_cleaner_interval_hours        = 48
  azure_policy_enabled                = true
  role_based_access_control_enabled   = true
  tags                                = var.tags

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
    type         = var.cluster_identity_type
    identity_ids = var.cluster_identity_type == "UserAssigned" ? var.cluster_identity_ids : null
  }

  oms_agent {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  dynamic "key_vault_secrets_provider" {
    for_each = var.key_vault_secrets_provider_enabled ? [1] : []

    content {
      secret_rotation_enabled  = var.secret_rotation_enabled
      secret_rotation_interval = var.secret_rotation_interval
    }
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
    for_each = (
      length(var.authorized_ip_ranges) > 0 ||
      var.api_server_subnet_id != null ||
      var.api_server_vnet_integration_enabled != null
    ) ? [1] : []

    content {
      authorized_ip_ranges                = length(var.authorized_ip_ranges) > 0 ? var.authorized_ip_ranges : null
      subnet_id                           = var.api_server_subnet_id
      virtual_network_integration_enabled = var.api_server_vnet_integration_enabled
    }
  }

  dynamic "monitor_metrics" {
    for_each = var.monitor_metrics_enabled == true ? [1] : []

    content {
      annotations_allowed = var.monitor_metrics_annotations_allowed
      labels_allowed      = var.monitor_metrics_labels_allowed
    }
  }

  lifecycle {
    # Prod migrates the control plane identity in place via Azure CLI because API server VNet integration
    # requires a user-assigned identity and the native provider path attempts destructive replacement.
    ignore_changes = [identity]
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
