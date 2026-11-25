.PHONY: help check fmt tf-test lint test up down smoke

TF_DIR := infra/terraform

help: ## List targets
	@grep -E '^[a-z-]+:.*##' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  %-9s %s\n", $$1, $$2}'

check: ## Run every local quality gate (IaC, security scans, app tests, secrets)
	scripts/check-all.sh

fmt: ## Format Terraform and Python
	terraform fmt -recursive infra
	cd app && ruff format . && ruff check --fix .

tf-test: ## Terraform fmt/validate/test with the mocked AWS provider (no AWS calls)
	terraform fmt -check -recursive infra
	terraform -chdir=$(TF_DIR) init -backend=false -input=false
	terraform -chdir=$(TF_DIR) validate
	terraform -chdir=$(TF_DIR) test

lint: ## tflint + checkov + hadolint + shellcheck
	tflint --chdir=$(TF_DIR) --config=$(CURDIR)/.tflint.hcl --recursive
	checkov --config-file .checkov.yaml -d infra --skip-path tests
	hadolint Dockerfile
	shellcheck scripts/*.sh

test: ## App unit tests with coverage gate
	cd app && python -m pytest

up: ## Start proxy + 2 web replicas + MySQL locally (needs .env)
	docker compose up -d --build --wait

down: ## Stop the local stack and delete its volume
	docker compose down -v --remove-orphans

smoke: ## Build, start, exercise and tear down the compose stack
	scripts/smoke-compose.sh
