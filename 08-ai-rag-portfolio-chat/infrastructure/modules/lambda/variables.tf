variable "role_arn" {
  description = "IAM role ARN for the Lambda function"
  type        = string

}
variable "function_zip" {
  description = "Path to the Lambda function zip file"
  type        = string
}

variable "bucket_name" {
  description = "S3 bucket name for the Lambda function"
  type        = string
}

variable "embed_model" {
  description = "Embedding model to be used by the Lambda function"
  type        = string
  default     = "amazon.titan-embed-text-v1"
}

variable "source_dir" {
  description = "Source directory for the Lambda function code"
  type        = string
}


variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources"
}

variable "project_suffix" {
  description = "Unique suffix for resource names"
  type        = string
  default     = ""
}
