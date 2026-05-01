#!/bin/bash

# Exit on error
set -e

echo "Starting cleanup of EKS Monitoring Stack..."

# 1. Delete Kubernetes resources (optional but good practice)
# We use -f to avoid errors if the files aren't applied
echo "Deleting K8s manifests..."
kubectl delete -f ../k8s/ --ignore-not-found=true || true
kubectl delete -f ../monitoring-config/prometheus-rules.yaml --ignore-not-found=true || true

# 2. Terraform Destroy
echo "Running terraform destroy..."
cd terraform
terraform destroy -auto-approve

echo "Cleanup complete!"
