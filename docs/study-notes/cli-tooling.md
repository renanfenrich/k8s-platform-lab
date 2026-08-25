# CLI tooling study note

`kubectl` talks to the Kubernetes API, Helm renders and tracks chart releases, `talosctl` speaks to the Talos machine API, and Cilium CLI installs, validates, and diagnoses Cilium. These are client tools only: installing them does not bootstrap a Kubernetes cluster or modify the libvirt network.

Inspect versions with `make tooling-validate`. Later phases use these exact pins to avoid accidental compatibility drift.
