# Cross-Cloud Kubernetes Deployment Guide

Complete step-by-step guide to deploy a production-ready cross-cloud Kubernetes cluster with GitOps.

## Prerequisites

### Required Tools
```bash
# Install Terraform
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install terraform

# Install Ansible
pip3 install ansible

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip && sudo ./aws/install

# Install Google Cloud SDK
curl https://sdk.cloud.google.com | bash
exec -l $SHELL
```

### Cloud Accounts Setup

#### AWS Setup
```bash
# Configure AWS CLI
aws configure

# Create S3 bucket for Terraform state
aws s3 mb s3://k8s-crosscloud-tfstate
aws dynamodb create-table \
    --table-name k8s-crosscloud-locks \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5
```

#### GCP Setup
```bash
# Authenticate with GCP
gcloud auth login
gcloud config set project YOUR_PROJECT_ID

# Create GCS bucket for Terraform state
gsutil mb gs://k8s-crosscloud-tfstate-gcp

# Enable required APIs
gcloud services enable compute.googleapis.com
gcloud services enable container.googleapis.com
```

#### SSH Key Setup
```bash
# Generate SSH key pair
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
```

## Deployment Steps

### Step 1: Infrastructure Deployment

```bash
# Clone the repository
git clone <your-repo-url>
cd 15-cross-cloud-k8s-gitops

# Make scripts executable
chmod +x scripts/*.sh

# Deploy infrastructure
./scripts/deploy-infrastructure.sh
```

**Expected Output:**
- AWS VPC with 3 subnets across AZs
- 3 master nodes + 3 worker nodes in AWS
- GCP VPC with subnet
- 3 master nodes + 3 worker nodes in GCP
- Load balancers for API servers
- Security groups and firewall rules

### Step 2: Update Inventory Files

After infrastructure deployment, update the inventory files with actual IPs:

```bash
# Edit AWS inventory
vim ansible/inventory/aws/hosts.yml

# Edit GCP inventory
vim ansible/inventory/gcp/hosts.yml
```

Replace placeholder IPs with actual values from Terraform outputs.

### Step 3: Kubernetes Deployment

```bash
# Deploy Kubernetes clusters
./scripts/deploy-kubernetes.sh
```

**Expected Output:**
- HA Kubernetes clusters on both clouds
- Cilium CNI for networking
- CoreDNS for service discovery
- Ingress controllers
- Kubeconfig files: `~/.kube/config-aws` and `~/.kube/config-gcp`

### Step 4: GitOps Setup

```bash
# Deploy Argo CD and GitOps components
./scripts/deploy-gitops.sh
```

**Expected Output:**
- Argo CD installed on both clusters
- ExternalDNS for automatic DNS management
- Sample applications deployed
- Access URLs and credentials

### Step 5: Cloudflare Configuration

1. **Add DNS Records:**
   ```bash
   # AWS cluster
   aws-k8s.example.com -> AWS_LB_IP
   
   # GCP cluster
   gcp-k8s.example.com -> GCP_LB_IP
   ```

2. **Configure Load Balancer:**
   - Create Cloudflare Load Balancer
   - Add both clusters as origins
   - Set health checks on `/healthz`
   - Configure failover rules

### Step 6: Verification

```bash
# Test AWS cluster
export KUBECONFIG=~/.kube/config-aws
kubectl get nodes
kubectl get pods --all-namespaces

# Test GCP cluster
export KUBECONFIG=~/.kube/config-gcp
kubectl get nodes
kubectl get pods --all-namespaces

# Test Argo CD access
curl -k https://AWS_ARGOCD_URL/api/version
curl -k https://GCP_ARGOCD_URL/api/version
```

## Optional: Cilium Cluster Mesh

For advanced cross-cluster networking:

```bash
# Install Cilium CLI
curl -L --remote-name-all https://github.com/cilium/cilium-cli/releases/latest/download/cilium-linux-amd64.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-amd64.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-amd64.tar.gz /usr/local/bin

# Enable cluster mesh on AWS
export KUBECONFIG=~/.kube/config-aws
cilium clustermesh enable --service-type LoadBalancer

# Enable cluster mesh on GCP
export KUBECONFIG=~/.kube/config-gcp
cilium clustermesh enable --service-type LoadBalancer

# Connect clusters
cilium clustermesh connect --destination-context gcp-cluster
```

## Monitoring and Maintenance

### Health Checks
```bash
# Check cluster health
kubectl get nodes
kubectl get pods --all-namespaces
kubectl top nodes
kubectl top pods --all-namespaces

# Check Argo CD sync status
kubectl get applications -n argocd
```

### Scaling
```bash
# Scale worker nodes (update Terraform variables)
cd terraform/aws
terraform plan -var="worker_count=5"
terraform apply

# Add nodes to cluster
cd ../../kubespray
ansible-playbook -i inventory/aws-cluster/hosts.yml scale.yml
```

### Backup
```bash
# Backup etcd
kubectl get all --all-namespaces -o yaml > cluster-backup.yaml

# Backup Argo CD applications
kubectl get applications -n argocd -o yaml > argocd-apps-backup.yaml
```

## Troubleshooting

### Common Issues

1. **Terraform State Lock:**
   ```bash
   terraform force-unlock LOCK_ID
   ```

2. **Ansible Connection Issues:**
   ```bash
   ansible all -i inventory/aws/hosts.yml -m ping
   ssh -i ~/.ssh/id_rsa ubuntu@NODE_IP
   ```

3. **Kubernetes API Unreachable:**
   ```bash
   kubectl cluster-info
   kubectl get cs
   ```

4. **Argo CD Not Accessible:**
   ```bash
   kubectl port-forward svc/argocd-server -n argocd 8080:443
   ```

### Logs and Debugging
```bash
# Check kubelet logs
journalctl -u kubelet -f

# Check container runtime
systemctl status containerd

# Check Argo CD logs
kubectl logs -n argocd deployment/argocd-server
```

## Cost Optimization

### Development Environment
- Use t3.small instances
- Single master node
- Spot instances for workers
- Schedule cluster shutdown

### Production Environment
- Use reserved instances
- Auto-scaling groups
- Resource quotas and limits
- Monitoring and alerting

## Security Best Practices

1. **Network Security:**
   - Private subnets for worker nodes
   - Security groups with minimal access
   - Network policies

2. **RBAC:**
   - Least privilege access
   - Service accounts for applications
   - Regular access reviews

3. **Secrets Management:**
   - External secrets operator
   - Vault integration
   - Encrypted etcd

4. **Image Security:**
   - Private registries
   - Image scanning
   - Admission controllers

## Next Steps

1. **CI/CD Integration:**
   - GitHub Actions workflows
   - Automated testing
   - Progressive deployments

2. **Observability:**
   - Prometheus and Grafana
   - Distributed tracing
   - Log aggregation

3. **Service Mesh:**
   - Istio or Linkerd
   - mTLS between services
   - Traffic management

4. **Disaster Recovery:**
   - Cross-region backups
   - Automated failover
   - Recovery testing

---

**Support:** For issues and questions, check the troubleshooting section or create an issue in the repository.