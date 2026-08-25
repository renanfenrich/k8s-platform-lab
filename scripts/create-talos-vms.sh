#!/usr/bin/env bash
# Create only the approved Phase 4 Talos domains and their empty QCOW2 disks.
set -euo pipefail

uri='qemu:///system'
pool='default'
base='/var/lib/libvirt/images'

declare -A disks=(
  [talos-cp01]='30G'
  [talos-worker01]='40G'
  [talos-worker02]='40G'
)

for name in talos-cp01 talos-worker01 talos-worker02; do
  if virsh -c "$uri" dominfo "$name" >/dev/null 2>&1; then
    printf 'ERROR: domain already exists: %s\n' "$name" >&2
    exit 1
  fi
  if virsh -c "$uri" vol-info --pool "$pool" "$name.qcow2" >/dev/null 2>&1; then
    printf 'ERROR: volume already exists: %s.qcow2\n' "$name" >&2
    exit 1
  fi
done

for name in talos-cp01 talos-worker01 talos-worker02; do
  virsh -c "$uri" vol-create-as "$pool" "$name.qcow2" "${disks[$name]}" --format qcow2
  virsh -c "$uri" define "infrastructure/libvirt/talos-vms/$name.xml"
done

printf 'Created three stopped Phase 4 Talos domains; router01 remains deferred to Phase 10.\n'
