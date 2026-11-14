# terraform-kind-argocd-prom

Terraform for a local, security-hardened Kubernetes cluster running in Docker ([kind](https://kind.sigs.k8s.io/)), with optional add-ons:

- **kind cluster:** 1 control-plane node and 2 workers, using the [`tehcyx/kind`](https://registry.terraform.io/providers/tehcyx/kind/latest) provider.
- **Persistent volumes** backed by a folder on your machine, so data survives a cluster rebuild.
- **CIS hardening:** audit logging, Secrets encrypted at rest, profiling disabled, and kubelet limits. See [Security hardening](#security-hardening).
- **[kro](https://kro.run/)** (Kube Resource Orchestrator). On by default.
- **[Argo CD](https://argo-cd.readthedocs.io/)**. Off by default. When enabled, it syncs the apps in [andrewstewartelliott-lang/argocd](https://github.com/andrewstewartelliott-lang/argocd): Prometheus, Grafana with dashboards, kube-state-metrics, node-exporter and ClickStack.

## Prerequisites

- Terraform 1.15 or later (`tfenv` works well).
- Docker, running. On macOS, Docker Desktop must be able to share this repo's folder; anything under `/Users` is shared by default.
- [kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation).
- `kubectl`. Terraform calls it to apply the Argo CD base manifest.
- Free host ports **80, 443, 8000 and 8080**. These are mapped to the control-plane node, which is labelled `ingress-ready=true` for an ingress controller.

## Quick start

```bash
git clone https://github.com/andrewstewartelliott-lang/terraform-kind-argocd-prom.git
cd terraform-kind-argocd-prom
terraform init
terraform apply                         # cluster + kro
terraform apply -var enable_argo=true   # cluster + kro + Argo CD and its apps
```

Then point `kubectl` at the cluster:

```bash
export KUBECONFIG=~/.kube/test-cluster-config
kubectl get nodes
```

Terraform writes the kubeconfig to `~/.kube/<cluster_name>-config`, not to your main `~/.kube/config`. To use it alongside your other clusters:

```bash
export KUBECONFIG=~/.kube/config:~/.kube/test-cluster-config
```

The file contains cluster-admin credentials, so don't share it.

## Configuration

Set variables with `-var name=value` or a `terraform.tfvars` file. `.tfvars` files are gitignored.

| Variable | Default | Description |
|---|---|---|
| `cluster_name` | `test-cluster` | kind cluster name. It is also used in the kubeconfig file name. |
| `node_image` | `kindest/node:v1.36.1` | kind node image, which sets the Kubernetes version. |
| `enable_argo` | `false` | Installs Argo CD (Helm chart `argo-cd` 10.18.0) and applies the Argo base manifest. |
| `argo_manifest_url` | `…/argocd/refs/heads/main/argo/base/base.yaml` | The Argo CD `Application` that bootstraps everything else. |
| `enable_kro` | `true` | Installs kro from `oci://registry.k8s.io/kro/charts/kro`. |
| `kro_chart_version` | `0.10.0` | kro chart version. |
| `host_storage_path` | `./.kind-storage` | Absolute path on the host used for volume data. |
| `api_version` | `kind.x-k8s.io/v1alpha4` | kind config API version. |

Outputs:
- `kind_cluster_status`: `ready` once the cluster is up.
- `argocd_helm_message`: Argo CD's install notes, or a note that Argo CD is disabled.

## Using the cluster

### Argo CD (when `enable_argo = true`)

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
kubectl port-forward service/argocd-server -n argocd 8080:443
```
Open https://localhost:8080 and log in as `admin` with that password. Delete `argocd-initial-admin-secret` after you change the password.

### Grafana

The Argo CD apps deploy Grafana into the `argocd` namespace.

```bash
kubectl get secret -n argocd kube-prometheus-stack-grafana -o jsonpath="{.data.admin-password}" | base64 -d; echo
kubectl port-forward service/kube-prometheus-stack-grafana -n argocd 9092:80
```
Open http://localhost:9092 and log in as `admin`.

### Prometheus

```bash
kubectl port-forward service/kube-prometheus-stack-prometheus -n argocd 9090:9090
```
Open http://localhost:9090.

### kro

```bash
kubectl -n kro-system get pods
kubectl get crd | grep kro.run
```
To define your own APIs with `ResourceGraphDefinition`s, see the [kro docs](https://kro.run/docs/overview).

## Persistent volumes

Every node mounts the host folder `host_storage_path` (default `./.kind-storage`, which is gitignored). As a result, volume data:
- can be read directly on your machine;
- is visible from every node, so a pod can move between workers and keep its data;
- survives `terraform destroy`.

| Use case | How | Data on the host |
|---|---|---|
| Dynamic volume (most cases) | Create a PVC. It gets kind's default `standard` StorageClass (local-path-provisioner). | `.kind-storage/local-path/<pv>_<namespace>_<pvc>/` |
| Your own hostPath PV | Point the PV's `hostPath` under `/mnt/data/`, and set `storageClassName: ""` on **both** the PV and the PVC. | `.kind-storage/static/...` |

Things that commonly trip people up:
- **A PVC stays `Pending` until a pod uses it.** `standard` waits for a pod before it creates the volume (`WaitForFirstConsumer`).
- **A PVC with no `storageClassName` never binds to a hand-made PV.** Kubernetes gives it `standard`, so it gets a new dynamic volume instead. Set `storageClassName: ""` on both to bind them.
- **Deleting a PVC deletes its data.** Dynamic volumes use the `Delete` reclaim policy. To keep one, run `kubectl patch pv <name> -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}'` before deleting the claim.

Test it:
```bash
kubectl apply -f tests/pvc/dynamic-pvc.yaml
kubectl get pvc,pv
kubectl logs test-dynamic-pod
kubectl delete -f tests/pvc/dynamic-pvc.yaml
```

## Security hardening

The cluster is set up to pass most of the [CIS Kubernetes Benchmark](https://www.cisecurity.org/benchmark/kubernetes) as checked by [kube-bench](https://github.com/aquasecurity/kube-bench). Everything is configured in [main.tf](main.tf).

| Hardening | kube-bench checks | Details |
|---|---|---|
| API server audit log | 1.2.16–1.2.19, 3.2.1 | Policy in [audit-policy.yaml](audit-policy.yaml). Logs are kept for 30 days, 10 files of up to 100 MB. |
| Secrets encrypted at rest | 1.2.27, 1.2.28 | `secretbox` with a random key generated into `.kind-secrets/` |
| Profiling disabled | 1.2.15, 1.3.2, 1.4.1 | API server, controller manager and scheduler |
| Service account tokens not extended | 1.2.30 | |
| Process limit per pod | 4.2.13 | `podPidsLimit: 4096` on every node |
| Default seccomp profile | 4.2.14 | `seccompDefault: true` on every node |

Latest kube-bench (v0.16.0) result: the control plane has 57 PASS and 2 FAIL, and each node has 19 PASS and 2 FAIL. Every remaining failure is something kind sets up, not something in this config:
- **1.1.12:** kind nodes have no `etcd` user to own etcd's data directory.
- **1.2.5:** the API server doesn't verify kubelet certificates, because the kubelets' serving certificates are self-signed.
- **4.1.1 and 4.1.9:** the kubelet service file and config file are mode 644 instead of 600.

Things to know:
- **Audit log:** read it with `docker exec test-cluster-control-plane tail -f /var/log/kubernetes/audit/audit.log`.
- **Encryption key:** `.kind-secrets/encryption-config.yaml` is created on the first apply and then reused. It never goes into Git or Terraform state.
  - **Don't delete it while a cluster is running**; the API server would fail on its next restart.
  - Deleting it between rebuilds is fine; the next apply creates a new key.
- **Seccomp default:** containers run under the runtime's default seccomp profile. A workload that needs blocked system calls can opt out with `securityContext.seccompProfile.type: Unconfined`.
- **Limits of encryption at rest:** anyone who can read your kubeconfig or the key file can still read Secrets. Don't put real production credentials into a local cluster.

To run kube-bench yourself, use the upstream Job manifests (`job-master.yaml` and `job-node.yaml` in the [kube-bench repo](https://github.com/aquasecurity/kube-bench)). Pin the image to a version, then read the results with `kubectl logs job/<name>`.

## Rebuilding and changing the cluster

Most changes to the kind cluster settings in [main.tf](main.tf) (node patches, mounts, port mappings, node image) can only take effect on a new cluster. **A rebuild deletes everything running on the cluster** except volume data in `.kind-storage/`.

Run a rebuild like this:
```bash
terraform destroy -refresh=false
terraform apply
```

`-refresh=false` is needed because, once the config requires a new cluster, the Helm provider can't connect to the old one during refresh. A plain `terraform destroy` or `terraform apply` then fails with `Kubernetes cluster unreachable`.

If `~/.kube/test-cluster-config` has been deleted while the cluster is still running, recreate it before destroying:
```bash
kind export kubeconfig --name test-cluster --kubeconfig ~/.kube/test-cluster-config
```

Turning `enable_argo` or `enable_kro` on or off doesn't need a rebuild. Turning Argo CD off removes Argo CD itself, but the apps it deployed stay on the cluster.

## Repository layout

| Path | Purpose |
|---|---|
| [main.tf](main.tf) | kind cluster: nodes, mounts, ports, hardening patches and encryption-key generation |
| [helm.tf](helm.tf) | Argo CD and kro Helm releases |
| [argo.tf](argo.tf) | Downloads and applies the Argo CD base `Application` |
| [variables.tf](variables.tf) / [outputs.tf](outputs.tf) | Inputs and outputs |
| [terraform.tf](terraform.tf) | Provider versions and configuration |
| [audit-policy.yaml](audit-policy.yaml) | API server audit policy |
| [tests/pvc/](tests/pvc/) | Persistent volume smoke test |
| `.kind-storage/` | Volume data (gitignored) |
| `.kind-secrets/` | Secrets encryption key (gitignored) |
