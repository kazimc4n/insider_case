# Architecture — Track B

```mermaid
flowchart LR
  dev[Developer] --> git[Git push]
  git --> gha[GitHub Actions]
  gha --> lint[Lint / Test]
  gha --> build[Build and push GHCR]
  gha --> scan[Trivy / Gitleaks]
  build --> runner[Self-hosted runner]
  runner --> k8s[minikube cluster]
  k8s --> helm[Helm release insider-case]
  helm --> svc[Service NodePort]
  svc --> tunnel[cloudflared tunnel]
  tunnel --> public[Public URL]
  k8s --> prom[kube-prometheus-stack]
  prom --> graf[Grafana dashboards]
```

## Components

| Component | Role |
|-----------|------|
| **Go service** | `/ping`, `/healthz`, `/version`, `/metrics` |
| **Helm** | Deployment, Service, ServiceMonitor |
| **minikube** | Local Kubernetes (Track B) |
| **GHCR** | Immutable `sha-<commit>` image tags |
| **cloudflared** | Outbound-only public exposure |
| **kube-prometheus-stack** | Prometheus, Grafana, Alertmanager |

Reproducible cluster bootstrap: `make track-b-setup` or `scripts/track-b-setup.sh`.
