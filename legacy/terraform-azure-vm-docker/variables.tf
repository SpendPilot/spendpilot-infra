variable "prefix" {
  type    = string
  default = "spendpilot"
}

variable "environment" {
  type    = string
  default = "prod"
}

variable "location" {
  type    = string
  default = "Central India"
}

variable "resource_group_name" {
  description = "Single Azure resource group name used for this entire VMSS deployment stack."
  type        = string
  default     = "spendpilot-prod-rg"
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "admin_username" {
  type    = string
  default = "azureuser"
}

variable "admin_password" {
  description = "Administrator password used for SSH login to the Linux virtual machine scale sets."
  type        = string
  sensitive   = true
}

variable "admin_allowed_cidrs" {
  description = "CIDRs allowed to SSH into the Linux virtual machine scale sets."
  type        = list(string)
  default     = []
}

variable "edge_vnet_cidr" {
  description = "Address space for the edge VNet that hosts ingress and admin-entry services."
  type        = string
  default     = "10.10.0.0/16"
}

variable "app_vnet_cidr" {
  description = "Address space for the application VNet that hosts frontend and backend VM scale sets."
  type        = string
  default     = "10.11.0.0/16"
}

variable "data_vnet_cidr" {
  description = "Address space for the data VNet that hosts PostgreSQL and Ollama/data services."
  type        = string
  default     = "10.12.0.0/16"
}

variable "appgw_subnet_cidr" {
  type    = string
  default = "10.10.0.0/24"
}

variable "bastion_subnet_cidr" {
  description = "Dedicated Azure Bastion subnet. Azure requires the subnet name AzureBastionSubnet and at least a /26 range."
  type        = string
  default     = "10.10.1.0/24"
}

variable "firewall_subnet_cidr" {
  description = "Dedicated Azure Firewall subnet in the hub VNet."
  type        = string
  default     = "10.10.2.0/24"
}

variable "frontend_subnet_cidr" {
  type    = string
  default = "10.11.0.0/24"
}

variable "backend_subnet_cidr" {
  type    = string
  default = "10.11.1.0/24"
}

variable "static_app_subnet_cidr" {
  description = "Subnet for the host-routed static application VM."
  type        = string
  default     = "10.11.2.0/24"
}

variable "data_ai_subnet_cidr" {
  type    = string
  default = "10.12.0.0/24"
}

variable "postgres_subnet_cidr" {
  type    = string
  default = "10.12.1.0/24"
}

variable "ollama_lb_private_ip" {
  description = "Static private IP exposed by the internal load balancer in front of the data-ai VM scale set."
  type        = string
  default     = "10.12.0.10"
}

variable "frontend_vm_size" {
  type    = string
  default = "Standard_D4ds_v5"
}

variable "backend_vm_size" {
  type    = string
  default = "Standard_D8ds_v5"
}

variable "data_vm_size" {
  type    = string
  default = "Standard_D4ds_v5"
}

variable "frontend_vmss_min_instances" {
  type    = number
  default = 1
}

variable "frontend_vmss_max_instances" {
  type    = number
  default = 2
}

variable "backend_vmss_min_instances" {
  type    = number
  default = 1
}

variable "backend_vmss_max_instances" {
  type    = number
  default = 2
}

variable "data_ai_vmss_min_instances" {
  type    = number
  default = 1
}

variable "data_ai_vmss_max_instances" {
  type    = number
  default = 2
}

variable "static_app_vm_size" {
  description = "Size of the single VM that serves the host-routed static site."
  type        = string
  default     = "Standard_D2s_v3"
}

variable "postgres_database_name" {
  description = "Application database name created in Azure Database for PostgreSQL Flexible Server."
  type        = string
  default     = "spend_control"
}

variable "postgres_app_username" {
  description = "Application login used by Azure Database for PostgreSQL Flexible Server."
  type        = string
  default     = "spendpilot"
}

variable "postgres_app_password" {
  description = "Application password used by Azure Database for PostgreSQL Flexible Server."
  type        = string
  sensitive   = true
}

variable "postgres_version" {
  type    = string
  default = "16"
}

variable "postgres_sku_name" {
  type    = string
  default = "GP_Standard_D4ds_v5"
}

variable "postgres_storage_mb" {
  type    = number
  default = 131072
}

variable "postgres_backup_retention_days" {
  type    = number
  default = 7
}

variable "postgres_zone" {
  type    = string
  default = "1"
}

variable "postgres_ha_mode" {
  type    = string
  default = "ZoneRedundant"
}

variable "postgres_ha_standby_zone" {
  type    = string
  default = "2"
}

variable "ollama_container_image" {
  description = "Container image used for the Ollama service on the data-ai VM scale set."
  type        = string
  default     = "ollama/ollama:latest"
}

variable "ollama_model" {
  description = "Ollama model to pull automatically on first boot."
  type        = string
  default     = "llama3.2"
}

variable "ollama_port" {
  description = "Private port exposed by Ollama on the data-ai VM scale set."
  type        = number
  default     = 11434
}

variable "bootstrap_repo_owner" {
  type    = string
  default = "SpendPilot"
}

variable "bootstrap_repo_branch" {
  type    = string
  default = "main"
}

variable "jwt_secret_key" {
  type      = string
  sensitive = true
  default   = "dev-secret-change-me"
}

variable "primary_host_name" {
  description = "Primary host name served by the main spend-control frontend and API."
  type        = string
  default     = "myfinagent.online"
}

variable "static_app_host_name" {
  description = "Host name routed to the demonstration static NGINX VM."
  type        = string
  default     = "app.myfinagent.online"
}

variable "zones" {
  type    = list(string)
  default = ["1", "2", "3"]
}

variable "app_gateway_min_capacity" {
  type    = number
  default = 2
}

variable "app_gateway_max_capacity" {
  type    = number
  default = 6
}
