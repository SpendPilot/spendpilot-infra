# Staging

Current scaffold status:

- dedicated backend state key: `staging.tfstate`
- resource-group Terraform root created
- `frontdoor_origin_contract` now exposes a staging origin contract from explicit hostname/IP inputs so `nonprod-shared` can attach the staging route when the runtime endpoint is known

Target ownership:

- staging runtime resources
- outputs for shared non-prod Front Door origin attachment
