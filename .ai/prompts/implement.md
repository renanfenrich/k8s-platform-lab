Implement Phase {{PHASE}} using the repository as the source of truth.

Read, in this order:
1. `AGENTS.md`
2. `.ai/project-policy.md`
3. `.ai/phases/phase-{{PHASE_PADDED}}.yaml`
4. only the repository files listed by that phase contract

Before editing, run `make phase-status` and `make phase-preflight PHASE={{PHASE}}`.

Implement only the approved phase contract. Do not perform a repository-wide redesign, change pinned versions, cross into another phase, or silently work around failed preconditions. Prefer existing project patterns and deterministic scripts over new dependencies.

After changes, run the narrowest relevant checks and `make phase-validate PHASE={{PHASE}}` if a phase-specific validator now exists. Report changed files, commands run, PASS/WARNING/BLOCKER results, remaining risks, and stop. Do not merge or begin the next phase.
