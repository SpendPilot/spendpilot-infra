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

variable "min_instances" {
  type = number
}

variable "max_instances" {
  type = number
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

variable "bootstrap_public_api_base_url" {
  type    = string
  default = ""
}

variable "bootstrap_public_base_url" {
  type    = string
  default = ""
}

variable "bootstrap_database_url" {
  type    = string
  default = ""
}

variable "bootstrap_database_host" {
  type    = string
  default = ""
}

variable "bootstrap_database_port" {
  type    = number
  default = 5432
}

variable "bootstrap_ollama_base_url" {
  type    = string
  default = ""
}

variable "bootstrap_jwt_secret_key" {
  type      = string
  sensitive = true
  default   = "dev-secret-change-me"
}

variable "bootstrap_expense_service_url" {
  type    = string
  default = "http://expense-service:8001"
}

variable "bootstrap_ai_service_url" {
  type    = string
  default = "http://ai-service:8002"
}

variable "bootstrap_receipt_threshold" {
  type    = number
  default = 75
}

variable "bootstrap_upload_dir" {
  type    = string
  default = "/data/uploads"
}

variable "bootstrap_ollama_timeout" {
  type    = number
  default = 30
}

variable "application_gateway_backend_pool_ids" {
  type    = list(string)
  default = []
}

variable "load_balancer_backend_address_pool_ids" {
  type    = list(string)
  default = []
}

variable "scale_out_cpu_threshold" {
  type    = number
  default = 70
}

variable "scale_in_cpu_threshold" {
  type    = number
  default = 30
}

variable "tags" {
  type    = map(string)
  default = {}
}
