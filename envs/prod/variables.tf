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
  default     = {}
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
  default     = ""
}

variable "private_cluster_enabled" {
  description = "Whether to create a private AKS control plane."
  type        = bool
  default     = false
}

variable "authorized_ip_ranges" {
  description = "Optional public IP ranges allowed to reach the AKS API server when the cluster is public."
  type        = list(string)
  default     = []
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
  default     = ""
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
  default     = "ZoneRedundant"
}

variable "postgres_ha_standby_zone" {
  description = "Standby availability zone for PostgreSQL high availability."
  type        = string
  default     = "2"
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
  default     = "spendpilot-prod-pgsql"
}

variable "postgres_dr_replica_enabled" {
  description = "Whether to provision a cross-region PostgreSQL read replica for disaster recovery."
  type        = bool
  default     = false
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
  description = "Availability zone used for the PostgreSQL disaster recovery replica."
  type        = string
  default     = "1"
}

variable "postgres_dr_replica_server_name" {
  description = "Optional explicit name override for the PostgreSQL disaster recovery replica."
  type        = string
  default     = ""
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

variable "document_intelligence_sku" {
  description = "Document Intelligence SKU."
  type        = string
  default     = "S0"
}

variable "document_intelligence_account_name" {
  description = "Optional explicit Document Intelligence account name override."
  type        = string
  default     = "spendpilot-prod-docint"
}

variable "document_intelligence_custom_subdomain_name" {
  description = "Optional explicit Document Intelligence custom subdomain override."
  type        = string
  default     = "spendpilotproddoc"
}

variable "foundry_sku_name" {
  description = "Azure AI Foundry/OpenAI account SKU."
  type        = string
  default     = "S0"
}

variable "foundry_account_name" {
  description = "Optional explicit Azure AI Foundry account name override."
  type        = string
  default     = "spendpilot-prod-foundry"
}

variable "foundry_custom_subdomain_name" {
  description = "Optional explicit Azure AI Foundry custom subdomain override."
  type        = string
  default     = "spendpilotprodai"
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
  default     = "api://spendpilot-prod-backend-api"
}

variable "backend_cors_origins" {
  description = "Comma-separated CORS origins allowed to call the backend APIs."
  type        = string
  default     = "https://example.z01.azurefd.net"
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
  default     = "spendpilotprodst"
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
  default     = ["http://localhost:3000/login"]
}

variable "frontdoor_sku_name" {
  description = "Front Door SKU."
  type        = string
  default     = "Premium_AzureFrontDoor"
}

variable "frontdoor_enabled" {
  description = "Whether to provision Azure Front Door resources in prod."
  type        = bool
  default     = false
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
  description = "Optional explicit origin host name or IP for Front Door. If empty, Terraform reads the current gateway service address from Kubernetes."
  type        = string
  default     = ""
}

variable "frontdoor_apex_host_name" {
  description = "Optional apex domain to onboard on Front Door."
  type        = string
  default     = ""
}

variable "frontdoor_www_host_name" {
  description = "Optional www domain to onboard on Front Door."
  type        = string
  default     = ""
}

variable "app_gateway_enabled" {
  description = "Whether to provision the prod edge Application Gateway."
  type        = bool
  default     = true
}

variable "app_gateway_subnet_cidr" {
  description = "Dedicated subnet CIDR for the prod Application Gateway."
  type        = string
  default     = "10.40.30.0/24"
}

variable "app_gateway_min_capacity" {
  description = "Minimum autoscale capacity for the prod Application Gateway."
  type        = number
  default     = 1
}

variable "app_gateway_max_capacity" {
  description = "Maximum autoscale capacity for the prod Application Gateway."
  type        = number
  default     = 2
}

variable "app_gateway_backend_ip_addresses" {
  description = "Backend IP addresses for the prod edge Application Gateway."
  type        = list(string)
  default     = []
}

variable "app_gateway_backend_port" {
  description = "Backend port for the prod edge Application Gateway."
  type        = number
  default     = 80
}

variable "app_gateway_listener_host_name" {
  description = "Optional host header bound to the prod edge Application Gateway listener."
  type        = string
  default     = ""
}

variable "app_gateway_tls_enabled" {
  description = "Whether to provision host-specific HTTPS termination on the prod Application Gateway."
  type        = bool
  default     = false
}

variable "app_gateway_tls_host_name" {
  description = "DNS host name to terminate on the prod Application Gateway."
  type        = string
  default     = ""
}
