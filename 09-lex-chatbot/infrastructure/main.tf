#terraform plan -generate-config-out="generated_resources.tf" 
terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.93.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.7.2"
    }
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = var.tags
  }
}

resource "random_id" "suffix" {
  byte_length = 4
}

import {
  to = aws_s3_bucket.bucket
  id = "09-lex-chatbot-knowledge-base-bucket"
}


import {
  to = aws_bedrockagent_knowledge_base.lex_bot_kb
  id = "H355OEACHV"
}

import {
  to = aws_lexv2models_bot.lex_bot
  id = "OMDQWXDCLR"
}

import {
  to = aws_lexv2models_bot_version.lex_bot_version
  id = "OMDQWXDCLR,1"

}

import {
  to = aws_lexv2models_bot_locale.bot_locale
  id = "en_US,OMDQWXDCLR,1"

}



# resource "aws_s3_bucket_versioning" "kb_docs_versioning" {
#   bucket = aws_s3_bucket.kb_docs.id
#   versioning_configuration {
#     status = "Enabled"
#   }
# }

# resource "aws_iam_role" "bedrock_role" {
#   name = "bedrock-custom-model-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Action    = "sts:AssumeRole"
#       Effect    = "Allow"
#       Principal = { Service = "bedrock.amazonaws.com" }
#     }]
#   })
# }

# resource "aws_iam_role_policy" "bedrock_s3_access" {
#   name = "bedrock-s3-access"
#   role = aws_iam_role.bedrock_role.id

#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [{
#       Action = ["s3:GetObject", "s3:ListBucket", "s3:PutObject"],
#       Effect = "Allow",
#       Resource = [
#         aws_s3_bucket.kb_docs.arn,
#         "${aws_s3_bucket.kb_docs.arn}/*"
#       ]
#     }]
#   })
# }

# data "aws_bedrock_foundation_model" "embed_model" {
#   model_id = "amazon.titan-embed-text-v2:0"
# }

# data "aws_bedrock_custom_model" "inference_model" {
#   model_id = "anthropic.claude-3-haiku-20240307-v1:0"
# }

# module "bedrock_kb" {
#   source  = "aws-ia/bedrock/aws"
#   version = "0.0.29"

#   create_kb             = true
#   kb_name               = "09-lex-chatbot-kb"
#   create_s3_data_source = true
#   # s3_bucket_arn              = aws_s3_bucket.kb_docs.arn
#   # s3_metadata_fields         = ["author", "creation-date"]
#   # kb_execution_role_arn      = aws_iam_role.bedrock_role.arn
#   s3_data_source_bucket_name = aws_s3_bucket.kb_docs.bucket
#   kb_embedding_model_arn     = data.aws_bedrock_foundation_model.embed_model.model_arn
#   kb_role_arn                = aws_iam_role.bedrock_role.arn
#   embedding_model_dimensions = 1024

#   tags = {
#     project-no = "9"
#     Project    = "09-lex-chatbot"
#   }
# }

# resource "aws_iam_role" "lex_bot_role" {
#   name = "09-lex-chatbot-lex-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [{
#       Effect    = "Allow",
#       Principal = { Service = "lexv2.amazonaws.com" },
#       Action    = "sts:AssumeRole"
#     }]
#   })
# }

# resource "aws_iam_role_policy" "lex_bot_policy" {
#   name = "09-lex-chatbot-lex-policy"
#   role = aws_iam_role.lex_bot_role.id

#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Effect   = "Allow",
#         Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"],
#         Resource = "*"
#       },
#       {
#         Effect = "Allow",
#         Action = [
#           "lex:Create*", "lex:Delete*", "lex:Put*"
#         ],
#         Resource = "*"
#       }
#     ]
#   })
# }

# resource "aws_lexv2models_bot" "bot_model" {
#   name                        = "09-lex-chatbot-bot"
#   description                 = "lex chatbot with Bedrock KB"
#   role_arn                    = aws_iam_role.lex_bot_role.arn
#   idle_session_ttl_in_seconds = 300
#   data_privacy {
#     child_directed = false
#   }
#   type = "Bot"
# }

# resource "aws_lexv2models_bot_locale" "bot_locale" {
#   bot_id      = aws_lexv2models_bot.bot_model.id
#   bot_version = "DRAFT"
#   locale_id   = "en_US"

#   name                             = "09-lex-chatbot-locale"
#   n_lu_intent_confidence_threshold = 0.8
#   description                      = "English locale"

#   voice_settings {
#     voice_id = "Ivy"
#     engine   = "standard"
#   }
# }

# resource "aws_lexv2models_intent" "qna_intent" {
#   name        = "09-lex-chatbot-QnAIntent"
#   bot_id      = aws_lexv2models_bot.bot_model.id
#   bot_version = aws_lexv2models_bot_locale.bot_locale.bot_version
#   locale_id   = aws_lexv2models_bot_locale.bot_locale.locale_id
#   description = "QnA intent for Lex bot with Bedrock KB"

#   parent_intent_signature = "AMAZON.QnAIntent"

#   initial_response_setting {
#     initial_response {
#       message_group {
#         message {
#           plain_text_message {
#             value = "Processing your question..."
#           }
#         }

#       }
#       allow_interrupt = false
#     }
#   }
# }

# output "s3_bucket" {
#   value = aws_s3_bucket.kb_docs.bucket
# }

# output "bedrock_kb_id" {
#   value = module.bedrock_kb.bda_blueprint
# }
