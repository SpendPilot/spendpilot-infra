# Replace the password and restrict SSH CIDRs before running `terraform apply`.
prefix              = "spendpilot"
environment         = "prod"
location            = "Central India"
resource_group_name = "spendpilot-rg"

# Azure tags applied to all resources in this stack.
tags = {
  owner   = "platform-team"
  project = "spend-control"
}

# VM administrator settings.
admin_username      = "lijaz"
admin_password      = "Lijazsalim@2020"
admin_allowed_cidrs = []

# Network topology.
edge_vnet_cidr         = "10.10.0.0/16"
app_vnet_cidr          = "10.11.0.0/16"
data_vnet_cidr         = "10.12.0.0/16"
appgw_subnet_cidr      = "10.10.0.0/24"
bastion_subnet_cidr    = "10.10.1.0/24"
firewall_subnet_cidr   = "10.10.2.0/24"
frontend_subnet_cidr   = "10.11.0.0/24"
backend_subnet_cidr    = "10.11.1.0/24"
static_app_subnet_cidr = "10.11.2.0/24"
data_ai_subnet_cidr    = "10.12.0.0/24"
postgres_subnet_cidr   = "10.12.1.0/24"
ollama_lb_private_ip   = "10.12.0.10"

# Availability zones used when creating the three VMs.
zones = ["1", "2", "3"]

# VM sizing.
frontend_vm_size   = "Standard_D2s_v3"
backend_vm_size    = "Standard_D2s_v3"
data_vm_size       = "Standard_D2s_v3"
static_app_vm_size = "Standard_D2s_v3"

frontend_vmss_min_instances = 1
frontend_vmss_max_instances = 2
backend_vmss_min_instances  = 1
backend_vmss_max_instances  = 2
data_ai_vmss_min_instances  = 1
data_ai_vmss_max_instances  = 2

# App Gateway autoscaling and routing edge.
app_gateway_min_capacity = 2
app_gateway_max_capacity = 6

# Repository bootstrap for frontend/backend VM startup.
bootstrap_repo_owner  = "SpendPilot"
bootstrap_repo_branch = "main"
jwt_secret_key        = "dev-secret-change-me"
primary_host_name     = "myfinagent.online"
static_app_host_name  = "app.myfinagent.online"

# Self-hosted PostgreSQL container on the data VM.
postgres_database_name         = "spend_control"
postgres_app_username          = "spendpilot"
postgres_app_password          = "spendpilot"
postgres_version               = "16"
postgres_sku_name              = "GP_Standard_D4ds_v5"
postgres_storage_mb            = 131072
postgres_backup_retention_days = 7
postgres_zone                  = "1"
postgres_ha_mode               = "SameZone"
postgres_ha_standby_zone       = "1"

# Ollama on the data VM.
ollama_container_image = "ollama/ollama:latest"
ollama_model           = "llama3.2"
ollama_port            = 11434
