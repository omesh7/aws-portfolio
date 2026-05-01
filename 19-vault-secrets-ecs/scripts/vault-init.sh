#!/bin/bash
set -e

# Configuration
VAULT_ADDR=${VAULT_ADDR:-"https://vault.example.com"}
SECRET_NAME=${SECRET_NAME:-"vault-production/vault-root-token"}

echo "Checking Vault status at $VAULT_ADDR..."

# Check if Vault is initialized
INIT_STATUS=$(curl -s $VAULT_ADDR/v1/sys/init | jq -r .initialized)

if [ "$INIT_STATUS" == "true" ]; then
    echo "Vault is already initialized."
else
    echo "Vault is not initialized. Initializing..."
    
    # Initialize Vault
    INIT_RESPONSE=$(curl -s -X PUT -d '{"secret_shares": 5, "secret_threshold": 3}' $VAULT_ADDR/v1/sys/init)
    
    # Extract keys and token
    ROOT_TOKEN=$(echo $INIT_RESPONSE | jq -r .root_token)
    RECOVERY_KEYS=$(echo $INIT_RESPONSE | jq -r .keys_base64)
    
    echo "Vault initialized successfully!"
    echo "Root Token: $ROOT_TOKEN"
    echo "Recovery Keys: $RECOVERY_KEYS"
    
    # Store root token in AWS Secrets Manager
    aws secretsmanager put-secret-value --secret-id $SECRET_NAME --secret-string "$ROOT_TOKEN"
    
    echo "Root token stored in Secrets Manager: $SECRET_NAME"
    echo "IMPORTANT: Save the recovery keys securely! They are not stored in Secrets Manager."
fi
