
variable "project_suffix" {
  description = "Unique suffix for resource names"
  type        = string
  default     = "08-rag-portfolio-chat-aws-portfolio"
}
variable "embed_model" {
  default = "amazon.titan-embed-text-v2:0"
}

variable "image_uri" {
  description = "ECR image URI for the Lambda function"
  type        = string
}

variable "subnet_ids" {
  default     = []
  description = "Optional for future"
}

variable "vpc_id" {
  default     = ""
  description = "Optional for future"
}

variable "chat_model" {
  default     = ""
  description = "The chat model to use for the application"
}

variable "aws_region" {
  default     = "ap-south-1"
  description = "AWS region for the resources"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources"
  default = {
    "project-no" = "8"
  }

}

