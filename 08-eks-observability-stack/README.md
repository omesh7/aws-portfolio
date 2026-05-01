# EKS Observability Stack — Prometheus + Grafana + HPA

Complete observability stack for Amazon EKS using Terraform, Helm, Prometheus, and Grafana. Includes auto-scaling with HPA, custom alerting rules, and pre-built dashboards.

## Architecture

```
┌─────────────────────────────────────────────────┐
│ AWS (us-east-1)                                 │
│                                                 │
│  VPC (10.0.0.0/16)                              │
│  ┌──────────────┐      ┌──────────────┐         │
│  │ Public Sub AZ1│      │ Public Sub AZ2│        │
│  │ [NAT Gateway] │      │              │        │
│  └──────┬───────┘      └──────┬───────┘         │
│         ▼                     ▼                  │
│  ┌──────────────┐      ┌──────────────┐         │
│  │Private Sub AZ1│      │Private Sub AZ2│        │
│  │[EKS Node Grp] │      │[EKS Node Grp] │       │
│  └──────┬───────┘      └──────┬───────┘         │
│         └────────┬────────────┘                  │
│                  ▼                               │
│  ┌─────────────────────────────────┐             │
│  │ Kubernetes (EKS)                │             │
│  │ ┌───────────────┐ ┌──────────┐ │             │
│  │ │ kube-prom-stack│ │ Metrics  │ │             │
│  │ │ (Helm)        │ │ Server   │ │             │
│  │ └───────────────┘ └──────────┘ │             │
│  │ ┌───────────────┐ ┌──────────┐ │             │
│  │ │ Flask App Pods│ │ HPA      │ │             │
│  │ │ (3 replicas)  │ │ CPU >70% │ │             │
│  │ └───────────────┘ └──────────┘ │             │
│  └─────────────────────────────────┘             │
└─────────────────────────────────────────────────┘
```

## Key Features

- **Terraform IaC**: VPC + EKS cluster provisioned with modular Terraform.
- **Helm**: `kube-prometheus-stack` for managed Prometheus, Grafana, and Alertmanager.
- **HPA**: Horizontal Pod Autoscaler with `metrics-server` (CPU > 70% threshold).
- **Custom Alerts**: CrashLoop, MemoryPressure, ReplicaMismatch rules in Alertmanager.
- **Dashboards**: Pre-built Grafana JSON dashboard for pod-level metrics.

## Project Structure

```
├── terraform/                   # VPC + EKS + Helm releases
│   ├── main.tf
│   ├── variables.tf
│   └── terraform.tfvars.example
├── k8s/                         # Application manifests
│   ├── deployment.yaml          # Flask app + HPA
│   └── service.yaml
├── monitoring-config/
│   ├── prometheus-rules.yaml    # Custom alert rules
│   └── grafana-dashboards/
│       └── pod-stats.json       # Dashboard export
├── destroy.sh                   # Full teardown script
└── README.md
```

## Quick Start

```bash
# 1. Deploy infrastructure
cd terraform
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply

# 2. Configure kubectl
aws eks update-kubeconfig --region us-east-1 --name monitoring-stack-eks

# 3. Deploy app + monitoring
kubectl apply -f k8s/
kubectl apply -f monitoring-config/prometheus-rules.yaml
```

## Access Monitoring

```bash
# Grafana (admin / <your-password-from-tfvars>)
kubectl port-forward svc/kube-prometheus-stack-grafana -n monitoring 3000:80

# Prometheus
kubectl port-forward svc/kube-prometheus-stack-prometheus -n monitoring 9090:9090

# Alertmanager
kubectl port-forward svc/kube-prometheus-stack-alertmanager -n monitoring 9093:9093
```

Import custom dashboard: Grafana → Dashboards → Import → upload `monitoring-config/grafana-dashboards/pod-stats.json`.

## Cost Warning

| Resource | Est. Monthly Cost |
|---|---|
| EKS Control Plane | ~$72 |
| NAT Gateway | ~$32 |
| 2-4x t3.medium nodes | ~$60 |
| EBS (Prometheus/Grafana) | ~$5 |
| **Total** | **~$5-7/day** |

> Always run `./destroy.sh` when finished.

## Cleanup

```bash
./destroy.sh
```

---
*Part of the [AWS DevOps Portfolio](https://github.com/omesh7/aws-portfolio)*
