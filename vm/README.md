# VM deployment

1. Provision an Ubuntu VM with outbound internet access and assign either a system-assigned or user-assigned managed identity.
2. Run `install-docker.sh`.
3. Copy `docker-compose.prod.yml`, `nginx.conf.example`, and your `.env` file into `/opt/business-ai-app`.
4. Set `DATABASE_URL` to an external PostgreSQL instance. Do not run a production database on the same VM unless this is a deliberate small deployment.
5. Start the stack with `deploy-with-docker-compose.sh`.

Managed identity notes:

- Grant `Storage Blob Data Contributor` if Blob Storage is enabled.
- Grant the appropriate Azure AI Foundry and Document Intelligence roles.
- Grant Key Vault access if secrets are read from Key Vault outside of environment files.

Ports:

- `80` and optionally `443` for Nginx
- The containers stay private behind Nginx
