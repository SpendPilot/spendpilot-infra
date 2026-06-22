variable "prefix" {
  description = "Short application prefix used in Azure resource names."
  type        = string
  default     = "spendpilot"
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region."
  type        = string
  default     = "Central India"
}

variable "resource_group_name" {
  description = "Primary Azure resource group name used for the platform stack."
  type        = string
  default     = "spendpilot-rg"
}

variable "aks_node_resource_group_name" {
  description = "Azure-managed AKS node resource group name."
  type        = string
  default     = "spendpilot-aks-rg"
}

variable "tags" {
  description = "Additional Azure tags."
  type        = map(string)
  default = {
    owner   = "platform-team"
    project = "spend-control"
  }
}

variable "backend_resource_group_name" {
  description = "Azure Blob backend resource group used by remote state reads."
  type        = string
  default     = "terraform-rg"
}

variable "backend_storage_account_name" {
  description = "Azure Blob backend storage account used by remote state reads."
  type        = string
  default     = "lijaztf"
}

variable "backend_container_name" {
  description = "Azure Blob backend container used by remote state reads."
  type        = string
  default     = "states"
}

variable "global_shared_state_key" {
  description = "Remote state key for the global-shared root."
  type        = string
  default     = "global-shared.tfstate"
}

variable "nonprod_shared_state_key" {
  description = "Remote state key for the nonprod-shared root."
  type        = string
  default     = "nonprod-shared.tfstate"
}

variable "identities_state_key" {
  description = "Remote state key for the shared identities root."
  type        = string
  default     = "identities.tfstate"
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
  description = "Pinned Argo CD Helm chart version."
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

variable "key_vault_name" {
  description = "Optional override for the dev Key Vault name."
  type        = string
  default     = ""
}

variable "key_vault_sku_name" {
  description = "Key Vault SKU used for dev runtime secrets."
  type        = string
  default     = "standard"
}

variable "key_vault_public_network_access_enabled" {
  description = "Whether the dev Key Vault is reachable over public network access."
  type        = bool
  default     = true
}

variable "key_vault_secrets_provider_enabled" {
  description = "Enable the AKS Key Vault Secrets Provider addon in dev."
  type        = bool
  default     = true
}

variable "key_vault_secret_rotation_enabled" {
  description = "Enable automatic Key Vault secret rotation for the AKS addon in dev."
  type        = bool
  default     = true
}

variable "key_vault_secret_rotation_interval" {
  description = "Rotation poll interval used by the AKS Key Vault Secrets Provider addon in dev."
  type        = string
  default     = "2m"
}

variable "key_vault_database_url_secret_name" {
  description = "Key Vault secret name that stores DATABASE_URL for dev."
  type        = string
  default     = "spend-control-database-url"
}

variable "key_vault_dev_auth_secret_name" {
  description = "Key Vault secret name that stores DEV_AUTH_SECRET for dev."
  type        = string
  default     = "spend-control-dev-auth-secret"
}

variable "key_vault_secrets_officer_principal_id" {
  description = "Stable Microsoft Entra object ID that should retain Key Vault Secrets Officer on the dev vault."
  type        = string
  default     = "26aed7c2-6718-47f1-997c-ab154ea36be0"
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
  description = "Kubernetes namespace used for the application."
  type        = string
  default     = "spend-control"
}

variable "service_account_name" {
  description = "Kubernetes service account used by the application workloads."
  type        = string
  default     = "spend-control-workload"
}

variable "vnet_cidr" {
  type    = string
  default = "10.40.0.0/16"
}

variable "aks_subnet_cidr" {
  type    = string
  default = "10.40.10.0/24"
}

variable "db_subnet_cidr" {
  type    = string
  default = "10.40.20.0/24"
}

variable "private_endpoint_subnet_cidr" {
  description = "Dedicated subnet CIDR for private endpoints."
  type        = string
  default     = "10.40.30.0/24"
}

variable "enable_key_vault_private_endpoint" {
  description = "Whether to create a private endpoint for the dev Key Vault."
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
  type    = string
  default = "Standard_D2s_v3"
}

variable "system_node_min_count" {
  type    = number
  default = 1
}

variable "system_node_max_count" {
  type    = number
  default = 1
}

variable "user_node_vm_size" {
  type    = string
  default = "Standard_D2s_v3"
}

variable "user_node_min_count" {
  type    = number
  default = 0
}

variable "user_node_max_count" {
  type    = number
  default = 1
}

variable "postgres_admin_login" {
  description = "PostgreSQL administrator username."
  type        = string
  default     = "spendpilot"
}

variable "postgres_admin_password" {
  description = "PostgreSQL administrator password."
  type        = string
  sensitive   = true
}

variable "postgres_version" {
  type    = string
  default = "16"
}

variable "postgres_sku_name" {
  type    = string
  default = "GP_Standard_D2s_v3"
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
  type    = number
  default = 32768
}

variable "postgres_database_name" {
  type    = string
  default = "spendcontrol"
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
  default     = "10.42.0.0/16"
}

variable "postgres_dr_db_subnet_cidr" {
  description = "Delegated subnet CIDR for the PostgreSQL disaster recovery replica."
  type        = string
  default     = "10.42.20.0/24"
}

variable "postgres_dr_zone" {
  description = "Optional availability zone used for the PostgreSQL disaster recovery replica. Leave empty when the target region does not expose zonal placement for the selected SKU."
  type        = string
  default     = ""
}

variable "postgres_dr_replica_server_name" {
  description = "Optional explicit name override for the PostgreSQL disaster recovery replica."
  type        = string
  default     = "spendpilot-dev-pgsql-dr"
}

variable "acr_sku" {
  type    = string
  default = "Standard"
}

variable "image_tag" {
  description = "Container image tag used for frontend and backend builds."
  type        = string
  default     = "latest"
}

variable "build_images_during_apply" {
  description = "When true, terraform apply will call az acr build for the frontend and backend images."
  type        = bool
  default     = false
}

variable "frontdoor_sku_name" {
  description = "Front Door SKU."
  type        = string
  default     = "Premium_AzureFrontDoor"
}

variable "frontdoor_origin_use_https" {
  description = "Whether Front Door should forward traffic to the AKS gateway over HTTPS. Keep this false unless the gateway origin serves a publicly trusted certificate."
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
  description = "Optional DNS hostname for the AKS gateway origin. Prefer a stable Azure or custom DNS name over the raw public IP when available."
  type        = string
  default     = ""
}

variable "frontdoor_apex_custom_domain_id" {
  description = "Optional Azure resource ID for the validated dev Front Door custom domain, such as dev.costpilot.online."
  type        = string
  default     = ""
}

variable "frontdoor_www_custom_domain_id" {
  description = "Optional Azure resource ID for an additional validated dev Front Door custom domain."
  type        = string
  default     = ""
}

variable "public_host_name" {
  description = "Primary public hostname expected to route to the dev environment."
  type        = string
  default     = "dev.costpilot.online"
}

variable "platform_admin_emails" {
  description = "Comma-separated platform admin emails passed into the workload config."
  type        = string
  default     = "lijazsalim@gmail.com"
}

variable "allowed_tenant_ids" {
  description = "Comma-separated tenant IDs allowed to call the API. Leave empty to allow any consenting Entra tenant."
  type        = string
  default     = ""
}

variable "frontend_redirect_uris" {
  description = "Additional redirect URIs for the frontend SPA app registration."
  type        = list(string)
  default     = ["http://localhost:3000/login"]
}

variable "github_repository_owner" {
  description = "GitHub repository owner used for the GitHub Actions OIDC subject."
  type        = string
  default     = "SpendPilot"
}

variable "github_repository_name" {
  description = "GitHub repository name used for the GitHub Actions OIDC subject."
  type        = string
  default     = "spend-control-platform"
}

variable "github_actions_main_branch" {
  description = "GitHub branch allowed to exchange OIDC tokens for mainline Terraform applies."
  type        = string
  default     = "main"
}

variable "email_data_location" {
  description = "Data location for Azure Communication Services Email."
  type        = string
  default     = "India"
}

variable "email_domain_name" {
  description = "Email domain resource name for dev. Use AzureManagedDomain for managed domains."
  type        = string
  default     = "AzureManagedDomain"
}

variable "email_domain_management" {
  description = "Email domain management mode for dev."
  type        = string
  default     = "AzureManaged"
}

variable "email_sender_username" {
  description = "Mail-from username used by the dev email sender function."
  type        = string
  default     = "DoNotReply"
}

variable "email_sender_display_name" {
  description = "Display name used by the dev email sender function."
  type        = string
  default     = "SpendPilot Dev"
}
