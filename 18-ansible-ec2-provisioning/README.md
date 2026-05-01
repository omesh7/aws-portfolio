# 🤖 Project 18: Ansible EC2 Provisioning & Hardening

A production-grade configuration management project that automates the provisioning, security hardening, and application deployment for AWS EC2 instances.

## 🏗️ Architecture

1.  **Infrastructure (Terraform)**: Provisions 2 EC2 instances (AL2023) in the default VPC with a security group allowing SSH (runner only) and HTTP/HTTPS.
2.  **Configuration (Ansible)**:
    *   **Dynamic Inventory**: Automatically discovers EC2 instances based on tags (`Environment=staging`).
    *   **Role-Based Access**: Decoupled roles for common setup, security, docker, and web services.
    *   **Ansible Vault**: Encrypts sensitive data like DB passwords and API keys.

## 📂 Role Structure

-   `common`: Basic system updates and performance tuning (`sysctl`).
-   `security_hardening`: Disables root SSH, enforces key-auth, configures `fail2ban` and `firewalld`.
-   `docker`: Installs Docker Engine and Docker Compose.
-   `webserver`: Deploys a containerized Python app and configures Nginx as a reverse proxy.

## 🔐 Ansible Vault

Sensitive variables are stored in `ansible/group_vars/all/vault.yml`. To edit the vault:

```bash
make vault-edit
# Or manually
ansible-vault edit ansible/group_vars/all/vault.yml
```

You will need the vault password to run the playbooks.

## 🚀 How to Run

### 1. Provision Infrastructure
```bash
cd terraform
terraform init
terraform apply -var="public_key=$(cat ~/.ssh/id_rsa.pub)"
```

### 2. Run Ansible Playbook
```bash
# Run the master playbook
make deploy
# Or for security only
ansible-playbook ansible/hardening.yml --ask-vault-pass
```

## 🛡️ Security Gates
-   **ansible-lint**: Automatically runs in GitHub Actions to ensure best practices.
-   **Dry Run**: The pipeline performs an `ansible-playbook --check` on every push to main to validate changes without affecting staging.
-   **Molecule**: Includes configuration for local testing of the `security_hardening` role using Docker.

---
*Part of the [AWS Portfolio](https://github.com/omesh7/aws-portfolio)*
