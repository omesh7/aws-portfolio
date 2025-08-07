variable "role_arn" {
  description = "IAM role ARN for the Lambda function"
  type        = string

}
variable "image_uri" {
  description = "ECR image URI for the Lambda function"
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




variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources"
}

variable "project_suffix" {
  description = "Unique suffix for resource names"
  type        = string
  default     = ""
}

variable "log_group_name" {
  description = "CloudWatch log group name for Lambda function"
  type        = string
}
