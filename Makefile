.PHONY: validate lint clean help

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

validate: ## Validate all Terraform configurations
	@for dir in */terraform */infrastructure; do \
		if [ -d "$$dir" ]; then \
			echo "==> Validating $$dir"; \
			cd "$$dir" && terraform init -backend=false > /dev/null 2>&1 && terraform validate && cd - > /dev/null; \
		fi; \
	done

lint: ## Run linters across all projects
	@echo "==> Checking Terraform formatting..."
	@terraform fmt -check -recursive . || true
	@echo "==> Checking Ansible (if installed)..."
	@command -v ansible-lint > /dev/null 2>&1 && ansible-lint 09-ansible-ec2-hardening/ansible/ || true
	@echo "==> Checking Dockerfiles (if hadolint installed)..."
	@command -v hadolint > /dev/null 2>&1 && find . -name Dockerfile -exec hadolint {} \; || true

clean: ## Remove Terraform caches and build artifacts
	find . -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.tfplan" -delete 2>/dev/null || true
	find . -type f -name "*.tfstate.backup" -delete 2>/dev/null || true
	@echo "Cleaned."
