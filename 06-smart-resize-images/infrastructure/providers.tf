
terraform {
  backend "s3" {
    bucket         = "aws-portfolio-terraform-state"
    key            = "06-smart-resize-images/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "aws-portfolio-terraform-locks"
    encrypt        = true
  }
  required_providers {
    vercel = {
      source  = "vercel/vercel"
      version = "~>3.8.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~>6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.tags
  }
}

provider "vercel" {
  api_token = var.vercel_api_token
}


