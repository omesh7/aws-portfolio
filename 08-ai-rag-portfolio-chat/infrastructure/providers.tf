terraform {
  backend "s3" {
    bucket         = "aws-portfolio-terraform-state"
    key            = "08-ai-rag-portfolio-chat/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "aws-portfolio-terraform-locks"
    encrypt        = true


  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = { source = "hashicorp/random", version = "~> 3.0" }
  }
}



provider "aws" {
  region = var.aws_region
}

