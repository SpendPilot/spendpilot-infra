variable "name" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "dns_prefix" {
  type = string
}

variable "kubernetes_version" {
  type = string
}

variable "private_cluster_enabled" {
  type    = bool
  default = null
}

variable "cluster_identity_type" {
  type    = string
  default = "SystemAssigned"
}

variable "cluster_identity_ids" {
  type    = list(string)
  default = null
}

variable "private_cluster_public_fqdn_enabled" {
  type    = bool
  default = null
}

variable "authorized_ip_ranges" {
  type    = list(string)
  default = []
}

variable "private_dns_zone_id" {
  type    = string
  default = null
}

variable "api_server_subnet_id" {
  type    = string
  default = null
}

variable "api_server_vnet_integration_enabled" {
  type    = bool
  default = null
}

variable "log_analytics_workspace_id" {
  type = string
}

variable "system_subnet_id" {
  type = string
}

variable "user_subnet_id" {
  type = string
}

variable "system_node_vm_size" {
  type = string
}

variable "system_node_min_count" {
  type = number
}

variable "system_node_max_count" {
  type = number
}

variable "user_node_vm_size" {
  type = string
}

variable "user_node_min_count" {
  type = number
}

variable "user_node_max_count" {
  type = number
}

variable "node_resource_group_name" {
  type = string
}

variable "service_cidr" {
  type = string
}

variable "dns_service_ip" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "key_vault_secrets_provider_enabled" {
  type    = bool
  default = true
}

variable "secret_rotation_enabled" {
  type    = bool
  default = true
}

variable "secret_rotation_interval" {
  type    = string
  default = "2m"
}

variable "monitor_metrics_enabled" {
  type    = bool
  default = null
}

variable "monitor_metrics_annotations_allowed" {
  type    = string
  default = null
}

variable "monitor_metrics_labels_allowed" {
  type    = string
  default = null
}
