# Networking

## Phase 2: isolated libvirt network

`lab-net` is defined declaratively in `infrastructure/libvirt/lab-net.xml`. It creates the `virbr-lab` bridge with `10.10.10.1/24`, local DHCP/DNS, and libvirt-managed NAT. The NAT boundary lets guests reach the internet through the host without adding routes, changing the physical NIC, or exposing guest services publicly.

| Guest | MAC | DHCP reservation |
| --- | --- | --- |
| talos-cp01 | `52:54:00:10:10:11` | `10.10.10.11` |
| talos-worker01 | `52:54:00:10:10:21` | `10.10.10.21` |
| talos-worker02 | `52:54:00:10:10:22` | `10.10.10.22` |
| router01 | `52:54:00:10:10:fe` | `10.10.10.254` |

Inspect the live state with `make network-status` and validate it with `tests/validate-lab-network.sh`. Do not destroy or undefine this network without the additional destructive-action approval gate.
