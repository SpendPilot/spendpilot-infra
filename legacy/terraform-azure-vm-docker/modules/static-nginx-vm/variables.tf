variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "vm_size" {
  type = string
}

variable "admin_username" {
  type = string
}

variable "admin_password" {
  type      = string
  sensitive = true
}

variable "zone" {
  type = string
}

variable "host_name" {
  type = string
}

variable "html_content" {
  type = string
}

variable "app_gateway_backend_pool_id" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
