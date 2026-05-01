# Cross-Cloud K8s GitOps — Terraform + Kubespray + Argo CD

Multi-cloud Kubernetes deployment across AWS and GCP. Infrastructure provisioned with Terraform, clusters bootstrapped with Kubespray (Ansible), and applications deployed via Argo CD GitOps.

## Architecture

```
Terraform ──┬── AWS VPC + VMs ──┐
            │                   │
            └── GCP VPC + VMs ──┤
                                ▼
                        Kubespray (Ansible)
                                │
                   ┌────────────┴────────────┐
                   ▼                         ▼
            K8s Cluster (AWS)         K8s Cluster (GCP)
                   │                         │
                   └────────┬────────────────┘
                            ▼
                      Argo CD (GitOps)
                            │
                            ▼
                    Cloudflare (Global LB)
```

## Key Features

- **Multi-Cloud IaC**: Terraform provisions VMs and networking on both AWS and GCP.
- **Kubespray**: Ansible-based HA Kubernetes cluster deployment.
- **GitOps**: Argo CD watches Git for declarative application state.
- **Global DNS**: Cloudflare for cross-cloud load balancing.
- **Optional**: Cilium Cluster Mesh for cross-cluster networking.

## Project Structure

```
├── terraform/               # Infrastructure as Code
│   ├── aws/                 # VPC, VMs, security groups
│   └── gcp/                 # VPC, VMs, firewall rules
├── ansible/                 # Kubespray configuration
│   └── inventory/           # Per-cluster inventory files
├── gitops/                  # Argo CD + application manifests
│   ├── argocd/
│   └── apps/
├── scripts/                 # Automation helpers
└── DEPLOYMENT_GUIDE.md      # Step-by-step walkthrough
```

## Quick Start

```bash
# 1. Provision infrastructure
cd terraform/aws && terraform apply
cd ../gcp && terraform apply

# 2. Bootstrap Kubernetes clusters
cd ../../ansible
ansible-playbook -i inventory/aws/hosts.yml cluster.yml
ansible-playbook -i inventory/gcp/hosts.yml cluster.yml

# 3. Deploy GitOps controller
kubectl apply -f gitops/argocd/
```

## Prerequisites

- AWS CLI + GCP CLI configured
- Terraform >= 1.0
- Ansible >= 2.12
- kubectl
- Cloudflare account (for DNS)

## Tech Stack

| Layer | Tool |
|---|---|
| Infrastructure | Terraform (AWS + GCP) |
| K8s Bootstrap | Kubespray / Ansible |
| GitOps | Argo CD, Helm, Kustomize |
| Networking | Cilium, ExternalDNS |
| DNS / LB | Cloudflare |

## Cost Optimization

- Spot/preemptible instances for worker nodes.
- Auto-scaling node groups.
- Resource quotas and LimitRanges.
- Scheduled shutdown for non-production.

---
*Part of the [AWS DevOps Portfolio](https://github.com/omesh7/aws-portfolio)*