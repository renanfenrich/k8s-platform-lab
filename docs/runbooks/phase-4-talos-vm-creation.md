# Phase 4 runbook: Talos VM creation

## Approved scope

Create only `talos-cp01`, `talos-worker01`, and `talos-worker02`. Each uses 2 vCPUs, 4 GiB RAM, host-passthrough CPU, a VirtIO disk and NIC, and `lab-net`. Their QCOW2 capacities are 30 GiB, 40 GiB, and 40 GiB respectively. `router01` is explicitly deferred to Phase 10.

The domains and disks are created stopped. This phase does not install Talos, generate machine configuration, boot a guest, or create `router01`.

## Apply and validate

```bash
make phase4-create
make phase4-validate
```

The creation target defines the checked-in XML files and creates the matching QCOW2 volumes in libvirt's `default` pool. Validation is read-only and checks domain state, CPU, memory, disk capacity, CPU mode, VirtIO devices, MAC addresses, and `lab-net` attachment.

## Rollback boundary

The phase creates three domains and three disks. Do not delete them without separate explicit destructive-action approval. Phase 5 generated and validated machine configurations offline only; booting and applying those configurations is deferred to the separately approved Phase 6 bootstrap runbook.
