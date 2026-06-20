variable "prefix" {
  description = "Project prefix used for Azure resource names."
  type        = string
  default     = "spendpilot"
}

variable "environment" {
  description = "Deployment environment label."
  type        = string
  default     = "staging"
}

variable "location" {
  description = "Azure region for staging resources."
  type        = string
  default     = "Central India"
}

variable "resource_group_name" {
  description = "Resource group name for the staging environment."
  type        = string
  default     = "rg-spendpilot-staging"
}

variable "root_domain_name" {
  description = "Root public DNS domain used by staging routing."
  type        = string
  default     = "costpilot.online"
}

variable "public_host_name" {
  description = "Primary public hostname expected to route to the staging environment."
  type        = string
  default     = "stage.costpilot.online"
}

variable "frontdoor_origin_hostname_override" {
  description = "Explicit origin host or IP to expose through the shared non-prod Front Door when staging runtime is not yet discovered automatically."
  type        = string
  default     = ""
}

variable "frontdoor_origin_use_https" {
  description = "Whether the staging origin should be reached over HTTPS."
  type        = bool
  default     = false
}

variable "gateway_public_ip" {
  description = "Optional known staging kGateway public IP."
  type        = string
  default     = ""
}

variable "gateway_public_hostname" {
  description = "Optional known staging kGateway public hostname."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Additional Azure tags."
  type        = map(string)
  default     = {}
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

variable "nonprod_shared_state_key" {
  description = "Remote state key for the nonprod-shared root."
  type        = string
  default     = "nonprod-shared.tfstate"
}
