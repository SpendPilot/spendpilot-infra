# Environment Setup

## Required repository or organization variables

Set these non-secret variables for `spendpilot-infra` as repository variables or organization variables:

- `AZURE_CLIENT_ID`
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`

Do not put these three only in GitHub Environments if you expect PR validation to work. PR jobs do not bind to `terraform-<env>` environments before the plan step, so environment-scoped variables are not available to `azure/login` there.

Optional Azure Key Vault lookup variables:
- `DEV_TERRAFORM_SECRETS_KEYVAULT_NAME`
- `DEV_POSTGRES_ADMIN_PASSWORD_SECRET_NAME`
- `PROD_TERRAFORM_SECRETS_KEYVAULT_NAME`
- `PROD_POSTGRES_ADMIN_PASSWORD_SECRET_NAME`

## Required secrets

Repository or organization secrets:
- `INFRACOST_API_KEY`

Fallback GitHub secrets if Key Vault lookup is not configured:
- `TF_VAR_POSTGRES_ADMIN_PASSWORD_DEV`
- `TF_VAR_POSTGRES_ADMIN_PASSWORD_PROD`

## Required GitHub Environments

Create:
- `terraform-global-shared`
- `terraform-identities`
- `terraform-nonprod-shared`
- `terraform-staging`
- `terraform-dev`
- `terraform-prod`

Recommended approvals:
- `terraform-global-shared`: approval required
- `terraform-identities`: approval required
- `terraform-nonprod-shared`: approval required
- `terraform-staging`: approval required
- `terraform-dev`: optional
- `terraform-prod`: required

## Azure OIDC setup

The shared identity root already manages the Microsoft Entra application for GitHub Actions.

Manual checks:
1. Confirm the client ID still matches the current output from `envs/identities`.
2. Confirm the federated credential for `repo:SpendPilot/spendpilot-infra:ref:refs/heads/main` exists.
3. Confirm the federated credential for `repo:SpendPilot/spendpilot-infra:pull_request` exists.
4. Confirm the service principal has:
   - backend storage access for Terraform state
   - resource-group or subscription access needed for the active roots
   - Microsoft Graph `Application.ReadWrite.All` for AzureAD-managed app registrations
   - `Key Vault Secrets User` on any vault used for CI secret retrieval

## Manual deployment

Manual apply:
1. Open GitHub Actions.
2. Run `Terraform Apply`.
3. Select one root.
4. Approve the GitHub Environment if required.

## Recovery

If an apply fails:
1. Review the uploaded text plan artifact from the failed workflow run.
2. Fix the Terraform root or cloud-side issue.
3. Re-run the workflow or merge a follow-up change.
4. Do not reuse artifacts from old runs.

## Adding a new Terraform root

1. Create `envs/<root>/`.
2. Put the root's non-secret config into `variables.tf` defaults.
3. Add `terraform.tfvars.example` if the root has secret inputs.
4. Update `scripts/terraform-env-detect.sh`.
5. Add the root to the `workflow_dispatch` choices in `terraform-apply.yml`.
6. Create `terraform-<root>` GitHub Environment if applies should be gated.
