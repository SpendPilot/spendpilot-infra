variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "server_version" {
  type = string
}

variable "delegated_subnet_id" {
  type = string
}

variable "virtual_network_ids" {
  type = list(string)
}

variable "private_dns_zone_name" {
  type = string
}

variable "administrator_login" {
  type = string
}

variable "administrator_password" {
  type      = string
  sensitive = true
}

variable "storage_mb" {
  type = number
}

variable "sku_name" {
  type = string
}

variable "backup_retention_days" {
  type    = number
  default = 7
}

variable "zone" {
  type    = string
  default = "1"
}

variable "ha_mode" {
  type    = string
  default = "ZoneRedundant"
}

variable "ha_standby_zone" {
  type    = string
  default = "2"
}

variable "database_name" {
  type = string
}

variable "collation" {
  type    = string
  default = "en_US.utf8"
}

variable "charset" {
  type    = string
  default = "UTF8"
}

variable "tags" {
  type    = map(string)
  default = {}
}
