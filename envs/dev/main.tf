data "azurerm_client_config" "current" {}
data "azuread_client_config" "current" {}

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

module "aks_cluster" {
  source = "../../modules/aks-cluster"

  name                       = "${local.name}-aks"
  location                   = module.resource_group.location
  resource_group_name        = module.resource_group.name
  dns_prefix                 = "${local.name}-dns"
  kubernetes_version         = var.kubernetes_version
  private_cluster_enabled    = var.private_cluster_enabled
  authorized_ip_ranges       = var.authorized_ip_ranges
  log_analytics_workspace_id = module.log_analytics.id
  system_subnet_id           = module.network.subnet_ids["aks-subnet"]
  user_subnet_id             = module.network.subnet_ids["aks-subnet"]
  system_node_vm_size        = var.system_node_vm_size
  system_node_min_count      = var.system_node_min_count
  system_node_max_count      = var.system_node_max_count
  user_node_vm_size          = var.user_node_vm_size
  user_node_min_count        = var.user_node_min_count
  user_node_max_count        = var.user_node_max_count
  node_resource_group_name   = var.aks_node_resource_group_name
  service_cidr               = var.service_cidr
  dns_service_ip             = var.dns_service_ip
  tags                       = local.tags
}

data "azurerm_kubernetes_cluster" "credentials" {
  name                = module.aks_cluster.name
  resource_group_name = module.resource_group.name

  depends_on = [module.aks_cluster]
}

resource "azurerm_role_assignment" "acr_pull" {
  scope                = module.container_registry.id
  role_definition_name = "AcrPull"
  principal_id         = module.aks_cluster.kubelet_object_id
}

resource "azurerm_user_assigned_identity" "workload" {
  name                = "${local.name}-uami"
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name
  tags                = local.tags
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

resource "azurerm_cdn_frontdoor_profile" "this" {
  name                = "${local.name}-fd"
  resource_group_name = module.resource_group.name
  sku_name            = var.frontdoor_sku_name
  tags                = local.tags
}

resource "azurerm_cdn_frontdoor_endpoint" "this" {
  name                     = "${local.name}-ep"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id
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
  config_path = "${path.root}/.generated-kubeconfig"
}

provider "helm" {
  kubernetes {
    config_path = "${path.root}/.generated-kubeconfig"
  }
}

resource "terraform_data" "build_identity_image" {
  count = var.build_images_during_apply ? 1 : 0

  triggers_replace = {
    image_tag  = var.image_tag
    dockerfile = filesha256("${path.root}/../../../spendpilot-services/services/identity/Dockerfile")
    source     = local.backend_source_hash
  }

  provisioner "local-exec" {
    command = "az acr build --registry ${module.container_registry.name} --image spend-control-identity:${var.image_tag} --file ${path.root}/../../../spendpilot-services/services/identity/Dockerfile ${path.root}/../../../spendpilot-services"
    environment = {
      AZURE_CLI_DISABLE_CONNECTION_VERIFICATION = "1"
    }
  }
}

resource "terraform_data" "build_finance_image" {
  count = var.build_images_during_apply ? 1 : 0

  triggers_replace = {
    image_tag  = var.image_tag
    dockerfile = filesha256("${path.root}/../../../spendpilot-services/services/finance/Dockerfile")
    source     = local.backend_source_hash
  }

  provisioner "local-exec" {
    command = "az acr build --registry ${module.container_registry.name} --image spend-control-finance:${var.image_tag} --file ${path.root}/../../../spendpilot-services/services/finance/Dockerfile ${path.root}/../../../spendpilot-services"
    environment = {
      AZURE_CLI_DISABLE_CONNECTION_VERIFICATION = "1"
    }
  }
}

resource "terraform_data" "build_documents_image" {
  count = var.build_images_during_apply ? 1 : 0

  triggers_replace = {
    image_tag  = var.image_tag
    dockerfile = filesha256("${path.root}/../../../spendpilot-services/services/documents/Dockerfile")
    source     = local.backend_source_hash
  }

  provisioner "local-exec" {
    command = "az acr build --registry ${module.container_registry.name} --image spend-control-documents:${var.image_tag} --file ${path.root}/../../../spendpilot-services/services/documents/Dockerfile ${path.root}/../../../spendpilot-services"
    environment = {
      AZURE_CLI_DISABLE_CONNECTION_VERIFICATION = "1"
    }
  }
}

resource "terraform_data" "build_frontend_image" {
  count = var.build_images_during_apply ? 1 : 0

  triggers_replace = {
    image_tag  = var.image_tag
    dockerfile = filesha256("${path.root}/../../../spendpilot-frontend/Dockerfile")
    source     = local.frontend_source_hash
  }

  provisioner "local-exec" {
    command = "az acr build --registry ${module.container_registry.name} --image spend-control-frontend:${var.image_tag} ${path.root}/../../../spendpilot-frontend"
    environment = {
      AZURE_CLI_DISABLE_CONNECTION_VERIFICATION = "1"
    }
  }
}

resource "terraform_data" "gateway_api_crds" {
  triggers_replace = {
    cluster_name        = module.aks_cluster.name
    gateway_api_version = var.gateway_api_version
  }

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]
    command     = "az aks command invoke --resource-group ${module.resource_group.name} --name ${module.aks_cluster.name} --command 'kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v${var.gateway_api_version}/standard-install.yaml'"
    environment = {
      AZURE_CLI_DISABLE_CONNECTION_VERIFICATION = "1"
    }
  }
}

resource "helm_release" "kgateway_crds" {
  name      = "kgateway-crds"
  chart     = "${path.root}/../../vendor/kgateway/kgateway-crds"
  namespace = "kgateway-system"

  create_namespace = true

  depends_on = [terraform_data.gateway_api_crds]
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

  depends_on = [helm_release.kgateway_crds]
}

resource "kubernetes_namespace" "application" {
  metadata {
    name = var.namespace
  }
}

resource "terraform_data" "gateway_origin_tls_secret" {
  triggers_replace = {
    cluster_name = module.aks_cluster.name
    namespace    = var.namespace
    secret_name  = local.gateway_origin_tls_secret_name
  }

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]
    command     = <<-EOT
      $tempDir = Join-Path $env:TEMP 'spend-control-gateway-origin-tls'
      New-Item -ItemType Directory -Force -Path $tempDir | Out-Null
      $pfxPath = Join-Path $tempDir 'origin.pfx'
      $certPemPath = Join-Path $tempDir 'origin.crt'
      $keyPemPath = Join-Path $tempDir 'origin.key'
      $password = ConvertTo-SecureString -String 'SpendControlOriginTls!2026' -Force -AsPlainText
      $cert = New-SelfSignedCertificate -DnsName 'spend-control-gateway','spend-control-gateway.${var.namespace}','spend-control-gateway.${var.namespace}.svc','spend-control-gateway.${var.namespace}.svc.cluster.local' -CertStoreLocation 'Cert:\CurrentUser\My' -NotAfter (Get-Date).AddYears(1) -KeyExportPolicy Exportable
      Export-PfxCertificate -Cert $cert -FilePath $pfxPath -Password $password | Out-Null
      @'
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.serialization import pkcs12
from pathlib import Path
import sys

pfx_path = Path(sys.argv[1])
password = sys.argv[2].encode("utf-8")
cert_pem_path = Path(sys.argv[3])
key_pem_path = Path(sys.argv[4])

private_key, certificate, _ = pkcs12.load_key_and_certificates(pfx_path.read_bytes(), password)
cert_pem_path.write_bytes(certificate.public_bytes(serialization.Encoding.PEM))
key_pem_path.write_bytes(
    private_key.private_bytes(
        serialization.Encoding.PEM,
        serialization.PrivateFormat.TraditionalOpenSSL,
        serialization.NoEncryption(),
    )
)
'@ | python - $pfxPath 'SpendControlOriginTls!2026' $certPemPath $keyPemPath
      $remoteCommand = "kubectl create secret tls ${local.gateway_origin_tls_secret_name} -n ${var.namespace} --cert=origin.crt --key=origin.key --dry-run=client -o yaml | kubectl apply -f -"
      az aks command invoke --resource-group ${module.resource_group.name} --name ${module.aks_cluster.name} --file $certPemPath --file $keyPemPath --command $remoteCommand
      Remove-Item -Force $pfxPath, $certPemPath, $keyPemPath
    EOT
    environment = {
      AZURE_CLI_DISABLE_CONNECTION_VERIFICATION = "1"
    }
  }

  depends_on = [kubernetes_namespace.application]
}

resource "helm_release" "application" {
  name             = "spend-control"
  chart            = "${path.root}/../../../spendpilot-helm/charts/spendpilot"
  namespace        = var.namespace
  create_namespace = false
  timeout          = 600
  wait_for_jobs    = true

  values = [
    yamlencode({
      namespace = {
        create = false
        name   = var.namespace
      }
      gateway = {
        enabled   = true
        className = "kgateway"
        name      = "spend-control-gateway"
        listener = {
          port     = 80
          protocol = "HTTP"
        }
        tls = {
          enabled               = var.frontdoor_origin_use_https
          port                  = 443
          protocol              = "HTTPS"
          mode                  = "Terminate"
          certificateSecretName = local.gateway_origin_tls_secret_name
        }
      }
      serviceAccount = {
        create = true
        name   = var.service_account_name
      }
      imagePullSecrets = []
      rollout = {
        revision = local.application_rollout_revision
      }
      frontend = {
        image = {
          repository = local.frontend_repo
          tag        = var.image_tag
          pullPolicy = var.image_tag == "latest" ? "Always" : "IfNotPresent"
        }
      }
      identityService = {
        image = {
          repository = local.identity_repo
          tag        = var.image_tag
          pullPolicy = var.image_tag == "latest" ? "Always" : "IfNotPresent"
        }
      }
      financeService = {
        image = {
          repository = local.finance_repo
          tag        = var.image_tag
          pullPolicy = var.image_tag == "latest" ? "Always" : "IfNotPresent"
        }
      }
      documentsService = {
        image = {
          repository = local.documents_repo
          tag        = var.image_tag
          pullPolicy = var.image_tag == "latest" ? "Always" : "IfNotPresent"
        }
      }
      migrationJob = {
        enabled = true
        image = {
          repository = local.identity_repo
          tag        = var.image_tag
          pullPolicy = var.image_tag == "latest" ? "Always" : "IfNotPresent"
        }
      }
      env = {
        appEnv                 = "production"
        backendCorsOrigins     = "https://${azurerm_cdn_frontdoor_endpoint.this.host_name}"
        financeDefaultCurrency = "INR"
      }
      auth = {
        mode                = "entra"
        authority           = "https://login.microsoftonline.com/common"
        frontendClientId    = azuread_application.frontend_spa.client_id
        backendClientId     = azuread_application.backend_api.client_id
        backendAudience     = local.backend_audience
        apiScope            = "${local.backend_audience}/access_as_user"
        allowedTenantIds    = var.allowed_tenant_ids
        platformAdminEmails = var.platform_admin_emails
      }
      azure = {
        tenantId                     = data.azurerm_client_config.current.tenant_id
        managedIdentityClientId      = azurerm_user_assigned_identity.workload.client_id
        aiFoundryEndpoint            = azurerm_cognitive_account.foundry.endpoint
        aiProjectEndpoint            = ""
        aiModelDeployment            = azurerm_cognitive_deployment.foundry_model.name
        documentIntelligenceEndpoint = azurerm_cognitive_account.document_intelligence.endpoint
        storageAccountUrl            = azurerm_storage_account.documents.primary_blob_endpoint
        storageContainerName         = azurerm_storage_container.documents.name
      }
      secrets = {
        create        = true
        databaseUrl   = "postgresql+psycopg://${var.postgres_admin_login}:${var.postgres_admin_password}@${module.postgres.fqdn}:5432/${module.postgres.database_name}?sslmode=require"
        devAuthSecret = "disabled-in-production"
      }
    }),
  ]

  depends_on = [
    kubernetes_namespace.application,
    helm_release.kgateway,
    azurerm_federated_identity_credential.workload,
    azurerm_role_assignment.storage_blob_contributor,
    azurerm_role_assignment.docint_user,
    azurerm_role_assignment.foundry_user,
    terraform_data.gateway_origin_tls_secret,
    terraform_data.build_identity_image,
    terraform_data.build_finance_image,
    terraform_data.build_documents_image,
    terraform_data.build_frontend_image,
  ]
}

resource "time_sleep" "wait_for_gateway_service" {
  depends_on      = [helm_release.application]
  create_duration = "90s"
}

data "kubernetes_service" "gateway" {
  metadata {
    name      = "spend-control-gateway"
    namespace = var.namespace
  }

  depends_on = [time_sleep.wait_for_gateway_service]
}

resource "azurerm_cdn_frontdoor_origin_group" "this" {
  name                     = "${local.name}-og"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id
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
}

resource "azurerm_cdn_frontdoor_origin" "kgateway" {
  name                           = "${local.name}-kgw"
  cdn_frontdoor_origin_group_id  = azurerm_cdn_frontdoor_origin_group.this.id
  enabled                        = true
  host_name                      = trimspace(var.frontdoor_origin_hostname_override) != "" ? trimspace(var.frontdoor_origin_hostname_override) : try(data.kubernetes_service.gateway.status[0].load_balancer[0].ingress[0].ip, data.kubernetes_service.gateway.status[0].load_balancer[0].ingress[0].hostname)
  http_port                      = 80
  https_port                     = 443
  origin_host_header             = trimspace(var.frontdoor_origin_hostname_override) != "" ? trimspace(var.frontdoor_origin_hostname_override) : try(data.kubernetes_service.gateway.status[0].load_balancer[0].ingress[0].ip, data.kubernetes_service.gateway.status[0].load_balancer[0].ingress[0].hostname)
  priority                       = 1
  weight                         = 1000
  certificate_name_check_enabled = false

  depends_on = [data.kubernetes_service.gateway]
}

resource "azurerm_cdn_frontdoor_firewall_policy" "this" {
  name                = "${local.alnum_name}waf"
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
}

resource "azurerm_cdn_frontdoor_route" "this" {
  name                          = "${local.name}-route"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.this.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.this.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.kgateway.id]
  cdn_frontdoor_custom_domain_ids = local.frontdoor_apex_custom_domain_id != "" ? [
    local.frontdoor_apex_custom_domain_id,
  ] : []
  enabled                = true
  forwarding_protocol    = var.frontdoor_origin_use_https ? "HttpsOnly" : "HttpOnly"
  https_redirect_enabled = true
  patterns_to_match      = ["/*"]
  supported_protocols    = ["Http", "Https"]
  link_to_default_domain = true
}

resource "azurerm_cdn_frontdoor_route" "www" {
  count = local.frontdoor_www_custom_domain_id != "" ? 1 : 0

  name                          = "${local.name}-www-route"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.this.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.this.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.kgateway.id]
  cdn_frontdoor_custom_domain_ids = [
    local.frontdoor_www_custom_domain_id,
  ]
  enabled                = true
  forwarding_protocol    = var.frontdoor_origin_use_https ? "HttpsOnly" : "HttpOnly"
  https_redirect_enabled = true
  patterns_to_match      = ["/*"]
  supported_protocols    = ["Http", "Https"]
  link_to_default_domain = false
}

resource "azurerm_cdn_frontdoor_security_policy" "this" {
  name                     = "${local.name}-security"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id

  security_policies {
    firewall {
      cdn_frontdoor_firewall_policy_id = azurerm_cdn_frontdoor_firewall_policy.this.id

      association {
        domain {
          cdn_frontdoor_domain_id = azurerm_cdn_frontdoor_endpoint.this.id
        }

        dynamic "domain" {
          for_each = local.frontdoor_custom_domain_ids

          content {
            cdn_frontdoor_domain_id = domain.value
          }
        }

        patterns_to_match = ["/*"]
      }
    }
  }
}
