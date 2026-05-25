# Changelog

## [Unreleased]

### Added
- Track B scripts and Makefile targets for minikube bootstrap
- kube-prometheus-stack values, Grafana dashboard, PrometheusRule
- ServiceMonitor for `/metrics`

### Changed
- `http_requests_total` includes `status` label for error-rate alerts
- Middleware merged into single `Instrument` handler

## [0.1.0] - 2026-05-24

- Go service: `/ping`, `/healthz`, `/version`
- Multi-stage Dockerfile (distroless, non-root)
- Helm chart with `values-dev.yaml` / `values-prod.yaml`
- CI: lint, test, build, Trivy, gitleaks, GHCR push
- Auto-deploy to minikube (self-hosted runner, `kubectl set image`)
- ADRs for Go, distroless, deploy approach
