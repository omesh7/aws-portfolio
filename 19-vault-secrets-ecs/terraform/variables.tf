variable "aws_region" {
  description = "AWS region to deploy to"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project used for resource naming"
  type        = string
  default     = "vault-production"
}

variable "domain_name" {
  description = "The domain name for the Vault ALB (e.g. vault.example.com). Must be valid for ACM."
  type        = string
}

variable "vault_image" {
  description = "Docker image for Vault"
  type        = string
  default     = "hashicorp/vault:1.15"
}
