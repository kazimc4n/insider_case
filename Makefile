.PHONY: run test build docker-build docker-run deploy-dev deploy-prod \
	minikube-start monitoring-install monitoring-uninstall monitoring-apply-extras \
	grafana tunnel setup

PROMETHEUS_NS := monitoring
PROMETHEUS_RELEASE := kube-prometheus

run:
	go run ./cmd/server/...

test:
	go test ./...

build:
	go build -o server ./cmd/server/...

docker-build:
	docker build -t insider-case:dev .

docker-run:
	docker run --rm -p 8080:8080 insider-case:dev

deploy-dev:
	helm upgrade --install insider-case charts/insider-case \
		-f charts/insider-case/values-dev.yaml

deploy-prod:
	helm upgrade --install insider-case charts/insider-case \
		-f charts/insider-case/values-prod.yaml

minikube-start:
	minikube start --cpus=4 --memory=6144

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

setup: minikube-start monitoring-install docker-build
	minikube image load insider-case:dev
	$(MAKE) deploy-dev
