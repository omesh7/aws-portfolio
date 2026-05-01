terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }

  backend "s3" {
    # Configure via -backend-config or terraform.tfvars
    # bucket = "your-terraform-state-bucket"
    # key    = "finops-cost-optimizer/terraform.tfstate"
    # region = "ap-south-1"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "finops-cost-optimizer"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = "devops"
    }
  }
}
