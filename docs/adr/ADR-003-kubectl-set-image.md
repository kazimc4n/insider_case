# ADR-003: Use `kubectl set image` over ArgoCD for Track B Deploys

**Status:** Accepted  
**Date:** 2026-05-24  

---

## Context

Track B requires deploying to a local minikube cluster exposed via cloudflared tunnel. The CI pipeline on GitHub Actions must auto-deploy on merges to main. Two approaches were evaluated: pull-based GitOps (ArgoCD/Flux inside minikube polling Git) and push-based deploy (self-hosted runner executing `kubectl set image`). The minikube cluster runs behind NAT with no static IP, so GitHub-hosted runners cannot reach the Kubernetes API server.

## Decision

We chose **`kubectl set image` via a self-hosted GitHub Actions runner** because:

- **GitHub-hosted runners cannot reach local minikube** — the cluster is behind NAT with no inbound connectivity. A self-hosted runner on the same machine has direct kubeconfig access.
- **ArgoCD pull-based model is unreliable over a tunnel** — cloudflared exposes HTTP services, not the K8s API. Configuring ArgoCD sync over this adds complexity disproportionate to project scope.
- **Simplicity** — `kubectl set image` is a single imperative command, easy to understand and debug. The deploy job is ~10 lines of YAML vs ~100+ lines for a full ArgoCD setup.
- **Immediate feedback** — `kubectl rollout status` confirms success/failure directly in the GitHub Actions run.

## Consequences

- **Self-hosted runner is a SPOF** — if the local machine is off, deploys queue indefinitely. Acceptable for a case study, not for production.
- **Not GitOps** — cluster state is not derived from a Git-tracked source of truth. Manual in-cluster changes cause drift that won't self-heal (ArgoCD would).
- **kubeconfig dependency** — the runner relies on `~/.kube/config` having a valid minikube context. Cluster recreation breaks deploys until config is updated.
- **Single-cluster only** — for multi-environment, a GitOps approach with ArgoCD ApplicationSets would be more appropriate.
