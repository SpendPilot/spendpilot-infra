data "azurerm_client_config" "current" {}
data "azuread_client_config" "current" {}

data "terraform_remote_state" "global_shared" {
  backend = "azurerm"

  config = {
    resource_group_name  = var.backend_resource_group_name
    storage_account_name = var.backend_storage_account_name
    container_name       = var.backend_container_name
    key                  = var.global_shared_state_key
    subscription_id      = data.azurerm_client_config.current.subscription_id
    tenant_id            = data.azurerm_client_config.current.tenant_id
  }
}

data "azurerm_container_registry" "global_shared" {
  name                = data.terraform_remote_state.global_shared.outputs.acr_name
  resource_group_name = data.terraform_remote_state.global_shared.outputs.resource_group_name
}

data "terraform_remote_state" "identities" {
  backend = "azurerm"

  config = {
    resource_group_name  = var.backend_resource_group_name
    storage_account_name = var.backend_storage_account_name
    container_name       = var.backend_container_name
    key                  = var.identities_state_key
    subscription_id      = data.azurerm_client_config.current.subscription_id
    tenant_id            = data.azurerm_client_config.current.tenant_id
  }
}

module "resource_group" {
  source = "../../modules/resource-group"

  name     = var.resource_group_name
  location = var.location
  tags     = local.tags
}

module "log_analytics" {
  source = "../../modules/log-analytics"

  name                = "${local.name}-law"
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name
  tags                = local.tags
}

resource "azurerm_log_analytics_solution" "container_insights" {
  solution_name         = "ContainerInsights"
  location              = module.resource_group.location
  resource_group_name   = module.resource_group.name
  workspace_resource_id = module.log_analytics.id
  workspace_name        = module.log_analytics.name
  tags                  = local.tags

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }
}

module "network" {
  source = "../../modules/network"

  name                = "${local.name}-vnet"
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name
  address_space       = [var.vnet_cidr]
  tags                = local.tags

  subnets = {
    "aks-subnet" = {
      address_prefixes = [var.aks_subnet_cidr]
    }
    "db-subnet" = {
      address_prefixes   = [var.db_subnet_cidr]
      service_endpoints  = ["Microsoft.Storage"]
      delegation_name    = "postgres-flex"
      delegation_service = "Microsoft.DBforPostgreSQL/flexibleServers"
    }
  }
}

module "postgres" {
  source = "../../modules/postgres-flex"

  name                         = var.postgres_server_name
  resource_group_name          = module.resource_group.name
  location                     = module.resource_group.location
  server_version               = var.postgres_version
  delegated_subnet_id          = module.network.subnet_ids["db-subnet"]
  virtual_network_id           = module.network.virtual_network_id
  private_dns_zone_name        = "${local.name}.postgres.database.azure.com"
  administrator_login          = var.postgres_admin_login
  administrator_password       = var.postgres_admin_password
  storage_mb                   = var.postgres_storage_mb
  sku_name                     = var.postgres_sku_name
  zone                         = var.postgres_zone
  ha_mode                      = var.postgres_ha_mode
  ha_standby_zone              = var.postgres_ha_standby_zone
  geo_redundant_backup_enabled = var.postgres_geo_redundant_backup_enabled
  database_name                = var.postgres_database_name
  tags                         = local.tags
}

module "postgres_dr_network" {
  count  = var.postgres_dr_replica_enabled ? 1 : 0
  source = "../../modules/network"

  name                = "${local.name}-dr-vnet"
  location            = var.postgres_dr_location
  resource_group_name = module.resource_group.name
  address_space       = [var.postgres_dr_vnet_cidr]
  tags                = local.tags

  subnets = {
    "db-subnet" = {
      address_prefixes   = [var.postgres_dr_db_subnet_cidr]
      service_endpoints  = ["Microsoft.Storage"]
      delegation_name    = "postgres-flex"
      delegation_service = "Microsoft.DBforPostgreSQL/flexibleServers"
    }
  }
}

resource "azurerm_virtual_network_peering" "postgres_dr_from_primary" {
  count = var.postgres_dr_replica_enabled ? 1 : 0

  name                      = "${local.name}-to-dr"
  resource_group_name       = module.resource_group.name
  virtual_network_name      = module.network.virtual_network_name
  remote_virtual_network_id = module.postgres_dr_network[0].virtual_network_id
}

resource "azurerm_virtual_network_peering" "postgres_dr_to_primary" {
  count = var.postgres_dr_replica_enabled ? 1 : 0

  name                      = "${local.name}-dr-to-primary"
  resource_group_name       = module.resource_group.name
  virtual_network_name      = module.postgres_dr_network[0].virtual_network_name
  remote_virtual_network_id = module.network.virtual_network_id
}

resource "azurerm_private_dns_zone" "postgres_dr" {
  count = var.postgres_dr_replica_enabled ? 1 : 0

  name                = "${local.name}-dr.postgres.database.azure.com"
  resource_group_name = module.resource_group.name
  tags                = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgres_dr" {
  count = var.postgres_dr_replica_enabled ? 1 : 0

  name                  = "${local.name}-dr-vnet-link"
  private_dns_zone_name = azurerm_private_dns_zone.postgres_dr[0].name
  resource_group_name   = module.resource_group.name
  virtual_network_id    = module.postgres_dr_network[0].virtual_network_id
  tags                  = local.tags
}

resource "azurerm_postgresql_flexible_server" "postgres_dr_replica" {
  count = var.postgres_dr_replica_enabled ? 1 : 0

  name                          = trimspace(var.postgres_dr_replica_server_name) != "" ? trimspace(var.postgres_dr_replica_server_name) : "${var.postgres_server_name}-dr"
  resource_group_name           = module.resource_group.name
  location                      = var.postgres_dr_location
  create_mode                   = "Replica"
  source_server_id              = module.postgres.server_id
  delegated_subnet_id           = module.postgres_dr_network[0].subnet_ids["db-subnet"]
  private_dns_zone_id           = azurerm_private_dns_zone.postgres_dr[0].id
  public_network_access_enabled = false
  zone                          = trimspace(var.postgres_dr_zone) != "" ? trimspace(var.postgres_dr_zone) : null
  tags = merge(local.tags, {
    role = "postgres-dr-replica"
  })

  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.postgres_dr,
    azurerm_virtual_network_peering.postgres_dr_from_primary,
    azurerm_virtual_network_peering.postgres_dr_to_primary,
  ]
}

module "aks_cluster" {
  source = "../../modules/aks-cluster"

  name                               = "${local.name}-aks"
  location                           = module.resource_group.location
  resource_group_name                = module.resource_group.name
  dns_prefix                         = "${local.name}-dns"
  kubernetes_version                 = var.kubernetes_version
  private_cluster_enabled            = var.private_cluster_enabled
  authorized_ip_ranges               = var.authorized_ip_ranges
  log_analytics_workspace_id         = module.log_analytics.id
  system_subnet_id                   = module.network.subnet_ids["aks-subnet"]
  user_subnet_id                     = module.network.subnet_ids["aks-subnet"]
  system_node_vm_size                = var.system_node_vm_size
  system_node_min_count              = var.system_node_min_count
  system_node_max_count              = var.system_node_max_count
  user_node_vm_size                  = var.user_node_vm_size
  user_node_min_count                = var.user_node_min_count
  user_node_max_count                = var.user_node_max_count
  node_resource_group_name           = var.aks_node_resource_group_name
  service_cidr                       = var.service_cidr
  dns_service_ip                     = var.dns_service_ip
  key_vault_secrets_provider_enabled = var.key_vault_secrets_provider_enabled
  secret_rotation_enabled            = var.key_vault_secret_rotation_enabled
  secret_rotation_interval           = var.key_vault_secret_rotation_interval
  tags                               = local.tags

  depends_on = [azurerm_log_analytics_solution.container_insights]
}

resource "azurerm_role_assignment" "acr_pull" {
  scope                = data.azurerm_container_registry.global_shared.id
  role_definition_name = "AcrPull"
  principal_id         = module.aks_cluster.kubelet_object_id
}

resource "azurerm_user_assigned_identity" "workload" {
  name                = "${local.name}-uami"
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name
  tags                = local.tags
}

resource "azurerm_key_vault" "workload" {
  name                          = local.key_vault_name
  location                      = module.resource_group.location
  resource_group_name           = module.resource_group.name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = var.key_vault_sku_name
  rbac_authorization_enabled    = true
  public_network_access_enabled = var.key_vault_public_network_access_enabled
  purge_protection_enabled      = true
  soft_delete_retention_days    = 90
  tags                          = local.tags
}

resource "azurerm_subnet" "private_endpoints" {
  count = var.enable_key_vault_private_endpoint ? 1 : 0

  name                              = "private-endpoints-subnet"
  resource_group_name               = module.resource_group.name
  virtual_network_name              = module.network.virtual_network_name
  address_prefixes                  = [var.private_endpoint_subnet_cidr]
  private_endpoint_network_policies = "NetworkSecurityGroupEnabled"
}

resource "azurerm_network_security_group" "private_endpoints" {
  count = var.enable_key_vault_private_endpoint ? 1 : 0

  name                = "${local.name}-private-endpoints-nsg"
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name
  tags                = local.tags

  security_rule {
    name                       = "AllowAksToKeyVaultPrivateEndpointHttps"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = var.aks_subnet_cidr
    destination_address_prefix = var.private_endpoint_subnet_cidr
  }

  security_rule {
    name                       = "DenyOtherVnetTrafficToPrivateEndpoints"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = var.private_endpoint_subnet_cidr
  }
}

resource "azurerm_subnet_network_security_group_association" "private_endpoints" {
  count = var.enable_key_vault_private_endpoint ? 1 : 0

  subnet_id                 = azurerm_subnet.private_endpoints[0].id
  network_security_group_id = azurerm_network_security_group.private_endpoints[0].id
}

resource "azurerm_private_dns_zone" "key_vault" {
  count = var.enable_key_vault_private_endpoint ? 1 : 0

  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = module.resource_group.name
  tags                = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "key_vault" {
  count = var.enable_key_vault_private_endpoint ? 1 : 0

  name                  = "${local.name}-kv-vnet-link"
  resource_group_name   = module.resource_group.name
  private_dns_zone_name = azurerm_private_dns_zone.key_vault[0].name
  virtual_network_id    = module.network.virtual_network_id
  tags                  = local.tags
}

resource "azurerm_private_endpoint" "key_vault" {
  count = var.enable_key_vault_private_endpoint ? 1 : 0

  name                = "${local.name}-kv-pe"
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name
  subnet_id           = azurerm_subnet.private_endpoints[0].id
  tags                = local.tags

  private_service_connection {
    name                           = "${local.name}-kv-psc"
    private_connection_resource_id = azurerm_key_vault.workload.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.key_vault[0].id]
  }

  depends_on = [
    azurerm_subnet_network_security_group_association.private_endpoints,
    azurerm_private_dns_zone_virtual_network_link.key_vault,
  ]
}

resource "azurerm_federated_identity_credential" "workload" {
  name                      = "${local.name}-fic"
  user_assigned_identity_id = azurerm_user_assigned_identity.workload.id
  issuer                    = module.aks_cluster.oidc_issuer_url
  audience                  = ["api://AzureADTokenExchange"]
  subject                   = "system:serviceaccount:${var.namespace}:${var.service_account_name}"
}

resource "terraform_data" "aks_get_credentials" {
  triggers_replace = {
    cluster_name        = module.aks_cluster.name
    resource_group_name = module.resource_group.name
    kubeconfig_path     = "${path.root}/.generated-kubeconfig"
  }

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]
    command     = "az aks get-credentials --resource-group ${module.resource_group.name} --name ${module.aks_cluster.name} --admin --overwrite-existing --file ${path.root}/.generated-kubeconfig"
    environment = {
      AZURE_CLI_DISABLE_CONNECTION_VERIFICATION = "1"
    }
  }

  depends_on = [module.aks_cluster]
}

resource "kubernetes_namespace_v1" "spendpilot" {
  metadata {
    name = var.namespace
  }

  depends_on = [terraform_data.aks_get_credentials]
}

resource "kubernetes_service_account_v1" "workload" {
  metadata {
    name      = var.service_account_name
    namespace = kubernetes_namespace_v1.spendpilot.metadata[0].name
    annotations = {
      "azure.workload.identity/client-id" = azurerm_user_assigned_identity.workload.client_id
    }
  }

  depends_on = [
    terraform_data.aks_get_credentials,
    kubernetes_namespace_v1.spendpilot,
    azurerm_federated_identity_credential.workload,
  ]
}

resource "azurerm_storage_account" "documents" {
  name                            = var.documents_storage_account_name
  resource_group_name             = module.resource_group.name
  location                        = module.resource_group.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  public_network_access_enabled   = true
  https_traffic_only_enabled      = true
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  default_to_oauth_authentication = true
  shared_access_key_enabled       = true
  local_user_enabled              = false
  tags                            = local.tags
}

resource "azurerm_storage_container" "documents" {
  name                  = "expense-documents"
  storage_account_id    = azurerm_storage_account.documents.id
  container_access_type = "private"
}

resource "azurerm_cognitive_account" "document_intelligence" {
  name                          = var.document_intelligence_account_name
  location                      = module.resource_group.location
  resource_group_name           = module.resource_group.name
  kind                          = "FormRecognizer"
  sku_name                      = var.document_intelligence_sku
  custom_subdomain_name         = var.document_intelligence_custom_subdomain_name
  public_network_access_enabled = true
  tags                          = local.tags
}

resource "azurerm_cognitive_account" "foundry" {
  name                          = var.foundry_account_name
  location                      = var.foundry_location
  resource_group_name           = module.resource_group.name
  kind                          = "AIServices"
  sku_name                      = var.foundry_sku_name
  custom_subdomain_name         = var.foundry_custom_subdomain_name
  public_network_access_enabled = true
  tags                          = local.tags

  identity {
    type = "SystemAssigned"
  }

  lifecycle {
    ignore_changes = [
      project_management_enabled,
    ]
  }
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

resource "azurerm_role_assignment" "storage_blob_contributor" {
  scope                = azurerm_storage_account.documents.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.workload.principal_id
}

resource "azurerm_role_assignment" "docint_user" {
  scope                = azurerm_cognitive_account.document_intelligence.id
  role_definition_name = "Cognitive Services User"
  principal_id         = azurerm_user_assigned_identity.workload.principal_id
}

resource "azurerm_role_assignment" "foundry_user" {
  scope                = azurerm_cognitive_account.foundry.id
  role_definition_name = "Cognitive Services OpenAI User"
  principal_id         = azurerm_user_assigned_identity.workload.principal_id
}

resource "azurerm_role_assignment" "key_vault_secrets_user" {
  scope                = azurerm_key_vault.workload.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.workload.principal_id
}

resource "azurerm_role_assignment" "key_vault_secrets_officer_current_user" {
  scope                = azurerm_key_vault.workload.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "time_sleep" "wait_for_key_vault_rbac" {
  create_duration = "45s"

  depends_on = [
    azurerm_role_assignment.key_vault_secrets_user,
    azurerm_role_assignment.key_vault_secrets_officer_current_user,
  ]
}

module "email_delivery" {
  source = "../../modules/email-delivery"

  name                            = local.name
  location                        = module.resource_group.location
  resource_group_name             = module.resource_group.name
  tags                            = local.tags
  backend_sender_principal_id     = azurerm_user_assigned_identity.workload.principal_id
  github_actions_principal_id     = try(data.terraform_remote_state.identities.outputs.github_actions_service_principal_object_id, "")
  email_data_location             = var.email_data_location
  email_domain_name               = var.email_domain_name
  email_domain_management         = var.email_domain_management
  function_sender_username        = var.email_sender_username
  function_sender_display_name    = var.email_sender_display_name
  manage_email_domain_association = var.email_domain_association_enabled
}

resource "kubernetes_config_map_v1" "spendpilot" {
  metadata {
    name      = var.app_config_map_name
    namespace = kubernetes_namespace_v1.spendpilot.metadata[0].name
  }

  data = {
    APP_ENV                                     = "production"
    BACKEND_CORS_ORIGINS                        = var.backend_cors_origins
    AUTH_MODE                                   = "entra"
    AZURE_TENANT_ID                             = data.azurerm_client_config.current.tenant_id
    AZURE_CLIENT_ID                             = azurerm_user_assigned_identity.workload.client_id
    ENTRA_FRONTEND_CLIENT_ID                    = azuread_application.frontend_spa.client_id
    ENTRA_BACKEND_CLIENT_ID                     = azuread_application.backend_api.client_id
    ENTRA_BACKEND_AUDIENCE                      = var.backend_application_id_uri
    ENTRA_AUTHORITY                             = var.auth_authority
    ENTRA_ALLOWED_TENANT_IDS                    = var.allowed_tenant_ids
    PLATFORM_ADMIN_EMAILS                       = var.platform_admin_emails
    AZURE_AI_FOUNDRY_ENDPOINT                   = azurerm_cognitive_account.foundry.endpoint
    AZURE_AI_PROJECT_ENDPOINT                   = ""
    AZURE_AI_MODEL_DEPLOYMENT                   = azurerm_cognitive_deployment.foundry_model.name
    AZURE_DOCUMENT_INTELLIGENCE_ENDPOINT        = azurerm_cognitive_account.document_intelligence.endpoint
    AZURE_STORAGE_ACCOUNT_URL                   = azurerm_storage_account.documents.primary_blob_endpoint
    AZURE_STORAGE_CONTAINER_NAME                = azurerm_storage_container.documents.name
    EMAIL_NOTIFICATIONS_ENABLED                 = "true"
    AZURE_SERVICE_BUS_FULLY_QUALIFIED_NAMESPACE = module.email_delivery.service_bus_fully_qualified_namespace
    AZURE_SERVICE_BUS_QUEUE_NAME                = module.email_delivery.service_bus_queue_name
    FINANCE_DEFAULT_CURRENCY                    = var.finance_default_currency
    NEXT_PUBLIC_API_BASE_URL                    = var.frontend_api_base_url
    NEXT_PUBLIC_AUTH_MODE                       = "entra"
    NEXT_PUBLIC_ENTRA_FRONTEND_CLIENT_ID        = azuread_application.frontend_spa.client_id
    NEXT_PUBLIC_ENTRA_BACKEND_CLIENT_ID         = azuread_application.backend_api.client_id
    NEXT_PUBLIC_ENTRA_BACKEND_AUDIENCE          = var.backend_application_id_uri
    NEXT_PUBLIC_ENTRA_API_SCOPE                 = "${var.backend_application_id_uri}/access_as_user"
    NEXT_PUBLIC_ENTRA_AUTHORITY                 = var.auth_authority
  }

  depends_on = [
    terraform_data.aks_get_credentials,
    kubernetes_namespace_v1.spendpilot,
    azuread_application.frontend_spa,
    azuread_application.backend_api,
  ]
}

resource "azuread_application" "backend_api" {
  display_name     = "${local.name}-backend-api"
  sign_in_audience = "AzureADandPersonalMicrosoftAccount"
  identifier_uris  = [var.backend_application_id_uri]
  owners           = [data.azuread_client_config.current.object_id]

  api {
    requested_access_token_version = 2

    oauth2_permission_scope {
      id                         = uuidv5("dns", "${local.name}-access-as-user")
      admin_consent_description  = "Allow the frontend SPA to access the SpendPilot API."
      admin_consent_display_name = "Access SpendPilot API"
      enabled                    = true
      type                       = "User"
      user_consent_description   = "Allow the application to access your SpendPilot workspace."
      user_consent_display_name  = "Access SpendPilot"
      value                      = "access_as_user"
    }
  }

  app_role {
    allowed_member_types = ["User"]
    description          = "Platform-wide administration access."
    display_name         = "Platform Admin"
    enabled              = true
    id                   = uuidv5("dns", "${local.name}-platform-admin")
    value                = "platform_admin"
  }

  app_role {
    allowed_member_types = ["User"]
    description          = "Organization administration access."
    display_name         = "Organization Admin"
    enabled              = true
    id                   = uuidv5("dns", "${local.name}-org-admin")
    value                = "org_admin"
  }

  app_role {
    allowed_member_types = ["User"]
    description          = "Finance manager access."
    display_name         = "Finance Manager"
    enabled              = true
    id                   = uuidv5("dns", "${local.name}-finance-manager")
    value                = "finance_manager"
  }

  app_role {
    allowed_member_types = ["User"]
    description          = "Expense approval access."
    display_name         = "Approver"
    enabled              = true
    id                   = uuidv5("dns", "${local.name}-approver")
    value                = "approver"
  }

  app_role {
    allowed_member_types = ["User"]
    description          = "Read-only audit access."
    display_name         = "Auditor"
    enabled              = true
    id                   = uuidv5("dns", "${local.name}-auditor")
    value                = "auditor"
  }

  app_role {
    allowed_member_types = ["User"]
    description          = "Standard employee access."
    display_name         = "Employee"
    enabled              = true
    id                   = uuidv5("dns", "${local.name}-employee")
    value                = "employee"
  }

  lifecycle {
    ignore_changes = [owners, api[0].known_client_applications]
  }
}

resource "azuread_service_principal" "backend_api" {
  client_id = azuread_application.backend_api.client_id
}

resource "azuread_application" "frontend_spa" {
  display_name     = "${local.name}-frontend-spa"
  sign_in_audience = "AzureADandPersonalMicrosoftAccount"
  owners           = [data.azuread_client_config.current.object_id]

  api {
    requested_access_token_version = 2
  }

  single_page_application {
    redirect_uris = local.frontend_redirect_uris
  }

  required_resource_access {
    resource_app_id = azuread_application.backend_api.client_id

    resource_access {
      id   = uuidv5("dns", "${local.name}-access-as-user")
      type = "Scope"
    }
  }

  lifecycle {
    ignore_changes = [owners]
  }
}

resource "azuread_service_principal" "frontend_spa" {
  client_id = azuread_application.frontend_spa.client_id
}

resource "azuread_application_known_clients" "backend_known_frontend" {
  application_id   = azuread_application.backend_api.id
  known_client_ids = [azuread_application.frontend_spa.client_id]
}

resource "azuread_application_pre_authorized" "backend_pre_authorize_frontend" {
  application_id       = azuread_application.backend_api.id
  authorized_client_id = azuread_application.frontend_spa.client_id
  permission_ids       = [azuread_application.backend_api.oauth2_permission_scope_ids["access_as_user"]]
}

resource "terraform_data" "gateway_api_crds" {
  triggers_replace = {
    cluster_name        = module.aks_cluster.name
    gateway_api_version = var.gateway_api_version
  }

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]
    command     = "az aks command invoke --resource-group ${module.resource_group.name} --name ${module.aks_cluster.name} --command \"kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v${var.gateway_api_version}/standard-install.yaml\""
    environment = {
      AZURE_CLI_DISABLE_CONNECTION_VERIFICATION = "1"
    }
  }

  depends_on = [terraform_data.aks_get_credentials]
}

resource "helm_release" "kgateway_crds" {
  name      = "kgateway-crds"
  chart     = "${path.root}/../../vendor/kgateway/kgateway-crds"
  namespace = "kgateway-system"

  create_namespace = true

  depends_on = [
    terraform_data.aks_get_credentials,
    terraform_data.gateway_api_crds,
  ]
}

resource "helm_release" "kgateway" {
  name      = "kgateway"
  chart     = "${path.root}/../../vendor/kgateway/kgateway"
  namespace = "kgateway-system"

  create_namespace = true
  values = [
    yamlencode({
      image = {
        tag = var.kgateway_version
      }
      controller = {
        image = {
          tag = var.kgateway_version
        }
      }
    }),
  ]

  depends_on = [
    terraform_data.aks_get_credentials,
    helm_release.kgateway_crds,
  ]
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.argocd_chart_version
  namespace  = var.argocd_namespace

  create_namespace = true
  timeout          = 900
  wait             = true

  values = [
    yamlencode({
      server = {
        service = {
          type                     = var.argocd_server_service_type
          annotations              = var.argocd_server_service_annotations
          loadBalancerIP           = trimspace(var.argocd_server_load_balancer_ip) != "" ? trimspace(var.argocd_server_load_balancer_ip) : null
          loadBalancerSourceRanges = length(var.argocd_server_service_load_balancer_source_ranges) > 0 ? var.argocd_server_service_load_balancer_source_ranges : null
        }
      }
    }),
  ]

  depends_on = [
    terraform_data.aks_get_credentials,
    module.aks_cluster,
  ]
}

resource "time_sleep" "wait_for_argocd_service" {
  depends_on      = [helm_release.argocd]
  create_duration = "90s"
}

data "kubernetes_service_v1" "argocd_server" {
  metadata {
    name      = local.argocd_server_service_name
    namespace = var.argocd_namespace
  }

  depends_on = [time_sleep.wait_for_argocd_service]
}

data "kubernetes_service_v1" "gateway" {
  count = local.frontdoor_enabled && trimspace(var.frontdoor_origin_hostname_override) == "" ? 1 : 0

  metadata {
    name      = "spend-control-gateway"
    namespace = var.namespace
  }

  depends_on = [terraform_data.aks_get_credentials]
}

resource "azurerm_cdn_frontdoor_profile" "this" {
  count = local.frontdoor_enabled ? 1 : 0

  name                = "${local.name}-fd"
  resource_group_name = module.resource_group.name
  sku_name            = var.frontdoor_sku_name
  tags                = local.tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_cdn_frontdoor_endpoint" "this" {
  count = local.frontdoor_enabled ? 1 : 0

  name                     = "${local.name}-ep"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this[0].id
  enabled                  = true
  tags                     = local.tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_cdn_frontdoor_custom_domain" "apex" {
  count = local.frontdoor_enabled && local.frontdoor_apex_host_name != "" ? 1 : 0

  name                     = replace(local.frontdoor_apex_host_name, ".", "-")
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this[0].id
  host_name                = local.frontdoor_apex_host_name

  tls {
    certificate_type = "ManagedCertificate"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_cdn_frontdoor_custom_domain" "www" {
  count = local.frontdoor_enabled && local.frontdoor_www_host_name != "" ? 1 : 0

  name                     = replace(local.frontdoor_www_host_name, ".", "-")
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this[0].id
  host_name                = local.frontdoor_www_host_name

  tls {
    certificate_type = "ManagedCertificate"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_cdn_frontdoor_origin_group" "this" {
  count = local.frontdoor_enabled ? 1 : 0

  name                     = "${local.name}-og"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this[0].id
  session_affinity_enabled = false

  health_probe {
    interval_in_seconds = 30
    path                = "/health"
    protocol            = var.frontdoor_origin_use_https ? "Https" : "Http"
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

resource "azurerm_cdn_frontdoor_origin" "kgateway" {
  count = local.frontdoor_enabled ? 1 : 0

  name                          = "${local.name}-kgw"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.this[0].id
  enabled                       = true
  host_name = trimspace(var.frontdoor_origin_hostname_override) != "" ? trimspace(var.frontdoor_origin_hostname_override) : (
    trimspace(try(data.kubernetes_service_v1.gateway[0].status[0].load_balancer[0].ingress[0].hostname, "")) != "" ? trimspace(data.kubernetes_service_v1.gateway[0].status[0].load_balancer[0].ingress[0].hostname) : trimspace(try(data.kubernetes_service_v1.gateway[0].status[0].load_balancer[0].ingress[0].ip, ""))
  )
  http_port  = 80
  https_port = 443
  origin_host_header = local.frontdoor_apex_host_name != "" ? local.frontdoor_apex_host_name : (
    trimspace(var.frontdoor_origin_hostname_override) != "" ? trimspace(var.frontdoor_origin_hostname_override) : try(
      data.kubernetes_service_v1.gateway[0].status[0].load_balancer[0].ingress[0].hostname,
      data.kubernetes_service_v1.gateway[0].status[0].load_balancer[0].ingress[0].ip,
    )
  )
  priority                       = 1
  weight                         = 1000
  certificate_name_check_enabled = false

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_cdn_frontdoor_firewall_policy" "this" {
  name                = "${replace(local.name, "-", "")}waf"
  resource_group_name = module.resource_group.name
  sku_name            = var.frontdoor_sku_name
  enabled             = true
  mode                = "Prevention"

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

  tags = local.tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_cdn_frontdoor_route" "this" {
  count = local.frontdoor_enabled ? 1 : 0

  name                            = "${local.name}-route"
  cdn_frontdoor_endpoint_id       = azurerm_cdn_frontdoor_endpoint.this[0].id
  cdn_frontdoor_origin_group_id   = azurerm_cdn_frontdoor_origin_group.this[0].id
  cdn_frontdoor_origin_ids        = [azurerm_cdn_frontdoor_origin.kgateway[0].id]
  cdn_frontdoor_custom_domain_ids = azurerm_cdn_frontdoor_custom_domain.apex[*].id
  enabled                         = true
  forwarding_protocol             = var.frontdoor_origin_use_https ? "HttpsOnly" : "HttpOnly"
  https_redirect_enabled          = true
  patterns_to_match               = ["/*"]
  supported_protocols             = ["Http", "Https"]
  link_to_default_domain          = true

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_cdn_frontdoor_route" "www" {
  count = local.frontdoor_enabled && length(azurerm_cdn_frontdoor_custom_domain.www) > 0 ? 1 : 0

  name                            = "${local.name}-www-route"
  cdn_frontdoor_endpoint_id       = azurerm_cdn_frontdoor_endpoint.this[0].id
  cdn_frontdoor_origin_group_id   = azurerm_cdn_frontdoor_origin_group.this[0].id
  cdn_frontdoor_origin_ids        = [azurerm_cdn_frontdoor_origin.kgateway[0].id]
  cdn_frontdoor_custom_domain_ids = azurerm_cdn_frontdoor_custom_domain.www[*].id
  enabled                         = true
  forwarding_protocol             = var.frontdoor_origin_use_https ? "HttpsOnly" : "HttpOnly"
  https_redirect_enabled          = true
  patterns_to_match               = ["/*"]
  supported_protocols             = ["Http", "Https"]
  link_to_default_domain          = false

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_cdn_frontdoor_security_policy" "this" {
  count = local.frontdoor_enabled ? 1 : 0

  name                     = "${local.name}-security"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this[0].id

  security_policies {
    firewall {
      cdn_frontdoor_firewall_policy_id = azurerm_cdn_frontdoor_firewall_policy.this.id

      association {
        domain {
          cdn_frontdoor_domain_id = azurerm_cdn_frontdoor_endpoint.this[0].id
        }

        dynamic "domain" {
          for_each = toset(concat(azurerm_cdn_frontdoor_custom_domain.apex[*].id, azurerm_cdn_frontdoor_custom_domain.www[*].id))

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
