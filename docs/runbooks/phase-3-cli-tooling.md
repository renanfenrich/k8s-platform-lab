# Phase 3 runbook: CLI tooling

## Pinned tools

`versions.env` pins Kubernetes CLI `v1.36.2`, Helm `v4.2.4`, Talos CLI `v1.13.8`, Cilium `v1.20.1`, and Cilium CLI `v0.19.7`. The two Cilium versions are intentionally distinct: one is the future cluster dataplane release, the other is the local management CLI.

## Why the host tools change

The previous `kubectl v1.34.2` is two minor releases behind the target API version. Helm v4.0.x supports Kubernetes through v1.34, so it is replaced by the v4.2.x line for Kubernetes v1.36 compatibility. The installer downloads official Linux amd64 artifacts, verifies SHA-256 before installation, and writes only the four scoped CLI binaries to `/usr/local/bin`.

The Cilium CLI's displayed default or stable image is informational only. Phase 7 must pass the pinned `CILIUM_VERSION` explicitly; it must never rely on a CLI default.

## Use and validation

```bash
make tooling-install
make tooling-validate
```

The installation target may require interactive `sudo` access. It creates no cluster, VM, network, credential, or kubeconfig state. To roll back, reinstall the explicitly recorded preceding versions (`kubectl v1.34.2` and Helm v4.0.1) from their official releases.
