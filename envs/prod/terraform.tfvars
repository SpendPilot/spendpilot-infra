prefix                       = "spendpilot"
environment                  = "prod"
location                     = "Central India"
resource_group_name          = "rg-spendpilot-prod"
aks_node_resource_group_name = "rg-spendpilot-prod-aks-nodes"

# Azure foundation
# Shared ACR now comes from the global-shared Terraform state.
#
# Change the ACR name in envs/global-shared/terraform.tfvars, apply global-shared,
# then apply prod. prod will resolve the registry from remote state automatically.

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
postgres_ha_mode                      = "Disabled"
postgres_ha_standby_zone              = null
postgres_geo_redundant_backup_enabled = true
postgres_storage_mb                   = 32768
postgres_database_name                = "spendpilot"
postgres_server_name                  = "spendpilot-prod-pgsql-2300"

# AI services
document_intelligence_sku                   = "S0"
document_intelligence_account_name          = "spendpilot-prod-docint-2300"
document_intelligence_custom_subdomain_name = "spendpilotproddoc2300"
foundry_sku_name                            = "S0"
foundry_account_name                        = "spendpilot-prod-foundry-2300"
foundry_custom_subdomain_name               = "spendpilotprodai2300"
foundry_location                            = "East US 2"
openai_model_name                           = "gpt-4.1-mini"
openai_model_version                        = "2025-04-14"
openai_deployment_sku_name                  = "GlobalStandard"
openai_deployment_capacity                  = 1

# App bootstrap contract
namespace            = "spend-control"
service_account_name = "spend-control-workload"
app_config_map_name  = "spend-control-config"
app_secret_name      = "spend-control-secrets"
frontend_redirect_uris = [
  "http://localhost:3000/login",
  "https://fin.nexaflow.site/login",
  "https://myfinagent.online/login",
  "https://www.myfinagent.online/login",
]
auth_authority                 = "https://login.microsoftonline.com/common"
backend_application_id_uri     = "api://spendpilot-prod-backend-api-2300"
backend_cors_origins           = "https://fin.nexaflow.site,https://myfinagent.online,https://www.myfinagent.online"
finance_default_currency       = "INR"
frontend_api_base_url          = "/api"
dev_auth_secret                = "disabled-in-production"
allowed_tenant_ids             = ""
platform_admin_emails          = ""
key_vault_name                 = "spendpilot-prod-kv-2300"
documents_storage_account_name = "sp2300proddocs"

# Front Door
frontdoor_enabled                  = false
frontdoor_origin_use_https         = false
frontdoor_origin_hostname_override = "4.247.241.143"
frontdoor_apex_host_name           = "myfinagent.online"
frontdoor_www_host_name            = "www.myfinagent.online"

# Application Gateway edge
app_gateway_enabled              = true
app_gateway_subnet_cidr          = "10.40.30.0/24"
app_gateway_min_capacity         = 1
app_gateway_max_capacity         = 2
app_gateway_backend_ip_addresses = ["4.224.237.131"]
app_gateway_backend_port         = 80
app_gateway_listener_host_name   = ""
app_gateway_tls_enabled          = true
app_gateway_tls_host_name        = "fin.nexaflow.site"

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
