# insider-case

Insider One DevOps internship case — small Go HTTP service, Docker, Helm on minikube, GitHub Actions CI, Prometheus/Grafana.

**Track:** B (local minikube + cloudflared; no AWS)

## Prerequisites

Go 1.26+, Docker, minikube, kubectl, Helm 3, cloudflared, Make.

## Quick start (Track B)

```bash
make track-b-setup          # minikube + build + deploy
make track-b-setup-full     # + kube-prometheus-stack
make tunnel                 # public URL via cloudflared
```

Shell alternative: `./scripts/track-b-setup.sh` (`--with-monitoring` for Day 4 stack).

## Local run

```bash
make run                    # go run
docker compose up --build   # container
curl localhost:8080/ping    # {"message":"pong"}
```

Endpoints: `/ping`, `/healthz`, `/version`, `/metrics`.

## Minikube deploy

```bash
make minikube-start
make load-image
make deploy-dev             # values-dev.yaml
make deploy-prod            # values-prod.yaml (2 replicas, GHCR image)
make verify
make port-forward           # localhost:8080
```

Teardown: `make track-b-teardown` or `make track-b-teardown-all` (deletes cluster).

Rollback: `helm history insider-case` → `helm rollback insider-case <rev>`.

## Observability

```bash
make monitoring-install
make deploy-dev             # apply ServiceMonitor
make grafana                # port-forward Grafana
```

Dashboard `insider-case` and alert `HighHTTPErrorRate` (5xx rate > 5%) live under `monitoring/`.

## Environment

| Variable | Default | Purpose |
|----------|---------|---------|
| `PORT` | `8080` | Listen port |
| `GIT_SHA` | build `version` | `/version` response |

See [`.env.example`](.env.example).

## CI/CD

On push/PR to `main`: golangci-lint, tests, image build to GHCR (`sha-<commit>`), Trivy (CRITICAL/HIGH fails build), gitleaks.

Merge to `main` deploys via self-hosted runner: `kubectl set image` on minikube.

Release tag `v*.*.*` triggers [`.github/workflows/release.yaml`](.github/workflows/release.yaml).

## Tool choices

| Choice | Why |
|--------|-----|
| Go + distroless | Static binary, small image, non-root | [ADR-001](docs/adr/ADR-001-go.md), [ADR-002](docs/adr/ADR-002-distroless.md) |
| Helm | Dev/prod values, rollback | chart under `charts/insider-case/` |
| kubectl set image | Self-hosted runner reaches local minikube; no ArgoCD on NAT cluster | [ADR-003](docs/adr/ADR-003-kubectl-set-image.md) |
| cloudflared | Public URL without opening inbound ports | `make tunnel` |
| Trivy + gitleaks | Image and repo secret scanning in CI | `.github/workflows/ci.yaml` |

## Docs

- [RUNBOOK.md](RUNBOOK.md) — restart, rollback, logs
- [SECURITY.md](SECURITY.md) — secrets, scanning, non-root
- [Architecture](docs/architecture/diagram.md)
