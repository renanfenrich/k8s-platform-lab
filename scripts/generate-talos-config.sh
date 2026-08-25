#!/usr/bin/env bash
# Generate Phase 5 configs offline; never applies config or starts a VM.
set -euo pipefail

repo_root=$(git rev-parse --show-toplevel)
output_dir="$repo_root/generated/talos-v1.13.8"
patch_dir="$repo_root/infrastructure/talos/phase-5"

if [[ -e "$output_dir" ]]; then
  printf 'ERROR: refusing to overwrite existing generated output: %s\n' "$output_dir" >&2
  exit 1
fi

set -a
. "$repo_root/versions.env"
set +a

mkdir -p "$output_dir"
talosctl gen config platform-lab https://10.10.10.11:6443 \
  --talos-version "$TALOS_VERSION" \
  --kubernetes-version "${KUBERNETES_VERSION#v}" \
  --install-disk /dev/vda \
  --config-patch "@$patch_dir/common.patch.yaml" \
  --with-docs=false \
  --with-examples=false \
  --output "$output_dir/base"

talosctl machineconfig patch "$output_dir/base/controlplane.yaml" \
  --patch "@$patch_dir/hostname-cp01.yaml" \
  --output "$output_dir/talos-cp01.yaml"
talosctl machineconfig patch "$output_dir/base/worker.yaml" \
  --patch "@$patch_dir/hostname-worker01.yaml" \
  --output "$output_dir/talos-worker01.yaml"
talosctl machineconfig patch "$output_dir/base/worker.yaml" \
  --patch "@$patch_dir/hostname-worker02.yaml" \
  --output "$output_dir/talos-worker02.yaml"

printf 'Generated final per-node configs under ignored %s; no VM was started or configured.\n' "$output_dir"
