variable "vm_names" {
  type = list(string)
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

variable "private_ip_addresses" {
  type    = list(string)
  default = []
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

variable "zones" {
  type    = list(string)
  default = ["1", "2", "3"]
}

variable "node_role" {
  type = string
}

variable "postgres_enabled" {
  type    = bool
  default = false
}

variable "postgres_image" {
  type    = string
  default = "postgres:16"
}

variable "postgres_db" {
  type    = string
  default = "spend_control"
}

variable "postgres_user" {
  type    = string
  default = "spendpilot"
}

variable "postgres_password" {
  type      = string
  sensitive = true
  default   = null
}

variable "postgres_port" {
  type    = number
  default = 5432
}

variable "ollama_enabled" {
  type    = bool
  default = false
}

variable "ollama_image" {
  type    = string
  default = "ollama/ollama:latest"
}

variable "ollama_model" {
  type    = string
  default = "llama3.2"
}

variable "ollama_port" {
  type    = number
  default = 11434
}

variable "bootstrap_repo_owner" {
  type    = string
  default = "SpendPilot"
}

variable "bootstrap_repo_branch" {
  type    = string
  default = "main"
}

variable "bootstrap_app_env" {
  type    = string
  default = "production"
}

variable "bootstrap_public_base_url" {
  type    = string
  default = ""
}

variable "bootstrap_data_vm_private_ip" {
  type    = string
  default = ""
}

variable "bootstrap_jwt_secret_key" {
  type      = string
  sensitive = true
  default   = "dev-secret-change-me"
}

variable "associate_with_app_gateway" {
  type    = bool
  default = false
}

variable "app_gateway_backend_pool_id" {
  type    = string
  default = ""
}

variable "tags" {
  type    = map(string)
  default = {}
}
