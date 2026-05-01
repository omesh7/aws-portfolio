#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# destroy.sh — Safely tear down all FinOps Cost Optimizer infrastructure
# Usage: ./destroy.sh [--auto-approve]
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

TF_DIR="$(cd "$(dirname "$0")/terraform" && pwd)"
AUTO_APPROVE="${1:-}"

echo "╔══════════════════════════════════════════════════════════╗"
echo "║       FinOps Cost Optimizer — Destroy                    ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

if [[ "$AUTO_APPROVE" != "--auto-approve" ]]; then
  echo "⚠️  This will DESTROY all FinOps resources. This cannot be undone."
  echo "   Resources that will be deleted:"
  echo "   - 2x Lambda functions (scheduler, cost-reporter)"
  echo "   - EventBridge rule + target"
  echo "   - SNS topics + subscriptions"
  echo "   - AWS Cost Anomaly Monitor + Subscription"
  echo "   - IAM roles + policies"
  echo "   - CloudWatch Log Groups"
  echo ""
  read -rp "Type 'yes' to confirm: " confirm
  if [[ "$confirm" != "yes" ]]; then
    echo "Aborted."
    exit 0
  fi
fi

echo "→ Initializing Terraform..."
cd "$TF_DIR"
terraform init

echo "→ Running terraform destroy..."
if [[ "$AUTO_APPROVE" == "--auto-approve" ]]; then
  terraform destroy -auto-approve
else
  terraform destroy
fi

echo ""
echo "✅ Destroy complete. All FinOps Cost Optimizer resources removed."
