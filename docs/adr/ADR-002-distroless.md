# ADR-002: Distroless base image

**Status:** Accepted

`gcr.io/distroless/static-debian12` has no shell or package manager, so the attack surface stays small. The Go binary is built with `CGO_ENABLED=0` and runs as `nonroot` (UID 65532).

**Trade-off:** no `kubectl exec` shell; use logs, `kubectl debug`, or port-forward for checks.
