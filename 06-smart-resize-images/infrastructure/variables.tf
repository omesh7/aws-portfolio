variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "06-resized-images-bucket-aws-portfolio"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "environment" {
  description = "Environment (local or ci)"
  type        = string
  default     = "local"
}

variable "lambda_zip_path" {
  description = "Path to Lambda deployment package"
  type        = string
  default     = "lambda-package.zip"
}

variable "vercel_api_token" {
  description = "Vercel API token"
  type        = string
  default     = ""
  sensitive   = true
}

variable "vercel_project_name" {
  description = "Vercel project name"
  type        = string
  default     = "image-resizer-aws-portfolio"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Project     = "06-resized-images-bucket-aws-portfolio"
    Environment = "portfolio"
    project-no  = "06"
  }
}
