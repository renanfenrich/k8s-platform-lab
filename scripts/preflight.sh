#!/usr/bin/env bash
# Read-only Phase 0 host inspection. It never changes host or lab state.
set -uo pipefail

warning=0
blocker=0

pass() { printf 'PASS     %s\n' "$1"; }
warn() { printf 'WARNING  %s\n' "$1"; warning=1; }
fail() { printf 'BLOCKER  %s\n' "$1"; blocker=1; }
section() { printf '\n== %s ==\n' "$1"; }
has() { command -v "$1" >/dev/null 2>&1; }

section 'Operating system and CPU'
if [[ -r /etc/os-release ]]; then
  . /etc/os-release
  [[ "${ID:-}" == ubuntu && "${VERSION_ID:-}" == 24.04 ]] && pass 'Ubuntu 24.04 detected' || warn "Expected Ubuntu 24.04; found ${PRETTY_NAME:-unknown}"
else
  fail 'Cannot read /etc/os-release'
fi
has lscpu && lscpu | grep -q 'Virtualization:.*VT-x\|Virtualization:.*AMD-V' && pass 'Hardware virtualization reported by CPU' || warn 'CPU virtualization capability was not detected by lscpu'
[[ -e /dev/kvm ]] && pass '/dev/kvm exists' || fail '/dev/kvm is absent'

section 'Capacity'
available_mem_kib=$(awk '/MemAvailable:/ { print $2 }' /proc/meminfo 2>/dev/null || true)
[[ "${available_mem_kib:-0}" -ge 20971520 ]] && pass 'At least 20 GiB RAM available' || warn "Less than 20 GiB RAM available (${available_mem_kib:-unknown} KiB)"
swap_total_kib=$(awk '/SwapTotal:/ { print $2 }' /proc/meminfo 2>/dev/null || true)
[[ "${swap_total_kib:-0}" -gt 0 ]] && pass 'Swap is configured' || warn 'No swap configured'
available_disk_kib=$(df -Pk / | awk 'NR == 2 { print $4 }')
[[ "${available_disk_kib:-0}" -ge 157286400 ]] && pass 'At least 150 GiB free on root filesystem' || warn "Less than 150 GiB free on root filesystem (${available_disk_kib:-unknown} KiB)"
[[ "${available_disk_kib:-0}" -ge 176160768 ]] || warn 'Nominal 168 GiB VM disk plan exceeds current physical free space; use QCOW2 headroom controls in Phase 4'

section 'Networking'
if has ip; then
  ip -brief address
  ip route
  ip route get 10.10.10.1 >/dev/null 2>&1 && pass 'Route lookup for 10.10.10.0/24 completed' || warn 'Cannot resolve route to 10.10.10.0/24'
  ip route get 10.10.100.1 >/dev/null 2>&1 && pass 'Route lookup for 10.10.100.0/24 completed' || warn 'Cannot resolve route to 10.10.100.0/24'
  ip route | grep -Eq '(^| )10\.10\.10\.0/24|(^| )10\.10\.100\.0/24' && fail 'Existing route conflicts with a proposed lab subnet' || pass 'No direct route conflict for proposed lab subnets'
  ip -brief link | grep -Eqi 'tun|tap|wg|vpn|tailscale|zt|ppp' && warn 'VPN-like interface detected; review its routes before Phase 2' || pass 'No VPN-like interface detected'
else
  fail "'ip' command is unavailable"
fi

section 'Virtualization and containers'
if has virsh; then
  virsh -c qemu:///system net-list --all && pass 'libvirt system connection available' || warn 'Cannot query qemu:///system without additional privileges'
else
  warn 'virsh is not installed'
fi
if has docker; then
  docker network ls && pass 'Docker networks listed' || warn 'Cannot query Docker daemon without additional privileges'
else
  pass 'Docker is not installed'
fi

section 'Required packages and tools'
for pkg in qemu-kvm libvirt-daemon-system libvirt-clients virtinst virt-manager cloud-image-utils; do
  dpkg-query -W -f='${db:Status-Status}' "$pkg" 2>/dev/null | grep -qx installed && pass "$pkg installed" || warn "$pkg not installed"
done
for tool in git kubectl helm talosctl cilium; do
  has "$tool" && pass "$tool at $(command -v "$tool")" || warn "$tool is not installed"
done

section 'Repository safety'
git rev-parse --is-inside-work-tree >/dev/null 2>&1 && pass 'Git repository initialized' || fail 'Not inside a Git repository'
git status --short
git log --oneline --decorate -n 10 2>/dev/null || true

section 'Summary'
if (( blocker )); then
  printf 'BLOCKER: resolve blockers before the next phase.\n'
  exit 2
elif (( warning )); then
  printf 'WARNING: review warnings before the next phase.\n'
  exit 0
fi
printf 'PASS: host meets all scripted Phase 0 checks.\n'
