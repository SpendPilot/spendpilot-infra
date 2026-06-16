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
  type = bool
}

variable "authorized_ip_ranges" {
  type    = list(string)
  default = []
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
