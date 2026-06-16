# Raw AKS Manifests

This folder contains raw Kubernetes manifests for the AKS deployment shape:

- `namespace.yaml`
- `serviceaccount.yaml`
- `configmap.yaml`
- `secret.example.yaml`
- `migration-job.yaml`
- frontend deployment and service
- identity, finance, and documents deployments and services
- Gateway API `Gateway` and `HTTPRoute` resources
- optional HPAs

Traffic model:

```txt
Azure Front Door -> kGateway -> HTTPRoutes -> services
```

Path split:

- `/` -> frontend
- `/api/auth`, `/api/admin`, `/health`, `/ready` -> identity-service
- `/api/finance` -> finance-service
- `/api/documents`, `/api/ai` -> documents-service
