variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "07-automated-receipt-processor-ci"
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

variable "s3_bucket_name" {
  description = "S3 bucket name for receipt uploads"
  type        = string
  default     = "07-receipt-processor-aws-portfolio"
}

variable "dynamodb_table_name" {
  description = "DynamoDB table name for receipts"
  type        = string
  default     = "Receipts"
}