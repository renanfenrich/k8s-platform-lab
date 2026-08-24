# KVM, QEMU, and libvirt

## What they are

KVM is the Linux kernel virtualization interface used for hardware acceleration. QEMU supplies the virtual-machine process and hardware model. Libvirt provides a stable API and CLI (`virsh`) for defining and operating those QEMU VMs.

Ubuntu 24.04 supplies the QEMU/KVM runtime through `qemu-system-x86`, `qemu-system-common`, and `qemu-utils`; the requested `qemu-kvm` package has no APT candidate on this host. The installed package set is the approved equivalent.

## How this lab will use them

Phase 4 will use libvirt domain definitions, QCOW2 disks, host-passthrough CPU mode, and VirtIO disks/NICs. The VMs remain stopped by default. Their virtual disks are limited to 118 GiB total: 30 GiB control plane, 40 GiB per worker, and 8 GiB router.

## Inspect, break safely, recover

Inspect with `ls -l /dev/kvm`, `lsmod | grep '^kvm'`, and `virsh -c qemu:///system list --all`. Do not unload KVM modules or alter the default libvirt network on this workstation. If a future lab VM fails, inspect its libvirt domain and log before any stop or deletion.
