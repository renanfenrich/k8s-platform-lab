SHELL := /usr/bin/env bash

PHASE ?=
MODE ?= implement
FINDINGS ?=

.PHONY: preflight validate orchestration-validate network-define network-autostart network-start network-status tooling-install tooling-validate phase4-create phase4-validate phase5-generate phase5-validate phase-status phase-context phase-goal phase-preflight phase-validate phase-report

preflight:
	./scripts/preflight.sh

validate:
	bash ./tests/validate-current-state.sh

orchestration-validate:
	bash ./tests/validate-phase-orchestration.sh

# Phase 2: each target maps directly to the documented virsh command.
network-define:
	virsh -c qemu:///system net-define infrastructure/libvirt/lab-net.xml

network-autostart:
	virsh -c qemu:///system net-autostart lab-net

network-start:
	virsh -c qemu:///system net-start lab-net

network-status:
	virsh -c qemu:///system net-info lab-net
	virsh -c qemu:///system net-dumpxml lab-net

tooling-install:
	./scripts/install-cli-tools.sh

tooling-validate:
	./tests/validate-cli-tools.sh

phase4-create:
	./scripts/create-talos-vms.sh

phase4-validate:
	./tests/validate-talos-vms.sh

phase5-generate:
	./scripts/generate-talos-config.sh

phase5-validate:
	./tests/validate-talos-configs.sh

phase-status:
	@bash ./scripts/phase.sh status

phase-context:
	@test -n "$(PHASE)" || (echo 'PHASE is required, e.g. make phase-context PHASE=6' >&2; exit 2)
	@bash ./scripts/phase.sh context "$(PHASE)"

phase-goal:
	@test -n "$(PHASE)" || (echo 'PHASE is required, e.g. make phase-goal PHASE=6 MODE=implement' >&2; exit 2)
	@bash ./scripts/phase.sh goal "$(PHASE)" "$(MODE)" "$(FINDINGS)"

phase-preflight:
	@test -n "$(PHASE)" || (echo 'PHASE is required, e.g. make phase-preflight PHASE=6' >&2; exit 2)
	@bash ./scripts/phase.sh preflight "$(PHASE)"

phase-validate:
	@test -n "$(PHASE)" || (echo 'PHASE is required, e.g. make phase-validate PHASE=6' >&2; exit 2)
	@bash ./scripts/phase.sh validate "$(PHASE)"

phase-report:
	@test -n "$(PHASE)" || (echo 'PHASE is required, e.g. make phase-report PHASE=6' >&2; exit 2)
	@bash ./scripts/phase.sh report "$(PHASE)"
