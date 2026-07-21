# terraform-kind-argocd-prom

The main purpose of this project is automate the creation of a local kind cluster with terraform. It then installs ArgoCD and sets up the initial repo from which to pull from.  This includes the Prometheus, Grafana and ArgoCD(now with dashboard!)

This terraform:
- provisions a local kubernetes-in-docker (kind) cluster with 1 control plane and 2 worker nodes using terraform tehcyx/kind provider
- terraform installs argocd via helm release chart argo-cd from argo-helm repo
- terraform pulls configs from https://github.com/andrewstewartelliott-lang/argocd using base/base.yaml on `main`
- argocd installs the prometheus/grafana monitoring stack and metrics from official sources

## Getting Started

Before running this project, make sure you have:

- Terraform greater than 1.15 installed (I use `tfenv`)
- Docker installed and running
- Kind installed
- kubectl installed

Now pull the code and apply terraform:
```bash
git clone https://github.com/andrewstewartelliott-lang/terraform-kind-argocd-prom.git
cd ./terraform-kind-argocd-prom/
terraform init
terraform apply
```

## Expected output
```bash
% terraform apply
...
...
Apply complete! Resources: 4 added, 0 changed, 0 destroyed.

Outputs:

argocd_helm_message = <<EOT

In order to access the server UI you have the following options:

1. kubectl port-forward service/argocd-server -n argocd 8080:443

    and then open the browser on http://localhost:8080 and accept the certificate

2. enable ingress in the values file `server.ingress.enabled` and either
      - Add the annotation for ssl passthrough: https://argo-cd.readthedocs.io/en/stable/operator-manual/ingress/#option-1-ssl-passthrough
      - Set the `configs.params."server.insecure"` in the values file and terminate SSL at your ingress: https://argo-cd.readthedocs.io/en/stable/operator-manual/ingress/#option-2-multiple-ingress-objects-and-hosts


After reaching the UI the first time you can login with username: admin and the random password generated during the installation. You can find the password by running:

kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

(You should delete the initial secret afterwards as suggested by the Getting Started Guide: https://argo-cd.readthedocs.io/en/stable/getting_started/#4-login-using-the-cli)

EOT
kind_cluster_status = "ready"
```

# Access the UIs
## ArgoCD
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```
```bash
kubectl port-forward service/argocd-server -n argocd 8080:443
```
```bash
https://localhost:8080/
```

## Grafana
```bash
kubectl get secret -n argocd kube-prometheus-stack-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```
```bash
kubectl port-forward service/kube-prometheus-stack-grafana -n argocd 9092:80
```
```bash
http://localhost:9092/
```


## Prometheus
```bash
kubectl port-forward service/kube-prometheus-stack-prometheus -n argocd 9090:9090
```
```bash
http://localhost:9090/
```