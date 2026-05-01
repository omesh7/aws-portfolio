#!/bin/bash

set -e

echo "🚀 Deploying Kubernetes Clusters with Kubespray"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    command -v ansible >/dev/null 2>&1 || { print_error "Ansible is required but not installed."; exit 1; }
    command -v git >/dev/null 2>&1 || { print_error "Git is required but not installed."; exit 1; }
    
    print_status "Prerequisites check passed ✅"
}

# Setup Kubespray
setup_kubespray() {
    print_status "Setting up Kubespray..."
    
    if [ ! -d "kubespray" ]; then
        git clone https://github.com/kubernetes-sigs/kubespray.git
        cd kubespray
        git checkout release-2.23
        pip3 install -r requirements.txt
        cd ..
    else
        print_status "Kubespray already exists, skipping clone"
    fi
    
    print_status "Kubespray setup completed ✅"
}

# Deploy AWS cluster
deploy_aws_cluster() {
    print_status "Deploying AWS Kubernetes cluster..."
    
    cd kubespray
    
    # Copy inventory
    cp -r ../ansible/inventory/aws inventory/aws-cluster
    cp -r ../ansible/group_vars inventory/aws-cluster/
    
    # Deploy cluster
    ansible-playbook -i inventory/aws-cluster/hosts.yml \
        --become --become-user=root \
        cluster.yml
    
    # Get kubeconfig
    ansible-playbook -i inventory/aws-cluster/hosts.yml \
        --become --become-user=root \
        --extra-vars "kubeconfig_localhost=true" \
        cluster.yml
    
    # Copy kubeconfig
    mkdir -p ~/.kube
    cp inventory/aws-cluster/artifacts/admin.conf ~/.kube/config-aws
    
    print_status "AWS cluster deployed ✅"
    cd ..
}

# Deploy GCP cluster
deploy_gcp_cluster() {
    print_status "Deploying GCP Kubernetes cluster..."
    
    cd kubespray
    
    # Copy inventory
    cp -r ../ansible/inventory/gcp inventory/gcp-cluster
    cp -r ../ansible/group_vars inventory/gcp-cluster/
    
    # Deploy cluster
    ansible-playbook -i inventory/gcp-cluster/hosts.yml \
        --become --become-user=root \
        cluster.yml
    
    # Get kubeconfig
    ansible-playbook -i inventory/gcp-cluster/hosts.yml \
        --become --become-user=root \
        --extra-vars "kubeconfig_localhost=true" \
        cluster.yml
    
    # Copy kubeconfig
    mkdir -p ~/.kube
    cp inventory/gcp-cluster/artifacts/admin.conf ~/.kube/config-gcp
    
    print_status "GCP cluster deployed ✅"
    cd ..
}

# Verify clusters
verify_clusters() {
    print_status "Verifying cluster deployments..."
    
    # Test AWS cluster
    export KUBECONFIG=~/.kube/config-aws
    kubectl get nodes
    kubectl get pods --all-namespaces
    
    print_status "AWS cluster verification completed ✅"
    
    # Test GCP cluster
    export KUBECONFIG=~/.kube/config-gcp
    kubectl get nodes
    kubectl get pods --all-namespaces
    
    print_status "GCP cluster verification completed ✅"
}

# Main execution
main() {
    print_status "Starting Kubernetes cluster deployment..."
    
    check_prerequisites
    setup_kubespray
    
    # Deploy clusters in parallel
    deploy_aws_cluster &
    AWS_PID=$!
    
    deploy_gcp_cluster &
    GCP_PID=$!
    
    # Wait for both deployments to complete
    wait $AWS_PID
    wait $GCP_PID
    
    verify_clusters
    
    print_status "🎉 Kubernetes clusters deployment completed!"
    print_status "Kubeconfig files:"
    echo "  AWS: ~/.kube/config-aws"
    echo "  GCP: ~/.kube/config-gcp"
    print_status "Next step: Run ./deploy-gitops.sh"
}

# Run main function
main "$@"