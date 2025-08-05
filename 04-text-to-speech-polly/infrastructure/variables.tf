variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "s3_bucket_name" {
  description = "S3 bucket name for audio files"
  type        = string
  default     = "04-polly-tts-aws-portfolio-bucket"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "04-polly-tts-aws-portfolio"
}
