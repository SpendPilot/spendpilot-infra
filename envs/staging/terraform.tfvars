prefix              = "spendpilot"
environment         = "staging"
location            = "Central India"
resource_group_name = "rg-spendpilot-staging"
root_domain_name    = "costpilot.online"
public_host_name    = "stage.costpilot.online"

# Fill these in when the staging runtime is provisioned or when a known
# kGateway public endpoint is available for the shared non-prod Front Door.
frontdoor_origin_hostname_override = ""
frontdoor_origin_use_https         = false
gateway_public_ip                  = ""
gateway_public_hostname            = ""
email_data_location                = "India"
email_domain_name                  = "AzureManagedDomain"
email_domain_management            = "AzureManaged"
email_sender_username              = "DoNotReply"
email_sender_display_name          = "SpendPilot Staging"

tags = {
  env         = "staging"
  application = "spendpilot"
  managed_by  = "terraform"
}
