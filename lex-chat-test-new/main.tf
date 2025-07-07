terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.93.0"
    }
    # random = {
    #   source  = "hashicorp/random"
    #   version = ">= 3.7.2"
    # }
  }
}

provider "aws" {
  region = var.aws_region
  #   default_tags {
  #     tags = var.tags
  #   }
}



module "kb" {
  source = "github.com/Robyt96/terraform-aws-bedrock-kb-aurora"

  aws_region = var.aws_region
  kb_config = [{
    kb_name            = "test_knowledge_base"
    source_bucket_name = "09-lex-chatbot-knowledge-base-bucket"

  }]

  rds_config = {
    vpc_id      = var.vpc_id
    db_name     = "Bedrock_Knowledge_Base_Cluster_test"
    subnet_ids  = var.subnet_ids
    db_username = "test_bedrock_user"
  }

  resource_name_prefix = "lex-test-kb"

  tags = {
    "project" : "kb-test-tag"
  }
}
