# Networking

No lab network exists during Phase 0. The existing host network, Docker bridges, and libvirt default network are observed but never modified by the preflight.

Phase 2 will propose `lab-net` (`10.10.10.0/24`), `virbr-lab`, NAT, and deterministic DHCP reservations only after a fresh conflict review and approval.
