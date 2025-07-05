# Terraform v6 AWS LangChain RAG variables

# variable "s3_bucket" {
#   description = "S3 bucket name where Lambda ingests documents"
#   type        = string
# }

# variable "s3_bucket_prefix" {
#   description = "Key prefix within S3 bucket where files are stored"
#   type        = string
#   default     = "docs"
# }

# variable "aurora_cluster_arn" {
#   description = "ARN of the Aurora Serverless PostgreSQL cluster"
#   type        = string
# }

# variable "aurora_secret_arn" {
#   description = "ARN of the Secrets Manager secret with DB credentials"
#   type        = string
# }
variable "vpc_id" {
  description = "VPC ID where the Aurora cluster and Lambda function are deployed"
  type        = string
}

variable "db_user" {
  description = "Database username for Aurora Serverless"
  type        = string
  default     = "postgres"

}

variable "db_name" {
  description = "Aurora database name (must exist within cluster)"
  type        = string
  default     = "postgres"
}

variable "db_schema" {
  description = "Schema name within the database for RAG table"
  type        = string
  default     = "bedrock_integration"
}

variable "table_name" {
  description = "Table name in Aurora for storing embeddings"
  type        = string
  default     = "bedrock_kb"
}

variable "embed_model" {
  description = "Amazon Bedrock embedding model"
  type        = string
  default     = "amazon.titan-embed-text-v2:0"
}

variable "chat_model" {
  description = "Amazon Bedrock chat/GPT model"
  type        = string
  default     = "amazon.titan-text-chat:0"
}
variable "db_password" {
  description = "Database password for Aurora Serverless"
  type        = string
  sensitive   = true
}

variable "subnet_ids" {
  description = "List of subnet IDs for the Aurora cluster and Lambda function"
  type        = list(string)
  default     = []
  sensitive   = true

}

variable "db_table" {
  description = "Full table name in the format 'schema.table' for RAG operations"
  type        = string
  default     = "bedrock_integration"

}
