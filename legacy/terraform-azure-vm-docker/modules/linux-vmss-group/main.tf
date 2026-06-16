resource "azurerm_linux_virtual_machine_scale_set" "this" {
  name                            = var.name
  resource_group_name             = var.resource_group_name
  location                        = var.location
  sku                             = var.vm_size
  instances                       = var.min_instances
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = false
  overprovision                   = false
  upgrade_mode                    = "Manual"
  zones                           = var.zones
  zone_balance                    = length(var.zones) > 1
  computer_name_prefix            = substr(replace(var.name, "-", ""), 0, 9)
  tags                            = var.tags

  identity {
    type = "SystemAssigned"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  network_interface {
    name    = "${var.name}-nic"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = var.subnet_id

      application_gateway_backend_address_pool_ids = var.application_gateway_backend_pool_ids
      load_balancer_backend_address_pool_ids       = var.load_balancer_backend_address_pool_ids
    }
  }

  custom_data = base64encode(templatefile("${path.module}/templates/install-docker.tftpl", {
    admin_username                = var.admin_username
    node_role                     = var.node_role
    ollama_enabled                = var.ollama_enabled
    ollama_image                  = var.ollama_image
    ollama_model                  = var.ollama_model
    ollama_port                   = var.ollama_port
    bootstrap_repo_owner          = var.bootstrap_repo_owner
    bootstrap_repo_branch         = var.bootstrap_repo_branch
    bootstrap_app_env             = var.bootstrap_app_env
    bootstrap_public_api_base_url = var.bootstrap_public_api_base_url
    bootstrap_public_base_url     = var.bootstrap_public_base_url
    bootstrap_database_url        = var.bootstrap_database_url
    bootstrap_database_host       = var.bootstrap_database_host
    bootstrap_database_port       = var.bootstrap_database_port
    bootstrap_ollama_base_url     = var.bootstrap_ollama_base_url
    bootstrap_jwt_secret_key      = var.bootstrap_jwt_secret_key
    bootstrap_expense_service_url = var.bootstrap_expense_service_url
    bootstrap_ai_service_url      = var.bootstrap_ai_service_url
    bootstrap_receipt_threshold   = var.bootstrap_receipt_threshold
    bootstrap_upload_dir          = var.bootstrap_upload_dir
    bootstrap_ollama_timeout      = var.bootstrap_ollama_timeout
  }))
}

resource "azurerm_monitor_autoscale_setting" "this" {
  name                = "${var.name}-autoscale"
  resource_group_name = var.resource_group_name
  location            = var.location
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.this.id
  tags                = var.tags

  profile {
    name = "default"

    capacity {
      default = tostring(var.min_instances)
      minimum = tostring(var.min_instances)
      maximum = tostring(var.max_instances)
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.this.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = var.scale_out_cpu_threshold
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.this.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT10M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = var.scale_in_cpu_threshold
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT10M"
      }
    }
  }
}
