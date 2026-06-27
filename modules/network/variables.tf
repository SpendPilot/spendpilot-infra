variable "name" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "address_space" {
  type = list(string)
}

variable "subnets" {
  type = map(object({
    address_prefixes                              = list(string)
    service_endpoints                             = optional(list(string), [])
    delegation_name                               = optional(string)
    delegation_service                            = optional(string)
    delegation_actions                            = optional(list(string), ["Microsoft.Network/virtualNetworks/subnets/join/action"])
    private_link_service_network_policies_enabled = optional(bool, true)
  }))
}

variable "tags" {
  type    = map(string)
  default = {}
}
