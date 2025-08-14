terraform {
  cloud {
    organization = "aws-portfolio-omesh"
    workspaces {
      name = "12-kubernetes-python-youtube-summarizer"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
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

