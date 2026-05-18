.PHONY: run test build docker-build docker-run deploy-dev deploy-prod

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