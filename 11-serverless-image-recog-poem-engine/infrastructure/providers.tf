# -------------------------------
# Terraform Configuration
# -------------------------------
terraform {
  backend "s3" {
    bucket         = "aws-portfolio-terraform-state"
    key            = "11-serverless-image-recog-poem-engine/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "aws-portfolio-terraform-locks"
    encrypt        = true

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

    vercel = {
      source  = "vercel/vercel"
      version = "3.12.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
  }
}

# -------------------------------
# Provider Configuration
# -------------------------------
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.tags
  }
}


provider "vercel" {
  # Configuration options
  api_token = var.vercel_api_token

}


provider "cloudflare" {
  api_token = var.cloudflare_api_token
}


data "cloudflare_zone" "zone" {
  zone_id = var.cloudflare_zone_id
}
