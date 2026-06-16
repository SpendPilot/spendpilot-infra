variable "prefix" {
  description = "Short application prefix used in Azure resource names."
  type        = string
  default     = "spctl"
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
  default     = "prod"
}

variable "location" {
  description = "Azure region."
  type        = string
  default     = "Central India"
}

variable "resource_group_name" {
  description = "Primary Azure resource group name used for the platform stack."
  type        = string
  default     = "spctl-prod-rg"
}

variable "aks_node_resource_group_name" {
  description = "Azure-managed AKS node resource group name."
  type        = string
  default     = "spctl-prod-aks-nodes-rg"
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
  default = 2
}

variable "user_node_vm_size" {
  type    = string
  default = "Standard_D2s_v3"
}

variable "user_node_min_count" {
  type    = number
  default = 1
}

variable "user_node_max_count" {
  type    = number
  default = 3
}

variable "postgres_admin_login" {
  description = "PostgreSQL administrator username."
  type        = string
  default     = "spendcontroladmin"
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
  default     = true
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
  description = "Optional Azure resource ID for the validated apex Front Door custom domain, such as myfinagent.online."
  type        = string
  default     = ""
}

variable "frontdoor_www_custom_domain_id" {
  description = "Optional Azure resource ID for the validated www Front Door custom domain, such as www.myfinagent.online."
  type        = string
  default     = ""
}

variable "document_intelligence_sku" {
  description = "Document Intelligence SKU."
  type        = string
  default     = "S0"
}

variable "foundry_sku_name" {
  description = "Azure AI Foundry/OpenAI account SKU."
  type        = string
  default     = "S0"
}

variable "foundry_location" {
  description = "Region used for Azure AI Foundry model hosting. Kept separate because Central India currently rejects the tested pay-per-token model deployments."
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
  description = "Comma-separated platform admin emails passed into the workload config."
  type        = string
  default     = ""
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
