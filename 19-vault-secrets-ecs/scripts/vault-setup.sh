#!/bin/bash
set -e

# Configuration
VAULT_ADDR=${VAULT_ADDR:-"https://vault.example.com"}
VAULT_TOKEN=${VAULT_TOKEN} # Root token should be provided as env var

if [ -z "$VAULT_TOKEN" ]; then
    echo "Error: VAULT_TOKEN environment variable is required."
    exit 1
fi

export VAULT_ADDR=$VAULT_ADDR
export VAULT_TOKEN=$VAULT_TOKEN

echo "Setting up Vault engines and auth methods..."

# 1. Enable KV v2 at secret/
vault secrets enable -path=secret kv-v2 || echo "KV engine already enabled"

# 2. Enable AWS secrets engine
vault secrets enable aws || echo "AWS secrets engine already enabled"

# Configure AWS engine (Assumes task role has IAM permissions)
vault write aws/config/root \
    region=us-east-1

# Create a role for dynamic IAM credentials
vault write aws/roles/my-role \
    credential_type=iam_user \
    policy_document=-<<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": "*"
    }
  ]
}
EOF

# 3. Enable AppRole auth method
vault auth enable approle || echo "AppRole already enabled"

# 4. Create policies
vault policy write app-policy vault/policies/app-policy.hcl
vault policy write admin-policy vault/policies/admin-policy.hcl

# 5. Create AppRole role and binding
vault write auth/approle/role/sample-app-role \
    secret_id_ttl=24h \
    token_num_uses=10 \
    token_ttl=1h \
    token_max_ttl=3h \
    policies="app-policy"

# Get Role ID and Secret ID for the sample app
ROLE_ID=$(vault read -field=role_id auth/approle/role/sample-app-role/role-id)
SECRET_ID=$(vault write -f -field=secret_id auth/approle/role/sample-app-role/secret-id)

echo "Setup complete!"
echo "Sample App Role ID: $ROLE_ID"
echo "Sample App Secret ID: $SECRET_ID (one-time use)"

# Create a sample secret
vault kv put secret/app/config db_password="super-secret-password-123"
