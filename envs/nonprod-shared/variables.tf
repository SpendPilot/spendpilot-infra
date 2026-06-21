variable "prefix" {
  description = "Project prefix used for Azure resource names."
  type        = string
  default     = "spendpilot"
}

variable "environment" {
  description = "Shared environment label."
  type        = string
  default     = "nonprod-shared"
}

variable "location" {
  description = "Azure region for non-prod shared resources."
  type        = string
  default     = "Central India"
}

variable "resource_group_name" {
  description = "Resource group name for non-prod shared resources."
  type        = string
  default     = "rg-spendpilot-nonprod-shared"
}

variable "root_domain_name" {
  description = "Root public DNS domain used by shared non-prod routing."
  type        = string
  default     = "costpilot.online"
}

variable "dev_public_host_name" {
  description = "Custom domain that should route to the dev environment."
  type        = string
  default     = "dev.costpilot.online"
}

variable "staging_public_host_name" {
  description = "Custom domain that should route to the staging environment."
  type        = string
  default     = "stage.costpilot.online"
}

variable "tags" {
  description = "Additional Azure tags."
  type        = map(string)
  default = {
    env         = "nonprod-shared"
    application = "spendpilot"
    managed_by  = "terraform"
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

variable "dev_state_key" {
  description = "Remote state key for the dev environment."
  type        = string
  default     = "spendpilot.tfstate"
}

variable "staging_state_key" {
  description = "Remote state key for the staging environment."
  type        = string
  default     = "staging.tfstate"
}

variable "read_dev_state" {
  description = "Whether nonprod-shared should read the dev env state."
  type        = bool
  default     = true
}

variable "read_staging_state" {
  description = "Whether nonprod-shared should read the staging env state."
  type        = bool
  default     = false
}

variable "frontdoor_enabled" {
  description = "Whether to provision the shared non-prod Front Door resources."
  type        = bool
  default     = true
}

variable "frontdoor_sku_name" {
  description = "Front Door SKU for the shared non-prod edge."
  type        = string
  default     = "Premium_AzureFrontDoor"
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

variable "document_intelligence_sku" {
  description = "Shared non-prod Document Intelligence SKU."
  type        = string
  default     = "S0"
}

variable "document_intelligence_account_name" {
  description = "Optional explicit name for the shared non-prod Document Intelligence account."
  type        = string
  default     = "spendpilot-nonprod-docint"
}

variable "document_intelligence_custom_subdomain_name" {
  description = "Optional explicit custom subdomain for the shared non-prod Document Intelligence account."
  type        = string
  default     = "spendpilotnonproddoc"
}

variable "foundry_sku_name" {
  description = "Shared non-prod Azure AI Foundry/OpenAI account SKU."
  type        = string
  default     = "S0"
}

variable "foundry_account_name" {
  description = "Optional explicit name for the shared non-prod Azure AI Foundry/OpenAI account."
  type        = string
  default     = "spendpilot-nonprod-foundry"
}

variable "foundry_custom_subdomain_name" {
  description = "Optional explicit custom subdomain for the shared non-prod Azure AI Foundry/OpenAI account."
  type        = string
  default     = "spendpilotnonprodai"
}

variable "foundry_location" {
  description = "Region used for the shared non-prod Azure AI Foundry/OpenAI account."
  type        = string
  default     = "East US 2"
}

variable "openai_model_name" {
  description = "Default shared non-prod Azure AI Foundry model deployment name."
  type        = string
  default     = "gpt-4.1-mini"
}

variable "openai_model_version" {
  description = "Default shared non-prod Azure AI Foundry model version."
  type        = string
  default     = "2025-04-14"
}

variable "openai_deployment_sku_name" {
  description = "Shared non-prod Azure OpenAI deployment SKU."
  type        = string
  default     = "GlobalStandard"
}

variable "openai_deployment_capacity" {
  description = "Shared non-prod Azure OpenAI deployment capacity."
  type        = number
  default     = 1
}
