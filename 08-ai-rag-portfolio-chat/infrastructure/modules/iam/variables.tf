variable "bucket_arn" {
  type        = string
  description = "ARN of the S3 bucket to be used by the IAM role"

}


variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources"
}
