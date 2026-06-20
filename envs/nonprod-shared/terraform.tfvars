prefix                   = "spendpilot"
environment              = "nonprod-shared"
location                 = "Central India"
resource_group_name      = "rg-spendpilot-nonprod-shared"
root_domain_name         = "costpilot.online"
dev_public_host_name     = "dev.costpilot.online"
staging_public_host_name = "stage.costpilot.online"

# Dev is the first non-prod target, so the shared Front Door reads dev state now.
# Staging can be enabled later once the staging runtime endpoint is ready.
read_dev_state     = true
read_staging_state = false
dev_state_key      = "spendpilot.tfstate"

frontdoor_enabled                           = true
document_intelligence_account_name          = "spendpilot-nonprod-docint"
document_intelligence_custom_subdomain_name = "spendpilotnonproddoc"
foundry_account_name                        = "spendpilot-nonprod-foundry"
foundry_custom_subdomain_name               = "spendpilotnonprodai"
foundry_location                            = "East US 2"

tags = {
  env         = "nonprod-shared"
  application = "spendpilot"
  managed_by  = "terraform"
}
