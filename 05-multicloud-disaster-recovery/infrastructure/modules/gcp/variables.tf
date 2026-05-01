variable "domain_name" {
  description = "The domain name for the website"
  type        = string
}

variable "gcp_region" {
  description = "Google Cloud region"
  type        = string
}

variable "gcp_project_id" {
  description = "Google Cloud project ID"
  type        = string
}

variable "lambda_function_url" {
  description = "AWS Lambda function URL for API calls"
  type        = string
}