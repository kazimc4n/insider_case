# Runbook — insider-case

Operational procedures for the `insider-case` HTTP service running on minikube (Track B).

---

## 1. Restart Procedures

### Single Pod Crash (CrashLoopBackOff)

```bash
# Identify the crashing pod
kubectl get pods -l app.kubernetes.io/name=insider-case

# Check why it crashed
kubectl describe pod <pod-name>
kubectl logs <pod-name> --previous

# Delete the pod — the Deployment controller will recreate it
kubectl delete pod <pod-name>

# Confirm it comes back healthy
kubectl get pods -l app.kubernetes.io/name=insider-case -w
```

### Full Service Restart

```bash
# Restart all pods in the deployment (rolling restart)
kubectl rollout restart deployment/insider-case

# Wait for rollout to complete
kubectl rollout status deployment/insider-case --timeout=120s
```

---

## 2. Rollback Procedures

### Helm Rollback

```bash
# List release history
helm history insider-case

# Roll back to a specific revision (e.g. revision 2)
helm rollback insider-case 2

# Confirm the rollback completed
kubectl rollout status deployment/insider-case --timeout=120s

# Verify the running image
kubectl get deployment insider-case -o jsonpath='{.spec.template.spec.containers[0].image}'
```

### Kubectl Rollback (emergency, without Helm)

```bash
# View deployment revision history
kubectl rollout history deployment/insider-case

# Roll back to the previous revision
kubectl rollout undo deployment/insider-case

# Or to a specific revision
kubectl rollout undo deployment/insider-case --to-revision=3
```

---

## 3. Viewing Logs

### Basic Log Access

```bash
# Tail logs from all pods
kubectl logs -l app.kubernetes.io/name=insider-case --tail=100 -f

# Logs from a specific pod
kubectl logs <pod-name> --tail=200

# Previous container logs (after a crash)
kubectl logs <pod-name> --previous
```

### Filtering by Request ID

Structured logs include a `request_id` field. Filter with `jq`:

```bash
kubectl logs -l app.kubernetes.io/name=insider-case --tail=500 | \
  jq -r 'select(.request_id == "<target-request-id>")'
```

### Filtering by Log Level

```bash
kubectl logs -l app.kubernetes.io/name=insider-case --tail=500 | \
  jq -r 'select(.level == "ERROR")'
```

---

## 4. Secret Rotation

The application currently uses environment variables passed via Helm values. To rotate a secret without downtime:

### Step 1 — Update the Helm Values

Edit `values-prod.yaml` (or the relevant values file) with the new secret value.

### Step 2 — Upgrade the Release

```bash
helm upgrade insider-case charts/insider-case \
  -f charts/insider-case/values-prod.yaml

# This triggers a rolling update — old pods serve traffic until new pods are ready
kubectl rollout status deployment/insider-case --timeout=120s
```

### Step 3 — Verify

```bash
# Confirm the new pods are running
kubectl get pods -l app.kubernetes.io/name=insider-case

# Hit the health endpoint to confirm service is up
curl http://localhost:8080/healthz
```

> **Note:** For production use, migrate from plain environment variables to Kubernetes Secrets or an external secret manager (e.g. HashiCorp Vault, Sealed Secrets). This ensures secrets are encrypted at rest and not stored in version control.

---

## 5. Useful Diagnostic Commands

```bash
# Pod status overview
kubectl get pods -l app.kubernetes.io/name=insider-case -o wide

# Deployment details
kubectl describe deployment insider-case

# Service and endpoints
kubectl get svc insider-case
kubectl get endpoints insider-case

# Resource usage (requires metrics-server)
kubectl top pods -l app.kubernetes.io/name=insider-case

# Events (for debugging scheduling/probe failures)
kubectl get events --sort-by=.metadata.creationTimestamp | tail -20
```
