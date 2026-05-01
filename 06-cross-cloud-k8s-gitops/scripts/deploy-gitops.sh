#!/bin/bash

set -e

echo "🚀 Deploying GitOps with Argo CD"

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
    
    command -v kubectl >/dev/null 2>&1 || { print_error "kubectl is required but not installed."; exit 1; }
    
    # Check if kubeconfig files exist
    if [ ! -f ~/.kube/config-aws ]; then
        print_error "AWS kubeconfig not found. Run deploy-kubernetes.sh first."
        exit 1
    fi
    
    if [ ! -f ~/.kube/config-gcp ]; then
        print_error "GCP kubeconfig not found. Run deploy-kubernetes.sh first."
        exit 1
    fi
    
    print_status "Prerequisites check passed ✅"
}

# Install Argo CD on AWS cluster
install_argocd_aws() {
    print_status "Installing Argo CD on AWS cluster..."
    
    export KUBECONFIG=~/.kube/config-aws
    
    # Install Argo CD operator
    kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    
    # Wait for Argo CD to be ready
    kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
    
    # Apply custom configuration
    kubectl apply -f ../gitops/argocd/
    
    # Get initial admin password
    AWS_ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
    
    print_status "AWS Argo CD installed ✅"
    print_status "AWS Argo CD admin password: $AWS_ARGOCD_PASSWORD"
}

# Install Argo CD on GCP cluster
install_argocd_gcp() {
    print_status "Installing Argo CD on GCP cluster..."
    
    export KUBECONFIG=~/.kube/config-gcp
    
    # Install Argo CD operator
    kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    
    # Wait for Argo CD to be ready
    kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
    
    # Apply custom configuration
    kubectl apply -f ../gitops/argocd/
    
    # Get initial admin password
    GCP_ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
    
    print_status "GCP Argo CD installed ✅"
    print_status "GCP Argo CD admin password: $GCP_ARGOCD_PASSWORD"
}

# Install ExternalDNS
install_external_dns() {
    print_status "Installing ExternalDNS..."
    
    # Create Cloudflare API token secret (you need to provide this)
    print_warning "Please create Cloudflare API token secret manually:"
    echo "kubectl create secret generic cloudflare-api-token --from-literal=api-token=YOUR_TOKEN -n kube-system"
    
    # Install on AWS cluster
    export KUBECONFIG=~/.kube/config-aws
    kubectl apply -f ../gitops/environments/aws/external-dns.yaml
    
    # Install on GCP cluster
    export KUBECONFIG=~/.kube/config-gcp
    kubectl apply -f ../gitops/environments/gcp/external-dns.yaml
    
    print_status "ExternalDNS installed ✅"
}

# Deploy sample applications
deploy_sample_apps() {
    print_status "Deploying sample applications..."
    
    # Deploy to AWS cluster
    export KUBECONFIG=~/.kube/config-aws
    kubectl apply -f ../gitops/apps/sample-app.yaml
    
    # Deploy to GCP cluster
    export KUBECONFIG=~/.kube/config-gcp
    kubectl apply -f ../gitops/apps/sample-app.yaml
    
    print_status "Sample applications deployed ✅"
}

# Get access information
get_access_info() {
    print_status "Getting access information..."
    
    # AWS cluster info
    export KUBECONFIG=~/.kube/config-aws
    AWS_ARGOCD_IP=$(kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    if [ -z "$AWS_ARGOCD_IP" ]; then
        AWS_ARGOCD_IP=$(kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
    fi
    
    # GCP cluster info
    export KUBECONFIG=~/.kube/config-gcp
    GCP_ARGOCD_IP=$(kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    if [ -z "$GCP_ARGOCD_IP" ]; then
        GCP_ARGOCD_IP=$(kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
    fi
    
    print_status "Access Information:"
    echo "AWS Argo CD: https://$AWS_ARGOCD_IP"
    echo "GCP Argo CD: https://$GCP_ARGOCD_IP"
    echo "Username: admin"
    echo "AWS Password: $AWS_ARGOCD_PASSWORD"
    echo "GCP Password: $GCP_ARGOCD_PASSWORD"
}

# Main execution
main() {
    print_status "Starting GitOps deployment..."
    
    check_prerequisites
    
    # Install Argo CD on both clusters
    install_argocd_aws &
    AWS_PID=$!
    
    install_argocd_gcp &
    GCP_PID=$!
    
    # Wait for both installations to complete
    wait $AWS_PID
    wait $GCP_PID
    
    install_external_dns
    deploy_sample_apps
    get_access_info
    
    print_status "🎉 GitOps deployment completed!"
    print_status "Next steps:"
    echo "1. Configure Cloudflare Load Balancer for global traffic routing"
    echo "2. Set up monitoring and alerting"
    echo "3. Configure Cilium Cluster Mesh (optional)"
}

# Run main function
main "$@"