# Terraform Pipeline

## Overview

This repository uses two GitHub Actions workflows:

- `terraform-pr.yml`
  - runs on pull requests to `main`
  - detects only the changed Terraform roots
  - runs `terraform fmt`, `terraform validate`, `tflint`, Trivy IaC scanning, speculative `terraform plan`, and Infracost
  - uploads review-only text artifacts
  - never uploads a reusable binary plan

- `terraform-apply.yml`
  - runs on push to `main` and on `workflow_dispatch`
  - detects only the changed Terraform roots, or uses the explicitly selected root for manual runs
  - creates a fresh saved binary plan from the merged `main` commit
  - uploads the exact plan artifact for that workflow run
  - applies only that exact artifact after GitHub Environment approval where configured

## Active Terraform roots

- `global-shared`
- `identities`
- `nonprod-shared`
- `dev`
- `prod`

`staging` remains in the repository as a placeholder root, but it is intentionally excluded from GitHub Actions validation and apply until a real staging footprint exists in Azure.

## Root configuration model

- non-secret environment settings live in each root's `variables.tf` defaults
- CI does not depend on committed `env.tfvars`
- only sensitive inputs are injected at runtime

## Environment detection

Environment detection is handled by `scripts/terraform-env-detect.sh`.

Rules:
- changes under `envs/<root>/` plan only that root
- changes under `modules/`, `scripts/`, `.github/workflows/terraform-*.yml`, or `.tflint.hcl` plan all active roots
- manual `workflow_dispatch` requires exactly one root input

## Plan artifact safety

PR workflow:
- review-only artifact name: `pr-tfplan-text-<environment>-<pr_sha>-<run_id>`
- includes only text plan output and markdown summary
- binary PR plans are intentionally not uploaded

Apply workflow:
- binary artifact name: `tfplan-<environment>-<commit_sha>-<run_id>`
- includes:
  - `tfplan-<environment>`
  - `tfplan-<environment>.txt`
  - `plan-metadata.json`
- apply verifies:
  - environment matches
  - commit SHA matches
  - workflow run ID matches
  - working directory matches
  - Terraform version matches

This prevents:
- using stale PR plans after merge
- cross-environment artifact mixups
- prod applying a dev plan

## Authentication

Azure authentication uses GitHub Actions OIDC with:
- `azure/login`
- repository or organization variables:
  - `AZURE_CLIENT_ID`
  - `AZURE_TENANT_ID`
  - `AZURE_SUBSCRIPTION_ID`

No `AZURE_CLIENT_SECRET` is required.

## GitHub Environments

Create these GitHub Environments:
- `terraform-global-shared`
- `terraform-identities`
- `terraform-nonprod-shared`
- `terraform-dev`
- `terraform-prod`

Recommended protection:
- `terraform-dev`: optional approval
- `terraform-staging`: approval required
- `terraform-prod`: approval required and restricted to `main`

Plan jobs do not bind to protected environments, so approval gates only block apply.

## Kubeconfig handling

`dev` still pre-seeds kubeconfig with `scripts/terraform-prime-kubeconfig.sh` because that root refreshes live Kubernetes data directly.

`prod` no longer depends on direct Kubernetes API access from the runner. Prod plan/apply uses Azure control-plane calls such as `az aks command invoke` and CLI-backed in-place orchestration for private-cluster operations, so the shared kubeconfig helper is an intentional no-op for prod.

## State handling

- remote backend: Azure Blob Storage (`azurerm`)
- one state key per root
- state files are never uploaded as artifacts
- apply always uses a fresh main-branch plan generated in the same workflow run
