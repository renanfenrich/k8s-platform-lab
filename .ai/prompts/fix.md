Fix only the recorded findings for Phase {{PHASE}}.

Read:
1. `AGENTS.md`
2. `.ai/phases/phase-{{PHASE_PADDED}}.yaml`
3. `{{FINDINGS_FILE}}`
4. only files directly required to resolve those findings

Do not perform a fresh repository-wide review, redesign the phase, change pinned versions, or add unrelated refactors. Resolve BLOCKER findings first, then WARNING findings that are in scope. Treat IMPROVEMENT findings as optional unless explicitly requested.

Run the narrowest deterministic checks that prove each fix and then `make phase-validate PHASE={{PHASE}}` when available. Report which findings were resolved, validation results, anything still blocked, and stop.
