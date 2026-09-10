Implement Phase {{PHASE}} using the repository as the source of truth.

Read, in this order:
1. `AGENTS.md`
2. `.ai/project-policy.md`
3. `.ai/phases/phase-{{PHASE_PADDED}}.yaml`
4. only the repository files listed by that phase contract

Before editing, run `make phase-status` and `make phase-preflight PHASE={{PHASE}}`.

Implement only the approved phase contract. Do not perform a repository-wide redesign, change pinned versions, cross into another phase, or silently work around failed preconditions. Prefer existing project patterns and deterministic scripts over new dependencies.

This is a study lab running in guided mode. Respect every `operator_checkpoints` entry in the phase contract. You may prepare scripts, validations, exact commands, expected results, and rollback notes around a checkpoint, but you must not execute human-owned checkpoint commands unattended. When execution reaches a checkpoint, explain it and stop so the operator can run the command locally and provide the result before continuation.

After changes and completed checkpoints, run the narrowest relevant checks and `make phase-validate PHASE={{PHASE}}` if a phase-specific validator now exists. Report changed files, commands run, PASS/WARNING/BLOCKER results, remaining risks, completed operator checkpoints, and stop. Do not merge or begin the next phase.
