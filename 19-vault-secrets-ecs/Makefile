.PHONY: init apply destroy setup status rotate-root

TERRAFORM_DIR=terraform

init:
	cd $(TERRAFORM_DIR) && terraform init

apply:
	cd $(TERRAFORM_DIR) && terraform apply -auto-approve

destroy:
	cd $(TERRAFORM_DIR) && terraform destroy -auto-approve

vault-init:
	./scripts/vault-init.sh

vault-setup:
	./scripts/vault-setup.sh

status:
	curl -s $(VAULT_ADDR)/v1/sys/health | jq

rotate-root:
	@echo "Rotating Vault root token..."
	vault token rotate

teardown: destroy
