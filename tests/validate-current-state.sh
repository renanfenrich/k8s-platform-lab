#!/usr/bin/env bash
set -uo pipefail

repo_root=$(git rev-parse --show-toplevel)
failures=0
warnings=0

run_check() {
  local label=$1
  shift
  printf '\n--- %s ---\n' "$label"
  if "$@"; then
    printf 'PASS  %s\n' "$label"
  else
    printf 'FAIL  %s\n' "$label" >&2
    failures=$((failures + 1))
  fi
}

run_check 'host preflight' bash "$repo_root/scripts/preflight.sh"
run_check 'CLI tool pins' bash "$repo_root/tests/validate-cli-tools.sh"
run_check 'libvirt lab network' bash "$repo_root/tests/validate-lab-network.sh"
run_check 'Talos VM definitions' bash "$repo_root/tests/validate-talos-vms.sh"

# Generated Talos configs are intentionally ignored. A fresh checkout can therefore
# be repository-healthy while still requiring local regeneration before Phase 6.
# shellcheck disable=SC1091
source "$repo_root/versions.env"
talos_version=${TALOS_VERSION#v}
config_dir="$repo_root/generated/talos-v$talos_version"
if [[ -d "$config_dir" ]]; then
  run_check 'Talos machine configs' bash "$repo_root/tests/validate-talos-configs.sh"
else
  printf '\nWARNING  generated Talos configs are absent: %s\n' "$config_dir"
  printf 'WARNING  regenerate and strictly validate them before Phase 6 execution\n'
  warnings=$((warnings + 1))
fi

printf '\n=== validation summary ===\n'
printf 'FAILURES=%d\nWARNINGS=%d\n' "$failures" "$warnings"

if (( failures > 0 )); then
  printf 'FAIL  current lab state has validation failures\n' >&2
  exit 1
fi

if (( warnings > 0 )); then
  printf 'WARNING  current lab state passed deterministic checks with warnings\n'
else
  printf 'PASS  current lab state passed all deterministic checks\n'
fi
