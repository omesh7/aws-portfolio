variable "aws_region" { default = "ap-south-1" }
variable "project_name" { default = "11-serverless-image-recog-poem-aws-portfolio" }
variable "tags" {
  default = {
    Environment = "Portfolio"
    Project     = "serverless-11-image-recog-poem"
    project-no  = "11"
  }
  type = map(string)
}
variable "bedrock_model_id" {
  default = "amazon.titan-text-lite-v1"
}

variable "environment" {
  description = "Environment (local or ci)"
  type        = string
  default     = "local"
}

variable "lambda_uploads_zip_path" {
  description = "Path to uploads lambda zip file"
  type        = string
  default     = ""
}

variable "lambda_image_recog_zip_path" {
  description = "Path to image recog lambda zip file"
  type        = string
  default     = ""
}

variable "lambda_get_poem_zip_path" {
  description = "Path to get poem lambda zip file"
  type        = string
  default     = ""
}

variable "vercel_api_token" {
  description = "Vercel API token"
  type        = string
  sensitive   = true
}

variable "vercel_project_name" {
  description = "Vercel project name"
  type        = string
  default     = "serverless-poem-engine"
  sensitive   = false
}
