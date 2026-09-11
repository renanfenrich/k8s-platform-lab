# Kubernetes Platform Engineering Lab

An isolated, reproducible Stage 1 platform-engineering lab for an Ubuntu 24.04 workstation. Every phase is reviewed and explicitly approved before execution.

The canonical objective, safety constraints, approved architecture decisions, and live phase completion status are maintained in [docs/stage-1-goal-and-phase-tracker.md](docs/stage-1-goal-and-phase-tracker.md). Read it before proposing or executing any phase.

## AI-assisted study workflow

The repository is the handoff layer between ChatGPT, Codex, deterministic validation, and the human operator. AI work is intentionally bounded so the lab remains a study exercise rather than an unattended deployment.

- `docs/ai-assisted-operator-workflow.md` is the operator-facing guide for local Git/Make commands, validation, AI handoffs, and checkpoint flow.
- `AGENTS.md` contains short permanent agent rules and safety boundaries.
- `.ai/project-policy.md` defines the ChatGPT/Codex/human workflow and usage-budget rules.
- `.ai/phases/phase-XX.yaml` defines the contract, model guidance, acceptance criteria, and human operator checkpoints for each active phase.
- `docs/runbooks/phase-6-kubernetes-bootstrap.md` is the guided technical runbook for the next phase. Consequential commands remain gated until Phase 6 is explicitly approved.
- `make phase-status` detects the next incomplete phase from the canonical tracker.
- `make phase-context PHASE=6` prints bounded phase context.
- `make phase-goal PHASE=6 MODE=implement` renders a concise Codex handoff without asking Codex to rediscover the project.
- `make orchestration-validate` statically validates the orchestration layer without touching the lab runtime.
- `make validate` runs cumulative live-state checks on the workstation.

Guided execution is the default. Learning-critical or consequential operations remain explicit local operator checkpoints: the agent explains the mechanism, exact commands, expected result, risk, and rollback boundary, then stops so the operator can execute and inspect the result before continuation.

## Phase 0

Run the read-only host inspection with `make preflight`. The command never installs packages, changes routes, restarts services, or creates libvirt resources. Warnings are visible in the report; blockers make the command fail.

The intended architecture, phase gates, resource plan, recovery rules, and study requirements are documented in [docs/architecture.md](docs/architecture.md) and [docs/runbooks/phase-0-host-preflight.md](docs/runbooks/phase-0-host-preflight.md).
