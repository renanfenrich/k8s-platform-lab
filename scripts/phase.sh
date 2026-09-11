#!/usr/bin/env bash
set -euo pipefail

repo_root=$(git rev-parse --show-toplevel)
tracker="$repo_root/docs/stage-1-goal-and-phase-tracker.md"

usage() {
  cat <<'EOF'
Usage:
  bash scripts/phase.sh status
  bash scripts/phase.sh context <phase>
  bash scripts/phase.sh goal <phase> [implement|review|fix] [findings-file]
  bash scripts/phase.sh preflight <phase>
  bash scripts/phase.sh validate <phase>
  bash scripts/phase.sh report <phase>
EOF
}

require_phase() {
  local phase=${1:-}
  [[ "$phase" =~ ^[0-9]+$ ]] || { printf 'BLOCKER  phase must be a number\n' >&2; exit 2; }
}

phase_padded() {
  printf '%02d' "$1"
}

contract_path() {
  printf '%s/.ai/phases/phase-%s.yaml' "$repo_root" "$(phase_padded "$1")"
}

next_phase_line() {
  grep -m1 '^- \[ \] Phase [0-9]' "$tracker" || true
}

next_phase_number() {
  local line
  line=$(next_phase_line)
  [[ -n "$line" ]] || return 1
  printf '%s\n' "$line" | sed -E 's/^- \[ \] Phase ([0-9]+).*/\1/'
}

cmd_status() {
  local line phase name
  line=$(next_phase_line)
  if [[ -z "$line" ]]; then
    printf 'PASS  no incomplete numbered phase found in canonical tracker\n'
    return 0
  fi
  phase=$(printf '%s\n' "$line" | sed -E 's/^- \[ \] Phase ([0-9]+).*/\1/')
  name=$(printf '%s\n' "$line" | sed -E 's/^- \[ \] Phase [0-9]+ — (.*)\.$/\1/')
  printf 'NEXT_PHASE=%s\nNEXT_PHASE_NAME=%s\n' "$phase" "$name"
}

cmd_context() {
  local phase=$1 contract
  require_phase "$phase"
  contract=$(contract_path "$phase")
  [[ -f "$contract" ]] || { printf 'BLOCKER  missing phase contract: %s\n' "$contract" >&2; exit 2; }

  printf '=== phase ===\n'
  printf 'PHASE=%s\nCONTRACT=%s\n\n' "$phase" "${contract#$repo_root/}"
  printf '=== git status ===\n'
  git -C "$repo_root" status --short --branch
  printf '\n=== recent git history ===\n'
  git -C "$repo_root" log --oneline --decorate -n 10
  printf '\n=== pinned versions ===\n'
  cat "$repo_root/versions.env"
  printf '\n=== phase contract ===\n'
  cat "$contract"
}

cmd_goal() {
  local phase=$1 mode=${2:-implement} findings=${3:-}
  local padded template escaped_findings
  require_phase "$phase"
  padded=$(phase_padded "$phase")

  case "$mode" in
    implement|review|fix) ;;
    *) printf 'BLOCKER  mode must be implement, review, or fix\n' >&2; exit 2 ;;
  esac

  template="$repo_root/.ai/prompts/$mode.md"
  [[ -f "$template" ]] || { printf 'BLOCKER  missing prompt template: %s\n' "$template" >&2; exit 2; }
  [[ -f "$(contract_path "$phase")" ]] || { printf 'BLOCKER  missing phase contract for Phase %s\n' "$phase" >&2; exit 2; }

  if [[ "$mode" == fix ]]; then
    [[ -n "$findings" ]] || { printf 'BLOCKER  fix mode requires a findings file\n' >&2; exit 2; }
    [[ -f "$repo_root/$findings" || -f "$findings" ]] || { printf 'BLOCKER  findings file does not exist: %s\n' "$findings" >&2; exit 2; }
  else
    findings=${findings:-not-applicable}
  fi

  escaped_findings=$(printf '%s' "$findings" | sed 's/[&|]/\\&/g')
  sed \
    -e "s|{{PHASE_PADDED}}|$padded|g" \
    -e "s|{{PHASE}}|$phase|g" \
    -e "s|{{FINDINGS_FILE}}|$escaped_findings|g" \
    "$template"
}

cmd_preflight() {
  local phase=$1 expected contract talos_version config_dir
  require_phase "$phase"
  contract=$(contract_path "$phase")
  [[ -f "$contract" ]] || { printf 'BLOCKER  missing phase contract: %s\n' "$contract" >&2; exit 2; }

  expected=$(next_phase_number || true)
  [[ -n "$expected" ]] || { printf 'BLOCKER  canonical tracker has no incomplete phase\n' >&2; exit 2; }
  [[ "$phase" == "$expected" ]] || {
    printf 'BLOCKER  requested Phase %s but canonical tracker says Phase %s is next\n' "$phase" "$expected" >&2
    exit 2
  }

  if [[ -n "$(git -C "$repo_root" status --porcelain)" ]]; then
    printf 'BLOCKER  working tree must be clean before phase execution\n' >&2
    git -C "$repo_root" status --short --branch >&2
    exit 2
  fi

  make -C "$repo_root" validate

  if [[ "$phase" == 6 ]]; then
    # shellcheck disable=SC1091
    source "$repo_root/versions.env"
    talos_version=${TALOS_VERSION#v}
    config_dir="$repo_root/generated/talos-v$talos_version"
    [[ -d "$config_dir" ]] || {
      printf 'BLOCKER  Phase 6 requires regenerated/validated local Talos configs: %s\n' "$config_dir" >&2
      exit 2
    }
    bash "$repo_root/tests/validate-talos-configs.sh"
  fi

  printf 'PASS  Phase %s preflight completed; consequential execution still requires explicit user approval\n' "$phase"
}

cmd_validate() {
  local phase=$1 validator
  require_phase "$phase"
  validator="$repo_root/tests/validate-phase-$(phase_padded "$phase").sh"
  [[ -f "$validator" ]] || {
    printf 'BLOCKER  phase-specific validator does not exist yet: %s\n' "${validator#$repo_root/}" >&2
    printf 'INFO  the active phase implementation should add this validator before claiming completion\n' >&2
    exit 2
  }
  bash "$validator"
}

cmd_report() {
  local phase=$1 contract validator
  require_phase "$phase"
  contract=$(contract_path "$phase")
  validator="$repo_root/tests/validate-phase-$(phase_padded "$phase").sh"

  printf 'PHASE=%s\n' "$phase"
  printf 'CONTRACT=%s\n' "${contract#$repo_root/}"
  printf 'HEAD=%s\n' "$(git -C "$repo_root" rev-parse HEAD)"
  printf 'BRANCH=%s\n' "$(git -C "$repo_root" branch --show-current)"
  printf 'VALIDATOR=%s\n' "$([[ -f "$validator" ]] && printf 'present' || printf 'missing')"
  printf '\n=== git status ===\n'
  git -C "$repo_root" status --short --branch
  printf '\n=== recent commits ===\n'
  git -C "$repo_root" log --oneline --decorate -n 10
  printf '\n=== current tracker state ===\n'
  cmd_status
}

command=${1:-}
case "$command" in
  status) cmd_status ;;
  context) cmd_context "${2:-}" ;;
  goal) cmd_goal "${2:-}" "${3:-implement}" "${4:-}" ;;
  preflight) cmd_preflight "${2:-}" ;;
  validate) cmd_validate "${2:-}" ;;
  report) cmd_report "${2:-}" ;;
  *) usage; exit 2 ;;
esac
