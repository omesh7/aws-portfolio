variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "lambda_function_name" {
  description = "Name of the Lambda function"
  type        = string
  default     = "aws-portfolio-controller"
}



variable "github_token" {
  description = "GitHub personal access token"
  type        = string
  sensitive   = true
}

variable "github_username" {
  description = "GitHub username"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "main-controller-app"
}

variable "tfc_api_token" {
  description = "Terraform Cloud API token"
  type        = string
  sensitive   = true
}

variable "tfc_organization" {
  description = "Terraform Cloud organization name"
  type        = string
  default     = "aws-portfolio"
}
