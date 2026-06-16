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

variable "tags" {
  type    = map(string)
  default = {}
}
