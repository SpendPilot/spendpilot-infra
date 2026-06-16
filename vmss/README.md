# VMSS deployment

Use this folder when you need to run stateless frontend and backend containers on every VMSS instance.

Guidance:

1. Keep PostgreSQL external to the scale set.
2. Supply environment variables through the VMSS model, Key Vault references, or a bootstrap script.
3. Assign a managed identity to the VMSS and grant Azure AI / Storage roles there.
4. Place the instances behind Azure Load Balancer or Application Gateway.
5. Configure health probes against `/` for the frontend or `/health` if you expose the backend independently.

Rolling upgrades:

- Publish new container images.
- Update the VMSS model or custom script reference.
- Use rolling instance upgrades so requests keep flowing while instances recycle.

Logging:

- Ship Docker and Nginx logs to Azure Monitor or another centralized sink.
