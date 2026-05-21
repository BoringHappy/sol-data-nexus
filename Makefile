# sol-data-nexus — orchestration entry points
#
# Run `make help` (or just `make`) to see all available targets.
# Each `## description` comment after a target name shows up in the help output.
# `##@ Section name` lines mark section headers in the help output.

SHELL := /bin/bash

.DEFAULT_GOAL := help

.PHONY: help \
        up down status demo \
        up-compose down-compose logs-compose status-compose \
        up-k8s down-k8s status-k8s \
        test-smoke

##@ High-level lifecycle (filled in by task #15)

help: ## Show this help message
	@awk 'BEGIN {FS = ":.*?## "} \
		/^##@ / { printf "\n\033[1m%s\033[0m\n", substr($$0, 5); next } \
		/^[a-zA-Z0-9_-]+:.*?## / { printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
	@echo ""

up: ## Bring up the full stack (Compose data plane + k8s compute plane)
	@echo "[stub] make up — to be implemented by task #15"

down: ## Tear down the full stack
	@echo "[stub] make down — to be implemented by task #15"

status: ## Print unified status of Compose + k8s
	@echo "[stub] make status — to be implemented by task #15"

demo: ## Run the end-to-end demo (stub until spec #8 / polish)
	@echo "[stub] make demo — to be implemented by spec #8"

##@ Docker Compose lifecycle (filled in by task #12)

up-compose: ## Bring up MinIO + Redpanda + ClickHouse via Docker Compose
	@echo "[stub] make up-compose — to be implemented by task #12"

down-compose: ## Tear down the Compose stack
	@echo "[stub] make down-compose — to be implemented by task #12"

logs-compose: ## Tail logs from the Compose stack
	@echo "[stub] make logs-compose — to be implemented by task #12"

status-compose: ## Show Compose service status
	@echo "[stub] make status-compose — to be implemented by task #12"

##@ Kubernetes lifecycle (filled in by tasks #13 and #14)

up-k8s: ## Bring up kind cluster + Spark Operator + Strimzi Kafka
	@echo "[stub] make up-k8s — to be implemented by tasks #13 / #14"

down-k8s: ## Tear down the kind cluster
	@echo "[stub] make down-k8s — to be implemented by tasks #13 / #14"

status-k8s: ## Show k8s cluster + operator status
	@echo "[stub] make status-k8s — to be implemented by tasks #13 / #14"

##@ Tests (filled in by task #15)

test-smoke: ## Run the foundation smoke test against the live stack
	@echo "[stub] make test-smoke — to be implemented by task #15"
