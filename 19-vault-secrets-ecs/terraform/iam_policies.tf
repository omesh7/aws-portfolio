resource "aws_iam_policy" "vault_permissions" {
  name        = "${var.project_name}-vault-permissions"
  description = "Permissions for Vault to access DynamoDB, KMS, and Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:DescribeTable",
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:DescribeTimeToLive"
        ]
        Resource = module.vault.dynamodb_table_arn
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = module.vault.kms_key_arn
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:PutSecretValue"
        ]
        Resource = module.vault.secrets_manager_arn
      },
      {
        # Required for AWS Secrets Engine dynamic IAM credentials
        Effect = "Allow"
        Action = [
          "iam:CreateUser",
          "iam:DeleteUser",
          "iam:CreateAccessKey",
          "iam:DeleteAccessKey",
          "iam:AttachUserPolicy",
          "iam:DetachUserPolicy",
          "iam:PutUserPolicy",
          "iam:DeleteUserPolicy",
          "iam:ListUserPolicies",
          "iam:ListAttachedUserPolicies",
          "iam:GetUser"
        ]
        Resource = "arn:aws:iam::*:user/vault-*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "task_role_vault_policy" {
  role       = module.iam.task_role_name
  policy_arn = aws_iam_policy.vault_permissions.arn
}
