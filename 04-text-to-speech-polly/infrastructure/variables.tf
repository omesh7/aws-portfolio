variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "04-text-to-speech-polly"
}

variable "s3_bucket_name" {
  description = "S3 bucket name for audio files"
  type        = string
  default     = "04-polly-tts-audio-bucket"
}

variable "environment" {
  description = "Environment (local or ci)"
  type        = string
  default     = "local"
}

variable "lambda_zip_path" {
  description = "Path to pre-built lambda zip (for CI)"
  type        = string
  default     = ""
}