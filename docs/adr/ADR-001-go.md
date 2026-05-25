# ADR-001: Use Go as the Application Language

**Status:** Accepted  
**Date:** 2026-05-18  

---

## Context

The case study requires building a lightweight HTTP microservice that exposes health check and version endpoints. The service will be containerised with a distroless Docker image, deployed to Kubernetes, and needs to start fast with minimal resource consumption. The language choice affects image size, startup latency, dependency management complexity, and compatibility with distroless base images. The primary candidates considered were Go, Node.js, and Python.

## Decision

We chose **Go** as the application language for the following reasons:

- **Single static binary:** Go compiles to a single, statically-linked binary with zero runtime dependencies. This makes it trivially compatible with distroless images that contain no libc, no interpreter, and no package manager. Node.js requires a runtime (~150 MB), and Python requires an interpreter plus virtual environment management.
- **Excellent standard library:** Go's `net/http` package provides a production-grade HTTP server without any external framework. Routing, JSON encoding, and test utilities (`httptest`) are all built-in, keeping the dependency tree minimal and the `go.sum` small.
- **Fast CI builds:** Go compiles in seconds and produces a small binary (~6–8 MB stripped), which reduces Docker image build time and layer cache invalidation. This is important for a CI pipeline that builds on every push.
- **Distroless compatibility:** The `gcr.io/distroless/static-debian12` image is designed for statically-compiled languages like Go. Using Go makes the final image under 10 MB, compared to ~100+ MB for Node.js or Python alternatives.
- **Built-in concurrency:** Go's goroutine model handles concurrent HTTP requests efficiently out of the box, without requiring async frameworks or event loops.

## Consequences

- **`go.sum` file:** Adding external dependencies (e.g., `prometheus/client_golang`) introduces a `go.sum` file that must be committed and kept in sync. This adds a small maintenance burden but ensures reproducible builds.
- **Longer compile times vs. interpreted languages:** Go requires a compilation step, which adds ~5–10 seconds to the CI pipeline compared to interpreted languages. This is offset by the faster runtime performance and smaller image size.
- **Less ecosystem for web frameworks:** Go's HTTP ecosystem is more minimal compared to Node.js (Express) or Python (FastAPI). For this use case, the standard library is sufficient, but a more complex service might benefit from a framework like Chi or Gin.
- **Steeper learning curve:** Go's error handling patterns and struct-based design are less familiar to developers coming from dynamic languages, which could slow initial development.
