.PHONY: lint dry-run deploy vault-edit tf-init tf-apply

ANSIBLE_DIR=ansible
TF_DIR=terraform

lint:
	cd $(ANSIBLE_DIR) && ansible-lint site.yml

dry-run:
	cd $(ANSIBLE_DIR) && ansible-playbook site.yml --check --ask-vault-pass

deploy:
	cd $(ANSIBLE_DIR) && ansible-playbook site.yml --ask-vault-pass

vault-edit:
	cd $(ANSIBLE_DIR) && ansible-vault edit group_vars/all/vault.yml

tf-init:
	cd $(TF_DIR) && terraform init

tf-apply:
	cd $(TF_DIR) && terraform apply -auto-approve
