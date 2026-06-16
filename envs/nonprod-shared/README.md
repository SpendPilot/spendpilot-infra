# Nonprod Shared

Current scaffold status:

- resource group root created
- remote-state wiring added for `dev.tfstate` and `staging.tfstate`
- origin contract outputs can now be consumed when `read_dev_state` and/or `read_staging_state` are enabled

Target ownership:

- non-prod Front Door
- non-prod WAF
- optional shared non-prod AI services
