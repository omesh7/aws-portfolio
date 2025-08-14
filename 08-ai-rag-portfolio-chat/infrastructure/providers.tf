terraform {
  cloud {
    organization = "aws-portfolio-omesh"
    workspaces {
      name = "08-ai-rag-portfolio-chat"
    }
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

