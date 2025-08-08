variable "aws_region" {
  description = "The AWS region where resources will be created."
  type        = string
  default     = "ap-south-1"

}


variable "project_name" {
  description = "The name of the project."
  type        = string
  default     = "08-ai-rag-portfolio-2-chat"
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default = {
    Project     = "08-ai-rag-portfolio-2-chat"
    Environment = "portfolio"
    project-no  = "08"
  }

}

#--------------------LAMBDA

variable "embed_model" {
  description = "Embed Model ID"
  type        = string
  default     = "amazon.titan-embed-text-v2:0"
}

variable "chat_model" {
  description = "Chat Model ID"
  type        = string
  default     = "anthropic.claude-3-haiku-20240307-v1:0"
}

variable "image_uri" {
  description = "ECR image URI for the Lambda function"
  type        = string
}
