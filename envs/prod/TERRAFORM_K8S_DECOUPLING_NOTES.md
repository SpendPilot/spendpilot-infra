# Prod Terraform Kubernetes API Decoupling and Private AKS Notes

## Goal

Keep `envs/prod` operable from GitHub Actions after the prod AKS control plane becomes private.

The runner must not require direct connectivity to the Kubernetes API server.

## What changed

### Provider changes

- Removed the `helm` provider from `envs/prod/versions.tf`.
- Removed the `kubernetes` provider from `envs/prod/versions.tf`.
- Added the `external` provider to `envs/prod/versions.tf`.
- Updated `envs/prod/.terraform.lock.hcl` for the provider change.

### In-cluster bootstrap changes

Replaced direct Terraform-managed Kubernetes and Helm resources with `terraform_data` resources that execute through Azure control-plane calls:

- `kubernetes_namespace_v1.spendpilot` -> `terraform_data.workload_bootstrap`
- `kubernetes_service_account_v1.workload` -> `terraform_data.workload_bootstrap`
- `kubernetes_config_map_v1.spendpilot` -> `terraform_data.workload_bootstrap`
- `helm_release.kgateway_crds` -> `terraform_data.kgateway_crds`
- `helm_release.kgateway` -> `terraform_data.kgateway`
- `helm_release.argocd` -> `terraform_data.argocd`

The new flow applies or upgrades resources with `az aks command invoke`, for example:

- `kubectl apply -f bootstrap.yaml`
- `helm upgrade --install kgateway-crds ...`
- `helm upgrade --install kgateway ...`
- `helm upgrade --install argocd ...`

### Service discovery changes

Replaced live Kubernetes provider reads with an external data source backed by `envs/prod/scripts/aks_service_query.py`.

This reads service status through:

- `az aks command invoke --command "kubectl get svc ... -o json"`

### AKS private cluster orchestration

The prod cluster remains managed by Terraform, but the private-cluster cutover is intentionally orchestrated in place with Azure CLI from Terraform because the native `azurerm_kubernetes_cluster` path wanted to replace the cluster.

Key behavior:

- a dedicated API server subnet is created in the prod VNet
- the AKS control plane is migrated in place to a user-assigned managed identity
- required subnet role assignments are created for the user-assigned identity
- API server VNet integration and private-cluster mode are enabled in place
- public API FQDN is disabled
- the system-managed private DNS zone is linked to the Australia ops VNet

### Monitoring and access additions

Added prod platform resources for post-cutover operations:

- Azure Monitor workspace for managed Prometheus
- Azure Managed Grafana integrated with that workspace
- Australia East ops resource group, VNet, subnet, peering, and jumpbox VM
- AAD-based SSH access on the jumpbox

## Live prod result

The current intended prod state is:

- AKS private cluster enabled
- API server VNet integration enabled
- public API FQDN removed
- managed Prometheus enabled
- Managed Grafana enabled
- jumpbox access available from the peered Australia ops VNet

## GitHub Actions impact

`scripts/terraform-prime-kubeconfig.sh` is still used by the shared workflows, but it is now a no-op for `prod`.

This is intentional:

- `dev` still uses live kubeconfig priming
- `prod` now uses Azure control-plane operations instead of direct Kubernetes API access from the runner

## Validation completed

Validated live in Azure after rollout:

- prod AKS reports `enablePrivateCluster = true`
- prod AKS reports `enableVnetIntegration = true`
- prod AKS public `fqdn = null`
- prod AKS `privateFqdn` resolves inside the ops VNet
- managed Prometheus is enabled on the cluster
- Managed Grafana is provisioned successfully
- Australia jumpbox is running and peered to prod

## Operational caveat

Azure ARM refreshes were intermittently unstable during rollout, so some final reconciliation steps had to use targeted Terraform applies plus CLI-backed in-place updates instead of a single clean full-root apply.

That operational reality is expected for this prod root until Azure management-plane refreshes are consistently stable again.
