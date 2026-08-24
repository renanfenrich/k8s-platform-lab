# Kubernetes Platform Engineering Lab

An isolated, reproducible Stage 1 platform-engineering lab for an Ubuntu 24.04 workstation. Every phase is reviewed and explicitly approved before execution.

## Phase 0

Run the read-only host inspection with `make preflight`. The command never installs packages, changes routes, restarts services, or creates libvirt resources. Warnings are visible in the report; blockers make the command fail.

The intended architecture, phase gates, resource plan, recovery rules, and study requirements are documented in [docs/architecture.md](docs/architecture.md) and [docs/runbooks/phase-0-host-preflight.md](docs/runbooks/phase-0-host-preflight.md).
