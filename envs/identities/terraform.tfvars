subscription_id = "e1f5b4be-e0ba-4ccb-8708-a949458fcd83"
tenant_id       = "920e9322-340c-4fbc-bf09-dc8fd6636182"

project_name = "spendpilot"

# Optional override.
# Leave empty to use "<project_name>-github-actions".
github_actions_application_name = ""

acr_name                = "spendpilotacr"
acr_resource_group_name = "rg-spendpilot-global"

# Run:
#
# az acr show \
#   --name spendpilotacr \
#   --resource-group rg-spendpilot-global \
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
