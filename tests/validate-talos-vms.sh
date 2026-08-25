#!/usr/bin/env bash
# Read-only validation for the Phase 4 Talos VM definitions.
set -euo pipefail

uri='qemu:///system'
pool='default'

pass() { printf 'PASS  %s\n' "$1"; }
fail() { printf 'FAIL  %s\n' "$1"; exit 1; }

declare -A vcpus=( [talos-cp01]=2 [talos-worker01]=2 [talos-worker02]=2 )
declare -A memory=( [talos-cp01]=4194304 [talos-worker01]=4194304 [talos-worker02]=4194304 )
declare -A capacity=( [talos-cp01]=32212254720 [talos-worker01]=42949672960 [talos-worker02]=42949672960 )
declare -A macs=(
  [talos-cp01]='52:54:00:10:10:11'
  [talos-worker01]='52:54:00:10:10:21'
  [talos-worker02]='52:54:00:10:10:22'
)

for name in talos-cp01 talos-worker01 talos-worker02; do
  info=$(virsh -c "$uri" dominfo "$name") || fail "$name domain is unavailable"
  grep -q '^State:.*shut off' <<<"$info" || fail "$name is not stopped"
  grep -q "^CPU(s):.*${vcpus[$name]}$" <<<"$info" || fail "$name has unexpected vCPU count"
  grep -q "^Max memory:.*${memory[$name]} KiB$" <<<"$info" || fail "$name has unexpected memory"

  xml=$(virsh -c "$uri" dumpxml "$name") || fail "$name XML is unavailable"
  grep -q "<source network='lab-net'" <<<"$xml" || fail "$name is not attached to lab-net"
  grep -q "<mac address='${macs[$name]}'" <<<"$xml" || fail "$name has unexpected MAC"
  grep -q "<cpu mode='host-passthrough'" <<<"$xml" || fail "$name lacks host-passthrough CPU"
  grep -q "<target dev='vda' bus='virtio'" <<<"$xml" || fail "$name lacks a VirtIO disk"

  volume=$(virsh -c "$uri" vol-info --bytes --pool "$pool" "$name.qcow2") || fail "$name disk is unavailable"
  grep -q "Capacity:.*${capacity[$name]} bytes" <<<"$volume" || fail "$name has unexpected disk capacity"
done

if virsh -c "$uri" dominfo router01 >/dev/null 2>&1; then
  fail 'router01 must remain deferred to Phase 10'
fi

pass 'three approved Talos VMs exist, are stopped, and match the Phase 4 definitions'
