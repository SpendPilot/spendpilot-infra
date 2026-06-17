prefix                     = "spendpilot"
environment                = "global"
location                   = "Central India"
resource_group_name        = "rg-spendpilot-global"
acr_name                   = "spendpilotacr"
acr_sku                    = "Standard"
acr_anonymous_pull_enabled = false
create_acr                 = true
tags = {
  "env" = "global"
}
