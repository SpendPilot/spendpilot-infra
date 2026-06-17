prefix                       = "spendpilot"
environment                  = "prod"
location                     = "Central India"
resource_group_name          = "rg-spendpilot-prod"
aks_node_resource_group_name = "rg-spendpilot-prod-aks-nodes"

# Azure foundation
acr_name                = "spendpilotacr"
acr_resource_group_name = "rg-spendpilot-global"

# Networking
vnet_cidr       = "10.40.0.0/16"
aks_subnet_cidr = "10.40.10.0/24"
db_subnet_cidr  = "10.40.20.0/24"
service_cidr    = "10.50.0.0/16"
dns_service_ip  = "10.50.0.10"

# AKS sizing
kubernetes_version      = "1.35"
system_node_vm_size     = "Standard_D2s_v3"
system_node_min_count   = 1
system_node_max_count   = 2
user_node_vm_size       = "Standard_D2s_v3"
user_node_min_count     = 1
user_node_max_count     = 3
private_cluster_enabled = false
authorized_ip_ranges    = []

# PostgreSQL
postgres_admin_login                  = "spendpilotadmin"
postgres_admin_password               = "replace-me"
postgres_version                      = "16"
postgres_sku_name                     = "GP_Standard_D2s_v3"
postgres_zone                         = "1"
postgres_ha_mode                      = "ZoneRedundant"
postgres_ha_standby_zone              = "2"
postgres_geo_redundant_backup_enabled = true
postgres_storage_mb                   = 32768
postgres_database_name                = "spendpilot"

# AI services
document_intelligence_sku  = "S0"
foundry_sku_name           = "S0"
foundry_location           = "East US 2"
openai_model_name          = "gpt-4.1-mini"
openai_model_version       = "2025-04-14"
openai_deployment_sku_name = "GlobalStandard"
openai_deployment_capacity = 1

# App bootstrap contract
namespace            = "spend-control"
service_account_name = "spend-control-workload"
app_config_map_name  = "spend-control-config"
app_secret_name      = "spend-control-secrets"
frontend_redirect_uris = [
  "http://localhost:3000/login",
]
auth_authority           = "https://login.microsoftonline.com/common"
backend_cors_origins     = "https://example.z01.azurefd.net"
finance_default_currency = "INR"
frontend_api_base_url    = "/api"
dev_auth_secret          = "disabled-in-production"
allowed_tenant_ids       = ""
platform_admin_emails    = ""

# Platform bootstrap
kgateway_version     = "2.3.0"
gateway_api_version  = "1.5.1"
argocd_chart_version = "9.5.21"
argocd_namespace     = "argocd"

# Argo CD dashboard exposure
argocd_server_service_type                        = "LoadBalancer"
argocd_server_service_annotations                 = {}
argocd_server_service_load_balancer_source_ranges = []
argocd_server_load_balancer_ip                    = ""

tags = {
  env         = "prod"
  application = "spendpilot"
  managed_by  = "terraform"
}
