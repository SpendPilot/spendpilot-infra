output "github_actions_application_display_name" {
  description = "Display name of the shared GitHub Actions Microsoft Entra application."
  value       = azuread_application.github_actions.display_name
}

output "github_actions_client_id" {
  description = "Set this as AZURE_CLIENT_ID in every trusted GitHub repository."
  value       = azuread_application.github_actions.client_id
}

output "github_actions_application_object_id" {
  description = "Object ID of the Microsoft Entra application registration."
  value       = azuread_application.github_actions.object_id
}

output "github_actions_service_principal_object_id" {
  description = "Object ID of the enterprise application/service principal used for Azure RBAC."
  value       = azuread_service_principal.github_actions.object_id
}

output "azure_tenant_id" {
  description = "Set this as AZURE_TENANT_ID in GitHub."
  value       = var.tenant_id
}

output "azure_subscription_id" {
  description = "Set this as AZURE_SUBSCRIPTION_ID in GitHub."
  value       = var.subscription_id
}

output "acr_id" {
  description = "Resource ID of the global shared Azure Container Registry."
  value       = data.azurerm_container_registry.global_shared.id
}

output "acr_name" {
  description = "Name of the global shared Azure Container Registry."
  value       = data.azurerm_container_registry.global_shared.name
}

output "acr_login_server" {
  description = "ACR login server used when building image names."
  value       = data.azurerm_container_registry.global_shared.login_server
}

output "acr_push_role_name" {
  description = "ACR role assigned to the shared GitHub Actions service principal."
  value       = local.acr_push_role_name
}

output "federated_credential_subjects" {
  description = "GitHub OIDC subjects trusted by the shared application registration."

  value = {
    for name, credential in var.github_federated_credentials :
    name => credential.subject
  }
}

output "github_repository_variables" {
  description = "Non-secret values to configure in the GitHub repositories."

  value = {
    AZURE_CLIENT_ID       = azuread_application.github_actions.client_id
    AZURE_TENANT_ID       = var.tenant_id
    AZURE_SUBSCRIPTION_ID = var.subscription_id
    ACR_NAME              = data.azurerm_container_registry.global_shared.name
    ACR_LOGIN_SERVER      = data.azurerm_container_registry.global_shared.login_server
  }
}

output "additional_role_assignments" {
  description = "Additional Azure roles assigned to the shared GitHub identity."

  value = {
    for name, assignment in azurerm_role_assignment.additional :
    name => {
      scope                = assignment.scope
      role_definition_name = assignment.role_definition_name
    }
  }
}