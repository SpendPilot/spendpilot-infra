# Staging

Current scaffold status:

- dedicated backend state key: `staging.tfstate`
- no live Azure resources are currently owned by this root
- `frontdoor_origin_contract` now exposes a staging origin contract from explicit hostname/IP inputs so `nonprod-shared` can attach the staging route when the runtime endpoint is known

Target ownership:

- staging runtime resources
- outputs for shared non-prod Front Door origin attachment

Operational note:

- `deploy_runtime_resources` defaults to `false` so this root stays aligned with the current Azure footprint and plans as a no-op
- GitHub Actions intentionally skips automatic plan/apply for `staging` until a real staging deployment exists
