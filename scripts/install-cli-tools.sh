#!/usr/bin/env bash
# Downloads official, pinned Linux amd64 CLI releases and verifies SHA-256 before installation.
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
# shellcheck source=../versions.env
source "$repo_root/versions.env"
install_dir=${INSTALL_DIR:-/usr/local/bin}
architecture=$(uname -m)
[[ "$architecture" == x86_64 ]] || { printf 'Unsupported architecture: %s\n' "$architecture" >&2; exit 1; }

work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT
download() { curl --fail --location --proto '=https' --tlsv1.2 --retry 3 --output "$2" "$1"; }
install_binary() {
  local source_file=$1 target_name=$2
  if [[ -w "$install_dir" ]]; then
    install -m 0755 "$source_file" "$install_dir/$target_name"
  else
    sudo install -m 0755 "$source_file" "$install_dir/$target_name"
  fi
}

cd "$work_dir"

download "https://dl.k8s.io/release/${KUBERNETES_VERSION}/bin/linux/amd64/kubectl" kubectl
download "https://dl.k8s.io/release/${KUBERNETES_VERSION}/bin/linux/amd64/kubectl.sha256" kubectl.sha256
printf '%s  kubectl\n' "$(<kubectl.sha256)" | sha256sum --check --status -
install_binary kubectl kubectl

download "https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz" helm.tar.gz
printf '%s  helm.tar.gz\n' 'c306b46f719b0a4da32d0f78ee21bf90ce8d602f15b22ab753f0674d1670a7f3' | sha256sum --check --status -
tar -xzf helm.tar.gz linux-amd64/helm
install_binary linux-amd64/helm helm

download "https://github.com/siderolabs/talos/releases/download/${TALOS_VERSION}/talosctl-linux-amd64" talosctl
download "https://github.com/siderolabs/talos/releases/download/${TALOS_VERSION}/sha256sum.txt" sha256sum.txt
printf '%s  talosctl\n' "$(awk '$2 == "talosctl-linux-amd64" { print $1 }' sha256sum.txt)" | sha256sum --check --status -
install_binary talosctl talosctl

download "https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-amd64.tar.gz" cilium-linux-amd64.tar.gz
download "https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-amd64.tar.gz.sha256sum" cilium-linux-amd64.tar.gz.sha256sum
sha256sum --check --status cilium-linux-amd64.tar.gz.sha256sum
tar -xzf cilium-linux-amd64.tar.gz cilium
install_binary cilium cilium

printf 'Installed kubectl %s, Helm %s, talosctl %s, and Cilium CLI %s to %s\n' "$KUBERNETES_VERSION" "$HELM_VERSION" "$TALOS_VERSION" "$CILIUM_CLI_VERSION" "$install_dir"
