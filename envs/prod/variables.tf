variable "prefix" {
  description = "Project prefix used in Azure resource names."
  type        = string
  default     = "spendpilot"
}

variable "environment" {
  description = "Deployment environment label."
  type        = string
  default     = "prod"
}

variable "location" {
  description = "Azure region for prod resources."
  type        = string
  default     = "Central India"
}

variable "resource_group_name" {
  description = "Primary Azure resource group name used for the platform stack."
  type        = string
  default     = "rg-spendpilot-prod"
}

variable "aks_node_resource_group_name" {
  description = "Azure-managed AKS node resource group name."
  type        = string
  default     = "rg-spendpilot-prod-aks-nodes"
}

variable "tags" {
  description = "Additional Azure tags."
  type        = map(string)
  default = {
    env         = "prod"
    application = "spendpilot"
    managed_by  = "terraform"
  }
}

variable "kubernetes_version" {
  description = "AKS version kept within the current kGateway support matrix."
  type        = string
  default     = "1.35"
}

variable "kgateway_version" {
  description = "kGateway Helm chart version."
  type        = string
  default     = "2.3.0"
}

variable "gateway_api_version" {
  description = "Gateway API CRD release version."
  type        = string
  default     = "1.5.1"
}

variable "argocd_chart_version" {
  description = "Pinned Argo CD Helm chart version. The upstream chart currently requires Kubernetes >= 1.25."
  type        = string
  default     = "9.5.21"
}

variable "argocd_namespace" {
  description = "Namespace where Argo CD will be installed."
  type        = string
  default     = "argocd"
}

variable "argocd_server_service_type" {
  description = "Kubernetes Service type used to expose the Argo CD server."
  type        = string
  default     = "LoadBalancer"
}

variable "argocd_server_service_annotations" {
  description = "Optional annotations for the Argo CD server service."
  type        = map(string)
  default     = {}
}

variable "argocd_server_service_load_balancer_source_ranges" {
  description = "Optional source ranges allowed to reach the Argo CD LoadBalancer service."
  type        = list(string)
  default     = []
}

variable "argocd_server_load_balancer_ip" {
  description = "Optional static public IP to assign to the Argo CD LoadBalancer service."
  type        = string
  default     = "135.235.224.62"
}

variable "private_cluster_enabled" {
  description = "Whether to create a private AKS control plane."
  type        = bool
  default     = true
}

variable "authorized_ip_ranges" {
  description = "Optional public IP ranges allowed to reach the AKS API server when the cluster is public."
  type        = list(string)
  default     = []
}

variable "aks_api_server_vnet_integration_enabled" {
  description = "Enable API server VNet integration for the prod AKS control plane."
  type        = bool
  default     = true
}

variable "aks_private_cluster_public_fqdn_enabled" {
  description = "Whether the private prod AKS cluster should retain a public FQDN."
  type        = bool
  default     = false
}

variable "aks_api_server_subnet_cidr" {
  description = "Dedicated API server subnet CIDR for AKS API server VNet integration."
  type        = string
  default     = "10.40.40.0/28"
}

variable "managed_prometheus_enabled" {
  description = "Enable Azure managed Prometheus scraping for the prod AKS cluster."
  type        = bool
  default     = true
}

variable "managed_prometheus_annotations_allowed" {
  description = "Comma-separated Prometheus annotations allowed by the AKS managed metrics addon."
  type        = string
  default     = null
}

variable "managed_prometheus_labels_allowed" {
  description = "Comma-separated Prometheus labels allowed by the AKS managed metrics addon."
  type        = string
  default     = null
}

variable "azure_monitor_workspace_name" {
  description = "Optional explicit Azure Monitor workspace name override for managed Prometheus."
  type        = string
  default     = "spendpilot-prod-amw"
}

variable "managed_grafana_enabled" {
  description = "Enable Azure Managed Grafana for the prod AKS cluster."
  type        = bool
  default     = true
}

variable "managed_grafana_name" {
  description = "Optional explicit Azure Managed Grafana workspace name override."
  type        = string
  default     = "spendpilot-prod-grafana"
}

variable "managed_grafana_major_version" {
  description = "Grafana major version for Azure Managed Grafana."
  type        = string
  default     = "12"
}

variable "aks_control_plane_identity_name" {
  description = "User-assigned managed identity name used by the prod AKS control plane for API server VNet integration."
  type        = string
  default     = "spendpilot-prod-aks-uami"
}

variable "managed_grafana_public_network_access_enabled" {
  description = "Whether the Azure Managed Grafana endpoint is reachable over public network access."
  type        = bool
  default     = true
}

variable "ops_resource_group_name" {
  description = "Separate Azure resource group for the prod operations jumpbox."
  type        = string
  default     = "rg-spendpilot-prod-ops-au"
}

variable "ops_location" {
  description = "Azure region for the prod operations jumpbox environment."
  type        = string
  default     = "Australia East"
}

variable "ops_vnet_cidr" {
  description = "Virtual network CIDR for the prod operations jumpbox environment."
  type        = string
  default     = "11.0.0.0/16"
}

variable "ops_jumpbox_subnet_cidr" {
  description = "Subnet CIDR for the prod operations jumpbox."
  type        = string
  default     = "11.0.1.0/24"
}

variable "ops_jumpbox_name" {
  description = "Name of the prod operations jumpbox VM."
  type        = string
  default     = "spendpilot-prod-jumpbox-au"
}

variable "ops_jumpbox_vm_size" {
  description = "VM size for the prod operations jumpbox."
  type        = string
  default     = "Standard_D2s_v3"
}

variable "ops_jumpbox_admin_username" {
  description = "Admin username for the prod operations jumpbox."
  type        = string
  default     = "azureuser"
}

variable "ops_jumpbox_bootstrap_public_key" {
  description = "Bootstrap SSH public key used only to satisfy Azure VM provisioning when AAD SSH login is enabled."
  type        = string
  default     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC/zXtsTNRiXRzkP3gcAotc4YfU1k4rUfV6LTQPbSI5bBjJOznIRrXBoaxv4LMMEEWHahK9ToXDSgC/t4sHC2n4msuDvtc9oRWUCTmdwIQRUAUznBfmkBMJq0yOpAX3798Tp2UfaAg/dwbojF24YyZk4msvDjvTLxNA0qOUs0VMfeHIM2W4yUWiQXshhqe41Ob+NBZ8zTei5JEBk7TU/eRshk4pPI6BCQyNJxkmj6bFGA97BM0Tm/i10NMNBxBOy5Cb/brwJFrFZda5glTyn1bbE5qmktidHmkMdot296rOzN5YGwJW3pcUj5ZxLjB9CCGeBEZvm7zw4m5F/zshVfgQcweJF5G6rpG+WHqhesKsQ9T9Va1wvlkQSIjCeDsc83RiZb73Urm95rO3Nm6ECt4OUUOdg3sngi8aRsRturV8jjt6n82pwhghZxDs+daQ4j2SM4HYqaHaZy+l6JvWjCiLbXnMgfnG3679gN+7GtuO4G8Do1j0SMwK5gXQl8b49+5At0RENqvBIdmRNTwTrkBH2NqD/+qMBUAnVwimuIEN5Rt7aNv7nOljcAynQkmErePqSR6+s9mR8t6IAwpaqbwU8udoPnRBOvTgpz6IMvJPdi4R7kHpBqPLVWpY7HSdj/Jpya30o4SBv1txeBmT2XRhjGxjLFgBzYth0qmEQN1zvw== lijaz@Lijaz_LAP"
}

variable "platform_operator_object_id" {
  description = "Stable Entra object ID for the human platform operator who should retain Grafana admin and jumpbox VM admin rights."
  type        = string
  default     = "26aed7c2-6718-47f1-997c-ab154ea36be0"
}

variable "namespace" {
  description = "Kubernetes namespace reserved for the SpendPilot application workloads."
  type        = string
  default     = "spend-control"
}

variable "service_account_name" {
  description = "Kubernetes service account reserved for SpendPilot workloads."
  type        = string
  default     = "spend-control-workload"
}

variable "app_config_map_name" {
  description = "Stable ConfigMap name consumed by the SpendPilot workloads."
  type        = string
  default     = "spend-control-config"
}

variable "app_secret_name" {
  description = "Stable Secret name consumed by the SpendPilot workloads."
  type        = string
  default     = "spend-control-secrets"
}

variable "key_vault_name" {
  description = "Optional override for the prod Key Vault name."
  type        = string
  default     = "spendpilot-prod-kv-2300"
}

variable "key_vault_sku_name" {
  description = "Key Vault SKU used for prod secrets."
  type        = string
  default     = "standard"
}

variable "key_vault_public_network_access_enabled" {
  description = "Whether the prod Key Vault is reachable over public network access."
  type        = bool
  default     = true
}

variable "key_vault_secrets_provider_enabled" {
  description = "Enable the AKS Key Vault Secrets Provider addon."
  type        = bool
  default     = true
}

variable "key_vault_secret_rotation_enabled" {
  description = "Enable automatic Key Vault secret rotation in the AKS addon."
  type        = bool
  default     = true
}

variable "key_vault_secret_rotation_interval" {
  description = "Rotation poll interval used by the AKS Key Vault Secrets Provider addon."
  type        = string
  default     = "2m"
}

variable "key_vault_database_url_secret_name" {
  description = "Key Vault secret name that stores DATABASE_URL."
  type        = string
  default     = "spend-control-database-url"
}

variable "key_vault_dev_auth_secret_name" {
  description = "Key Vault secret name that stores DEV_AUTH_SECRET."
  type        = string
  default     = "spend-control-dev-auth-secret"
}

variable "key_vault_secrets_officer_principal_id" {
  description = "Stable Microsoft Entra object ID that should retain Key Vault Secrets Officer on the prod vault."
  type        = string
  default     = "26aed7c2-6718-47f1-997c-ab154ea36be0"
}

variable "vnet_cidr" {
  description = "Virtual network CIDR."
  type        = string
  default     = "10.40.0.0/16"
}

variable "aks_subnet_cidr" {
  description = "AKS subnet CIDR."
  type        = string
  default     = "10.40.10.0/24"
}

variable "db_subnet_cidr" {
  description = "PostgreSQL delegated subnet CIDR."
  type        = string
  default     = "10.40.20.0/24"
}

variable "private_endpoint_subnet_cidr" {
  description = "Dedicated subnet CIDR for private endpoints."
  type        = string
  default     = "10.40.30.0/24"
}

variable "enable_key_vault_private_endpoint" {
  description = "Whether to create a private endpoint for the prod Key Vault."
  type        = bool
  default     = true
}

variable "service_cidr" {
  description = "Kubernetes service CIDR."
  type        = string
  default     = "10.50.0.0/16"
}

variable "dns_service_ip" {
  description = "Kubernetes DNS service IP."
  type        = string
  default     = "10.50.0.10"
}

variable "system_node_vm_size" {
  description = "AKS system node pool VM size."
  type        = string
  default     = "Standard_D2s_v3"
}

variable "system_node_min_count" {
  description = "Minimum AKS system node count."
  type        = number
  default     = 1
}

variable "system_node_max_count" {
  description = "Maximum AKS system node count."
  type        = number
  default     = 2
}

variable "user_node_vm_size" {
  description = "AKS user node pool VM size."
  type        = string
  default     = "Standard_D2s_v3"
}

variable "user_node_min_count" {
  description = "Minimum AKS user node count."
  type        = number
  default     = 1
}

variable "user_node_max_count" {
  description = "Maximum AKS user node count."
  type        = number
  default     = 3
}

variable "postgres_admin_login" {
  description = "PostgreSQL administrator username."
  type        = string
  default     = "spendpilotadmin"
}

variable "postgres_admin_password" {
  description = "PostgreSQL administrator password."
  type        = string
  sensitive   = true
}

variable "postgres_version" {
  description = "PostgreSQL major version."
  type        = string
  default     = "16"
}

variable "postgres_sku_name" {
  description = "PostgreSQL SKU name."
  type        = string
  default     = "GP_Standard_D2s_v3"
}

variable "postgres_zone" {
  description = "Primary availability zone for PostgreSQL Flexible Server."
  type        = string
  default     = "1"
}

variable "postgres_ha_mode" {
  description = "PostgreSQL high availability mode."
  type        = string
  default     = "Disabled"
}

variable "postgres_ha_standby_zone" {
  description = "Standby availability zone for PostgreSQL high availability."
  type        = string
  default     = ""
}

variable "postgres_geo_redundant_backup_enabled" {
  description = "Enable geo-redundant backup for PostgreSQL Flexible Server."
  type        = bool
  default     = true
}

variable "postgres_storage_mb" {
  description = "PostgreSQL storage size in MB."
  type        = number
  default     = 32768
}

variable "postgres_database_name" {
  description = "Application database name."
  type        = string
  default     = "spendpilot"
}

variable "postgres_server_name" {
  description = "Optional explicit PostgreSQL Flexible Server name override."
  type        = string
  default     = "spendpilot-prod-pgsql-2300"
}

variable "postgres_dr_replica_enabled" {
  description = "Whether to provision a cross-region PostgreSQL read replica for disaster recovery."
  type        = bool
  default     = true
}

variable "postgres_dr_location" {
  description = "Azure region used for the cross-region PostgreSQL disaster recovery replica."
  type        = string
  default     = "South India"
}

variable "postgres_dr_vnet_cidr" {
  description = "Dedicated virtual network CIDR for the PostgreSQL disaster recovery replica."
  type        = string
  default     = "10.41.0.0/16"
}

variable "postgres_dr_db_subnet_cidr" {
  description = "Delegated subnet CIDR for the PostgreSQL disaster recovery replica."
  type        = string
  default     = "10.41.20.0/24"
}

variable "postgres_dr_zone" {
  description = "Optional availability zone used for the PostgreSQL disaster recovery replica. Leave empty when the target region does not expose zonal placement for the selected SKU."
  type        = string
  default     = ""
}

variable "postgres_dr_replica_server_name" {
  description = "Optional explicit name override for the PostgreSQL disaster recovery replica."
  type        = string
  default     = "spendpilot-prod-pgsql-2300-dr"
}

variable "backend_resource_group_name" {
  description = "Azure Blob backend resource group used to read the global-shared remote state."
  type        = string
  default     = "terraform-rg"
}

variable "backend_storage_account_name" {
  description = "Azure Blob backend storage account used to read the global-shared remote state."
  type        = string
  default     = "lijaztf"
}

variable "backend_container_name" {
  description = "Azure Blob backend container used to read the global-shared remote state."
  type        = string
  default     = "states"
}

variable "global_shared_state_key" {
  description = "State key for the global-shared Terraform root that owns the shared ACR."
  type        = string
  default     = "global-shared.tfstate"
}

variable "identities_state_key" {
  description = "State key for the shared identities Terraform root."
  type        = string
  default     = "identities.tfstate"
}

variable "document_intelligence_sku" {
  description = "Document Intelligence SKU."
  type        = string
  default     = "S0"
}

variable "document_intelligence_account_name" {
  description = "Optional explicit Document Intelligence account name override."
  type        = string
  default     = "spendpilot-prod-docint-2300"
}

variable "document_intelligence_custom_subdomain_name" {
  description = "Optional explicit Document Intelligence custom subdomain override."
  type        = string
  default     = "spendpilotproddoc2300"
}

variable "foundry_sku_name" {
  description = "Azure AI Foundry/OpenAI account SKU."
  type        = string
  default     = "S0"
}

variable "foundry_account_name" {
  description = "Optional explicit Azure AI Foundry account name override."
  type        = string
  default     = "spendpilot-prod-foundry-2300"
}

variable "foundry_custom_subdomain_name" {
  description = "Optional explicit Azure AI Foundry custom subdomain override."
  type        = string
  default     = "spendpilotprodai2300"
}

variable "foundry_location" {
  description = "Region used for Azure AI Foundry model hosting."
  type        = string
  default     = "East US 2"
}

variable "openai_model_name" {
  description = "Default Azure AI Foundry model deployment name."
  type        = string
  default     = "gpt-4.1-mini"
}

variable "openai_model_version" {
  description = "Default Azure AI Foundry model version."
  type        = string
  default     = "2025-04-14"
}

variable "openai_deployment_sku_name" {
  description = "Azure OpenAI deployment SKU."
  type        = string
  default     = "GlobalStandard"
}

variable "openai_deployment_capacity" {
  description = "Azure OpenAI deployment capacity."
  type        = number
  default     = 1
}

variable "platform_admin_emails" {
  description = "Comma-separated platform admin emails reserved for workload config."
  type        = string
  default     = ""
}

variable "allowed_tenant_ids" {
  description = "Comma-separated tenant IDs allowed to call the API."
  type        = string
  default     = ""
}

variable "auth_authority" {
  description = "Authority URL exposed to frontend and backend auth configuration."
  type        = string
  default     = "https://login.microsoftonline.com/common"
}

variable "backend_application_id_uri" {
  description = "Application ID URI exposed by the backend API app registration."
  type        = string
  default     = "api://spendpilot-prod-backend-api-2300"
}

variable "backend_cors_origins" {
  description = "Comma-separated CORS origins allowed to call the backend APIs."
  type        = string
  default     = "https://costpilot.online,https://myfinagent.online,https://www.myfinagent.online"
}

variable "finance_default_currency" {
  description = "Default finance currency exposed to the runtime configuration."
  type        = string
  default     = "INR"
}

variable "frontend_api_base_url" {
  description = "Public API base URL exposed to the frontend runtime."
  type        = string
  default     = "/api"
}

variable "documents_storage_account_name" {
  description = "Optional explicit Azure Storage Account name override for documents."
  type        = string
  default     = "sp2300proddocs"
}

variable "dev_auth_secret" {
  description = "Fallback secret value kept for compatibility even when Entra auth is enabled."
  type        = string
  sensitive   = true
  default     = "disabled-in-production"
}

variable "frontend_redirect_uris" {
  description = "Frontend SPA redirect URIs."
  type        = list(string)
  default = [
    "http://localhost:3000/login",
    "https://myfinagent.online/login",
    "https://www.myfinagent.online/login",
  ]
}

variable "frontdoor_sku_name" {
  description = "Front Door SKU."
  type        = string
  default     = "Premium_AzureFrontDoor"
}

variable "frontdoor_enabled" {
  description = "Whether to provision Azure Front Door resources in prod."
  type        = bool
  default     = true
}

variable "frontdoor_origin_use_https" {
  description = "Whether Front Door should forward traffic to the application gateway over HTTPS."
  type        = bool
  default     = false
}

variable "frontdoor_auth_rate_limit_threshold" {
  description = "Per-minute threshold for authentication endpoint rate limiting at Front Door."
  type        = number
  default     = 60
}

variable "frontdoor_auth_rate_limit_duration_minutes" {
  description = "Duration window in minutes for the authentication endpoint rate limit."
  type        = number
  default     = 1
}

variable "frontdoor_origin_hostname_override" {
  description = "Optional explicit origin host name or IP for Front Door. If empty, Terraform uses the private gateway load balancer IP."
  type        = string
  default     = ""
}

variable "gateway_private_load_balancer_ip" {
  description = "Static internal load balancer IP reserved for the prod kGateway Service."
  type        = string
  default     = "10.40.10.50"
}

variable "gateway_private_link_service_name" {
  description = "Deterministic Azure Private Link Service name created for the prod kGateway Service."
  type        = string
  default     = "spendpilot-prod-gateway-pls"
}

variable "gateway_parameters_name" {
  description = "GatewayParameters resource name used to make the prod kGateway Service internal-only."
  type        = string
  default     = "spendpilot-prod-gateway-params"
}

variable "gateway_name" {
  description = "Kubernetes Gateway resource name that fronts the SpendPilot prod app."
  type        = string
  default     = "spend-control-gateway"
}

variable "frontdoor_private_link_request_message" {
  description = "Approval request message attached to the Front Door managed private endpoint for the prod gateway."
  type        = string
  default     = "Approve Front Door access to the SpendPilot prod private gateway."
}

variable "frontdoor_apex_host_name" {
  description = "Optional apex domain to onboard on Front Door."
  type        = string
  default     = "costpilot.online"
}

variable "frontdoor_www_host_name" {
  description = "Optional www domain to onboard on Front Door."
  type        = string
  default     = ""
}

variable "email_data_location" {
  description = "Data location for Azure Communication Services Email."
  type        = string
  default     = "India"
}

variable "email_domain_name" {
  description = "Email domain resource name for prod. Use the custom sender domain when customer-managed."
  type        = string
  default     = "costpilot.online"
}

variable "email_domain_management" {
  description = "Email domain management mode for prod."
  type        = string
  default     = "CustomerManaged"
}

variable "email_sender_username" {
  description = "Mail-from username used by the prod email sender function."
  type        = string
  default     = "notifications"
}

variable "email_sender_display_name" {
  description = "Display name used by the prod email sender function."
  type        = string
  default     = "SpendPilot"
}

variable "email_domain_association_enabled" {
  description = "Whether prod should attempt to link the ACS email domain now. Keep false until Hostinger DNS verification records are live."
  type        = bool
  default     = false
}
