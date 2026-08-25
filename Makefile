SHELL := /usr/bin/env bash

.PHONY: preflight network-define network-autostart network-start network-status tooling-install tooling-validate phase4-create phase4-validate

preflight:
	./scripts/preflight.sh

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
