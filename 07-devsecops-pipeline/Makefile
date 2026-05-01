.PHONY: scan build deploy

# Variables
APP_DIR=app
INFRA_DIR=infrastructure
IMAGE_NAME=devsecops-sample-app
AWS_REGION=ap-south-1

scan:
	@echo "🔍 Running Security Scans..."
	# Filesystem scan
	trivy fs $(APP_DIR)
	# Terraform scan
	checkov -d $(INFRA_DIR) --compact
	# Dependency scan
	cd $(APP_DIR) && npm audit

build:
	@echo "📦 Building Docker Image..."
	docker build -t $(IMAGE_NAME):latest $(APP_DIR)

deploy:
	@echo "🚀 Provisioning Infrastructure..."
	cd $(INFRA_DIR) && terraform init && terraform apply -auto-approve
