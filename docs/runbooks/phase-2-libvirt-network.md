# Phase 2 runbook: libvirt lab network

## Why this exists

Libvirt creates a Linux bridge, attaches guest TAP devices to it, supplies DHCP/DNS, and implements NAT. This lets the lab remain isolated from the workstation's physical NIC and existing Docker/VPN configuration.

## Apply deliberately

The Make targets expose—not hide—the underlying commands:

```bash
make network-define
make network-autostart
make network-start
```

## Inspect and validate

```bash
make network-status
./tests/validate-lab-network.sh
```

The network's persistence does not create or start VMs. Destruction requires a separate confirmation because `virsh net-destroy lab-net` and `virsh net-undefine lab-net` remove the network definition and disrupt attached guests.
