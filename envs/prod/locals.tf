locals {
  name          = lower("${var.prefix}-${var.environment}")
  compact_name  = substr(replace(lower("${var.prefix}${var.environment}"), "-", ""), 0, 18)
  location_slug = replace(lower(var.location), " ", "")

  aks_context_name         = "${local.name}-aks"
  key_vault_name           = trimspace(var.key_vault_name) != "" ? trimspace(var.key_vault_name) : substr("${local.name}-kv", 0, 24)
  frontdoor_enabled        = var.frontdoor_enabled
  frontdoor_apex_host_name = trimspace(var.frontdoor_apex_host_name)
  frontdoor_www_host_name  = trimspace(var.frontdoor_www_host_name)
  frontend_redirect_uris = distinct(
    concat(
      var.frontend_redirect_uris,
      local.frontdoor_enabled ? ["https://${azurerm_cdn_frontdoor_endpoint.this[0].host_name}/login"] : [],
      local.frontdoor_apex_host_name != "" ? ["https://${local.frontdoor_apex_host_name}/login"] : [],
      local.frontdoor_www_host_name != "" ? ["https://${local.frontdoor_www_host_name}/login"] : [],
    )
  )

  argocd_server_service_name = "argocd-server"

  workload_config_map_data = {
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
    NEXT_PUBLIC_ENTRA_API_SCOPE                 = format("%s/access_as_user", var.backend_application_id_uri)
    NEXT_PUBLIC_ENTRA_AUTHORITY                 = var.auth_authority
  }

  workload_bootstrap_manifest = <<-YAML
    apiVersion: v1
    kind: Namespace
    metadata:
      name: ${var.namespace}
    ---
    apiVersion: v1
    kind: ServiceAccount
    metadata:
      name: ${var.service_account_name}
      namespace: ${var.namespace}
      annotations:
        azure.workload.identity/client-id: ${azurerm_user_assigned_identity.workload.client_id}
    ---
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: ${var.app_config_map_name}
      namespace: ${var.namespace}
    data:
${indent(6, yamlencode(local.workload_config_map_data))}
  YAML

  argocd_values = yamlencode({
    server = {
      service = {
        type                     = var.argocd_server_service_type
        annotations              = var.argocd_server_service_annotations
        loadBalancerIP           = trimspace(var.argocd_server_load_balancer_ip) != "" ? trimspace(var.argocd_server_load_balancer_ip) : null
        loadBalancerSourceRanges = length(var.argocd_server_service_load_balancer_source_ranges) > 0 ? var.argocd_server_service_load_balancer_source_ranges : null
      }
    }
  })

  gateway_private_origin_host = trimspace(var.frontdoor_origin_hostname_override) != "" ? trimspace(var.frontdoor_origin_hostname_override) : var.gateway_private_load_balancer_ip
  gateway_private_link_service_id = format(
    "/subscriptions/%s/resourceGroups/%s/providers/Microsoft.Network/privateLinkServices/%s",
    data.azurerm_client_config.current.subscription_id,
    data.azurerm_kubernetes_cluster.existing.node_resource_group,
    var.gateway_private_link_service_name,
  )

  kgateway_gateway_parameters_manifest = <<-YAML
    apiVersion: gateway.kgateway.dev/v1alpha1
    kind: GatewayParameters
    metadata:
      name: ${var.gateway_parameters_name}
      namespace: ${var.namespace}
    spec:
      kube:
        service:
          type: LoadBalancer
        serviceOverlay:
          metadata:
            annotations:
              service.beta.kubernetes.io/azure-load-balancer-internal: "true"
              service.beta.kubernetes.io/azure-load-balancer-internal-subnet: "aks-subnet"
              service.beta.kubernetes.io/azure-load-balancer-ipv4: "${var.gateway_private_load_balancer_ip}"
              service.beta.kubernetes.io/azure-pls-create: "true"
              service.beta.kubernetes.io/azure-pls-name: "${var.gateway_private_link_service_name}"
              service.beta.kubernetes.io/azure-pls-resource-group: "${data.azurerm_kubernetes_cluster.existing.node_resource_group}"
  YAML

  kgateway_values = yamlencode({
    gatewayClassParametersRefs = {
      kgateway = {
        name      = var.gateway_parameters_name
        namespace = "kgateway-system"
      }
    }
    image = {
      tag = var.kgateway_version
    }
    controller = {
      image = {
        tag = var.kgateway_version
      }
    }
  })

  ops_jumpbox_cloud_init = <<-CLOUD
    #cloud-config
    package_update: true
    package_upgrade: false
    packages:
      - apt-transport-https
      - ca-certificates
      - curl
      - dnsutils
      - git
      - gnupg
      - jq
      - lsb-release
      - unzip
    write_files:
      - path: /usr/local/bin/install-ops-tools.sh
        permissions: "0755"
        content: |
          #!/usr/bin/env bash
          set -euo pipefail
          install -d -m 0755 /etc/apt/keyrings
          curl -sLS https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | tee /etc/apt/keyrings/microsoft.gpg > /dev/null
          chmod go+r /etc/apt/keyrings/microsoft.gpg
          AZ_REPO=$(lsb_release -cs)
          echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" > /etc/apt/sources.list.d/azure-cli.list
          apt-get update
          apt-get install -y azure-cli
          az aks install-cli
          curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
          cat >/etc/motd <<'EOF'
          SpendPilot prod ops jumpbox

          Typical first steps:
            az login
            az account set --subscription c00887fb-883e-4d8b-83ba-697054b43421
            az aks get-credentials --resource-group rg-spendpilot-prod --name spendpilot-prod-aks
            kubectl get nodes
          EOF
    runcmd:
      - /usr/local/bin/install-ops-tools.sh
  CLOUD

  tags = merge(
    {
      application = "spendpilot"
      environment = var.environment
      managed_by  = "terraform"
      stack       = "platform-bootstrap"
    },
    var.tags,
  )
}
