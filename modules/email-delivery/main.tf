locals {
  normalized_name               = lower(var.name)
  service_bus_namespace_name    = substr("${replace(local.normalized_name, "-", "")}sb", 0, 50)
  email_service_name            = substr("${local.normalized_name}-email", 0, 63)
  communication_service_name    = substr("${local.normalized_name}-comm", 0, 63)
  function_storage_account_name = substr(replace("${local.normalized_name}funcst", "-", ""), 0, 24)
  function_plan_name            = substr("${local.normalized_name}-func-plan", 0, 40)
  function_app_name             = substr("${local.normalized_name}-email-func", 0, 60)
  sender_username_normalized    = replace(var.function_sender_username, " ", "")
  sender_address                = "${local.sender_username_normalized}@${azurerm_email_communication_service_domain.this.from_sender_domain}"
  backend_sender_principal_id   = trimspace(var.backend_sender_principal_id)
  github_actions_principal_id   = trimspace(var.github_actions_principal_id)
}

moved {
  from = azurerm_communication_service_email_domain_association.this
  to   = azurerm_communication_service_email_domain_association.this[0]
}

resource "azurerm_servicebus_namespace" "this" {
  name                = local.service_bus_namespace_name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.service_bus_sku
  tags                = var.tags
}

resource "azurerm_servicebus_queue" "email_requests" {
  name         = var.queue_name
  namespace_id = azurerm_servicebus_namespace.this.id

  requires_duplicate_detection            = true
  duplicate_detection_history_time_window = var.duplicate_detection_history_time_window
  dead_lettering_on_message_expiration    = true
  max_delivery_count                      = 10
}

resource "azurerm_email_communication_service" "this" {
  name                = local.email_service_name
  resource_group_name = var.resource_group_name
  data_location       = var.email_data_location
  tags                = var.tags
}

resource "azurerm_email_communication_service_domain" "this" {
  name                             = var.email_domain_name
  email_service_id                 = azurerm_email_communication_service.this.id
  domain_management                = var.email_domain_management
  user_engagement_tracking_enabled = var.email_user_engagement_tracking_enabled
}

resource "azurerm_email_communication_service_domain_sender_username" "this" {
  name                    = local.sender_username_normalized
  email_service_domain_id = azurerm_email_communication_service_domain.this.id
  display_name            = var.function_sender_display_name
}

resource "azurerm_communication_service" "this" {
  name                = local.communication_service_name
  resource_group_name = var.resource_group_name
  data_location       = var.email_data_location
  tags                = var.tags
}

resource "azurerm_communication_service_email_domain_association" "this" {
  count = var.manage_email_domain_association ? 1 : 0

  communication_service_id = azurerm_communication_service.this.id
  email_service_domain_id  = azurerm_email_communication_service_domain.this.id
}

resource "azurerm_storage_account" "function" {
  name                            = local.function_storage_account_name
  resource_group_name             = var.resource_group_name
  location                        = var.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  https_traffic_only_enabled      = true
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  public_network_access_enabled   = true
  shared_access_key_enabled       = true
  tags                            = var.tags
}

resource "azurerm_service_plan" "function" {
  name                = local.function_plan_name
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = var.function_plan_os_type
  sku_name            = var.function_plan_sku_name
  tags                = var.tags
}

resource "azurerm_linux_function_app" "this" {
  name                        = local.function_app_name
  location                    = var.location
  resource_group_name         = var.resource_group_name
  service_plan_id             = azurerm_service_plan.function.id
  storage_account_name        = azurerm_storage_account.function.name
  storage_account_access_key  = azurerm_storage_account.function.primary_access_key
  functions_extension_version = var.function_extension_version
  https_only                  = true
  builtin_logging_enabled     = false
  tags                        = var.tags

  identity {
    type = "SystemAssigned"
  }

  app_settings = {
    FUNCTIONS_WORKER_RUNTIME                       = var.function_worker_runtime
    AzureWebJobsFeatureFlags                       = "EnableWorkerIndexing"
    ENABLE_ORYX_BUILD                              = "true"
    SCM_DO_BUILD_DURING_DEPLOYMENT                 = "true"
    EMAIL_SERVICE_BUS_QUEUE_NAME                   = azurerm_servicebus_queue.email_requests.name
    SERVICEBUS_CONNECTION                          = azurerm_servicebus_namespace.this.default_primary_connection_string
    SERVICEBUS_CONNECTION__fullyQualifiedNamespace = azurerm_servicebus_namespace.this.name != "" ? "${azurerm_servicebus_namespace.this.name}.servicebus.windows.net" : ""
    ACS_EMAIL_CONNECTION_STRING                    = azurerm_communication_service.this.primary_connection_string
    ACS_EMAIL_ENDPOINT                             = "https://${azurerm_communication_service.this.hostname}"
    ACS_EMAIL_SENDER_ADDRESS                       = local.sender_address
  }

  site_config {
    application_stack {
      python_version = var.function_python_version
    }
  }

  lifecycle {
    ignore_changes = [
      app_settings["WEBSITE_ENABLE_SYNC_UPDATE_SITE"],
      app_settings["WEBSITE_RUN_FROM_PACKAGE"],
    ]
  }
}

resource "azurerm_role_assignment" "backend_sender" {
  count = local.backend_sender_principal_id != "" ? 1 : 0

  scope                = azurerm_servicebus_namespace.this.id
  role_definition_name = "Azure Service Bus Data Sender"
  principal_id         = local.backend_sender_principal_id
}

resource "azurerm_role_assignment" "function_receiver" {
  scope                = azurerm_servicebus_namespace.this.id
  role_definition_name = "Azure Service Bus Data Receiver"
  principal_id         = azurerm_linux_function_app.this.identity[0].principal_id
}

resource "azurerm_role_assignment" "github_actions_function_contributor" {
  count = local.github_actions_principal_id != "" ? 1 : 0

  scope                            = azurerm_linux_function_app.this.id
  role_definition_name             = "Contributor"
  principal_id                     = local.github_actions_principal_id
  skip_service_principal_aad_check = true
}
