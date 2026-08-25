#!/usr/bin/env bash
# Read-only Phase 3 CLI validation.
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
# shellcheck source=../versions.env
source "$repo_root/versions.env"

pass() { printf 'PASS  %s\n' "$1"; }
fail() { printf 'FAIL  %s\n' "$1"; exit 1; }

[[ "$(uname -m)" == x86_64 ]] || fail 'expected x86_64 host architecture'
command -v kubectl helm talosctl cilium >/dev/null || fail 'one or more required CLI binaries are absent from PATH'
kubectl_version=$(kubectl version --client --output=yaml)
helm_version=$(helm version --short)
talosctl_version=$(talosctl version --client)
cilium_version=$(cilium version --client)
grep -q "gitVersion: ${KUBERNETES_VERSION}" <<<"$kubectl_version" || fail 'kubectl version differs from pin'
grep -q "${HELM_VERSION}" <<<"$helm_version" || fail 'Helm version differs from pin'
grep -q "${TALOS_VERSION}" <<<"$talosctl_version" || fail 'talosctl version differs from pin'
grep -q "${CILIUM_CLI_VERSION}" <<<"$cilium_version" || fail 'Cilium CLI version differs from pin'
pass 'all pinned CLI tools are installed for linux/amd64'
