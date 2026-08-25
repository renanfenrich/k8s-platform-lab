#!/usr/bin/env bash
# Offline validation for the final Phase 5 per-node machine configurations.
set -euo pipefail

repo_root=$(git rev-parse --show-toplevel)
config_dir="$repo_root/generated/talos-v1.13.8"

pass() { printf 'PASS  %s\n' "$1"; }
fail() { printf 'FAIL  %s\n' "$1" >&2; exit 1; }

[[ -d "$config_dir" ]] || fail "generated config directory is missing: $config_dir"

for node in talos-cp01 talos-worker01 talos-worker02; do
  config="$config_dir/$node.yaml"
  [[ -f "$config" ]] || fail "final config is missing: $config"
  talosctl validate --config "$config" --mode metal --strict || fail "$node failed Talos validation"
  grep -q '^            name: none$' "$config" || fail "$node does not disable Talos-managed CNI"
  grep -q '^        disabled: true$' "$config" || fail "$node does not disable kube-proxy"
  grep -q "^hostname: $node$" "$config" || fail "$node lacks its explicit hostname"
  ! grep -q '^auto:' "$config" || fail "$node hostname config must omit auto"
  grep -q '^        disk: /dev/vda$' "$config" || fail "$node does not target the VM VirtIO disk"
done

pass 'all final per-node Talos configurations validate offline with the approved Phase 5 settings'
