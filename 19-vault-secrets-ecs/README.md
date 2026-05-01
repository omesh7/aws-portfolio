# 19-vault-secrets-ecs: Production-Grade HashiCorp Vault on AWS

A production-grade, highly available HashiCorp Vault deployment on AWS ECS Fargate featuring auto-unseal via KMS and DynamoDB storage backend.

## Architecture

```ascii
      +-----------------------------------------------------------+
      | AWS Cloud (Region: us-east-1)                             |
      |                                                           |
      |   +---------------------------------------------------+   |
      |   | VPC (10.0.0.0/16)                                 |   |
      |   |                                                   |   |
      |   |   +-----------------+       +-----------------+   |   |
      |   |   | Public Subnet 1 |       | Public Subnet 2 |   |   |
      |   |   | [ ALB (HTTPS) ] |<----->| [ ALB (HTTPS) ] |   |   |
      |   |   +--------+--------+       +--------+--------+   |   |
      |   |            |                         |            |   |
      |   |            v                         v            |   |
      |   |   +-----------------+       +-----------------+   |   |
      |   |   | Private Subnet 1|       | Private Subnet 2|   |   |
      |   |   | [ Vault Task 1 ]|       | [ Vault Task 2 ]|   |   |
      |   |   +--------+--------+       +--------+--------+   |   |
      |   |            |                         |            |   |
      |   +------------|-------------------------|------------+   |
      |                |                         |                |
      |     +----------v----------+    +---------v---------+      |
      |     | DynamoDB (Storage)  |    | AWS KMS (Unseal)  |      |
      |     +---------------------+    +-------------------+      |
      |                                                           |
      |     +---------------------+                               |
      |     | AWS Secrets Manager | (Stores Root Token)           |
      |     +---------------------+                               |
      +-----------------------------------------------------------+
```

## Features
- **Auto-Unseal**: Uses AWS KMS for automated unsealing, removing the need for manual intervention on restarts.
- **Durable Storage**: DynamoDB backend for high availability and serverless scalability.
- **TLS Termination**: AWS ALB handles SSL/TLS termination with ACM certificates.
- **Dynamic Secrets**: Configured with AWS Secrets Engine to generate on-demand IAM credentials.
- **AppRole Auth**: Secure machine-to-machine authentication for applications.

## Prerequisites
- AWS CLI configured
- Terraform >= 1.0.0
- A registered domain name in Route53 (or manual DNS entry)

## Deployment Steps

### 1. Provision Infrastructure
```bash
make init
make apply
```
**Note**: Manual Step - You must validate the ACM certificate by adding the DNS records shown in the AWS Console.

### 2. Initialize Vault
Once the ALB is active and the certificate is validated:
```bash
export VAULT_ADDR="https://your-vault-domain.com"
make vault-init
```
This script will initialize Vault, store the root token in AWS Secrets Manager, and output recovery keys. **Store recovery keys safely!**

### 3. Setup Vault Engines
```bash
export VAULT_TOKEN=$(aws secretsmanager get-secret-value --secret-id vault-production/vault-root-token --query SecretString --output text)
make vault-setup
```

### 4. Test Sample App
The sample app (`sample-app/`) demonstrates how to:
1. Authenticate using AppRole.
2. Fetch a secret from Vault KV v2.
3. Use the secret in a Flask endpoint.

## Why Dynamic Secrets?
Unlike static IAM keys (which are often leaked or forgotten), Vault's AWS secrets engine generates **temporary** IAM credentials.
- **Lease Duration**: Credentials expire automatically (e.g., after 1 hour).
- **Auditability**: Every credential request is logged in Vault.
- **Blast Radius**: If a token is compromised, it has a short lifespan and can be revoked instantly.

## Cost Estimate (Monthly)
| Resource | Count | Estimated Cost |
| --- | --- | --- |
| ECS Fargate (0.5 vCPU, 1GB RAM) | 1 | ~$15 |
| NAT Gateway | 1 | ~$32 |
| Application Load Balancer | 1 | ~$16 |
| DynamoDB | PAY_PER_REQUEST | ~$1 |
| KMS Key | 1 | ~$1 |
| **Total** | | **~$65** |

## Maintenance
- **Unseal Status**: `make status`
- **Rotate Root Token**: `make rotate-root`
- **Teardown**: `make teardown`
