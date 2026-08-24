# Troubleshooting

## Phase 0

- `WARNING Cannot query qemu:///system`: run the read-only preflight from a user with libvirt access, then investigate group membership before Phase 1.
- `BLOCKER /dev/kvm is absent`: stop and investigate BIOS virtualization settings and kernel modules; do not change firmware or boot configuration without approval.
- Lab-subnet route conflict: stop before Phase 2 and propose a new address plan for approval.
