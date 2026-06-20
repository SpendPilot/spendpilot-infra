# Prod

This Terraform root now bootstraps the production platform foundation:

- Azure resource group, network, Log Analytics, PostgreSQL, Storage, and AI services
- AKS with OIDC issuer and Workload Identity enabled
- shared ACR pull access for the cluster
- kGateway CRDs and kGateway control plane
- Argo CD installed into `argocd`
- Argo CD server exposed through a Kubernetes `LoadBalancer` service by default
- Azure Front Door owns the intended public edge for `costpilot.online`

Important behavior:

- `terraform apply` bootstraps the prod namespace, workload identity service account, runtime `ConfigMap`, and runtime `Secret`
- Argo CD is bootstrapped first
- Terraform does not register the SpendPilot Argo CD `Application`; you apply that manifest manually later when you want workloads to deploy
- the prod GitOps values now point at stable in-cluster config/secret names, so there is no manual Terraform-output-to-Helm-values handoff step

Useful outputs after apply:

- `argocd_server_url`
- `frontend_client_id`
- `backend_client_id`
- `workload_identity_client_id`
- `app_config_map_name`
- `app_secret_name`
- `gitops_values_contract`
- `frontdoor_apex_validation`
- `frontdoor_origin_target`
- `prod_edge_transition_contract`
