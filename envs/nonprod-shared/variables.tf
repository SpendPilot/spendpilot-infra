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

variable "read_dev_state" {
  description = "Whether nonprod-shared should read the dev env state."
  type        = bool
  default     = false
}

variable "read_staging_state" {
  description = "Whether nonprod-shared should read the staging env state."
  type        = bool
  default     = false
}
