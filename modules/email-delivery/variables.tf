variable "name" {
  description = "Base name used for email delivery resources."
  type        = string
}

variable "location" {
  description = "Azure region for regional resources."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group where the resources are created."
  type        = string
}

variable "tags" {
  description = "Tags applied to email delivery resources."
  type        = map(string)
  default     = {}
}

variable "queue_name" {
  description = "Service Bus queue name used for email requests."
  type        = string
  default     = "email-requests"
}

variable "service_bus_sku" {
  description = "Service Bus namespace SKU."
  type        = string
  default     = "Standard"
}

variable "duplicate_detection_history_time_window" {
  description = "Duplicate detection window for the email queue."
  type        = string
  default     = "PT10M"
}

variable "backend_sender_principal_id" {
  description = "Optional principal ID allowed to send email requests to Service Bus."
  type        = string
  default     = ""
}

variable "function_worker_runtime" {
  description = "Functions worker runtime."
  type        = string
  default     = "python"
}

variable "function_python_version" {
  description = "Python version used by the Function App."
  type        = string
  default     = "3.11"
}

variable "function_extension_version" {
  description = "Azure Functions runtime extension version."
  type        = string
  default     = "~4"
}

variable "function_plan_sku_name" {
  description = "App Service plan SKU for the Function App."
  type        = string
  default     = "Y1"
}

variable "function_plan_os_type" {
  description = "Operating system for the Function App service plan."
  type        = string
  default     = "Linux"
}

variable "function_sender_display_name" {
  description = "Display name shown for sent emails."
  type        = string
  default     = "SpendPilot Notifications"
}

variable "function_sender_username" {
  description = "Mail-from username to provision on the ACS email domain."
  type        = string
  default     = "DoNotReply"
}

variable "email_data_location" {
  description = "Data location for Azure Communication Services Email."
  type        = string
  default     = "India"
}

variable "email_domain_name" {
  description = "Domain name for the email domain resource. Use AzureManagedDomain for managed domains."
  type        = string
}

variable "email_domain_management" {
  description = "Email domain management mode."
  type        = string
  default     = "AzureManaged"
}

variable "email_user_engagement_tracking_enabled" {
  description = "Whether ACS email user engagement tracking is enabled."
  type        = bool
  default     = false
}

variable "github_actions_principal_id" {
  description = "Optional GitHub Actions service principal object ID granted permission to deploy function code."
  type        = string
  default     = ""
}

variable "manage_email_domain_association" {
  description = "Whether the module should link the email domain to the communication service."
  type        = bool
  default     = true
}
