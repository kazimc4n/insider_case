# ADR-003: kubectl set image (not ArgoCD)

**Status:** Accepted

Track B runs minikube on a laptop behind NAT. GitHub-hosted runners cannot reach the API server. A self-hosted runner with local kubeconfig can run `kubectl set image` after each merge to `main`.

ArgoCD would need stable API access and more moving parts than this case scope needs.

**Trade-off:** deploys depend on that machine being on; not full GitOps.
