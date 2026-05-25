#!/usr/bin/env bash
# Tear down Track B resources (app + optional monitoring). Keeps minikube cluster by default.
set -euo pipefail

DELETE_CLUSTER=0

usage() {
  cat <<'EOF'
Usage: scripts/track-b-teardown.sh [options]

Options:
  --delete-cluster   Stop and delete the minikube cluster
  -h, --help         Show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --delete-cluster) DELETE_CLUSTER=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
  shift
done

echo "==> Removing Helm releases"
helm uninstall insider-case 2>/dev/null || true
helm uninstall kube-prometheus -n monitoring 2>/dev/null || true

if [[ "$DELETE_CLUSTER" -eq 1 ]]; then
  echo "==> Deleting minikube cluster"
  minikube delete
else
  echo "Minikube cluster left running. Use --delete-cluster to remove it."
fi

echo "Track B teardown complete."
