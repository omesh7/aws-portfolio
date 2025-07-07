# __generated__ by Terraform
# Please review these resources and move them into your main configuration files.

# __generated__ by Terraform
resource "aws_lexv2models_bot_version" "lex_bot_version" {
  bot_id      = "OMDQWXDCLR"
  bot_version = "1"
  description = null
  locale_specification = {
    source_bot_version = "1"
  }
}

# __generated__ by Terraform from "en_US,OMDQWXDCLR,1"
resource "aws_lexv2models_bot_locale" "bot_locale" {
  bot_id                           = "OMDQWXDCLR"
  bot_version                      = "1"
  description                      = null
  locale_id                        = "en_US"
  n_lu_intent_confidence_threshold = 0.4
  name                             = "English (US)"
  voice_settings {
    engine   = "neural"
    voice_id = "Joanna"
  }
}

# __generated__ by Terraform from "H355OEACHV"
resource "aws_bedrockagent_knowledge_base" "lex_bot_kb" {
  description = null
  name        = "09-lex-chatbot-knowledge-base"
  role_arn    = "arn:aws:iam::982534384941:role/service-role/AmazonBedrockExecutionRoleForKnowledgeBase_sss8v"
  tags        = null
  knowledge_base_configuration {
    type = "VECTOR"
    vector_knowledge_base_configuration {
      embedding_model_arn = "arn:aws:bedrock:us-east-1::foundation-model/amazon.titan-embed-text-v2:0"
      embedding_model_configuration {
        bedrock_embedding_model_configuration {
          dimensions          = 1024
          embedding_data_type = null
        }
      }
    }
  }
  storage_configuration {
    type = "RDS"
    rds_configuration {
      credentials_secret_arn = "arn:aws:secretsmanager:us-east-1:982534384941:secret:BedrockUserSecret-Pbint0nsUqEM-iQ3x4F"
      database_name          = "Bedrock_Knowledge_Base_Cluster"
      resource_arn           = "arn:aws:rds:us-east-1:982534384941:cluster:knowledgebasequickcreateaurora-a00-auroradbcluster-j4fn9zt7qkrk"
      table_name             = "bedrock_integration.bedrock_knowledge_base"
      field_mapping {
        metadata_field    = "metadata"
        primary_key_field = "id"
        text_field        = "chunks"
        vector_field      = "embedding"
      }
    }
  }
}

# __generated__ by Terraform from "OMDQWXDCLR"
resource "aws_lexv2models_bot" "lex_bot" {
  description                 = "Helput Assistant 09-project-lex-bot-rag"
  idle_session_ttl_in_seconds = 300
  name                        = "MYAWSBOT"
  role_arn                    = "arn:aws:iam::982534384941:role/aws-service-role/lexv2.amazonaws.com/AWSServiceRoleForLexV2Bots_7QS88KPCMY"
  tags                        = null
  test_bot_alias_tags         = null
  type                        = "Bot"
  data_privacy {
    child_directed = false
  }
}

# __generated__ by Terraform from "09-lex-chatbot-knowledge-base-bucket"
resource "aws_s3_bucket" "bucket" {
  bucket              = "09-lex-chatbot-knowledge-base-bucket"
  bucket_prefix       = null
  force_destroy       = null
  object_lock_enabled = false
  tags                = {}
  tags_all            = {}
}
