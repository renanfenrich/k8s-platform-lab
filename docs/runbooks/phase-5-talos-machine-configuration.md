# Phase 5 runbook: Talos machine configuration

## Approved scope

Generate and validate Talos `v1.13.8` machine configurations for `platform-lab` using Kubernetes `v1.36.2`, endpoint `https://10.10.10.11:6443`, and the existing DHCP reservations. The VM VirtIO disks are `/dev/vda`.

The tracked patches set `cluster.network.cni.name` to `none`, disable `cluster.proxy`, and assign explicit hostnames to each node. `HostnameConfig` intentionally contains `hostname` only; `auto` is omitted because it conflicts with a static hostname in Talos 1.13.

Generated machine configs and `talosconfig` are written under ignored `generated/talos-v1.13.8/`.

## Generate and validate

```bash
make phase5-generate
make phase5-validate
```

Validation runs `talosctl validate --mode metal --strict` against each final per-node configuration and checks the approved CNI, kube-proxy, hostname, and install-disk fields.

## Boundary

This phase does not run `talosctl apply-config`, `virsh start`, Talos installation, or Kubernetes bootstrap. Applying these configs or booting a VM requires a separate reviewed and approved phase boundary.
