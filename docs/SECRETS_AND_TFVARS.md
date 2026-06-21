# Secrets And Tfvars

## What is committed

Committed:
- `envs/*/variables.tf`
- `envs/*/terraform.tfvars.example`

Not committed:
- `terraform.tfvars`
- `*.auto.tfvars`
- `*.auto.tfvars.json`
- state files
- plan files
- generated kubeconfigs

## Current pattern

Non-secret environment settings now live in each root's `variables.tf` defaults.

Secret values must not live in git. The active example is:
- `TF_VAR_postgres_admin_password`

## CI secret resolution order

For `dev` and `prod`, the workflows resolve `TF_VAR_postgres_admin_password` in this order:

1. Azure Key Vault secret if both of these variables are set:
   - `<ENV>_TERRAFORM_SECRETS_KEYVAULT_NAME`
   - `<ENV>_POSTGRES_ADMIN_PASSWORD_SECRET_NAME`
2. GitHub Actions secret fallback:
   - `TF_VAR_POSTGRES_ADMIN_PASSWORD_DEV`
   - `TF_VAR_POSTGRES_ADMIN_PASSWORD_PROD`

The secret value is masked and exported only into the current job environment.

## Local usage

Example:

```bash
cd envs/dev
export TF_VAR_postgres_admin_password='replace-me'
terraform init
terraform plan
```

## Why secrets stay out of tfvars

Keeping secrets out of tracked tfvars prevents:
- accidental git leaks
- artifact leaks
- PR review exposure
- stale copied secrets across environments

## Legacy note

The new pipeline intentionally covers the active `envs/` roots. Legacy folders are not automatically rewritten by this pass and should be cleaned separately if you want the same hygiene there.
