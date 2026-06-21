# SpendPilot Infra

SpendPilot infrastructure is managed from this Terraform repository.

Active Terraform roots:
- `envs/global-shared`
- `envs/identities`
- `envs/nonprod-shared`
- `envs/staging`
- `envs/dev`
- `envs/prod`

Supporting folders:
- `modules/`
- `scripts/`
- `.github/workflows/`

CI/CD entry points:
- `.github/workflows/terraform-pr.yml`
- `.github/workflows/terraform-apply.yml`

Documentation:
- `docs/TERRAFORM_PIPELINE.md`
- `docs/SECRETS_AND_TFVARS.md`
- `docs/ENVIRONMENT_SETUP.md`
- `docs/VAULT_TERRAFORM.md`

Environment-specific non-secret configuration now lives in each root's `variables.tf` defaults. Only sensitive overrides such as `postgres_admin_password` should be passed at runtime through `TF_VAR_*`, Azure Key Vault, or GitHub Secrets.

Legacy folders such as `legacy/`, `vm/`, and `vmss/` are intentionally not part of the new GitHub Actions pipeline.
