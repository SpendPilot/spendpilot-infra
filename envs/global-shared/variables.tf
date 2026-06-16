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
