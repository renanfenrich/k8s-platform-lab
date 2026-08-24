# Phase 1 runbook: KVM, QEMU, and libvirt

## Installed baseline

- `qemu-system-x86` (Ubuntu 24.04 replacement for unavailable `qemu-kvm`)
- `libvirt-daemon-system`, `libvirt-clients`, `virtinst`, and `virt-manager`
- `cloud-image-utils`

## Validation

```bash
ls -l /dev/kvm
lsmod | grep '^kvm'
virsh -c qemu:///system uri
id -nG
```

Expected: `/dev/kvm` is present, KVM modules are loaded, the URI is `qemu:///system`, and the user is in `kvm` and `libvirt` groups. No lab network or VM is created in this phase.
