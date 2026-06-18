subscription_id = "c00887fb-883e-4d8b-83ba-697054b43421"
tenant_id       = "23009888-f985-4438-a6a8-32650f036be3"

project_name = "spendpilot"

# Optional override.
# Leave empty to use "<project_name>-github-actions".
github_actions_application_name = ""

# Reads the shared ACR from the global-shared remote state.
#
# Change the ACR name in global-shared only, then apply global-shared before identities.
# identities will resolve the registry from that state automatically.
#
# Run after global-shared apply:
#
# az acr show \
#   --name <global-shared-acr-name> \
#   --resource-group <global-shared-rg> \
#   --query roleAssignmentMode \
#   --output tsv
#
# Set true when the returned mode is ABAC-enabled/rbac-abac.
acr_abac_enabled = false

github_federated_credentials = {
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

  docs_main = {
    subject     = "repo:SpendPilot/spendpilot-docs:ref:refs/heads/main"
    description = "Allows the SpendPilot docs main branch to access Azure when required."
  }
}

# Start with no additional Azure permissions.
#
# The identity initially receives only ACR push permission.
additional_role_assignments = {}

tags = {
  project     = "spendpilot"
  environment = "global-shared"
  managed-by  = "terraform"
  purpose     = "github-actions-oidc"
}
