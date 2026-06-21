#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <environment> <plan-json-path>" >&2
  exit 1
fi

environment_name="$1"
plan_json_path="$2"

if [[ ! -f "$plan_json_path" ]]; then
  echo "Missing plan JSON: $plan_json_path" >&2
  exit 1
fi

create_count="$(jq '[.resource_changes[]? | select(.change.actions == ["create"])] | length' "$plan_json_path")"
update_count="$(jq '[.resource_changes[]? | select(.change.actions == ["update"])] | length' "$plan_json_path")"
delete_count="$(jq '[.resource_changes[]? | select(.change.actions == ["delete"])] | length' "$plan_json_path")"
replace_count="$(jq '[.resource_changes[]? | select(.change.actions == ["delete","create"] or .change.actions == ["create","delete"])] | length' "$plan_json_path")"
noop_count="$(jq '[.resource_changes[]? | select(.change.actions == ["no-op"])] | length' "$plan_json_path")"

{
  echo "### Terraform plan summary for \`$environment_name\`"
  echo
  echo "| Action | Count |"
  echo "| --- | ---: |"
  echo "| Create | $create_count |"
  echo "| Update | $update_count |"
  echo "| Delete | $delete_count |"
  echo "| Replace | $replace_count |"
  echo "| No-op | $noop_count |"
} 
