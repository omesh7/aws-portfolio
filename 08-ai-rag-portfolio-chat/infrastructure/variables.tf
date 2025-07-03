# S3 Bucket for Lambda code
variable "s3_bucket" {

  description = "S3 bucket name for Lambda code"
  type        = string
  default     = "08-ai-rag-portfolio-chat-aws-portfolio"

}
variable "s3_bucket_prefix" {
  description = "S3 bucket prefix for Lambda code"
  type        = string
  default     = "readmes"
}
