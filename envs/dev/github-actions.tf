data "azuread_application_published_app_ids" "well_known" {}

data "azuread_service_principal" "microsoft_graph" {
  client_id = data.azuread_application_published_app_ids.well_known.result["MicrosoftGraph"]
}

data "azurerm_storage_account" "terraform_state" {
  name                = "lijazterracount"
  resource_group_name = "terra-rg"
}

resource "azuread_application" "github_actions" {
  display_name = "${local.name}-github-actions"
  owners       = [data.azuread_client_config.current.object_id]

  lifecycle {
    ignore_changes = [owners, required_resource_access]
  }
}

resource "azuread_service_principal" "github_actions" {
  client_id = azuread_application.github_actions.client_id
}

resource "azuread_application_api_access" "github_actions_microsoft_graph" {
  application_id = azuread_application.github_actions.id
  api_client_id  = data.azuread_application_published_app_ids.well_known.result["MicrosoftGraph"]

  role_ids = [
    data.azuread_service_principal.microsoft_graph.app_role_ids["Application.ReadWrite.All"],
  ]
}

resource "azuread_app_role_assignment" "github_actions_microsoft_graph_application_read_write_all" {
  app_role_id         = data.azuread_service_principal.microsoft_graph.app_role_ids["Application.ReadWrite.All"]
  principal_object_id = azuread_service_principal.github_actions.object_id
  resource_object_id  = data.azuread_service_principal.microsoft_graph.object_id

  depends_on = [azuread_application_api_access.github_actions_microsoft_graph]
}

resource "azuread_application_federated_identity_credential" "github_actions_pull_request" {
  application_id = azuread_application.github_actions.id
  display_name   = "${replace(local.name, "-", "")}-pull-request"
  description    = "GitHub Actions pull request plans for ${local.github_repository}"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = local.github_actions_oidc_issuer
  subject        = "repo:${local.github_repository}:pull_request"
}

resource "azuread_application_federated_identity_credential" "github_actions_main" {
  application_id = azuread_application.github_actions.id
  display_name   = "${replace(local.name, "-", "")}-main"
  description    = "GitHub Actions applies from ${local.github_repository} ${var.github_actions_main_branch}"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = local.github_actions_oidc_issuer
  subject        = "repo:${local.github_repository}:ref:refs/heads/${var.github_actions_main_branch}"
}

resource "azurerm_role_assignment" "github_actions_subscription_owner" {
  scope                = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  role_definition_name = "Owner"
  principal_id         = azuread_service_principal.github_actions.object_id
}

resource "azurerm_role_assignment" "github_actions_state_blob_owner" {
  scope                = data.azurerm_storage_account.terraform_state.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = azuread_service_principal.github_actions.object_id
}
