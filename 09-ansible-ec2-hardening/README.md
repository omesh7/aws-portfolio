# Ansible EC2 Hardening — Roles + Vault + Molecule

Production-grade configuration management with Ansible. Provisions EC2 instances via Terraform, then applies security hardening, Docker installation, and application deployment using role-based Ansible playbooks with Vault-encrypted secrets.

## Architecture

```
Terraform ──► 2x EC2 (AL2023) + Security Group
                      │
                      ▼
Ansible (Dynamic Inventory — aws_ec2 plugin)
    │
    ├── common          → System updates, sysctl tuning
    ├── security        → Disable root SSH, fail2ban, firewalld
    ├── docker          → Docker Engine + Compose
    └── webserver       → Containerized app + Nginx reverse proxy
```

## Key Features

- **Dynamic Inventory**: EC2 instances auto-discovered by tag (`Environment=staging`).
- **Role-Based**: 4 decoupled roles — reusable across environments.
- **Ansible Vault**: DB passwords, API keys encrypted at rest.
- **Security Hardening**: Key-only SSH, fail2ban, firewalld, disabled root login.
- **CI/CD**: GitHub Actions runs `ansible-lint` + dry-run (`--check`) on every push.
- **Molecule**: Local testing of the `security_hardening` role via Docker.
- **Makefile**: `make deploy`, `make vault-edit`, `make lint`.

## Project Structure

```
├── ansible/
│   ├── ansible.cfg              # Dynamic inventory, key config
│   ├── site.yml                 # Master playbook
│   ├── hardening.yml            # Security-only playbook
│   ├── inventory/
│   │   └── aws_ec2.yml          # Dynamic inventory plugin
│   ├── group_vars/all/
│   │   ├── vars.yml             # Non-sensitive variables
│   │   └── vault.yml            # Vault-encrypted secrets
│   └── roles/
│       ├── common/
│       ├── security_hardening/
│       │   └── molecule/        # Molecule test config
│       ├── docker/
│       └── webserver/
├── terraform/                   # EC2 + SG provisioning
├── Makefile
└── .github/workflows/
    └── ansible.yml              # Lint + dry-run CI
```

## Quick Start

```bash
# 1. Provision EC2 instances
cd terraform
terraform init
terraform apply -var="public_key=$(cat ~/.ssh/id_rsa.pub)"

# 2. Run full playbook
make deploy
# or
ansible-playbook ansible/site.yml --ask-vault-pass

# 3. Security hardening only
ansible-playbook ansible/hardening.yml --ask-vault-pass
```

## Vault Management

```bash
# Edit encrypted secrets
make vault-edit

# View encrypted file
ansible-vault view ansible/group_vars/all/vault.yml
```

## Security Gates (CI)

| Check | What It Does |
|---|---|
| `ansible-lint` | Enforces Ansible best practices |
| `--check` (dry run) | Validates playbook against staging without changing state |
| Molecule | Tests `security_hardening` role in a Docker container |

## Cleanup

```bash
cd terraform && terraform destroy
```

---
*Part of the [AWS DevOps Portfolio](https://github.com/omesh7/aws-portfolio)*
