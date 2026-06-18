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

variable "zones" {
  type    = list(string)
  default = ["1", "2", "3"]
}

variable "min_capacity" {
  type = number
}

variable "max_capacity" {
  type = number
}

variable "backend_ip_addresses" {
  type = list(string)
}

variable "backend_port" {
  type    = number
  default = 80
}

variable "backend_protocol" {
  type    = string
  default = "Http"
}

variable "probe_path" {
  type    = string
  default = "/health"
}

variable "probe_host" {
  type    = string
  default = ""
}

variable "listener_host_name" {
  type    = string
  default = ""
}

variable "identity_ids" {
  type    = list(string)
  default = []
}

variable "tls_certificate_secret_id" {
  type    = string
  default = ""
}

variable "tls_host_name" {
  type    = string
  default = ""
}

variable "http_redirect_priority" {
  type    = number
  default = 90
}

variable "https_rule_priority" {
  type    = number
  default = 110
}

variable "waf_mode" {
  type    = string
  default = "Prevention"
}

variable "waf_rule_set_version" {
  type    = string
  default = "3.2"
}

variable "tags" {
  type    = map(string)
  default = {}
}
