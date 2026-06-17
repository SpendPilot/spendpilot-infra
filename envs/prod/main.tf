data "azurerm_client_config" "current" {}
data "azuread_client_config" "current" {}

data "azurerm_container_registry" "global_shared" {
  name                = var.acr_name
  resource_group_name = var.acr_resource_group_name
}

module "resource_group" {
  source = "../../modules/resource-group"

  name     = local.rg_name
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

  name                         = "${local.name}-pgsql"
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
    context_name        = local.aks_context_name
  }

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]
    command     = "az aks get-credentials --resource-group ${module.resource_group.name} --name ${module.aks_cluster.name} --overwrite-existing"
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
  name                            = substr("${local.compact_name}st", 0, 24)
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
  name                          = "${local.name}-docint"
  location                      = module.resource_group.location
  resource_group_name           = module.resource_group.name
  kind                          = "FormRecognizer"
  sku_name                      = var.document_intelligence_sku
  custom_subdomain_name         = substr("${local.compact_name}doc", 0, 63)
  public_network_access_enabled = true
  tags                          = local.tags
}

resource "azurerm_cognitive_account" "foundry" {
  name                          = "${local.name}-foundry"
  location                      = var.foundry_location
  resource_group_name           = module.resource_group.name
  kind                          = "AIServices"
  sku_name                      = var.foundry_sku_name
  custom_subdomain_name         = substr("${local.compact_name}ai", 0, 63)
  public_network_access_enabled = true
  tags                          = local.tags
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

resource "kubernetes_config_map_v1" "spendpilot" {
  metadata {
    name      = var.app_config_map_name
    namespace = kubernetes_namespace_v1.spendpilot.metadata[0].name
  }

  data = {
    APP_ENV                              = "production"
    BACKEND_CORS_ORIGINS                 = var.backend_cors_origins
    AUTH_MODE                            = "entra"
    AZURE_TENANT_ID                      = data.azurerm_client_config.current.tenant_id
    AZURE_CLIENT_ID                      = azurerm_user_assigned_identity.workload.client_id
    ENTRA_FRONTEND_CLIENT_ID             = azuread_application.frontend_spa.client_id
    ENTRA_BACKEND_CLIENT_ID              = azuread_application.backend_api.client_id
    ENTRA_BACKEND_AUDIENCE               = "api://${azuread_application.backend_api.client_id}"
    ENTRA_AUTHORITY                      = var.auth_authority
    ENTRA_ALLOWED_TENANT_IDS             = var.allowed_tenant_ids
    PLATFORM_ADMIN_EMAILS                = var.platform_admin_emails
    AZURE_AI_FOUNDRY_ENDPOINT            = azurerm_cognitive_account.foundry.endpoint
    AZURE_AI_PROJECT_ENDPOINT            = ""
    AZURE_AI_MODEL_DEPLOYMENT            = azurerm_cognitive_deployment.foundry_model.name
    AZURE_DOCUMENT_INTELLIGENCE_ENDPOINT = azurerm_cognitive_account.document_intelligence.endpoint
    AZURE_STORAGE_ACCOUNT_URL            = azurerm_storage_account.documents.primary_blob_endpoint
    AZURE_STORAGE_CONTAINER_NAME         = azurerm_storage_container.documents.name
    FINANCE_DEFAULT_CURRENCY             = var.finance_default_currency
    NEXT_PUBLIC_API_BASE_URL             = var.frontend_api_base_url
    NEXT_PUBLIC_AUTH_MODE                = "entra"
    NEXT_PUBLIC_ENTRA_FRONTEND_CLIENT_ID = azuread_application.frontend_spa.client_id
    NEXT_PUBLIC_ENTRA_BACKEND_CLIENT_ID  = azuread_application.backend_api.client_id
    NEXT_PUBLIC_ENTRA_BACKEND_AUDIENCE   = "api://${azuread_application.backend_api.client_id}"
    NEXT_PUBLIC_ENTRA_API_SCOPE          = "api://${azuread_application.backend_api.client_id}/access_as_user"
    NEXT_PUBLIC_ENTRA_AUTHORITY          = var.auth_authority
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
