# Stage 1 goal and phase tracker

This is the canonical repository reference for continuing the lab in a later conversation. It records the approved goal and actual completion status; do not infer phase completion from intent or prior chat history.

## Goal

Build a reproducible, version-controlled, observable, recoverable Kubernetes platform-engineering study lab on the existing Ubuntu 24.04 workstation. It must support deliberate failure experiments and portfolio-quality documentation while preserving the workstation as a normal daily-use system.

The intended platform is KVM/QEMU/libvirt, Talos Linux, Kubernetes, Cilium/eBPF/Hubble, FRRouting/BGP, Gateway API, Traefik, cert-manager, Argo CD, Prometheus/Grafana/Alertmanager, OpenBao, External Secrets Operator, Longhorn, CloudNativePG, MinIO, and Crossplane.

## Non-negotiable operating model

1. Execute exactly one numbered phase at a time.
2. Before proposing a phase, inspect the previous phase's actual Git, resource, network, and runtime state and classify it `PASS`, `WARNING`, or `BLOCKER`.
3. Present objective, concepts, exact consequential commands, expected result, validation, risk, and rollback; then stop for explicit approval.
4. After approval, recheck safety-critical assumptions, execute only that phase, validate live state, document, test where appropriate, commit, report, and stop.
5. Do not silently work around a failure, change pinned versions, or start the next phase.
6. Before every phase inspect `git status --short --branch` and `git log --oneline --decorate -n 10`. Use a dedicated branch and a small Conventional Commit per phase.

## Host and safety boundary

- Keep Ubuntu, its bootloader, partitions, desktop, physical NIC, default route, firewall, unrelated Docker configuration, VPN configuration, and development tooling unchanged.
- Do not expose lab services publicly. Prefer isolated libvirt NAT networking.
- Require an additional explicit confirmation before deleting a VM/volume/network, changing host firewall/NIC/default route, Talos reset, etcd restore, deleting persistent or database data, restoring over data, deleting MinIO data, or destructive Git operations.
- Discover exact resources before any destructive command. Never commit credentials, generated Talos configs, `generated/`, `artifacts/`, disks, or private keys.

## Approved architecture decisions

| Area | Decision |
| --- | --- |
| Lab network | `lab-net`, `10.10.10.0/24`, bridge `virbr-lab`, isolated libvirt NAT |
| DHCP reservations | control plane `.11`; workers `.21`, `.22`; router `.254` |
| LoadBalancer range | `10.10.100.0/24` |
| BGP ASNs | Cilium `65010`; FRRouting `65000` |
| VM disks | 30 GiB control plane, 40 GiB per worker, 8 GiB router; 118 GiB nominal total |
| QEMU package | Ubuntu 24.04 `qemu-system-x86` package set, approved equivalent for unavailable `qemu-kvm` |
| Versions | `versions.env` is authoritative; never use `latest` or change a pin without compatibility review and approval |

## Completion register

Only mark a phase complete after its successful validation and commit. Add the commit SHA and a short evidence summary when updating this register.

- [x] Phase 0 — Host preflight. Evidence: `1f52032`; read-only preflight, host capacity/route/KVM baseline.
- [x] Phase 1 — KVM / QEMU / libvirt installation. Evidence: `0e0cbc2`; QEMU/KVM, libvirt access, groups, and package baseline validated.
- [x] Phase 2 — libvirt lab network. Evidence: `bb9c05a`; `lab-net` active/persistent/autostarted with NAT, bridge, and reservations.
- [x] Phase 3 — CLI tooling. Evidence: `4956c16`; checksum-verified `kubectl v1.36.2`, Helm v4.2.4, `talosctl v1.13.8`, and Cilium CLI v0.19.7; `make tooling-validate`, `make preflight`, and lab-network validation passed.
- [x] Phase 4 — Talos VM creation. Evidence: `2dca954`; three stopped Talos domains and 30/40/40 GiB QCOW2 disks validated on `lab-net`; `router01` deferred to Phase 10.
- [x] Phase 5 — Talos machine configuration. Evidence: `2c4e151`; generated ignored per-node Talos `v1.13.8` configs with CNI none, kube-proxy disabled, explicit hostnames, and strict offline validation; no VM boot or config application.
- [ ] Phase 6 — Kubernetes bootstrap.
- [ ] Phase 7 — Cilium installation.
- [ ] Phase 8 — eBPF inspection exercises.
- [ ] Phase 9 — NetworkPolicy exercises.
- [ ] Phase 10 — router01 creation.
- [ ] Phase 11 — FRRouting configuration.
- [ ] Phase 12 — Cilium BGP.
- [ ] Phase 13 — LoadBalancer routing validation.
- [ ] Phase 14 — Gateway API.
- [ ] Phase 15 — Traefik comparison.
- [ ] Phase 16 — cert-manager.
- [ ] Phase 17 — Argo CD bootstrap.
- [ ] Phase 18 — GitOps migration.
- [ ] Phase 19 — Prometheus / Grafana / Alertmanager.
- [ ] Phase 20 — Hubble observability exercises.
- [ ] Phase 21 — Failure-observability exercises.
- [ ] Phase 22 — OpenBao.
- [ ] Phase 23 — External Secrets Operator.
- [ ] Phase 24 — Worker storage preparation.
- [ ] Phase 25 — Longhorn.
- [ ] Phase 26 — CloudNativePG.
- [ ] Phase 27 — MinIO and backup/restore.
- [ ] Phase 28 — Crossplane.
- [ ] Phase 29 — Internal Developer Platform.
- [ ] Phase 30 — Reliability and failure engineering.
- [ ] Phase 31 — Backup and reconstruction.
- [ ] Phase 32 — Kubernetes upgrade exercise.
- [ ] Phase 33 — Talos upgrade exercise.

## Required learning and validation pattern

Each phase must demonstrate the mechanism rather than merely install it: inspect eBPF maps, deny and restore network traffic, trace flows in Hubble, establish and withdraw BGP routes, introduce GitOps drift, rotate secrets, test storage/database recovery, and record symptoms, telemetry, root cause, recovery, and prevention for controlled failures.

`make validate` will grow progressively. It must eventually report explicit `PASS`, `WARNING`, and `FAIL` results for KVM, libvirt, network, VMs, Talos, Kubernetes, Cilium, BGP, Gateway, GitOps, and observability health.
