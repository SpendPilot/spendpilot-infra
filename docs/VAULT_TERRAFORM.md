# Vault And Terraform

## Current SpendPilot position

This repository already uses Azure Key Vault for runtime secrets, so the new CI/CD pipeline prefers:
- Azure OIDC for authentication
- Azure Key Vault for optional CI secret retrieval
- GitHub Secrets only as a fallback for plan-time Terraform inputs that are not yet centralized

HashiCorp Vault is not enabled in Terraform by default in this repository.

## Why HashiCorp Vault is not wired directly today

The main sensitive Terraform input here is `postgres_admin_password`. Terraform must pass that value into Azure PostgreSQL creation, which means Terraform will still treat it as a managed input. Adding a Vault provider would not eliminate that state exposure risk for the resource itself.

Because of that, the safe default is:
- do not add a Vault provider just to copy raw secrets through Terraform
- keep runtime application secrets in Azure Key Vault and let workloads read them at runtime
- use OIDC-authenticated secret retrieval in CI only for unavoidable Terraform inputs

## If HashiCorp Vault is added later

Use it only for CI-time secret delivery, not for application runtime where Azure Key Vault already exists.

Recommended design:
- GitHub Actions authenticates to Vault with OIDC
- Vault role is scoped per environment
- Vault policy exposes only the minimal secret path
- workflow reads the secret into an ephemeral environment variable
- Terraform consumes the variable without writing extra secret artifacts

Example future paths:
- `kv/data/terraform/dev`
- `kv/data/terraform/staging`
- `kv/data/terraform/prod`

Example future policy shape:
- `read` on only the environment-specific path
- no list or write access for CI roles unless explicitly required

## Temporary fallback if Vault is introduced before OIDC is ready

If you adopt HashiCorp Vault later and cannot use OIDC immediately:
- use short-lived `VAULT_TOKEN`
- keep `VAULT_ADDR` in GitHub variables
- keep `VAULT_TOKEN` in GitHub secrets
- mark the fallback as temporary

Do not commit Vault tokens or static root credentials.
