# InsiderOne DevOps Internship Case Study

A lightweight HTTP microservice built with Go, containerised with a distroless Docker image, deployed to a local **minikube** cluster via Helm, and exposed to the public internet through a **Cloudflare Tunnel**.

> **Track chosen:** Track B — minikube + cloudflared tunnel (no AWS/EC2)

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Running Locally](#running-locally)
- [Deploy to Minikube](#deploy-to-minikube)
- [Observability](#observability)
- [Environment Variables](#environment-variables)
- [Architecture Overview](#architecture-overview)
- [Tool Choices](#tool-choices)
- [Day-by-Day Summary](#day-by-day-summary)
- [Documentation Links](#documentation-links)
- [AI Tool Disclosure](#ai-tool-disclosure)

---

## Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| Go | 1.24+ | Application language |
| Docker | 24+ | Container build |
| minikube | 1.33+ | Local Kubernetes cluster |
| kubectl | 1.30+ | Cluster management |
| Helm | 3.15+ | Kubernetes package manager |
| cloudflared | 2024.5+ | Tunnel to public URL |
| GNU Make | 4+ | Task automation |

---

## Quick Start

```bash
# One-command bootstrap (starts minikube, deploys chart, opens tunnel)
make setup
```

---

## Running Locally

### With Go

```bash
make run
# → http://localhost:8080/ping
```

### With Docker Compose

```bash
docker-compose up --build
# → http://localhost:8080/ping
```

### Verify Endpoints

```bash
curl http://localhost:8080/ping      # {"message":"pong"}
curl http://localhost:8080/healthz   # {"status":"ok"}
curl http://localhost:8080/version   # {"version":"dev"}
```

---

## Deploy to Minikube

```bash
# Start cluster
make minikube-start

# Deploy dev environment
make deploy-dev

# Deploy prod environment
make deploy-prod

# Access via port-forward
kubectl port-forward svc/insider-case 8080:80

# Or expose via cloudflared tunnel
make tunnel
```

### Rollback

```bash
# View release history
helm history insider-case

# Roll back to previous revision
helm rollback insider-case <revision>

# Confirm rollout status
kubectl rollout status deployment/insider-case
```

---

## Observability

Prometheus metrics are exposed at `/metrics` (`http_requests_total`, `http_request_duration_seconds`). The stack below is optional but matches the case study observability requirements.

### Install kube-prometheus-stack

```bash
# Prometheus Operator, Prometheus, Grafana, Alertmanager
make monitoring-install

# Redeploy app so ServiceMonitor is applied
make deploy-dev
```

### Grafana dashboard

A custom dashboard **insider-case** is loaded via the Grafana sidecar and includes:

- Requests per second (RPS)
- Request latency (p50 / p95)
- HTTP 5xx error rate
- Pod restarts (`kube_pod_container_status_restarts_total`)

```bash
make grafana
# → http://127.0.0.1:3000  (admin / password printed by make grafana)
```

Open **Dashboards → insider-case**.

### Alert rule

`monitoring/prometheus-rules.yaml` defines **HighHTTPErrorRate**: the ratio of 5xx responses to all requests exceeds 5% for 2 minutes.

```bash
# Inspect loaded rules in Prometheus UI
kubectl port-forward -n monitoring svc/kube-prometheus-kube-prome-prometheus 9090:9090
# → http://127.0.0.1:9090/alerts
```

### Generate sample traffic

```bash
kubectl port-forward svc/insider-case 8080:80 &
while true; do curl -s http://localhost:8080/ping > /dev/null; sleep 0.2; done
```

---

## Environment Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `PORT` | string | `8080` | HTTP listen port |
| `GIT_SHA` | string | `dev` | Build version / git SHA for the `/version` endpoint |

Reference: [`.env.example`](.env.example)

---

## Architecture Overview

**Chosen track:** Track B (minikube + cloudflared tunnel)

```
Developer → git push → GitHub Actions (CI)
                            │
                            ├── lint (golangci-lint)
                            ├── test (go test)
                            ├── build & push → GHCR (ghcr.io/kazimc4n/insider_case:sha-<full-sha>)
                            ├── trivy scan (image vulnerability)
                            └── gitleaks (secret scan)
                                    │
                          merge to main triggers deploy job
                                    │
                          self-hosted runner (local machine)
                                    │
                          kubectl set image → minikube cluster
                                    │
                          Helm-managed deployment (insider-case)
                                    │
                          cloudflared tunnel → public URL
```

The self-hosted GitHub Actions runner has direct `kubeconfig` access to minikube, enabling push-based deploys via `kubectl set image`. This avoids the complexity of GitOps controllers (ArgoCD/Flux) that cannot reliably reach a local cluster behind NAT.

For the full component diagram see: [`docs/architecture/diagram.md`](docs/architecture/diagram.md)

---

## Tool Choices

| Tool | Rationale | ADR |
|------|-----------|-----|
| **Go** | Single static binary, excellent stdlib for HTTP, distroless-compatible, fast CI builds | [ADR-001](docs/adr/ADR-001-go.md) |
| **Distroless** | Minimal attack surface — no shell, no package manager, smallest possible image | [ADR-002](docs/adr/ADR-002-distroless.md) |
| **kubectl set image** | Push-based deploy from self-hosted runner; ArgoCD pull-based model unreliable over tunnel to local cluster | [ADR-003](docs/adr/ADR-003-kubectl-set-image.md) |
| **Helm** | Templated K8s manifests with dev/prod value overlays and built-in rollback |
| **GitHub Actions** | Native GHCR integration, free for public repos, supports self-hosted runners |
| **Trivy** | Industry-standard container image scanner, CI-native via GitHub Action |
| **Gitleaks** | Pre-commit and CI secret detection to prevent credential leaks |
| **cloudflared** | Zero-trust tunnel to expose minikube services without port-forwarding or static IPs |

---

## Day-by-Day Summary

### Day 1 — Application
- Built Go HTTP service with `/ping`, `/healthz`, `/version` endpoints
- Created multi-stage Dockerfile with `gcr.io/distroless/static-debian12` and `nonroot` user
- Injected build version via `-ldflags -X main.version`
- Added `docker-compose.yaml` for local development
- Wrote unit tests covering all three endpoints with `httptest`

### Day 2 — Kubernetes & Helm
- Created Helm chart with `values-dev.yaml` and `values-prod.yaml`
- Configured liveness and readiness probes against `/healthz`
- Set resource requests/limits per environment
- Tested `helm upgrade`, `helm rollback`, and `kubectl rollout status`

### Day 3 — CI/CD & Supply Chain
- Built GitHub Actions CI pipeline: lint → test → build-push → trivy → gitleaks
- Pushed images to GHCR with full SHA tags (`sha-<full-sha>`)
- Added Trivy image scanning for CRITICAL/HIGH vulnerabilities
- Created release workflow for semver tags with GitHub Release
- Implemented auto-deploy to minikube via self-hosted runner

### Day 4 — Observability & Documentation
- Added structured logging with `log/slog`
- Integrated Prometheus metrics (`http_requests_total`, `http_request_duration_seconds`)
- Installed `kube-prometheus-stack` on minikube
- Created Grafana dashboard showing RPS, latency, error rate
- Wrote RUNBOOK.md, SECURITY.md, and 3 ADRs
- Extended Makefile with `minikube-start`, `tunnel`, and `setup` targets

---

## Documentation Links

- [RUNBOOK.md](RUNBOOK.md) — Operational runbook (restart, rollback, logs, secret rotation)
- [SECURITY.md](SECURITY.md) — Security policy and rationale
- [ADR-001: Why Go](docs/adr/ADR-001-go.md)
- [ADR-002: Why Distroless](docs/adr/ADR-002-distroless.md)
- [ADR-003: Why kubectl set image](docs/adr/ADR-003-kubectl-set-image.md)
- [Architecture Diagram](docs/architecture/diagram.md)

---

## AI Tool Disclosure

AI coding assistants (GitHub Copilot, Gemini) were used during development for boilerplate generation, Helm template scaffolding, and CI workflow authoring. All generated code was reviewed, tested, and understood before committing. Architectural decisions and trade-off reasoning are the candidate's own.
