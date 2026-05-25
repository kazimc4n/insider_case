# Security

## Secrets

- No real credentials in the repo. `.env` is gitignored; [`.env.example`](.env.example) has placeholders only.
- CI runs [gitleaks](https://github.com/gitleaks/gitleaks) on every push/PR.
- GHCR login uses the workflow `GITHUB_TOKEN`, not a stored PAT.

## Image scanning

[Trivy](https://github.com/aquasecurity/trivy) runs on every built image. CRITICAL and HIGH findings fail the pipeline (`exit-code: 1`). Unfixed issues are reported but do not block when no fix exists (`ignore-unfixed: true`).

## Container hardening

- Base: `gcr.io/distroless/static-debian12`, user `nonroot` (65532).
- Helm sets `runAsNonRoot` and `runAsUser: 65532`.
- App listens on `PORT` (default 8080) inside the cluster only.

## Exposure

- Service is cluster-internal (NodePort on minikube host).
- Public access is via **cloudflared** (outbound tunnel), not open SSH or wide security groups.

## Images

Tags: `sha-<full-commit-sha>` on CI; semver on release tags. Deploy uses the SHA tag for reproducibility.
