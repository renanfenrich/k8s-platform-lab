# Phase 6 runbook: Kubernetes bootstrap

> **Status:** proposed, not approved for consequential execution yet.
>
> This runbook is a study guide for the operator checkpoints defined in `.ai/phases/phase-06.yaml`. Commands that boot VMs, apply Talos configuration, bootstrap etcd, or change VM boot media must not be run until Phase 6 is explicitly approved and the current live state passes preflight.

## Objective

Bootstrap the existing three-node Talos Kubernetes lab from the approved Phase 5 machine configurations while keeping CNI `none` and kube-proxy disabled. Cilium belongs to Phase 7.

The intended nodes are:

| Node | Role | Address |
| --- | --- | --- |
| `talos-cp01` | control plane | `10.10.10.11` |
| `talos-worker01` | worker | `10.10.10.21` |
| `talos-worker02` | worker | `10.10.10.22` |

The generated machine configs and client `talosconfig` are local ignored artifacts. `versions.env` remains authoritative for the Talos and Kubernetes versions.

## Why this phase is guided

This is the first phase where the lab changes from offline definitions into a running distributed system. The operator should directly observe:

- Talos maintenance mode before configuration;
- installation to `/dev/vda` and reboot behavior;
- the difference between unauthenticated maintenance access and authenticated Talos API access;
- the one-time nature of etcd bootstrap;
- Kubernetes API availability before a CNI exists;
- the expected `NotReady`/`Pending` state before Cilium is installed.

## Session setup

Run from the repository root.

```bash
set -euo pipefail
source versions.env

export CP=10.10.10.11
export W1=10.10.10.21
export W2=10.10.10.22
export CONFIG_DIR="generated/talos-${TALOS_VERSION}"
export TALOSCONFIG="$PWD/$CONFIG_DIR/talosconfig"
export KUBECONFIG="$PWD/kubeconfig"
```

Confirm the derived paths without changing anything:

```bash
printf 'Talos: %s\nKubernetes: %s\nConfigs: %s\nTalosconfig: %s\nKubeconfig: %s\n' \
  "$TALOS_VERSION" "$KUBERNETES_VERSION" "$CONFIG_DIR" "$TALOSCONFIG" "$KUBECONFIG"
```

Expected: the paths reference the pinned Talos version and remain inside ignored local artifact locations/files.

---

## Checkpoint 6.1: inspect runtime and boot-media readiness

**Owner:** operator  
**Risk:** read-only  
**Purpose:** prove that the assumptions from Phases 0-5 still match the workstation before anything is started.

### Repository and orchestration state

```bash
git status --short --branch
git log --oneline --decorate -n 10
make phase-status
make validate
make phase-preflight PHASE=6
```

Expected before execution:

- Phase 6 is the next incomplete phase;
- the phase branch/worktree is clean at the execution boundary;
- host/KVM/libvirt/network/VM checks pass;
- generated Talos configs exist and pass strict validation;
- warnings are understood rather than silently ignored.

### Inspect the three domains

```bash
for vm in talos-cp01 talos-worker01 talos-worker02; do
  echo "=== $vm ==="
  virsh -c qemu:///system domstate "$vm"
  virsh -c qemu:///system domblklist "$vm" --details
  virsh -c qemu:///system domiflist "$vm"
done
```

Expected: all three VMs exist, are stopped before boot-media work, use the approved disks/network, and have no unexplained attached media.

### Check current host capacity

```bash
free -h
df -h /var/lib/libvirt/images
virsh -c qemu:///system pool-info default
```

The operator should confirm that current memory and physical storage headroom remain reasonable before starting three 4 GiB guests. Thin-provisioned QCOW2 capacity is not the same as physical free space.

### Boot-media verification boundary

The Phase 6 implementation must provide a checksum-verified method for obtaining the Talos boot image pinned by `TALOS_VERSION`. Before using it, inspect the implementation and independently compare the expected checksum/source.

Do **not** use a `latest` URL and do not substitute another Talos version without a separate compatibility review and explicit approval.

**Stop condition:** any unexpected domain, disk, network, version, config, checksum, or capacity state is a `BLOCKER` until reviewed.

---

## Checkpoint 6.2: attach media and start Talos VMs

**Owner:** operator  
**Risk:** consequential but non-destructive when performed against the existing domains  
**Purpose:** boot Talos into maintenance mode and observe the machine before applying configuration.

The exact `virsh` media attach/detach commands and ISO path are intentionally finalized by the Phase 6 implementation only after the current domain XML and verified boot artifact are inspected. Do not guess a CD-ROM target device or ISO path from this document.

Before running the generated commands, review them with:

```bash
virsh -c qemu:///system dumpxml talos-cp01
virsh -c qemu:///system dumpxml talos-worker01
virsh -c qemu:///system dumpxml talos-worker02
```

After the approved media is attached, start one node at a time so its behavior is visible:

```bash
virsh -c qemu:///system start talos-cp01
virsh -c qemu:///system console talos-cp01
```

Exit a libvirt serial console with `Ctrl+]`.

Repeat for each worker only after the previous node's first boot is understood:

```bash
virsh -c qemu:///system start talos-worker01
virsh -c qemu:///system console talos-worker01

virsh -c qemu:///system start talos-worker02
virsh -c qemu:///system console talos-worker02
```

### What to observe

Talos should boot into maintenance mode and expose the expected DHCP address for each reserved MAC/IP. At this point the nodes have not yet received their machine configuration.

Read-only network checks from the host can include:

```bash
virsh -c qemu:///system net-dhcp-leases lab-net
ping -c 2 "$CP"
ping -c 2 "$W1"
ping -c 2 "$W2"
```

A failed ping is not by itself proof that Talos is broken; correlate it with DHCP leases and console state.

**Stop condition:** wrong IP, wrong disk/media, unexpected boot source, repeated reboot loop, or unexplained console errors.

---

## Checkpoint 6.3: apply Talos machine configurations

**Owner:** operator  
**Risk:** consequential; installs/configures Talos on the existing VM disks  
**Purpose:** transition each maintenance-mode machine into its approved configured state.

Talos maintenance mode initially has no authenticated cluster PKI. For the initial apply, `--insecure` means the connection is encrypted but not authenticated.

Apply the control-plane config first:

```bash
talosctl apply-config \
  --insecure \
  --nodes "$CP" \
  --file "$CONFIG_DIR/talos-cp01.yaml"
```

Observe the console and wait for the installation/reboot transition before proceeding.

Then apply the worker configs individually:

```bash
talosctl apply-config \
  --insecure \
  --nodes "$W1" \
  --file "$CONFIG_DIR/talos-worker01.yaml"

talosctl apply-config \
  --insecure \
  --nodes "$W2" \
  --file "$CONFIG_DIR/talos-worker02.yaml"
```

### After reboot, verify authenticated Talos access

```bash
talosctl --talosconfig "$TALOSCONFIG" \
  --endpoints "$CP" \
  --nodes "$CP" version
```

Then inspect services without changing them:

```bash
talosctl --talosconfig "$TALOSCONFIG" \
  --endpoints "$CP" \
  --nodes "$CP,$W1,$W2" service
```

### What to observe

- Talos installs to the already-approved `/dev/vda` target.
- The machines reboot into the configured Talos installation.
- Authenticated Talos API access works with the generated `talosconfig`.
- Control-plane and worker service sets differ by role.
- Do not expect a functional Kubernetes network yet.

**Stop condition:** installation targets an unexpected disk, authenticated access fails after a reasonable reboot period, a node gets an unexpected identity/address, or services show persistent unexplained failures.

Do not respond to a failure with `talosctl reset`, disk deletion, or VM recreation. Those are outside the normal rollback boundary and require separate explicit approval.

---

## Checkpoint 6.4: bootstrap etcd exactly once

**Owner:** operator  
**Risk:** high-significance one-time cluster initialization  
**Purpose:** initialize etcd on the single control-plane node so the Kubernetes control plane can form.

Before bootstrap, confirm that the target is the control-plane node:

```bash
talosctl --talosconfig "$TALOSCONFIG" \
  --endpoints "$CP" \
  --nodes "$CP" get members
```

Then bootstrap **once, on `talos-cp01` only**:

```bash
talosctl --talosconfig "$TALOSCONFIG" \
  --endpoints "$CP" \
  --nodes "$CP" bootstrap
```

Do not rerun this command just because the cluster takes time to converge. Talos documents bootstrap as a one-time operation on a single control-plane node.

### Inspect etcd after bootstrap

```bash
talosctl --talosconfig "$TALOSCONFIG" \
  --endpoints "$CP" \
  --nodes "$CP" service etcd

talosctl --talosconfig "$TALOSCONFIG" \
  --endpoints "$CP" \
  --nodes "$CP" etcd member list

talosctl --talosconfig "$TALOSCONFIG" \
  --endpoints "$CP" \
  --nodes "$CP" etcd status
```

If etcd is unhealthy, inspect before changing anything:

```bash
talosctl --talosconfig "$TALOSCONFIG" \
  --endpoints "$CP" \
  --nodes "$CP" logs etcd --tail 100
```

**Stop condition:** bootstrap reports a clear error, etcd repeatedly crashes, membership is inconsistent with the one-control-plane design, or there is evidence that bootstrap may already have been performed unexpectedly.

---

## Checkpoint 6.5: retrieve access config and inspect the first Kubernetes state

**Owner:** operator  
**Risk:** primarily read-only after writing the ignored local kubeconfig  
**Purpose:** prove that the Kubernetes API exists and understand the intentional pre-Cilium state.

Retrieve the kubeconfig into the repository's ignored `kubeconfig` path rather than merging it into the workstation's default Kubernetes configuration:

```bash
talosctl --talosconfig "$TALOSCONFIG" \
  --endpoints "$CP" \
  --nodes "$CP" kubeconfig "$KUBECONFIG"
```

Inspect the API and nodes:

```bash
kubectl --kubeconfig "$KUBECONFIG" cluster-info
kubectl --kubeconfig "$KUBECONFIG" get nodes -o wide
kubectl --kubeconfig "$KUBECONFIG" get pods -A -o wide
```

Inspect Talos membership and services as a second source of evidence:

```bash
talosctl --talosconfig "$TALOSCONFIG" \
  --endpoints "$CP" \
  --nodes "$CP" get members

talosctl --talosconfig "$TALOSCONFIG" \
  --endpoints "$CP" \
  --nodes "$CP,$W1,$W2" service
```

### Expected transitional state

The Kubernetes API should be reachable, but **do not require all nodes or network-dependent pods to be `Ready` in Phase 6**. The machine configs intentionally set CNI to `none` and disable kube-proxy. Phase 7 installs Cilium.

The important distinction to learn is:

- etcd/control-plane/API bootstrap can succeed;
- Kubernetes node networking is not complete yet;
- `NotReady` nodes or pending networking-dependent workloads can therefore be expected at this boundary.

Unexpected crash loops or API unreachability are different from the expected missing-CNI readiness condition and should be investigated.

---

## Checkpoint 6.6: detach boot media and verify disk boot

**Owner:** operator  
**Risk:** consequential boot configuration operation  
**Purpose:** prove that Talos is installed persistently and the VMs no longer depend on installation media.

As with attachment, the exact detach command/device is finalized by the Phase 6 implementation after inspecting the actual libvirt domain configuration. Do not guess the target device.

Before detaching anything:

```bash
for vm in talos-cp01 talos-worker01 talos-worker02; do
  echo "=== $vm ==="
  virsh -c qemu:///system domblklist "$vm" --details
done
```

After executing the reviewed detach/reboot sequence, inspect again and verify the machines return from their virtual disks.

```bash
for vm in talos-cp01 talos-worker01 talos-worker02; do
  echo "=== $vm ==="
  virsh -c qemu:///system domstate "$vm"
  virsh -c qemu:///system domblklist "$vm" --details
done
```

Then re-run authenticated state checks:

```bash
talosctl --talosconfig "$TALOSCONFIG" \
  --endpoints "$CP" \
  --nodes "$CP,$W1,$W2" version

kubectl --kubeconfig "$KUBECONFIG" get nodes -o wide
```

**Stop condition:** a node no longer boots, installation media remains unexpectedly attached, or a node loses its configured identity/state.

Do not delete/recreate the VM or disk as an automatic fix.

---

## Phase validation

The Phase 6 implementation must add a phase-specific read-only validator before Phase 6 can be marked complete:

```bash
make phase-validate PHASE=6
```

It should demonstrate at minimum:

- all three nodes are installed and reachable through Talos;
- the three expected node identities/addresses exist;
- etcd is healthy on `talos-cp01`;
- the Kubernetes API is reachable using the ignored local kubeconfig;
- CNI remains `none` and kube-proxy remains disabled;
- Cilium has not been installed;
- installation media is no longer required for normal boot;
- no host safety-boundary change occurred.

Collect final evidence with:

```bash
make phase-report PHASE=6
```

Phase 6 then stops. Cilium installation and node-network readiness belong to Phase 7.

## Troubleshooting discipline

When an unexpected state appears, collect evidence before attempting repair. Useful read-only commands include:

```bash
virsh -c qemu:///system domstate <vm>
virsh -c qemu:///system domblklist <vm> --details
virsh -c qemu:///system net-dhcp-leases lab-net

talosctl --talosconfig "$TALOSCONFIG" --endpoints "$CP" --nodes <ip> version
talosctl --talosconfig "$TALOSCONFIG" --endpoints "$CP" --nodes <ip> service
talosctl --talosconfig "$TALOSCONFIG" --endpoints "$CP" --nodes <ip> dmesg
talosctl --talosconfig "$TALOSCONFIG" --endpoints "$CP" --nodes <ip> logs <service> --tail 100
```

Classify the result as `PASS`, `WARNING`, or `BLOCKER` before choosing a fix. Do not silently cross the destructive rollback boundary.

## Primary Talos references

The command sequence follows the Talos getting-started/CLI model: boot Talos, apply machine configuration in maintenance mode, configure authenticated `talosctl` access, bootstrap etcd once on one control-plane node, and retrieve kubeconfig. Before Phase 6 execution, re-check the official documentation for the pinned Talos version if any CLI behavior has changed.
