#!/usr/bin/env bash
# Reproducible Track B bootstrap: minikube + insider-case (+ optional monitoring).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

WITH_MONITORING=0
SKIP_BUILD=0
SKIP_MINIKUBE=0

usage() {
  cat <<'EOF'
Usage: scripts/track-b-setup.sh [options]

Options:
  --with-monitoring   Install kube-prometheus-stack after the app
  --skip-build        Skip docker build and minikube image load
  --skip-minikube     Skip minikube start (cluster must already be running)
  -h, --help          Show this help

Environment:
  MINIKUBE_CPUS       CPUs for minikube (default: 4)
  MINIKUBE_MEMORY     Memory in MiB (default: 6144)
  MINIKUBE_DRIVER     minikube driver (default: docker)
  IMAGE_NAME          Docker image name (default: insider-case:dev)
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --with-monitoring) WITH_MONITORING=1 ;;
    --skip-build) SKIP_BUILD=1 ;;
    --skip-minikube) SKIP_MINIKUBE=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
  shift
done

MINIKUBE_CPUS="${MINIKUBE_CPUS:-4}"
MINIKUBE_MEMORY="${MINIKUBE_MEMORY:-6144}"
MINIKUBE_DRIVER="${MINIKUBE_DRIVER:-docker}"
IMAGE_NAME="${IMAGE_NAME:-insider-case:dev}"

require() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "error: required command not found: $cmd" >&2
    exit 1
  fi
}

echo "==> Checking prerequisites"
for cmd in minikube kubectl helm docker make; do
  require "$cmd"
done

if [[ "$SKIP_MINIKUBE" -eq 0 ]]; then
  echo "==> Starting minikube (driver=${MINIKUBE_DRIVER}, cpus=${MINIKUBE_CPUS}, memory=${MINIKUBE_MEMORY})"
  minikube start \
    --driver="${MINIKUBE_DRIVER}" \
    --cpus="${MINIKUBE_CPUS}" \
    --memory="${MINIKUBE_MEMORY}"
fi

echo "==> Enabling minikube addons"
minikube addons enable metrics-server 2>/dev/null || true

if [[ "$SKIP_BUILD" -eq 0 ]]; then
  echo "==> Building Docker image: ${IMAGE_NAME}"
  docker build -t "${IMAGE_NAME}" .
  echo "==> Loading image into minikube"
  minikube image load "${IMAGE_NAME}"
fi

echo "==> Deploying insider-case (dev)"
make deploy-dev

echo "==> Waiting for rollout"
kubectl rollout status deployment/insider-case --timeout=120s

if [[ "$WITH_MONITORING" -eq 1 ]]; then
  echo "==> Installing monitoring stack"
  make monitoring-install
fi

echo "==> Verifying /healthz via port-forward"
kubectl port-forward svc/insider-case 18080:80 >/tmp/insider-case-pf.log 2>&1 &
PF_PID=$!
trap 'kill "$PF_PID" 2>/dev/null || true' EXIT
sleep 2
curl -sf http://127.0.0.1:18080/healthz | grep -q '"status":"ok"'
kill "$PF_PID" 2>/dev/null || true
trap - EXIT

echo ""
echo "Track B setup complete."
echo "  kubectl get pods,svc"
echo "  make port-forward    # http://localhost:8080"
echo "  make tunnel          # public URL via cloudflared"
echo "  make grafana         # after: make monitoring-install"
