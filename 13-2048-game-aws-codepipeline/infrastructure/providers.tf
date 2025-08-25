
terraform {
  backend "s3" {
    bucket         = "aws-portfolio-terraform-state"
    key            = "13-2048-game-aws-codepipeline/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "aws-portfolio-terraform-locks"

    encrypt = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    grafana = {
      source  = "grafana/grafana"
      version = "~> 2.0"
    }
  }
}

# Configure AWS provider with default tags for resource management
provider "aws" {
  region = var.aws_region
  default_tags {
    tags = var.tags
  }
}

# Configure Grafana provider (use Grafana Cloud free tier)
provider "grafana" {
  url  = var.grafana_url
  auth = var.grafana_auth
}



# Random string for unique resource naming to avoid conflicts
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}
