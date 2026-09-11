# AI-assisted operator workflow

This guide describes how the human operator, ChatGPT, Codex, and deterministic repository tooling collaborate on each numbered lab phase.

The lab uses **guided study mode** by default. AI prepares bounded work, explanations, validation, and evidence. The operator remains responsible for learning-critical or consequential checkpoints defined in the active phase contract.

## Roles

- **ChatGPT** reviews architecture, creates/reviews phase contracts, explains local checkpoints, and reviews PRs/findings.
- **Codex** performs bounded repository implementation and narrowly scoped fixes. It must stop at human-owned checkpoints.
- **Repository tooling** detects phase state, renders bounded prompts, runs deterministic validation, and records evidence.
- **Operator** runs learning-critical local commands, inspects the result, makes/approves decisions, and controls merges/destructive actions.

## Start of a work session

Before switching branches or running phase tooling, inspect the local repository:

```bash
git status --short --branch
git log --oneline --decorate -n 10
```

Expected result: the current branch and recent commits are understood, and there are no unexplained local changes. Do not discard local changes just to make the tree clean.

Fetch current remote state:

```bash
git fetch --prune origin
```

For the current orchestration draft PR, switch to:

```bash
git switch chore/phase-orchestration
git pull --ff-only
```

## Validate the orchestration layer

Run the static checks first. These do not boot VMs or modify the Talos cluster:

```bash
make orchestration-validate
```

This verifies the orchestration file set, shell syntax, canonical next-phase detection, prompt rendering, and guided Phase 6 checkpoints.

Then inspect what the tracker considers next:

```bash
make phase-status
```

Current expected result:

```text
NEXT_PHASE=6
NEXT_PHASE_NAME=Kubernetes bootstrap
```

## Inspect bounded Phase 6 context

To see exactly what an implementation agent should receive:

```bash
make phase-context PHASE=6
```

This prints the current Git state, recent history, pinned versions, and the Phase 6 contract. It is intentionally much smaller than asking an agent to rediscover the whole project.

To render the implementation handoff without invoking Codex:

```bash
make phase-goal PHASE=6 MODE=implement
```

Likewise, review and targeted-fix prompts can be rendered with:

```bash
make phase-goal PHASE=6 MODE=review
make phase-goal PHASE=6 MODE=fix FINDINGS=path/to/findings.md
```

These commands only print prompts. They do **not** invoke an AI model or consume Codex quota by themselves.

## Validate current live lab state

The cumulative validation command is:

```bash
make validate
```

Unlike `make orchestration-validate`, this inspects the workstation and current lab resources. It currently covers host preflight, pinned CLI tooling, the libvirt lab network, Talos VM definitions, and local generated Talos machine configs when present.

A fresh clone can legitimately report a warning when ignored generated Talos configs are absent. Phase 6 cannot proceed until those configs are present and strictly validated locally.

Do not treat a failed live validation as permission to repair or recreate resources automatically. Record the failure and review it first.

## Phase preflight

After the orchestration PR is merged and before consequential Phase 6 execution, run:

```bash
make phase-preflight PHASE=6
```

This verifies that Phase 6 is actually the next incomplete phase, checks repository cleanliness, runs cumulative validation, and verifies the local Talos configs required by Phase 6.

A successful preflight still does **not** authorize booting VMs, applying configs, or bootstrapping etcd. Explicit phase approval and the Phase 6 operator checkpoints still apply.

## Operator checkpoint pattern

For every checkpoint owned by the operator, use the same loop:

1. Read the checkpoint section in `docs/runbooks/phase-6-kubernetes-bootstrap.md` (or the active phase runbook).
2. Understand what the command changes and why it is needed.
3. Review the expected output/state and stop conditions.
4. Run only the presented command(s) locally.
5. Inspect the output yourself.
6. Share the relevant output with ChatGPT/Codex for interpretation when useful.
7. Continue only after the checkpoint result is classified `PASS`, `WARNING`, or `BLOCKER`.

Never combine several learning-critical checkpoints into an unattended script just to finish a phase faster.

## After implementation

When a phase-specific validator exists:

```bash
make phase-validate PHASE=6
```

Collect concise evidence with:

```bash
make phase-report PHASE=6
```

Review the PR/diff against the active contract. Findings should be classified as `BLOCKER`, `WARNING`, or `IMPROVEMENT`. If a fix is needed, give Codex only the recorded findings and directly relevant files rather than requesting another repository-wide review.

## Completion boundary

A phase is complete only after its acceptance criteria pass, documentation/evidence are recorded, the change is merged, and the canonical tracker is updated with durable evidence.

After completing a phase, stop. Do not begin the next numbered phase automatically.
