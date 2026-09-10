# AI agent instructions

This repository uses explicit phase contracts to keep AI-assisted work bounded, reproducible, and reviewable.

## Sources of truth

1. `docs/stage-1-goal-and-phase-tracker.md` is the canonical project and phase tracker.
2. `.ai/phases/phase-XX.yaml` is the execution contract for a specific phase.
3. `versions.env` is authoritative for pinned component versions.

## Operating rules

- Work on exactly one numbered phase at a time.
- Before phase work, inspect `git status --short --branch`, `git log --oneline --decorate -n 10`, and run `make phase-status`.
- Do not start a phase unless its contract exists and the user has explicitly approved that phase.
- Do not expand scope beyond the active phase contract.
- Do not silently change pinned versions, architecture decisions, or safety boundaries.
- Prefer deterministic repository validation over repeated AI review.
- Use the lowest-capability model/reasoning level that can safely complete the task; model guidance belongs in the phase contract.
- Stop after the active phase has been implemented, validated, documented, and reported. Never continue into the next phase automatically.

## Safety boundary

Do not modify the Ubuntu bootloader, partitions, desktop, physical NIC, default route, firewall, unrelated Docker/VPN configuration, or unrelated development tooling.

Require explicit additional confirmation before destructive operations including deleting VMs, volumes, networks, persistent/database/MinIO data; Talos reset; etcd restore; restore-over-data; destructive Git operations; or host firewall/NIC/default-route changes.

Never commit credentials, generated Talos machine configs, `generated/`, `artifacts/`, VM disks, kubeconfig, talosconfig, private keys, or environment secrets.

## AI workflow

Use `make phase-context PHASE=<n>` to produce bounded context and `make phase-goal PHASE=<n> MODE=implement|review|fix` to produce a concise handoff prompt. Run deterministic validation before requesting another AI pass. Reviews must classify findings as `BLOCKER`, `WARNING`, or `IMPROVEMENT` and avoid unrelated refactors.
