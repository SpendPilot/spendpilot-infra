variable "prefix" {
  description = "Project prefix used for Azure resource names."
  type        = string
  default     = "spendpilot"
}

variable "environment" {
  description = "Shared environment label."
  type        = string
  default     = "global"
}

variable "location" {
  description = "Azure region for global shared resources."
  type        = string
  default     = "Central India"
}

variable "resource_group_name" {
  description = "Resource group name for global shared resources."
  type        = string
  default     = "rg-spendpilot-global"
}

variable "root_domain_name" {
  description = "Primary root public DNS domain hosted in Azure DNS."
  type        = string
  default     = "costpilot.online"
}

variable "legacy_root_domain_name" {
  description = "Legacy root public DNS domain kept in Azure DNS for rollback or historical references."
  type        = string
  default     = "myfinagent.online"
}

variable "manage_legacy_root_domain" {
  description = "Keep managing the legacy Azure DNS zone alongside the new primary root domain."
  type        = bool
  default     = true
}

variable "acr_name" {
  description = "Optional explicit ACR name override."
  type        = string
  default     = ""
}

variable "acr_sku" {
  description = "ACR SKU."
  type        = string
  default     = "Standard"
}

variable "acr_anonymous_pull_enabled" {
  description = "Allow anonymous pull access to the shared ACR."
  type        = bool
  default     = false
}

variable "create_acr" {
  description = "Create the shared ACR from this root."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional Azure tags."
  type        = map(string)
  default     = {}
}
