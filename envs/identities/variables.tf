variable "subscription_id" {
  description = "Azure subscription ID containing the SpendPilot global shared resources."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[0-9a-fA-F-]{36}$", trimspace(var.subscription_id)))
    error_message = "subscription_id must be a valid GUID."
  }
}

variable "tenant_id" {
  description = "Microsoft Entra tenant ID where the GitHub Actions app registration will be created."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[0-9a-fA-F-]{36}$", trimspace(var.tenant_id)))
    error_message = "tenant_id must be a valid GUID."
  }
}

variable "project_name" {
  description = "Project name used in resource display names."
  type        = string
  default     = "spendpilot"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.project_name))
    error_message = "project_name may contain only letters, numbers, and hyphens."
  }
}

variable "github_actions_application_name" {
  description = "Optional display name override for the shared Microsoft Entra GitHub Actions application."
  type        = string
  default     = ""
}

variable "acr_name" {
  description = "Name of the existing global shared Azure Container Registry."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[a-zA-Z0-9]{5,50}$", var.acr_name))
    error_message = "ACR names must contain only letters and numbers and be between 5 and 50 characters."
  }
}

variable "acr_resource_group_name" {
  description = "Resource group containing the existing global shared ACR."
  type        = string
  nullable    = false

  validation {
    condition     = length(trimspace(var.acr_resource_group_name)) > 0
    error_message = "acr_resource_group_name must not be empty."
  }
}

variable "acr_abac_enabled" {
  description = <<-DESCRIPTION
    Whether the ACR uses 'RBAC Registry + ABAC Repository Permissions'.

    true:
      Assigns 'Container Registry Repository Writer'.

    false:
      Assigns the legacy 'AcrPush' role.

    Check with:
      az acr show \
        --name <acr-name> \
        --resource-group <resource-group> \
        --query roleAssignmentMode \
        --output tsv
  DESCRIPTION

  type     = bool
  nullable = false
}

variable "github_federated_credentials" {
  description = <<-DESCRIPTION
    GitHub OIDC subjects trusted by the single shared app registration.

    Branch subject example:
      repo:SpendPilot/spendpilot-frontend:ref:refs/heads/main

    The map key becomes the federated credential display name.
  DESCRIPTION

  type = map(object({
    subject     = string
    description = optional(string)
  }))

  validation {
    condition = alltrue([
      for credential in values(var.github_federated_credentials) :
      startswith(credential.subject, "repo:")
    ])

    error_message = "Every federated credential subject must start with 'repo:'."
  }
}

variable "additional_role_assignments" {
  description = <<-DESCRIPTION
    Optional additional Azure RBAC assignments for the shared GitHub identity.

    Leave empty while the identity only needs to push images to ACR.

    Example:
      infra_dev_contributor = {
        scope                = "/subscriptions/.../resourceGroups/rg-spendpilot-dev"
        role_definition_name = "Contributor"
      }

    WARNING:
    Every GitHub repository trusted by this shared application will receive
    every role assigned to the service principal.
  DESCRIPTION

  type = map(object({
    scope                = string
    role_definition_name = string
  }))

  default = {}
}

variable "tags" {
  description = "Tags used for global Azure resources where supported."
  type        = map(string)

  default = {
    project     = "spendpilot"
    environment = "global-shared"
    managed-by  = "terraform"
  }
}
