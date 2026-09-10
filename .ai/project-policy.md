# AI orchestration policy

The repository is the handoff layer between ChatGPT, Codex, deterministic tooling, and the human operator.

## Roles

- **ChatGPT:** architecture/research, phase-contract creation, risk review, PR/diff review, and targeted fix guidance. Normal chat should carry as much reasoning as possible before Codex is invoked.
- **Codex:** bounded repository implementation and narrowly scoped fixes. It should not rediscover the project roadmap or redesign an approved phase unless explicitly asked.
- **Deterministic tooling:** current-state detection, preflight, validation, and evidence collection. Prefer scripts over AI for facts that can be checked locally.
- **Human operator:** approves each numbered phase, participates in learning-critical execution/decisions, and approves any additional destructive action required by the safety boundary.

## Guided study mode

Guided study mode is the default for every phase.

A phase contract may define `operator_checkpoints`. These are intentionally local, human-run gates for mechanisms worth observing directly or actions with meaningful operational consequences. At each checkpoint the assistant/agent must:

1. explain the mechanism and why the step is required;
2. show the exact command(s) to run locally;
3. state expected output/state, risk, and rollback boundary;
4. stop and wait for the operator's output or explicit approval before continuing.

Do not turn operator checkpoints into unattended scripts. Automation should cover repetitive discovery, static checks, evidence collection, and other low-risk work that does not hide the mechanism being studied.

## Lifecycle

1. Detect the next incomplete phase with `make phase-status`.
2. Create or review `.ai/phases/phase-XX.yaml`, including operator checkpoints.
3. Run `make phase-preflight PHASE=<n>` before consequential phase execution.
4. Generate the implementation handoff with `make phase-goal PHASE=<n> MODE=implement`.
5. Codex implements only preparatory/automation work allowed by the approved contract and stops at operator checkpoints.
6. The human operator performs each checkpoint locally and shares/inspects the result before continuation.
7. Run `make phase-validate PHASE=<n>` when a phase-specific validator exists.
8. Review the diff/PR against the contract. Classify findings as `BLOCKER`, `WARNING`, or `IMPROVEMENT`.
9. If fixes are needed, save actionable findings to a small text/Markdown file and generate `MODE=fix`; do not resend broad repository context.
10. Re-run deterministic validation.
11. Human approves merge. Update tracker evidence only after successful validation and merge.
12. Stop. Do not begin the next phase automatically.

## Usage-budget rules

- Keep permanent instructions short; put phase-specific detail in the phase contract.
- Give Codex file paths and acceptance criteria instead of asking it to review the whole repository.
- Prefer one implementation pass plus targeted fixes over repeated broad reviews.
- Start with the lowest capable model and reasoning effort. Escalate only when a concrete failure requires deeper reasoning.
- Do not enable automatic Codex execution on every commit or PR update by default.
- Never invoke Codex from a Make target implicitly. AI execution must remain an explicit human action so quota cannot be consumed unexpectedly.
