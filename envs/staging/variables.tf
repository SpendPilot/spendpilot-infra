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

variable "tags" {
  description = "Additional Azure tags."
  type        = map(string)
  default     = {}
}
