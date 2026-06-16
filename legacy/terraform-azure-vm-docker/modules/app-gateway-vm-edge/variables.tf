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

variable "frontend_backend_port" {
  type    = number
  default = 3000
}

variable "api_backend_port" {
  type    = number
  default = 8000
}

variable "static_backend_port" {
  type    = number
  default = 80
}

variable "primary_host_name" {
  type = string
}

variable "static_host_name" {
  type    = string
  default = ""
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
