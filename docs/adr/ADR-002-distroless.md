# ADR-002: Use Distroless Base Image over Alpine

**Status:** Accepted  
**Date:** 2026-05-18  

---

## Context

The final Docker image needs a base that is secure, small, and suitable for production workloads running in Kubernetes. The two primary candidates are `alpine:3.x` (~7 MB, includes musl libc, shell, and apk package manager) and `gcr.io/distroless/static-debian12` (~2 MB, contains nothing except CA certificates and timezone data). Since the Go binary is statically compiled with `CGO_ENABLED=0`, it does not require any libc or shared libraries at runtime, making both options viable from a compatibility standpoint.

## Decision

We chose **`gcr.io/distroless/static-debian12`** as the production base image for the following reasons:

- **Minimal attack surface:** Distroless images contain no shell (`/bin/sh`), no package manager (`apk`/`apt`), and no UNIX utilities. If an attacker achieves remote code execution, they cannot install tools, spawn a shell, or escalate privileges. Alpine includes BusyBox, which provides a shell and dozens of utilities that could be leveraged post-exploitation.
- **Smaller image size:** The distroless static image is approximately 2 MB compared to Alpine's 7 MB. Combined with a stripped Go binary (~6 MB), the total image is under 10 MB, reducing pull times and storage costs.
- **No CVEs from OS packages:** With no packages installed, there are no OS-level CVEs to patch. Alpine images frequently have CVEs in musl, BusyBox, or apk itself, requiring regular base image updates.
- **Built-in nonroot user:** Distroless images ship with a `nonroot` user (UID 65532) ready to use, making it straightforward to run the container as a non-root user without additional `adduser` commands.
- **Google-maintained:** Distroless images are maintained by Google and used internally for production workloads, providing confidence in their long-term maintenance and security posture.

## Consequences

- **No shell for debugging:** `kubectl exec -it <pod> -- /bin/sh` will fail because no shell exists. Debugging requires `kubectl logs`, ephemeral debug containers (`kubectl debug --image=busybox`), or attaching a sidecar. This adds friction during incident response but is an acceptable trade-off for the security benefits.
- **Cannot install packages at runtime:** If the application needs additional OS-level tools (e.g., `curl` for health checks inside the container), they must be copied from the builder stage during the Docker build. The Dockerfile `HEALTHCHECK` instruction is limited to what's available in the image.
- **Dependency on Google's distroless repository:** If Google discontinues the distroless project, we would need to switch to an alternative minimal image (e.g., `chainguard/static`). This is a low-probability risk given Google's investment in the project.
- **Static compilation required:** The application must be compiled with `CGO_ENABLED=0` to avoid dynamically linking against glibc/musl. This precludes the use of Go packages that require cgo (e.g., some SQLite bindings), though this is not a concern for this HTTP-only service.
