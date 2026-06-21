variable "subscription_id" {
  description = "Azure subscription ID containing the SpendPilot global shared resources."
  type        = string
  nullable    = false
  default     = "c00887fb-883e-4d8b-83ba-697054b43421"

  validation {
    condition     = can(regex("^[0-9a-fA-F-]{36}$", trimspace(var.subscription_id)))
    error_message = "subscription_id must be a valid GUID."
  }
}

variable "tenant_id" {
  description = "Microsoft Entra tenant ID where the GitHub Actions app registration will be created."
  type        = string
  nullable    = false
  default     = "23009888-f985-4438-a6a8-32650f036be3"

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

variable "backend_resource_group_name" {
  description = "Azure Blob backend resource group used to read the global-shared remote state."
  type        = string
  default     = "terraform-rg"
}

variable "backend_storage_account_name" {
  description = "Azure Blob backend storage account used to read the global-shared remote state."
  type        = string
  default     = "lijaztf"
}

variable "backend_container_name" {
  description = "Azure Blob backend container used to read the global-shared remote state."
  type        = string
  default     = "states"
}

variable "global_shared_state_key" {
  description = "State key for the global-shared Terraform root that owns the shared ACR."
  type        = string
  default     = "global-shared.tfstate"
}

variable "acr_abac_enabled" {
  description = <<-DESCRIPTION
    Whether the ACR uses 'RBAC Registry + ABAC Repository Permissions'.

    true:
      Assigns 'Container Registry Repository Writer'.

    false:
      Assigns the legacy 'AcrPush' role.

    Check with the ACR created by global-shared:
      az acr show \
        --name <global-shared-acr-name> \
        --resource-group <global-shared-rg> \
        --query roleAssignmentMode \
        --output tsv
  DESCRIPTION

  type     = bool
  nullable = false
  default  = false
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

  default = {
    frontend_main = {
      subject     = "repo:SpendPilot/spendpilot-frontend:ref:refs/heads/main"
      description = "Allows the SpendPilot frontend main branch to push frontend images."
    }

    services_main = {
      subject     = "repo:SpendPilot/spendpilot-services:ref:refs/heads/main"
      description = "Allows the SpendPilot services main branch to push backend service images."
    }

    helm_main = {
      subject     = "repo:SpendPilot/spendpilot-helm:ref:refs/heads/main"
      description = "Allows the SpendPilot Helm repository main branch to access Azure when required."
    }

    gitops_main = {
      subject     = "repo:SpendPilot/spendpilot-gitops:ref:refs/heads/main"
      description = "Allows the SpendPilot GitOps repository main branch to access Azure when required."
    }

    infra_main = {
      subject     = "repo:SpendPilot/spendpilot-infra:ref:refs/heads/main"
      description = "Allows non-deployment validation from the SpendPilot infra main branch."
    }

    infra_pull_request = {
      subject     = "repo:SpendPilot/spendpilot-infra:pull_request"
      description = "Allows speculative Terraform plans from SpendPilot infra pull requests."
    }

    docs_main = {
      subject     = "repo:SpendPilot/spendpilot-docs:ref:refs/heads/main"
      description = "Allows the SpendPilot docs main branch to access Azure when required."
    }
  }

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

  default = {
    terraform_subscription_owner = {
      scope                = "/subscriptions/c00887fb-883e-4d8b-83ba-697054b43421"
      role_definition_name = "Owner"
    }

    terraform_state_blob_owner = {
      scope                = "/subscriptions/c00887fb-883e-4d8b-83ba-697054b43421/resourceGroups/terraform-rg/providers/Microsoft.Storage/storageAccounts/lijaztf"
      role_definition_name = "Storage Blob Data Owner"
    }

    terraform_dev_key_vault_secrets_user = {
      scope                = "/subscriptions/c00887fb-883e-4d8b-83ba-697054b43421/resourceGroups/spendpilot-rg/providers/Microsoft.KeyVault/vaults/spendpilot-dev-kv"
      role_definition_name = "Key Vault Secrets User"
    }

    terraform_prod_key_vault_secrets_user = {
      scope                = "/subscriptions/c00887fb-883e-4d8b-83ba-697054b43421/resourceGroups/rg-spendpilot-prod/providers/Microsoft.KeyVault/vaults/spendpilot-prod-kv-2300"
      role_definition_name = "Key Vault Secrets User"
    }
  }
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
