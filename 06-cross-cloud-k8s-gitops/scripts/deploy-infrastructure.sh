#!/bin/bash

set -e

echo "🚀 Deploying Cross-Cloud Kubernetes Infrastructure"

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
    
    command -v terraform >/dev/null 2>&1 || { print_error "Terraform is required but not installed."; exit 1; }
    command -v aws >/dev/null 2>&1 || { print_error "AWS CLI is required but not installed."; exit 1; }
    command -v gcloud >/dev/null 2>&1 || { print_error "Google Cloud SDK is required but not installed."; exit 1; }
    
    print_status "Prerequisites check passed ✅"
}

# Deploy AWS infrastructure
deploy_aws() {
    print_status "Deploying AWS infrastructure..."
    
    cd ../terraform/aws
    
    # Initialize Terraform
    terraform init
    
    # Plan deployment
    terraform plan -out=aws.tfplan
    
    # Apply deployment
    terraform apply aws.tfplan
    
    # Save outputs
    terraform output -json > aws-outputs.json
    
    print_status "AWS infrastructure deployed ✅"
    cd - > /dev/null
}

# Deploy GCP infrastructure
deploy_gcp() {
    print_status "Deploying GCP infrastructure..."
    
    cd ../terraform/gcp
    
    # Initialize Terraform
    terraform init
    
    # Plan deployment
    terraform plan -out=gcp.tfplan
    
    # Apply deployment
    terraform apply gcp.tfplan
    
    # Save outputs
    terraform output -json > gcp-outputs.json
    
    print_status "GCP infrastructure deployed ✅"
    cd - > /dev/null
}

# Update Ansible inventories
update_inventories() {
    print_status "Updating Ansible inventories..."
    
    # Extract IPs from Terraform outputs
    AWS_MASTER_IPS=$(cat ../terraform/aws/aws-outputs.json | jq -r '.master_ips.value[]')
    AWS_WORKER_IPS=$(cat ../terraform/aws/aws-outputs.json | jq -r '.worker_ips.value[]')
    AWS_MASTER_PRIVATE_IPS=$(cat ../terraform/aws/aws-outputs.json | jq -r '.master_private_ips.value[]')
    AWS_WORKER_PRIVATE_IPS=$(cat ../terraform/aws/aws-outputs.json | jq -r '.worker_private_ips.value[]')
    
    GCP_MASTER_IPS=$(cat ../terraform/gcp/gcp-outputs.json | jq -r '.master_ips.value[]')
    GCP_WORKER_IPS=$(cat ../terraform/gcp/gcp-outputs.json | jq -r '.worker_ips.value[]')
    GCP_MASTER_PRIVATE_IPS=$(cat ../terraform/gcp/gcp-outputs.json | jq -r '.master_private_ips.value[]')
    GCP_WORKER_PRIVATE_IPS=$(cat ../terraform/gcp/gcp-outputs.json | jq -r '.worker_private_ips.value[]')
    
    print_warning "Please update the inventory files manually with the following IPs:"
    echo "AWS Master IPs: $AWS_MASTER_IPS"
    echo "AWS Worker IPs: $AWS_WORKER_IPS"
    echo "GCP Master IPs: $GCP_MASTER_IPS"
    echo "GCP Worker IPs: $GCP_WORKER_IPS"
    
    print_status "Inventory update information provided ✅"
}

# Main execution
main() {
    print_status "Starting cross-cloud infrastructure deployment..."
    
    check_prerequisites
    
    # Deploy infrastructure in parallel
    deploy_aws &
    AWS_PID=$!
    
    deploy_gcp &
    GCP_PID=$!
    
    # Wait for both deployments to complete
    wait $AWS_PID
    wait $GCP_PID
    
    update_inventories
    
    print_status "🎉 Infrastructure deployment completed!"
    print_status "Next steps:"
    echo "1. Update Ansible inventory files with the provided IPs"
    echo "2. Run: ./deploy-kubernetes.sh"
    echo "3. Run: ./deploy-gitops.sh"
}

# Run main function
main "$@"