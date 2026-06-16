# Replace the password before running `terraform apply`.
prefix                             = "spendpilot"
environment                        = "prod"
location                           = "Central India"
resource_group_name                = "spendpilot-rg"
aks_node_resource_group_name       = "spendpilot-aks-rg"
postgres_admin_login               = "spendpilot"
postgres_admin_password            = "postgresspass"
platform_admin_emails              = "lijazsalim@gmail.com"
frontdoor_origin_use_https         = false
frontdoor_origin_hostname_override = "spendpilot-prod-origin-ci.centralindia.cloudapp.azure.com"
frontdoor_apex_custom_domain_id    = "/subscriptions/e1f5b4be-e0ba-4ccb-8708-a949458fcd83/resourceGroups/spendpilot-rg/providers/Microsoft.Cdn/profiles/spendpilot-prod-fd/customDomains/myfinagent-online-08dc"
frontdoor_www_custom_domain_id     = "/subscriptions/e1f5b4be-e0ba-4ccb-8708-a949458fcd83/resourceGroups/spendpilot-rg/providers/Microsoft.Cdn/profiles/spendpilot-prod-fd/customDomains/www-myfinagent-online"

tags = {
  owner   = "platform-team"
  project = "spend-control"
}
