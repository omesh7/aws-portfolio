# EKS Monitoring Stack (Observability)

A complete observability stack for Amazon EKS using Terraform, Helm, Prometheus, and Grafana.

## Architecture

```text
+-----------------------------------------------------------+
| AWS Region (us-east-1)                                    |
| +-------------------------------------------------------+ |
| | VPC                                                   | |
| | +-------------------+       +-------------------+     | |
| | | Public Subnet AZ1 |       | Public Subnet AZ2 |     | |
| | | [NAT Gateway]     |       |                   |     | |
| | +---------+---------+       +---------+---------+     | |
| |           |                           |               | |
| | +---------v---------+       +---------v---------+     | |
| | | Private Subnet AZ1|       | Private Subnet AZ2|     | |
| | | [EKS Node Group]  |       | [EKS Node Group]  |     | |
| | +---------+---------+       +---------+---------+     | |
| +-----------|---------------------------|---------------+ |
|             |                           |                 |
|      +------v---------------------------v------+           |
|      |        Kubernetes Cluster (EKS)        |           |
|      | +------------------+ +---------------+ |           |
|      | | kube-prometheus- | | Metrics Server| |           |
|      | | stack (Helm)     | | (HPA support) | |           |
|      | +------------------+ +---------------+ |           |
|      |                                        |           |
|      | +------------------+ +---------------+ |           |
|      | | Flask App Pods   | | HPA Resource  | |           |
|      | | (3 Replicas)     | | (CPU > 70%)   | |           |
|      | +------------------+ +---------------+ |           |
|      +----------------------------------------+           |
+-----------------------------------------------------------+
```

## Features

- **Infrastructure as Code**: Full VPC and EKS setup using Terraform modules.
- **Managed Prometheus/Grafana**: Deployed via `kube-prometheus-stack` Helm chart.
- **Auto-Scaling**: `metrics-server` and `HorizontalPodAutoscaler` configured for the sample app.
- **Custom Alerts**: Alertmanager rules for CrashLoops, Memory Pressure, and Replica mismatches.
- **Dashboards**: Pre-configured JSON dashboard for Pod-level metrics.

## Deployment Steps

### 1. Initialize Infrastructure
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your settings
terraform init
terraform apply
```

### 2. Configure Kubectl
```bash
# Command provided in terraform outputs
aws eks update-kubeconfig --region us-east-1 --name monitoring-stack-eks
```

### 3. Deploy Application and Monitoring Config
```bash
cd ..
kubectl apply -f k8s/
kubectl apply -f monitoring-config/prometheus-rules.yaml
```

### 4. Access Monitoring Tools

**Grafana:**
```bash
# Port forward to local port 3000
kubectl port-forward svc/kube-prometheus-stack-grafana -n monitoring 3000:80
```
- **URL**: [http://localhost:3000](http://localhost:3000)
- **User**: admin
- **Password**: (Your `grafana_admin_password` from tfvars)

**Alertmanager:**
```bash
kubectl port-forward svc/kube-prometheus-stack-alertmanager -n monitoring 9093:9093
```
- **URL**: [http://localhost:9093](http://localhost:9093)

**Prometheus:**
```bash
kubectl port-forward svc/kube-prometheus-stack-prometheus -n monitoring 9090:9090
```

## Import Custom Dashboard
1. Go to Grafana -> Dashboards -> Import.
2. Upload the JSON file from `monitoring-config/grafana-dashboards/pod-stats.json`.

## Cleanup
To avoid ongoing AWS charges:
```bash
./destroy.sh
```

## AWS Cost Warning
This stack uses:
- 1 NAT Gateway (~$32/month)
- 1 EKS Cluster Control Plane (~$72/month)
- 2-4 t3.medium EC2 instances (~$60/month base)
- EBS Volumes for Prometheus/Grafana persistence.
**Estimated cost: ~$5-7 per day.** Always run `./destroy.sh` when finished.
