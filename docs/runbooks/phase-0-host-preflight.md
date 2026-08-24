# Phase 0 runbook: host preflight

## Purpose

Establish a read-only baseline before any host or lab change. `scripts/preflight.sh` reports `PASS`, `WARNING`, or `BLOCKER`; it performs no remediation.

## What it checks

- Ubuntu release, CPU virtualization, `/dev/kvm`, memory, swap, and root filesystem capacity.
- Interfaces, routes, DNS-relevant state, VPN-like interfaces, and direct conflicts with the two proposed lab ranges.
- Libvirt and Docker visibility without changing either service.
- Required virtualization packages, CLI tools, and Git state.

## Interpretation

Warnings do not authorize the next phase. A blocker stops phase progression until a separately approved remediation is complete. Review host disk consumption again immediately before VM creation; the virtual-disk plan exceeds the current physical free space if images are fully populated.

## Safe learning exercise

Run `make preflight`, then compare the `ip route get` results for `10.10.10.1` and `10.10.100.1` against the routing table. This demonstrates route lookup without adding a route.
