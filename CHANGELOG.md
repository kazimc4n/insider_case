# Changelog

All notable changes to this project will be documented in this file.

## [0.1.0] - 2026-05-24

### Added
- HTTP service with `/ping`, `/healthz`, `/version` endpoints (Go)
- Multi-stage Dockerfile with distroless base image and non-root user
- Helm chart with `values-dev.yaml` and `values-prod.yaml` environments
- Liveness, readiness probes pointed at `/healthz`
- Resource requests and limits per container
- Rollout and rollback verified via `helm history`
- CI pipeline: lint (golangci-lint), test, Docker build, Trivy image scan, GHCR push
- Gitleaks secret scanning in CI
- Build-time version injection via `-ldflags`
- Auto-deploy to minikube via self-hosted GitHub Actions runner (`kubectl set image`)
- ADR-003: kubectl set image over ArgoCD for Track B