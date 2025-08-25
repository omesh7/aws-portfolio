terraform {
  backend "s3" {
    bucket         = "aws-portfolio-terraform-state"
    key            = "12-kubernetes-python-youtube-summarizer/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "aws-portfolio-terraform-locks"
    encrypt        = true
    use_lockfile   = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Environment = var.environment
      Application = var.app_name
      Owner       = "Omesh"
      Project     = "AWS Portfolio 12 - Kubernetes Simple App"
      project_no  = "12"
    }
  }
}

