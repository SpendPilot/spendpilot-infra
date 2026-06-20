prefix                     = "spendpilot"
environment                = "global"
location                   = "Central India"
resource_group_name        = "rg-spendpilot-global"
root_domain_name           = "costpilot.online"
legacy_root_domain_name    = "myfinagent.online"
manage_legacy_root_domain  = true
acr_name                   = "spendpilotglobalacr"
acr_sku                    = "Standard"
acr_anonymous_pull_enabled = false
create_acr                 = true

# This is the single edit point for the shared registry name.
# identities and prod both read the ACR from global-shared remote state.
tags = {
  "env" = "global"
}
