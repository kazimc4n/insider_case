# Track B (minikube) automation — see scripts/track-b-setup.sh
.PHONY: run test build docker-build docker-run deploy-dev deploy-prod \
	check-tools minikube-start minikube-stop minikube-delete minikube-status \
	load-image verify port-forward \
	monitoring-install monitoring-uninstall monitoring-apply-extras \
	grafana tunnel \
	track-b-setup track-b-setup-full track-b-teardown track-b-teardown-all

PROMETHEUS_NS := monitoring
PROMETHEUS_RELEASE := kube-prometheus
IMAGE_NAME ?= insider-case:dev
MINIKUBE_CPUS ?= 4
MINIKUBE_MEMORY ?= 6144
MINIKUBE_DRIVER ?= docker

export MINIKUBE_CPUS MINIKUBE_MEMORY MINIKUBE_DRIVER IMAGE_NAME

run:
	go run ./cmd/server/...

test:
	go test ./...

build:
	go build -o server ./cmd/server/...

docker-build:
	docker build -t $(IMAGE_NAME) .

docker-run:
	docker run --rm -p 8080:8080 $(IMAGE_NAME)

check-tools:
	@command -v minikube >/dev/null || (echo "missing: minikube" && exit 1)
	@command -v kubectl >/dev/null || (echo "missing: kubectl" && exit 1)
	@command -v helm >/dev/null || (echo "missing: helm" && exit 1)
	@command -v docker >/dev/null || (echo "missing: docker" && exit 1)
	@echo "All Track B tools present."

deploy-dev:
	helm upgrade --install insider-case charts/insider-case \
		-f charts/insider-case/values-dev.yaml

deploy-prod:
	helm upgrade --install insider-case charts/insider-case \
		-f charts/insider-case/values-prod.yaml

minikube-start: check-tools
	minikube start --driver=$(MINIKUBE_DRIVER) --cpus=$(MINIKUBE_CPUS) --memory=$(MINIKUBE_MEMORY)
	minikube addons enable metrics-server 2>/dev/null || true

minikube-stop:
	minikube stop

minikube-delete:
	minikube delete

minikube-status:
	minikube status
	kubectl get nodes -o wide 2>/dev/null || true

load-image: docker-build
	minikube image load $(IMAGE_NAME)

verify:
	@kubectl rollout status deployment/insider-case --timeout=60s
	@kubectl get pods -l app.kubernetes.io/name=insider-case
	@kubectl get svc insider-case

port-forward:
	kubectl port-forward svc/insider-case 8080:80

monitoring-install:
	helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>/dev/null || true
	helm repo update prometheus-community
	helm upgrade --install $(PROMETHEUS_RELEASE) prometheus-community/kube-prometheus-stack \
		-n $(PROMETHEUS_NS) --create-namespace \
		-f monitoring/kube-prometheus-stack-values.yaml \
		--wait --timeout 15m
	$(MAKE) monitoring-apply-extras

monitoring-apply-extras:
	kubectl apply -f monitoring/prometheus-rules.yaml
	-kubectl delete configmap insider-case-grafana-dashboard --ignore-not-found
	kubectl create configmap insider-case-grafana-dashboard \
		--from-file=insider-case.json=monitoring/dashboards/insider-case.json
	kubectl label configmap insider-case-grafana-dashboard grafana_dashboard=1 --overwrite

monitoring-uninstall:
	helm uninstall $(PROMETHEUS_RELEASE) -n $(PROMETHEUS_NS) || true

grafana:
	@echo "Grafana: http://127.0.0.1:3000  user=admin  password=$$(kubectl get secret -n $(PROMETHEUS_NS) $(PROMETHEUS_RELEASE)-grafana -o jsonpath='{.data.admin-password}' | base64 -d; echo)"
	kubectl port-forward -n $(PROMETHEUS_NS) svc/$(PROMETHEUS_RELEASE)-grafana 3000:80

tunnel:
	cloudflared tunnel --url http://$$(minikube ip):$$(kubectl get svc insider-case -o jsonpath='{.spec.ports[0].nodePort}')

# App only: minikube + build + deploy + health check
track-b-setup:
	chmod +x scripts/track-b-setup.sh scripts/track-b-teardown.sh
	./scripts/track-b-setup.sh

# Full stack including kube-prometheus-stack
track-b-setup-full:
	chmod +x scripts/track-b-setup.sh scripts/track-b-teardown.sh
	./scripts/track-b-setup.sh --with-monitoring

track-b-teardown:
	chmod +x scripts/track-b-teardown.sh
	./scripts/track-b-teardown.sh

track-b-teardown-all:
	chmod +x scripts/track-b-teardown.sh
	./scripts/track-b-teardown.sh --delete-cluster
