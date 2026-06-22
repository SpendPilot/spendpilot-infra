#!/usr/bin/env bash
set -euo pipefail

known_envs=(dev global-shared identities nonprod-shared prod)

manual_env=""
base_ref=""
head_ref=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --environment)
      manual_env="${2:-}"
      shift 2
      ;;
    --base)
      base_ref="${2:-}"
      shift 2
      ;;
    --head)
      head_ref="${2:-}"
      shift 2
      ;;
    *)
      echo "Unsupported argument: $1" >&2
      exit 1
      ;;
  esac
done

emit_json_array() {
  local items=("$@")
  if [[ ${#items[@]} -eq 0 ]]; then
    printf '[]\n'
    return
  fi

  local first=1
  printf '['
  for item in "${items[@]}"; do
    if [[ $first -eq 0 ]]; then
      printf ','
    fi
    printf '"%s"' "$item"
    first=0
  done
  printf ']\n'
}

if [[ -n "$manual_env" ]]; then
  for env_name in "${known_envs[@]}"; do
    if [[ "$env_name" == "$manual_env" ]]; then
      emit_json_array "$manual_env"
      exit 0
    fi
  done

  echo "Unknown environment: $manual_env" >&2
  exit 1
fi

if [[ -z "$base_ref" || -z "$head_ref" ]]; then
  echo "Both --base and --head are required when --environment is not provided." >&2
  exit 1
fi

mapfile -t changed_files < <(git diff --name-only "$base_ref" "$head_ref")

if [[ ${#changed_files[@]} -eq 0 ]]; then
  emit_json_array
  exit 0
fi

declare -A selected=()
plan_all=0

for file_path in "${changed_files[@]}"; do
  if [[ "$file_path" == modules/* || "$file_path" == scripts/* || "$file_path" == .github/workflows/terraform-* || "$file_path" == .tflint.hcl ]]; then
    plan_all=1
    break
  fi

  for env_name in "${known_envs[@]}"; do
    if [[ "$file_path" == "envs/${env_name}/"* ]]; then
      selected["$env_name"]=1
    fi
  done
done

if [[ $plan_all -eq 1 ]]; then
  emit_json_array "${known_envs[@]}"
  exit 0
fi

ordered=()
for env_name in "${known_envs[@]}"; do
  if [[ -n "${selected[$env_name]:-}" ]]; then
    ordered+=("$env_name")
  fi
done

emit_json_array "${ordered[@]}"
