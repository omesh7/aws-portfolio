#!/bin/bash

set -e

echo "🗑️  Destroying Multi-Cloud Weather Tracker"
echo "=========================================="

command -v terraform >/dev/null 2>&1 || { echo "❌ Terraform required"; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/../../terraform"

echo "🔧 Destroying infrastructure..."
terraform destroy -auto-approve

echo "✅ Infrastructure destroyed!"