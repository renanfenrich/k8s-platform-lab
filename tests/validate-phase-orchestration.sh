#!/usr/bin/env bash
set -euo pipefail

repo_root=$(git rev-parse --show-toplevel)

pass() { printf 'PASS  %s\n' "$1"; }
fail() { printf 'FAIL  %s\n' "$1" >&2; exit 1; }

for path in \
  AGENTS.md \
  .ai/project-policy.md \
  .ai/phases/phase-06.yaml \
  .ai/prompts/implement.md \
  .ai/prompts/review.md \
  .ai/prompts/fix.md \
  scripts/phase.sh; do
  [[ -f "$repo_root/$path" ]] || fail "missing orchestration file: $path"
done
pass 'orchestration files exist'

bash -n "$repo_root/scripts/phase.sh" || fail 'scripts/phase.sh has invalid shell syntax'
bash -n "$repo_root/tests/validate-current-state.sh" || fail 'tests/validate-current-state.sh has invalid shell syntax'
pass 'orchestration shell syntax is valid'

status=$(bash "$repo_root/scripts/phase.sh" status)
grep -q '^NEXT_PHASE=6$' <<<"$status" || fail 'canonical tracker should currently resolve Phase 6 as next'
grep -q '^NEXT_PHASE_NAME=Kubernetes bootstrap$' <<<"$status" || fail 'Phase 6 name was not parsed correctly'
pass 'phase status resolves canonical tracker state'

contract="$repo_root/.ai/phases/phase-06.yaml"
grep -q '^execution_mode: guided$' "$contract" || fail 'Phase 6 must use guided execution mode'
grep -q '^operator_checkpoints:$' "$contract" || fail 'Phase 6 must define operator checkpoints'
grep -q 'name: Bootstrap etcd exactly once' "$contract" || fail 'Phase 6 must keep etcd bootstrap as an operator checkpoint'
pass 'Phase 6 preserves guided study checkpoints'

for mode in implement review; do
  rendered=$(bash "$repo_root/scripts/phase.sh" goal 6 "$mode")
  grep -q '{{PHASE' <<<"$rendered" && fail "$mode prompt still contains phase placeholders"
done
pass 'implementation and review prompts render without unresolved phase placeholders'

printf 'PASS  phase orchestration is statically valid\n'
