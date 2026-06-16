locals {
  name    = lower("${var.prefix}-${var.environment}")
  rg_name = var.resource_group_name

  tags = merge(
    {
      application = "spend-control"
      environment = var.environment
      managed_by  = "terraform"
      stack       = "vm-docker"
    },
    var.tags,
  )

  frontend_scale_set_name = "${local.name}-frontend-vmss"
  backend_scale_set_name  = "${local.name}-backend-vmss"
  data_ai_scale_set_name  = "${local.name}-data-ai-vmss"
  static_app_vm_name      = "${local.name}-static-web"

  postgres_server_name         = "${local.name}-psql"
  postgres_private_dns_zone    = "${local.name}.postgres.database.azure.com"
  backend_database_host        = module.postgres.fqdn
  backend_database_url         = "postgresql+psycopg://${var.postgres_app_username}:${var.postgres_app_password}@${local.backend_database_host}:5432/${var.postgres_database_name}?sslmode=require"
  ollama_private_base_url      = "http://${var.ollama_lb_private_ip}:${var.ollama_port}"
  frontend_public_api_base_url = ""
  static_app_html              = <<-HTML
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="utf-8" />
      <meta name="viewport" content="width=device-width, initial-scale=1" />
      <title>SpendPilot Host Routing Demo</title>
      <style>
        :root {
          color-scheme: light;
          --bg: #f4f7fb;
          --card: #ffffff;
          --ink: #11233a;
          --accent: #1d6fdc;
          --muted: #62748a;
        }
        body {
          margin: 0;
          min-height: 100vh;
          display: grid;
          place-items: center;
          font-family: "Segoe UI", Arial, sans-serif;
          background: radial-gradient(circle at top, #dce9ff, var(--bg) 60%);
          color: var(--ink);
        }
        main {
          width: min(760px, calc(100vw - 48px));
          padding: 40px;
          border-radius: 24px;
          background: var(--card);
          box-shadow: 0 24px 80px rgba(17, 35, 58, 0.12);
        }
        .eyebrow {
          display: inline-block;
          padding: 8px 14px;
          border-radius: 999px;
          background: rgba(29, 111, 220, 0.12);
          color: var(--accent);
          font-size: 13px;
          font-weight: 700;
          letter-spacing: 0.08em;
          text-transform: uppercase;
        }
        h1 {
          margin: 18px 0 12px;
          font-size: clamp(2rem, 4vw, 3.2rem);
          line-height: 1.05;
        }
        p {
          margin: 0 0 12px;
          font-size: 1.05rem;
          line-height: 1.7;
          color: var(--muted);
        }
        code {
          font-family: Consolas, "Courier New", monospace;
          background: #eef4ff;
          color: var(--ink);
          padding: 2px 6px;
          border-radius: 8px;
        }
      </style>
    </head>
    <body>
      <main>
        <span class="eyebrow">Host-Based Routing Demo</span>
        <h1>${var.static_app_host_name}</h1>
        <p>This static page is served by a standalone NGINX VM in the application spoke VNet.</p>
        <p>Application Gateway routes requests for <code>${var.static_app_host_name}</code> here, while <code>${var.primary_host_name}</code> continues to reach the main SpendPilot frontend and API.</p>
      </main>
    </body>
    </html>
  HTML
}
