terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "networking" {
  source       = "./modules/networking"
  project_name = var.project_name
}

module "vault" {
  source             = "./modules/vault"
  project_name       = var.project_name
  vpc_id             = module.networking.vpc_id
  public_subnets     = module.networking.public_subnets
  private_subnets    = module.networking.private_subnets
  execution_role_arn = module.iam.execution_role_arn
  task_role_arn      = module.iam.task_role_arn
  domain_name        = var.domain_name
}

module "iam" {
  source              = "./modules/iam"
  project_name        = var.project_name
  dynamodb_table_arn  = module.vault.dynamodb_table_arn
  kms_key_arn         = module.vault.kms_key_arn
  secrets_manager_arn = module.vault.secrets_manager_arn
}

output "vault_alb_dns" {
  value = module.vault.alb_dns_name
}

output "vault_root_token_secret_arn" {
  value = module.vault.secrets_manager_arn
}
