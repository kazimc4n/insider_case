# Runbook

Track B (minikube). Bootstrap: `make track-b-setup` / teardown: `make track-b-teardown`.

## Restart

```bash
# one pod
kubectl delete pod -l app.kubernetes.io/name=insider-case

# whole deployment
kubectl rollout restart deployment/insider-case
kubectl rollout status deployment/insider-case --timeout=120s
```

## Rollback

```bash
helm history insider-case
helm rollback insider-case <revision>
kubectl rollout status deployment/insider-case --timeout=120s
```

Emergency without Helm:

```bash
kubectl rollout undo deployment/insider-case
```

## Logs

```bash
kubectl logs -l app.kubernetes.io/name=insider-case --tail=100 -f
kubectl logs <pod> --previous   # after crash
```

JSON logs include `request_id`, `method`, `path`, `status`, `duration`.

Filter with jq:

```bash
kubectl logs -l app.kubernetes.io/name=insider-case --tail=200 | jq 'select(.level=="ERROR")'
```

## Observability

```bash
make grafana
# Dashboard: insider-case
# Alert: HighHTTPErrorRate (>5% 5xx for 2m)
```

Reinstall stack: `make monitoring-uninstall && make monitoring-install`.

## Checks

```bash
kubectl get pods,svc -l app.kubernetes.io/name=insider-case
kubectl describe deployment insider-case
kubectl top pods -l app.kubernetes.io/name=insider-case   # needs metrics-server
```
