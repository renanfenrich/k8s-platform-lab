#!/usr/bin/env bash
# Read-only validation for the Phase 2 libvirt network.
set -euo pipefail

uri='qemu:///system'
name='lab-net'

pass() { printf 'PASS  %s\n' "$1"; }
fail() { printf 'FAIL  %s\n' "$1"; exit 1; }

xml=$(virsh -c "$uri" net-dumpxml "$name") || fail 'lab-net definition is unavailable'
network_info=$(virsh -c "$uri" net-info "$name") || fail 'lab-net state is unavailable'
grep -q 'Active:.*yes' <<<"$network_info" || fail 'lab-net is not active'
bridge_address=$(ip -4 addr show dev virbr-lab) || fail 'virbr-lab is unavailable'
grep -q '10.10.10.1/24' <<<"$bridge_address" || fail 'virbr-lab lacks 10.10.10.1/24'

for reservation in \
  '52:54:00:10:10:11.*10.10.10.11' \
  '52:54:00:10:10:21.*10.10.10.21' \
  '52:54:00:10:10:22.*10.10.10.22' \
  '52:54:00:10:10:fe.*10.10.10.254'; do
  grep -Eq "$reservation" <<<"$xml" || fail "missing DHCP reservation matching $reservation"
done

grep -q '<forward mode=.nat.' <<<"$xml" || fail 'lab-net is not configured for NAT'
pass 'lab-net is active with the expected bridge, NAT, and reservations'
