# Replace the password before running `terraform apply`.
prefix                       = "spendpilot"
environment                  = "dev"
location                     = "Central India"
resource_group_name          = "spendpilot-rg"
aks_node_resource_group_name = "spendpilot-aks-rg"
frontend_redirect_uris = [
  "http://localhost:3000/login",
  "https://dev.costpilot.online/login",
]
postgres_admin_login               = "spendpilot"
postgres_admin_password            = "postgresspass"
postgres_dr_replica_enabled        = true
postgres_dr_location               = "South India"
postgres_dr_vnet_cidr              = "10.42.0.0/16"
postgres_dr_db_subnet_cidr         = "10.42.20.0/24"
postgres_dr_replica_server_name    = "spendpilot-dev-pgsql-dr"
platform_admin_emails              = "lijazsalim@gmail.com"
public_host_name                   = "dev.costpilot.online"
system_node_min_count              = 1
system_node_max_count              = 1
user_node_min_count                = 0
user_node_max_count                = 1
build_images_during_apply          = false
frontdoor_origin_use_https         = false
frontdoor_origin_hostname_override = ""
frontdoor_apex_custom_domain_id    = ""
frontdoor_www_custom_domain_id     = ""
email_data_location                = "India"
email_domain_name                  = "AzureManagedDomain"
email_domain_management            = "AzureManaged"
email_sender_username              = "DoNotReply"
email_sender_display_name          = "SpendPilot Dev"

tags = {
  owner   = "platform-team"
  project = "spend-control"
}
