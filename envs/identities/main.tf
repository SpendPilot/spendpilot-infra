data "azuread_client_config" "current" {}

data "terraform_remote_state" "global_shared" {
  backend = "azurerm"

  config = {
    resource_group_name  = var.backend_resource_group_name
    storage_account_name = var.backend_storage_account_name
    container_name       = var.backend_container_name
    key                  = var.global_shared_state_key
    subscription_id      = var.subscription_id
    tenant_id            = var.tenant_id
  }
}

data "azurerm_container_registry" "global_shared" {
  name                = data.terraform_remote_state.global_shared.outputs.acr_name
  resource_group_name = data.terraform_remote_state.global_shared.outputs.resource_group_name
}

locals {
  github_oidc_issuer              = "https://token.actions.githubusercontent.com"
  github_oidc_audience            = "api://AzureADTokenExchange"
  normalized_project_name         = lower(var.project_name)
  github_actions_application_name = trimspace(var.github_actions_application_name) != "" ? trimspace(var.github_actions_application_name) : "${local.normalized_project_name}-github-actions"
  acr_push_role_name = var.acr_abac_enabled ? (
    "Container Registry Repository Writer"
  ) : "AcrPush"
}

# One shared Microsoft Entra application registration for all SpendPilot
# GitHub Actions workflows.
resource "azuread_application" "github_actions" {
  display_name            = local.github_actions_application_name
  sign_in_audience        = "AzureADMyOrg"
  prevent_duplicate_names = true
  owners = [
    data.azuread_client_config.current.object_id
  ]
}
# Enterprise application / service principal belonging to the app registration.
#
# Azure RBAC permissions are assigned to this object.
resource "azuread_service_principal" "github_actions" {
  client_id                    = azuread_application.github_actions.client_id
  app_role_assignment_required = false
  owners = [
    data.azuread_client_config.current.object_id
  ]
}
# Creates multiple federated credentials under the same application.
#
# Examples:
# - frontend main branch
# - services main branch
# - infra main branch
# - docs main branch
resource "azuread_application_federated_identity_credential" "github" {
  for_each       = var.github_federated_credentials
  application_id = azuread_application.github_actions.id
  display_name   = each.key
  description = coalesce(
    each.value.description,
    "GitHub Actions OIDC credential for ${each.value.subject}"
  )
  audiences = [
    local.github_oidc_audience
  ]
  issuer  = local.github_oidc_issuer
  subject = each.value.subject
}
# Grants the shared GitHub Actions identity permission to push images
# to the global shared ACR.
#
# If ABAC is enabled, Repository Writer without an ABAC condition grants
# writer permission across every repository in the registry.
#
# If ABAC is disabled, AcrPush grants push/pull permission across the registry.
resource "azurerm_role_assignment" "github_acr_push" {
  scope                            = data.azurerm_container_registry.global_shared.id
  role_definition_name             = local.acr_push_role_name
  principal_id                     = azuread_service_principal.github_actions.object_id
  skip_service_principal_aad_check = true
}
# Optional future permissions for Terraform or deployment workflows.
#
# Keep this empty until each permission is genuinely required.
resource "azurerm_role_assignment" "additional" {
  for_each = var.additional_role_assignments

  scope                            = each.value.scope
  role_definition_name             = each.value.role_definition_name
  principal_id                     = azuread_service_principal.github_actions.object_id
  skip_service_principal_aad_check = true
}
