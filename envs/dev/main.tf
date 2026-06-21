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

data "terraform_remote_state" "nonprod_shared" {
  backend = "azurerm"

  config = {
    resource_group_name  = var.backend_resource_group_name
    storage_account_name = var.backend_storage_account_name
    container_name       = var.backend_container_name
    key                  = var.nonprod_shared_state_key
    subscription_id      = data.azurerm_client_config.current.subscription_id
    tenant_id            = data.azurerm_client_config.current.tenant_id
  }
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

data "azurerm_container_registry" "global_shared" {
  name                = data.terraform_remote_state.global_shared.outputs.acr_name
  resource_group_name = data.terraform_remote_state.global_shared.outputs.resource_group_name
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

module "container_registry" {
  source = "../../modules/container-registry"

  name                = substr("${local.compact_name}acr", 0, 50)
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name
  sku                 = var.acr_sku
  tags                = local.tags
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

  name                          = trimspace(var.postgres_dr_replica_server_name) != "" ? trimspace(var.postgres_dr_replica_server_name) : "${local.name}-pgsql-dr"
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
}

data "azurerm_kubernetes_cluster" "credentials" {
  name                = module.aks_cluster.name
  resource_group_name = module.resource_group.name

  depends_on = [module.aks_cluster]
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

resource "azurerm_role_assignment" "storage_blob_contributor" {
  scope                = azurerm_storage_account.documents.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.workload.principal_id
}

resource "azurerm_role_assignment" "docint_user" {
  scope                = data.terraform_remote_state.nonprod_shared.outputs.shared_document_intelligence_id
  role_definition_name = "Cognitive Services User"
  principal_id         = azurerm_user_assigned_identity.workload.principal_id
}

resource "azurerm_role_assignment" "foundry_user" {
  scope                = data.terraform_remote_state.nonprod_shared.outputs.shared_foundry_id
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

  name                         = local.name
  location                     = module.resource_group.location
  resource_group_name          = module.resource_group.name
  tags                         = local.tags
  backend_sender_principal_id  = azurerm_user_assigned_identity.workload.principal_id
  github_actions_principal_id  = try(data.terraform_remote_state.identities.outputs.github_actions_service_principal_object_id, "")
  email_data_location          = var.email_data_location
  email_domain_name            = var.email_domain_name
  email_domain_management      = var.email_domain_management
  function_sender_username     = var.email_sender_username
  function_sender_display_name = var.email_sender_display_name
}

resource "azuread_application" "backend_api" {
  display_name     = "${local.name}-backend-api"
  sign_in_audience = "AzureADandPersonalMicrosoftAccount"
  owners           = [data.azuread_client_config.current.object_id]
  identifier_uris  = [local.backend_audience]

  api {
    requested_access_token_version = 2

    oauth2_permission_scope {
      id                         = uuidv5("dns", "${local.name}-access-as-user")
      admin_consent_description  = "Allow the frontend SPA to access the Spend Control API."
      admin_consent_display_name = "Access Spend Control API"
      enabled                    = true
      type                       = "User"
      user_consent_description   = "Allow the application to access your finance workspace."
      user_consent_display_name  = "Access Spend Control"
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

provider "kubernetes" {
  config_path = fileexists("${path.root}/.generated-kubeconfig") ? "${path.root}/.generated-kubeconfig" : pathexpand("~/.kube/config")
}

provider "helm" {
  kubernetes {
    config_path = fileexists("${path.root}/.generated-kubeconfig") ? "${path.root}/.generated-kubeconfig" : pathexpand("~/.kube/config")
  }
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

  depends_on = [data.azurerm_kubernetes_cluster.credentials]
}

resource "terraform_data" "gateway_api_crds" {
  triggers_replace = {
    cluster_name        = module.aks_cluster.name
    gateway_api_version = var.gateway_api_version
  }

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]
    command     = <<-EOT
      $ErrorActionPreference = 'Stop'
      az aks command invoke --resource-group ${module.resource_group.name} --name ${module.aks_cluster.name} --command "kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v${var.gateway_api_version}/standard-install.yaml"
    EOT
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

  depends_on = [terraform_data.aks_get_credentials, terraform_data.gateway_api_crds]
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

  depends_on = [terraform_data.aks_get_credentials, helm_release.kgateway_crds]
}

resource "kubernetes_namespace" "application" {
  metadata {
    name = var.namespace
  }

  lifecycle {
    ignore_changes = [
      metadata[0].annotations["argocd.argoproj.io/tracking-id"],
    ]
  }

  depends_on = [terraform_data.aks_get_credentials]
}

resource "terraform_data" "bootstrap_gateway" {
  triggers_replace = {
    cluster_name             = module.aks_cluster.name
    namespace                = var.namespace
    gateway_name             = "spend-control-gateway"
    gateway_class_name       = "kgateway"
    frontdoor_origin_use_tls = tostring(var.frontdoor_origin_use_https)
  }

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]
    command     = <<-EOT
      $ErrorActionPreference = 'Stop'
      $gatewayYaml = @'
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: spend-control-gateway
  namespace: ${var.namespace}
spec:
  gatewayClassName: kgateway
  listeners:
    - name: http
      port: 80
      protocol: HTTP
      allowedRoutes:
        namespaces:
          from: Same
'@
      $gatewayPath = Join-Path $env:TEMP 'spend-control-gateway.yaml'
      Set-Content -LiteralPath $gatewayPath -Value $gatewayYaml -Encoding ascii
      az aks command invoke --resource-group ${module.resource_group.name} --name ${module.aks_cluster.name} --file $gatewayPath --command "kubectl apply -f spend-control-gateway.yaml"
      Remove-Item -Force $gatewayPath
    EOT
    environment = {
      AZURE_CLI_DISABLE_CONNECTION_VERIFICATION = "1"
    }
  }

  depends_on = [terraform_data.aks_get_credentials, kubernetes_namespace.application]
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

resource "time_sleep" "wait_for_gateway_service" {
  depends_on      = [terraform_data.bootstrap_gateway]
  create_duration = "90s"
}

data "kubernetes_service" "gateway" {
  metadata {
    name      = "spend-control-gateway"
    namespace = var.namespace
  }

  depends_on = [time_sleep.wait_for_gateway_service]
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
