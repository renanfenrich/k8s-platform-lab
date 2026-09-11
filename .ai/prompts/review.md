Review Phase {{PHASE}} against the repository contract. Do not redesign unrelated parts of the lab.

Read:
1. `AGENTS.md`
2. `.ai/project-policy.md`
3. `.ai/phases/phase-{{PHASE_PADDED}}.yaml`
4. the Phase {{PHASE}} diff/PR and only directly relevant files

Verify scope adherence, safety boundaries, pinned-version discipline, implementation correctness, validation coverage, rollback behavior, documentation, and whether acceptance criteria are actually demonstrated.

Classify every finding as `BLOCKER`, `WARNING`, or `IMPROVEMENT`. Prefer concrete file/line references and specific remediation. If there are no blockers, say so explicitly. Do not implement fixes during the review and do not begin another phase.
