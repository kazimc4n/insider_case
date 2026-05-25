# Security Policy

Security practices and rationale for the `insider-case` service.

---

## 1. Secret Handling

**Policy:** No plaintext secrets are stored in this repository.

- All environment-specific values use Kubernetes ConfigMaps or Helm values overlays.
- `.env` is git-ignored; only `.env.example` with placeholder values is committed.
- `gitleaks` runs in CI on every push and PR to detect accidental secret commits.
- `GITHUB_TOKEN` (an automatically-provisioned, scoped token) is used for GHCR authentication — no personal access tokens (PATs) are stored in workflow files.

**Recommendation for production:** Migrate environment variables to Kubernetes Secrets (encrypted at rest via `EncryptionConfiguration`) or an external secret manager such as HashiCorp Vault or Sealed Secrets.

---

## 2. Image Scanning

**Tool:** [Trivy](https://github.com/aquasecurity/trivy) (Aqua Security)

**Why Trivy:**
- Industry-standard, open-source vulnerability scanner with the largest CVE database coverage.
- First-class GitHub Actions integration (`aquasecurity/trivy-action`).
- Scans both OS-level packages and application dependencies in a single pass.
- Supports multiple output formats (table, JSON, SARIF) for CI integration and GitHub Security tab.

**CI configuration:**
- Trivy scans every image pushed to GHCR as part of the CI pipeline.
- Severity threshold: `CRITICAL,HIGH` — the build fails if any critical or high-severity vulnerability is found.
- `ignore-unfixed: true` — vulnerabilities without an available fix are reported but do not block the build, since no action can be taken.

---

## 3. Non-Root Container

**Decision:** The application runs as `nonroot:nonroot` (UID 65532) inside a `gcr.io/distroless/static-debian12` base image.

**Justification:**
- Running as root inside a container is a well-known attack vector. If the application is compromised, an attacker gains root-level access to the container filesystem and potentially the host (via container escape vulnerabilities).
- Distroless images contain no shell (`/bin/sh`), no package manager, and no utilities — an attacker who gains code execution cannot install tools, escalate privileges, or pivot easily.
- The Kubernetes Deployment enforces `runAsNonRoot: true` and `runAsUser: 65532` at the pod security context level, providing defense-in-depth even if the Dockerfile is modified.

**Trade-offs:**
- Debugging is harder — `kubectl exec` into the container will not provide a shell. Use `kubectl logs`, ephemeral debug containers (`kubectl debug`), or a sidecar with a shell image for troubleshooting.

---

## 4. Port Exposure

| Port | Protocol | Exposed To | Purpose |
|------|----------|------------|---------|
| 8080 | TCP | Cluster-internal (via Kubernetes Service) | Application HTTP server |
| 80 | TCP | Cluster-internal (Service → 8080) | Service abstraction port |
| NodePort (dynamic) | TCP | minikube host | Development access via `minikube service` |

- **No ports are exposed to `0.0.0.0` on the host** by default.
- Public access is provided exclusively through `cloudflared tunnel`, which establishes an outbound-only connection to Cloudflare's edge — no inbound firewall rules or port-forwarding required.
- SSH and admin ports are not exposed.
- The application does not bind to any port other than the configured `PORT` environment variable (default `8080`).

---

## 5. Supply Chain Security

- Container images are pushed to **GitHub Container Registry (GHCR)** with immutable SHA-based tags (`sha-<full-commit-sha>`).
- The `latest` tag is updated only on merges to `main`, but deployments always reference the SHA tag for reproducibility.
- All CI dependencies use pinned versions (`actions/checkout@v4`, `docker/build-push-action@v6`, etc.).
- `gitleaks` scans the full git history (`fetch-depth: 0`) to catch secrets in any commit, not just the latest.

---

## Reporting a Vulnerability

If you discover a security vulnerability, please open a private issue or contact the maintainer directly. Do not open a public issue for security reports.
