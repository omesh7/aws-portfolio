# Cross-Cloud Kubernetes Cluster with GitOps

Multi-cloud Kubernetes deployment across AWS and GCP with GitOps CI/CD using Terraform, Kubespray, and Argo CD.

## Architecture

Two HA Kubernetes clusters (AWS + GCP) with:
- **Infrastructure**: Terraform for VMs and networking
- **K8s Deployment**: Kubespray (Ansible) for cluster setup
- **GitOps**: Argo CD for application deployment
- **DNS/LB**: Cloudflare for global load balancing
- **Optional**: Cilium Cluster Mesh for cross-cluster networking

## Quick Start

```bash
# 1. Infrastructure
cd terraform/aws && terraform apply
cd ../gcp && terraform apply

# 2. Kubernetes
cd ../../ansible
ansible-playbook -i inventory/aws/hosts.yml cluster.yml
ansible-playbook -i inventory/gcp/hosts.yml cluster.yml

# 3. GitOps
kubectl apply -f gitops/argocd/
```

## Prerequisites

- AWS CLI + GCP CLI configured
- Terraform >= 1.0
- Ansible >= 2.12
- kubectl
- Cloudflare account (for DNS)

## Project Structure

```
├── terraform/          # Infrastructure as Code
│   ├── aws/            # AWS VPC, VMs, security groups
│   └── gcp/            # GCP VPC, VMs, firewall rules
├── ansible/            # Kubespray configuration
│   └── inventory/      # Cluster inventories
├── gitops/             # Argo CD and applications
│   ├── argocd/         # Argo CD installation
│   └── apps/           # Application manifests
└── scripts/            # Automation scripts
```

## Milestones

1. ✅ **Infrastructure**: Multi-cloud VMs with Terraform
2. ✅ **Kubernetes**: HA clusters with Kubespray
3. ✅ **GitOps**: Argo CD deployment
4. ✅ **DNS/LB**: Cloudflare global routing
5. 🔄 **Service Mesh**: Cilium Cluster Mesh (optional)

## Tech Stack

- **Infrastructure**: Terraform, AWS, GCP
- **Orchestration**: Kubernetes, Kubespray
- **GitOps**: Argo CD, Helm, Kustomize
- **Networking**: Cilium, ExternalDNS, Cloudflare
- **Monitoring**: Prometheus, Grafana (optional)

## Cost Optimization

- Use spot instances where possible
- Auto-scaling for worker nodes
- Resource quotas and limits
- Scheduled cluster shutdown for dev/test

---

**Note**: This is a production-ready setup. Start with single-node clusters for testing.